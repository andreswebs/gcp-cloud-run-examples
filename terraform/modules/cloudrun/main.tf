data "google_project" "this" {
  project_id = var.project_id
}

locals {
  project_id = data.google_project.this.project_id
}

resource "google_tags_location_tag_binding" "this" {
  for_each = var.tag_bindings
  parent = (
    "//run.googleapis.com/projects/${var.project_id}/locations/${var.region}/services/${local.service.name}"
  )
  tag_value = each.value
  location  = var.region
}
