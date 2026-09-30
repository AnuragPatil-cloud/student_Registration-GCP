# ============================================
# Service accounts (no keys are ever created)
# ============================================

resource "google_service_account" "jenkins" {
  account_id   = "${var.sa_prefix}-${var.environment}-jenkins"
  display_name = "Jenkins VM (${var.environment})"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.sa_prefix}-${var.environment}-gke-nodes"
  display_name = "GKE nodes (${var.environment})"

  depends_on = [google_project_service.required]
}

locals {
  # Artifact Registry access is granted on the repository itself (artifact-registry.tf)
  jenkins_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]

  gke_node_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/autoscaling.metricsWriter",
  ]
}

resource "google_project_iam_member" "jenkins" {
  for_each = toset(local.jenkins_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = toset(local.gke_node_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
