resource "google_cloud_run_v2_job_iam_member" "this" {
  for_each = var.type == "JOB" ? local.iam_flattened : {}
  project  = local.job.project
  location = local.job.location
  name     = local.job.name
  role     = each.value.role
  member   = each.value.member
}
