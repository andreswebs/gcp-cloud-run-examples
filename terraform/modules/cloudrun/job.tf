resource "google_cloud_run_v2_job_iam_binding" "this" {
  for_each = var.type == "JOB" ? var.iam_bindings : {}
  project  = local.service.project
  location = local.service.location
  name     = local.service.name
  role     = each.key
  members  = each.value
}
