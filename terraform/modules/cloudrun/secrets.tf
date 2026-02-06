data "google_secret_manager_secret" "this" {
  for_each  = toset(var.secrets_access)
  secret_id = each.value
}

resource "google_secret_manager_secret_iam_member" "this" {
  for_each  = toset(var.secrets_access)
  secret_id = data.google_secret_manager_secret.this[each.value].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = local.service_account.member
}
