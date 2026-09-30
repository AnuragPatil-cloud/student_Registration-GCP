# ============================================
# Google APIs
# ============================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  labels = {
    project     = var.project_name
    environment = var.environment
    managed-by  = "terraform"
  }

  gke_node_tag = "${local.name_prefix}-gke-node"

  required_services = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "artifactregistry.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "oslogin.googleapis.com",
    "iap.googleapis.com",
  ]
}

resource "google_project_service" "required" {
  for_each = toset(local.required_services)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
