# ============================================
# Artifact Registry
# One Docker repository holding the "backend" and "frontend" images.
# ============================================

resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = var.project_name
  description   = "Docker images for ${var.project_name}"
  format        = "DOCKER"
  labels        = local.labels

  docker_config {
    immutable_tags = false
  }

  depends_on = [google_project_service.required]
}

# Jenkins pushes images
resource "google_artifact_registry_repository_iam_member" "jenkins_writer" {
  project    = google_artifact_registry_repository.main.project
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.jenkins.email}"
}

# GKE nodes pull images
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  project    = google_artifact_registry_repository.main.project
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}
