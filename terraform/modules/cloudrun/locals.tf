locals {
  connector = try(var.revision_config.vpc_access.connector, null)

  revision_name = (
    var.revision_config.name == null ? null : "${var.name}-${var.revision_config.name}"
  )

  service_account = var.service_account_config.create ? try(google_service_account.this[0], null) : try(data.google_service_account.this[0], try(data.google_compute_default_service_account.this[0], null))

  service_account_roles = distinct(compact(concat(var.service_account_default_roles, var.service_account_config.roles)))

  service = var.type == "SERVICE" ? var.is_managed_revision ? try(google_cloud_run_v2_service.managed[0], null) : try(google_cloud_run_v2_service.unmanaged[0], null) : null

  job = var.type == "JOB" ? var.is_managed_revision ? try(google_cloud_run_v2_job.managed[0], null) : try(google_cloud_run_v2_job.unmanaged[0], null) : null
}
