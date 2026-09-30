# ============================================
# Network
# ============================================

output "network_name" {
  description = "Student Registration VPC name"
  value       = google_compute_network.main.name
}

# ============================================
# GKE
# ============================================

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.main.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value       = google_container_cluster.main.endpoint
}

output "gke_get_credentials_command" {
  description = "Run this on your laptop / Cloud Shell to configure kubectl (needs gke-gcloud-auth-plugin)"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --zone ${var.zone} --project ${var.project_id}"
}

# ============================================
# Cloud SQL
# ============================================

output "cloudsql_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.main.name
}

output "cloudsql_connection_name" {
  description = "Cloud SQL connection name (project:region:instance)"
  value       = google_sql_database_instance.main.connection_name
}

output "cloudsql_private_ip" {
  description = "Cloud SQL private IP - goes into DB_HOST of the Kubernetes Secret"
  value       = google_sql_database_instance.main.private_ip_address
}

output "cloudsql_database" {
  description = "Database name - DB_NAME of the Kubernetes Secret"
  value       = google_sql_database.main.name
}

# ============================================
# Artifact Registry / Ingress
# ============================================

output "artifact_registry_url" {
  description = "Image path prefix: <this>/backend:<tag> and <this>/frontend:<tag>"
  value       = "${var.region}-docker.pkg.dev/${google_artifact_registry_repository.main.project}/${google_artifact_registry_repository.main.repository_id}"
}

output "ingress_static_ip" {
  description = "Public IP of the application (create after the Ingress binds to it)"
  value       = google_compute_global_address.ingress.address
}

output "ingress_static_ip_name" {
  description = "Put this in helm values: ingress.staticIpName"
  value       = google_compute_global_address.ingress.name
}

# ============================================
# Jenkins
# ============================================

output "jenkins_public_ip" {
  description = "Jenkins UI is on :8080, SonarQube on :9000 (admin IP only)"
  value       = google_compute_address.jenkins.address
}

output "jenkins_ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.jenkins.name} --zone ${var.zone} --project ${var.project_id}"
}
