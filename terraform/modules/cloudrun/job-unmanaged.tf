resource "google_cloud_run_v2_job" "unmanaged" {
  count = var.type == "JOB" && !var.is_managed_revision && length(var.containers) > 0 ? 1 : 0

  depends_on = [google_secret_manager_secret_iam_member.this]

  annotations         = var.job_config.annotations
  deletion_protection = var.deletion_protection
  labels              = var.labels
  launch_stage        = var.launch_stage
  location            = var.region
  name                = var.name
  project             = local.project_id

  template {
    labels     = var.revision_config.labels
    task_count = var.job_config.task_count

    template {
      encryption_key                = var.encryption_key
      gpu_zonal_redundancy_disabled = var.revision_config.gpu_zonal_redundancy_disabled
      max_retries                   = var.job_config.max_retries
      service_account               = local.service_account.email
      timeout                       = var.job_config.timeout

      dynamic "node_selector" {
        for_each = var.revision_config.node_selector == null ? [] : [""]
        content {
          accelerator = var.revision_config.node_selector.accelerator
        }
      }

      dynamic "vpc_access" {
        for_each = local.connector == null ? [] : [""]
        content {
          connector = local.connector
          egress    = try(var.revision_config.vpc_access.egress, null)
        }
      }

      dynamic "vpc_access" {
        for_each = var.revision_config.vpc_access.subnet == null && var.revision_config.vpc_access.network == null ? [] : [""]
        content {
          egress = var.revision_config.vpc_access.egress
          network_interfaces {
            subnetwork = var.revision_config.vpc_access.subnet == null ? null : lookup(
              local.ctx.subnets, var.revision_config.vpc_access.subnet,
              var.revision_config.vpc_access.subnet
            )
            network = var.revision_config.vpc_access.network == null ? null : lookup(
              local.ctx.networks, var.revision_config.vpc_access.network,
              var.revision_config.vpc_access.network
            )
            tags = var.revision_config.vpc_access.tags
          }
        }
      }

      dynamic "containers" {
        for_each = var.containers
        content {
          name       = containers.value.name
          image      = containers.value.image
          depends_on = containers.value.depends_on
          command    = containers.value.command
          args       = containers.value.args

          dynamic "env" {
            for_each = try(containers.value.env, null) != null ? containers.value.env : []
            content {
              name  = env.value.name
              value = try(env.value.value, null)
              dynamic "value_source" {
                for_each = try(env.value.value_source, null) != null ? [true] : []
                content {
                  dynamic "secret_key_ref" {
                    for_each = try(env.value.value_source.secret_key_ref, null) != null ? [true] : []
                    content {
                      secret  = env.value.value_source.secret_key_ref.secret
                      version = try(env.value.value_source.secret_key_ref.version, null)
                    }
                  }
                }
              }
            }
          }

          dynamic "resources" {
            for_each = containers.value.resources == null ? [] : [""]
            content {
              limits = containers.value.resources.limits
            }
          }

          dynamic "ports" {
            for_each = coalesce(containers.value.ports, tomap({}))
            content {
              container_port = ports.value.container_port
              name           = ports.value.name
            }
          }

          dynamic "volume_mounts" {
            for_each = try(containers.value.volume_mounts, null) != null ? [for v in containers.value.volume_mounts : v if v.name != "cloudsql"] : []
            content {
              name       = volume_mounts.value.name
              mount_path = volume_mounts.value.mount_path
              sub_path   = try(volume_mounts.value.sub_path, null)
            }
          }

          # CloudSQL is the last mount in the list returned by API
          dynamic "volume_mounts" {
            for_each = try(containers.value.volume_mounts, null) != null ? [for v in containers.value.volume_mounts : v if v.name == "cloudsql"] : []
            content {
              name       = volume_mounts.key
              mount_path = volume_mounts.value
            }
          }

          dynamic "startup_probe" {
            for_each = containers.value.startup_probe == null ? [] : [""]
            content {
              initial_delay_seconds = containers.value.startup_probe.initial_delay_seconds
              timeout_seconds       = containers.value.startup_probe.timeout_seconds
              period_seconds        = containers.value.startup_probe.period_seconds
              failure_threshold     = containers.value.startup_probe.failure_threshold
              dynamic "http_get" {
                for_each = containers.value.startup_probe.http_get == null ? [] : [""]
                content {
                  path = containers.value.startup_probe.http_get.path
                  port = containers.value.startup_probe.http_get.port
                  dynamic "http_headers" {
                    for_each = coalesce(containers.value.startup_probe.http_get.http_headers, tomap({}))
                    content {
                      name  = http_headers.key
                      value = http_headers.value
                    }
                  }
                }
              }
              dynamic "tcp_socket" {
                for_each = containers.value.startup_probe.tcp_socket == null ? [] : [""]
                content {
                  port = containers.value.startup_probe.tcp_socket.port
                }
              }
              dynamic "grpc" {
                for_each = containers.value.startup_probe.grpc == null ? [] : [""]
                content {
                  port    = containers.value.startup_probe.grpc.port
                  service = containers.value.startup_probe.grpc.service
                }
              }
            }
          }
        }
      }

      dynamic "volumes" {
        for_each = [for v in var.volumes : v if v.cloud_sql_instance == null]
        content {
          name = volumes.value.name
          dynamic "empty_dir" {
            for_each = try(volumes.value.empty_dir, null) != null ? [true] : []
            content {
              medium     = try(volumes.value.empty_dir.medium, null)
              size_limit = try(volumes.value.empty_dir.size_limit, null)
            }
          }
          dynamic "gcs" {
            for_each = try(volumes.value.gcs, null) != null ? [true] : []
            content {
              bucket        = volumes.value.gcs.bucket
              mount_options = try(volumes.value.gcs.mount_options, null)
              read_only     = try(volumes.value.gcs.read_only, null)
            }
          }
          dynamic "nfs" {
            for_each = try(volumes.value.nfs, null) != null ? [true] : []
            content {
              path      = volumes.value.nfs.path
              read_only = try(volumes.value.nfs.read_only, null)
              server    = volumes.value.nfs.server
            }
          }
          dynamic "secret" {
            for_each = try(volumes.value.secret, null) != null ? [true] : []
            content {
              default_mode = try(volumes.value.secret.default_mode, null)
              secret       = volumes.value.secret.secret
              dynamic "items" {
                for_each = try(volumes.value.secret.items, null) != null ? volumes.value.secret.items : []
                content {
                  mode    = try(items.value.mode, null)
                  path    = items.value.path
                  version = try(items.value.version, null)
                }
              }
            }
          }
        }
      }

      # CloudSQL is the last volume in the list returned by API
      dynamic "volumes" {
        for_each = [for v in var.volumes : v if v.cloud_sql_instance != null]
        content {
          name = volumes.value.name
          dynamic "cloud_sql_instance" {
            for_each = try(volumes.value.cloud_sql_instance, null) != null ? [true] : []
            content {
              instances = try(volumes.value.cloud_sql_instance.instances, null)
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].annotations["run.googleapis.com/operation-id"],
      template[0].template,
      template[0].labels
    ]
  }
}
