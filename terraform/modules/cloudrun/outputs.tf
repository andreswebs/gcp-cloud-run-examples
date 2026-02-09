output "service" {
  description = "The `google_cloud_run_v2_service` resource"
  value       = local.service
}

output "job" {
  description = "The `google_cloud_run_v2_job` resource"
  value       = local.job
}

output "service_account" {
  description = "The `google_service_account` resource"
  value       = local.service_account
}
