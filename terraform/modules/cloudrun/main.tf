data "google_project" "this" {
  project_id = var.project_id
}

locals {
  project_id = data.google_project.this.project_id

  connector = try(var.revision_config.vpc_access.connector, null)

  revision_name = (
    var.revision_config.name == null ? null : "${var.name}-${var.revision_config.name}"
  )

  service_account       = var.service_account_config.create ? try(google_service_account.this[0], null) : try(data.google_service_account.this[0], try(data.google_compute_default_service_account.this[0], null))
  service_account_roles = distinct(compact(concat(var.service_account_default_roles, var.service_account_config.roles)))

  service = var.type == "SERVICE" ? (var.is_managed_revision ? one(google_cloud_run_v2_service.managed) : one(google_cloud_run_v2_service.unmanaged)) : null
  job     = var.type == "JOB" ? (var.is_managed_revision ? one(google_cloud_run_v2_job.managed) : one(google_cloud_run_v2_job.unmanaged)) : null

  iam_flattened = merge([
    for binding in var.iam_members : {
      for member in binding.members :
      "${binding.role}-${member}" => {
        role   = binding.role
        member = member
      }
    }
  ]...)
}
