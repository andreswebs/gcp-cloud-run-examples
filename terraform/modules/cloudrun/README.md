# cloudrun

[//]: # (BEGIN_TF_DOCS)





## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_containers"></a> [containers](#input\_containers) | List of container objects. | <pre>list(object({<br/>    name       = string<br/>    image      = string<br/>    depends_on = optional(list(string))<br/>    command    = optional(list(string))<br/>    args       = optional(list(string))<br/>    env = optional(list(object({<br/>      name  = string,<br/>      value = optional(string),<br/>      value_source = optional(object({<br/>        secret_key_ref = optional(object({<br/>          secret  = string,<br/>          version = optional(string, "latest")<br/>        }))<br/>      }))<br/>    }))),<br/>    liveness_probe = optional(object({<br/>      grpc = optional(object({<br/>        port    = optional(number)<br/>        service = optional(string)<br/>      }))<br/>      http_get = optional(object({<br/>        http_headers = optional(map(string))<br/>        path         = optional(string)<br/>        port         = optional(number)<br/>      }))<br/>      failure_threshold     = optional(number)<br/>      initial_delay_seconds = optional(number)<br/>      period_seconds        = optional(number)<br/>      timeout_seconds       = optional(number)<br/>    }))<br/>    ports = optional(map(object({<br/>      container_port = optional(number)<br/>      name           = optional(string)<br/>    })))<br/>    resources = optional(object({<br/>      limits            = optional(map(string))<br/>      cpu_idle          = optional(bool)<br/>      startup_cpu_boost = optional(bool)<br/>    }))<br/>    startup_probe = optional(object({<br/>      grpc = optional(object({<br/>        port    = optional(number)<br/>        service = optional(string)<br/>      }))<br/>      http_get = optional(object({<br/>        http_headers = optional(map(string))<br/>        path         = optional(string)<br/>        port         = optional(number)<br/>      }))<br/>      tcp_socket = optional(object({<br/>        port = optional(number)<br/>      }))<br/>      failure_threshold     = optional(number)<br/>      initial_delay_seconds = optional(number)<br/>      period_seconds        = optional(number)<br/>      timeout_seconds       = optional(number)<br/>    }))<br/>    volume_mounts = optional(list(object({<br/>      name       = string,<br/>      mount_path = string,<br/>      sub_path   = optional(string)<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Deletion protection setting for this Cloud Run service. | `bool` | `false` | no |
| <a name="input_encryption_key"></a> [encryption\_key](#input\_encryption\_key) | The full resource name of the Cloud KMS CryptoKey. | `string` | `null` | no |
| <a name="input_iam_members"></a> [iam\_members](#input\_iam\_members) | Optional IAM bindings: list of { role, members } to grant on the Cloud Run resource | <pre>list(object({<br/>    role    = string<br/>    members = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_is_managed_revision"></a> [is\_managed\_revision](#input\_is\_managed\_revision) | Whether the Terraform module should control the deployment of revisions. | `bool` | `true` | no |
| <a name="input_job_config"></a> [job\_config](#input\_job\_config) | Cloud Run Job specific configuration options. | <pre>object({<br/>    annotations = optional(map(string), null)<br/>    max_retries = optional(number)<br/>    task_count  = optional(number)<br/>    timeout     = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Resource labels. | `map(string)` | `{}` | no |
| <a name="input_launch_stage"></a> [launch\_stage](#input\_launch\_stage) | The launch stage as defined by Google Cloud Platform Launch Stages. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used for Cloud Run service. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project id used for all resources. Defaults to the current project. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region used for all resources. | `string` | n/a | yes |
| <a name="input_revision_config"></a> [revision\_config](#input\_revision\_config) | Revision template configurations. | <pre>object({<br/>    gpu_zonal_redundancy_disabled = optional(bool)<br/>    labels                        = optional(map(string))<br/>    name                          = optional(string)<br/>    node_selector = optional(object({<br/>      accelerator = string<br/>    }))<br/>    vpc_access = optional(object({<br/>      connector = optional(string)<br/>      egress    = optional(string)<br/>      network   = optional(string)<br/>      subnet    = optional(string)<br/>      tags      = optional(list(string))<br/>    }), {})<br/>    timeout = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_secrets_access"></a> [secrets\_access](#input\_secrets\_access) | List of secret IDs or names to provide access to. | `list(string)` | `[]` | no |
| <a name="input_service_account_config"></a> [service\_account\_config](#input\_service\_account\_config) | Service account configurations. | <pre>object({<br/>    create       = optional(bool, true)<br/>    display_name = optional(string)<br/>    email        = optional(string)<br/>    name         = optional(string)<br/>    roles        = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_service_account_default_roles"></a> [service\_account\_default\_roles](#input\_service\_account\_default\_roles) | Service account default roles. | `list(string)` | <pre>[<br/>  "roles/logging.logWriter",<br/>  "roles/monitoring.metricWriter",<br/>  "roles/cloudtrace.agent"<br/>]</pre> | no |
| <a name="input_service_config"></a> [service\_config](#input\_service\_config) | Cloud Run Service specific configuration options. | <pre>object({<br/>    annotations                = optional(map(string), null)<br/>    client                     = optional(string, null)<br/>    client_version             = optional(string, null)<br/>    custom_audiences           = optional(list(string), null)<br/>    default_uri_disabled       = optional(bool, false)<br/>    description                = optional(string, null)<br/>    gen2_execution_environment = optional(bool, false)<br/>    ingress                    = optional(string, null)<br/>    invoker_iam_disabled       = optional(bool, false)<br/>    max_concurrency            = optional(number)<br/>    scaling = optional(object({<br/>      max_instance_count = optional(number)<br/>      min_instance_count = optional(number)<br/>    }))<br/>    timeout = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of Cloud Run resource to deploy: JOB or SERVICE. | `string` | `"SERVICE"` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Named volumes in containers in name => attributes format. | <pre>list(object({<br/>    name = string,<br/>    cloud_sql_instance = optional(object({<br/>      instances = optional(list(string))<br/>    })),<br/>    empty_dir = optional(object({<br/>      medium     = optional(string),<br/>      size_limit = optional(string)<br/>    })),<br/>    gcs = optional(object({<br/>      bucket        = string,<br/>      mount_options = optional(list(string)),<br/>      read_only     = optional(bool)<br/>    })),<br/>    nfs = optional(object({<br/>      path      = string,<br/>      read_only = optional(bool),<br/>      server    = string<br/>    })),<br/>    secret = optional(object({<br/>      default_mode = optional(number),<br/>      secret       = string,<br/>      items = optional(list(object({<br/>        mode    = optional(number),<br/>        path    = string,<br/>        version = optional(string)<br/>      })))<br/>    }))<br/>  }))</pre> | `[]` | no |



## Outputs

| Name | Description |
|------|-------------|
| <a name="output_job"></a> [job](#output\_job) | The `google_cloud_run_v2_job` resource |
| <a name="output_service"></a> [service](#output\_service) | The `google_cloud_run_v2_service` resource |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The `google_service_account` resource |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 7.14 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.14 |

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_job.managed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job) | resource |
| [google_cloud_run_v2_job.unmanaged](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job) | resource |
| [google_cloud_run_v2_job_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job_iam_member) | resource |
| [google_cloud_run_v2_service.managed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service.unmanaged](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_project_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_secret_manager_secret_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_compute_default_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_default_service_account) | data source |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_secret_manager_secret.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret) | data source |
| [google_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account) | data source |

[//]: # (END_TF_DOCS)