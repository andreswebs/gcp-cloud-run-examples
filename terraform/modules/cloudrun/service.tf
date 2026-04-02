resource "google_cloud_run_v2_service_iam_member" "this" {
  for_each = var.type == "SERVICE" ? local.iam_flattened : {}
  project  = local.service.project
  location = local.service.location
  name     = local.service.name
  role     = each.value.role
  member   = each.value.member
}
