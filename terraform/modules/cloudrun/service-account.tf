data "google_service_account" "this" {
  count      = !var.service_account_config.create && var.service_account_config.email != null ? 1 : 0
  account_id = var.service_account_config.email
}

data "google_compute_default_service_account" "this" {
  count   = !var.service_account_config.create && var.service_account_config.email == null ? 1 : 0
  project = local.project_id
}

resource "google_service_account" "this" {
  count      = var.service_account_config.create ? 1 : 0
  project    = local.project_id
  account_id = coalesce(var.service_account_config.name, var.name)
  display_name = coalesce(
    var.service_account_config.display_name,
    var.service_account_config.name,
    var.name
  )
}

resource "google_project_iam_member" "this" {
  for_each = toset(local.service_account_roles)
  project  = local.project_id
  role     = each.key
  member   = local.service_account.member
}
