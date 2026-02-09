module "service" {
  source = "../../modules/cloudrun"
  region = var.region
  name   = "example-api"

  labels = {
    service = "example-api"
  }

  service_config = {
    invoker_iam_disabled = true
  }

  revision_config = {
    labels = {
      service = "example-api"
    }
  }

  containers = [
    {
      name        = "example-api"
      image       = var.service_image_uri
      description = "An example .NET web api to test Datadog configuration"

      resources = {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      liveness_probe = {
        http_get = {
          path = "/healthz"
        }
      }

      env = [
        {
          name  = "CORECLR_ENABLE_PROFILING"
          value = "1"
        },
        {
          name  = "DD_PROFILING_ALLOCATION_ENABLED"
          value = "true"
        },
        {
          name  = "DD_RUNTIME_METRICS_ENABLED"
          value = "true"
        },
        {
          name  = "DD_PROFILING_ENABLED"
          value = "true"
        },
        {
          name  = "DD_CODE_ORIGIN_FOR_SPANS_ENABLED"
          value = "true"
        },
        {
          name  = "DD_APM_ENABLED"
          value = "true"
        },
        {
          name  = "DD_LOGS_INJECTION"
          value = "true"
        },
        {
          name  = "DD_ENV"
          value = "devops-sandbox"
        },
        {
          name  = "DD_SERVICE" ## must be identical to the Cloud Run "service" label
          value = "example-api"
        },
        {
          name  = "DD_VERSION" ## set to git sha
          value = "4"
        },
      ]

      volume_mounts = [
        {
          name       = "logs"
          mount_path = "/app/logs"
        },
      ]
    },
    {
      name        = "datadog-sidecar"
      image       = "gcr.io/datadoghq/serverless-init:latest"
      description = "Datadog sidecar"

      health_port = 5555 # DD_HEALTH_PORT

      resources = {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env = [
        {
          name = "DD_API_KEY"
          value_source = {
            secret_key_ref = {
              secret = "DD_API_KEY"
            }
          }
        },
        {
          name  = "DD_HEALTH_PORT"
          value = "5555"
        },
        {
          name  = "DD_SOURCE"
          value = "csharp"
        },
        {
          name  = "DD_SITE"
          value = "us5.datadoghq.com"
        },
        # {
        #   name  = "DD_TAGS"
        #   value = ""
        # },
        {
          name  = "DD_SERVERLESS_LOG_PATH"
          value = "/app/logs/*.log"
        },
        {
          name  = "DD_ENV"
          value = "devops-sandbox"
        },
        {
          name  = "DD_SERVICE" ## must be identical to the Cloud Run "service" label
          value = "example-api"
        },
        {
          name  = "DD_VERSION" ## set to git sha
          value = "4"
        },
      ]

      volume_mounts = [
        {
          name       = "logs"
          mount_path = "/app/logs"
        },
      ]

      startup_probe = {
        failure_threshold = 3
        period_seconds    = 10
        timeout_seconds   = 1
        tcp_socket = {
          port = 5555
        }
      }

    },
  ]

  secrets_access = [
    "DD_API_KEY",
  ]

  volumes = [
    {
      name = "logs"
      empty_dir = {
        medium     = "MEMORY"
        size_limit = "512Mi"
      }
    },
  ]

}

module "job" {
  source = "../../modules/cloudrun"
  region = var.region
  name   = "example-inspect"

  type = "JOB"

  containers = [
    {
      name        = "inspect"
      image       = var.job_image_uri
      description = "Inspect the Cloud Run Job environment"
    },
  ]

}
