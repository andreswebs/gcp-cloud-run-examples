variable "containers" {
  description = "List of container objects."
  type = list(object({
    name       = string
    image      = string
    depends_on = optional(list(string))
    command    = optional(list(string))
    args       = optional(list(string))
    env = optional(list(object({
      name  = string,
      value = optional(string),
      value_source = optional(object({
        secret_key_ref = optional(object({
          secret  = string,
          version = optional(string, "latest")
        }))
      }))
    }))),
    liveness_probe = optional(object({
      grpc = optional(object({
        port    = optional(number)
        service = optional(string)
      }))
      http_get = optional(object({
        http_headers = optional(map(string))
        path         = optional(string)
        port         = optional(number)
      }))
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    ports = optional(map(object({
      container_port = optional(number)
      name           = optional(string)
    })))
    resources = optional(object({
      limits            = optional(map(string))
      cpu_idle          = optional(bool)
      startup_cpu_boost = optional(bool)
    }))
    startup_probe = optional(object({
      grpc = optional(object({
        port    = optional(number)
        service = optional(string)
      }))
      http_get = optional(object({
        http_headers = optional(map(string))
        path         = optional(string)
        port         = optional(number)
      }))
      tcp_socket = optional(object({
        port = optional(number)
      }))
      failure_threshold     = optional(number)
      initial_delay_seconds = optional(number)
      period_seconds        = optional(number)
      timeout_seconds       = optional(number)
    }))
    volume_mounts = optional(list(object({
      name       = string,
      mount_path = string,
      sub_path   = optional(string)
    })))
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for c in var.containers : (
        c.resources == null ? true : 0 == length(setsubtract(
          keys(lookup(c.resources, "limits", {})),
          ["cpu", "memory", "nvidia.com/gpu"]
        ))
      )
    ])
    error_message = "Only following resource limits are available: 'cpu', 'memory' and 'nvidia.com/gpu'."
  }
}

variable "deletion_protection" {
  description = "Deletion protection setting for this Cloud Run service."
  type        = bool
  default     = false
}

variable "encryption_key" {
  description = "The full resource name of the Cloud KMS CryptoKey."
  type        = string
  default     = null
}

variable "iam_members" {
  type = list(object({
    role    = string
    members = list(string)
  }))
  description = "Optional IAM bindings: list of { role, members } to grant on the Cloud Run resource"
  default     = []
  nullable    = false
}

variable "is_managed_revision" {
  description = "Whether the Terraform module should control the deployment of revisions."
  type        = bool
  nullable    = false
  default     = true
}

variable "job_config" {
  description = "Cloud Run Job specific configuration options."
  type = object({
    annotations = optional(map(string), null)
    max_retries = optional(number)
    task_count  = optional(number)
    timeout     = optional(string)
  })
  default  = {}
  nullable = false
  validation {
    condition     = var.job_config.timeout == null ? true : endswith(var.job_config.timeout, "s")
    error_message = "Timeout should follow format of number with up to nine fractional digits, ending with 's'. Example: '3.5s'."
  }
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "launch_stage" {
  description = "The launch stage as defined by Google Cloud Platform Launch Stages."
  type        = string
  default     = null
  validation {
    condition = (
      var.launch_stage == null ? true : contains(
        ["UNIMPLEMENTED", "PRELAUNCH", "EARLY_ACCESS", "ALPHA", "BETA",
      "GA", "DEPRECATED"], var.launch_stage)
    )
    error_message = <<EOF
    The launch stage should be one of UNIMPLEMENTED, PRELAUNCH, EARLY_ACCESS, ALPHA,
    BETA, GA, DEPRECATED.
    EOF
  }
}

variable "name" {
  description = "Name used for Cloud Run service."
  type        = string
}

variable "project_id" {
  description = "Project id used for all resources. Defaults to the current project."
  type        = string
  default     = null
}

variable "region" {
  description = "Region used for all resources."
  type        = string
}

variable "revision_config" {
  description = "Revision template configurations."
  type = object({
    gpu_zonal_redundancy_disabled = optional(bool)
    labels                        = optional(map(string))
    name                          = optional(string)
    node_selector = optional(object({
      accelerator = string
    }))
    vpc_access = optional(object({
      connector = optional(string)
      egress    = optional(string)
      network   = optional(string)
      subnet    = optional(string)
      tags      = optional(list(string))
    }), {})
    timeout = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition = (
      try(var.revision_config.vpc_access.egress, null) == null ? true : contains(
      ["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.revision_config.vpc_access.egress)
    )
    error_message = "Egress should be one of ALL_TRAFFIC, PRIVATE_RANGES_ONLY."
  }

  validation {
    condition = (
      var.revision_config.vpc_access.network == null || (var.revision_config.vpc_access.network != null && var.revision_config.vpc_access.subnet != null)
    )
    error_message = "When providing var.revision_config.vpc_access.network provide also var.revision_config.vpc_access.subnet."
  }
}

variable "secrets_access" {
  description = "List of secret IDs or names to provide access to."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "service_account_config" {
  description = "Service account configurations."
  type = object({
    create       = optional(bool, true)
    display_name = optional(string)
    email        = optional(string)
    name         = optional(string)
    roles        = optional(list(string), [])
  })
  nullable = false
  default  = {}
}

variable "service_account_default_roles" {
  description = "Service account default roles."
  type        = list(string)
  nullable    = false
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ]
}

variable "service_config" {
  description = "Cloud Run Service specific configuration options."
  type = object({
    annotations                = optional(map(string), null)
    client                     = optional(string, null)
    client_version             = optional(string, null)
    custom_audiences           = optional(list(string), null)
    default_uri_disabled       = optional(bool, false)
    description                = optional(string, null)
    gen2_execution_environment = optional(bool, false)
    ingress                    = optional(string, null)
    invoker_iam_disabled       = optional(bool, false)
    max_concurrency            = optional(number)
    scaling = optional(object({
      max_instance_count = optional(number)
      min_instance_count = optional(number)
    }))
    timeout = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition = (
      var.service_config.ingress == null ? true : contains(
        ["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.service_config.ingress)
    )
    error_message = <<EOF
    Ingress should be one of INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY,
    INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER.
    EOF
  }
}

variable "type" {
  description = "Type of Cloud Run resource to deploy: JOB or SERVICE."
  # description = "Type of Cloud Run resource to deploy: JOB, SERVICE or WORKERPOOL." ## TODO - WORKERPOOL will be supported in the future
  type    = string
  default = "SERVICE"
  validation {
    condition     = contains(["JOB", "WORKERPOOL", "SERVICE"], var.type)
    error_message = "Allowed values for `var.type` are: `JOB`, `SERVICE`."
    # error_message = "Allowed values for `var.type` are: `JOB`, `SERVICE`, `WORKERPOOL`"
  }
}

variable "volumes" {
  description = "Named volumes in containers in name => attributes format."
  type = list(object({
    name = string,
    cloud_sql_instance = optional(object({
      instances = optional(list(string))
    })),
    empty_dir = optional(object({
      medium     = optional(string),
      size_limit = optional(string)
    })),
    gcs = optional(object({
      bucket        = string,
      mount_options = optional(list(string)),
      read_only     = optional(bool)
    })),
    nfs = optional(object({
      path      = string,
      read_only = optional(bool),
      server    = string
    })),
    secret = optional(object({
      default_mode = optional(number),
      secret       = string,
      items = optional(list(object({
        mode    = optional(number),
        path    = string,
        version = optional(string)
      })))
    }))
  }))
  default  = []
  nullable = false
  validation {
    condition = alltrue([
      for v in var.volumes :
      sum([
        for k, vv in v :
        k != "name" && vv != null ? 1 : 0
      ]) == 1
    ])
    error_message = "Only one type of volume can be defined at a time."
  }
}

