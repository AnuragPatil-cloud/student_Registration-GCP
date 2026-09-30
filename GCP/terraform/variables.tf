# ============================================
# Project / location
# ============================================

variable "project_id" {
  description = "GCP project ID (not the project name or number)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1" # Mumbai
}

variable "zone" {
  description = "GCP zone for the Jenkins VM and the (zonal) GKE cluster"
  type        = string
  default     = "asia-south1-a"
}

variable "project_name" {
  description = "Project name, used as a prefix for resource names (lowercase letters, digits, hyphens)"
  type        = string
  default     = "student-registration"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "sa_prefix" {
  description = "Short prefix for service account IDs (they are limited to 30 characters)"
  type        = string
  default     = "sr"
}

variable "deletion_protection" {
  description = "Protect the GKE cluster and Cloud SQL instance from deletion. false = easy terraform destroy for a demo stack."
  type        = bool
  default     = false
}

# ============================================
# Network
# ============================================

variable "vm_subnet_cidr" {
  description = "Subnet for the Jenkins VM"
  type        = string
  default     = "10.0.1.0/24"
}

variable "gke_subnet_cidr" {
  description = "Primary range of the GKE subnet (nodes)"
  type        = string
  default     = "10.0.11.0/24"
}

variable "gke_pods_cidr" {
  description = "Secondary range for GKE Pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gke_services_cidr" {
  description = "Secondary range for GKE Services"
  type        = string
  default     = "10.2.0.0/20"
}

variable "gke_master_cidr" {
  description = "/28 range for the GKE control plane. Must not overlap any other range."
  type        = string
  default     = "172.16.0.0/28"
}

variable "psa_prefix_length" {
  description = "Prefix length of the range reserved for Private Service Access (Cloud SQL private IP)"
  type        = number
  default     = 20
}

variable "admin_cidr" {
  description = "Your public IP in CIDR form, e.g. 49.37.123.45/32. Allowed to reach Jenkins, SonarQube, SSH and the GKE API."
  type        = string
}

variable "enable_iap_ssh" {
  description = "Also allow SSH through Identity-Aware Proxy (gcloud compute ssh --tunnel-through-iap)"
  type        = bool
  default     = true
}

# ============================================
# Jenkins VM
# ============================================

variable "jenkins_machine_type" {
  description = "Machine type for the Jenkins + SonarQube VM"
  type        = string
  default     = "e2-standard-2" # 2 vCPU / 8 GiB
}

variable "jenkins_disk_size" {
  description = "Jenkins VM boot disk size in GiB"
  type        = number
  default     = 40
}

# ============================================
# GKE
# ============================================

variable "gke_machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-standard-2" # 2 vCPU / 8 GiB
}

variable "gke_initial_nodes" {
  description = "Initial number of worker nodes (zonal cluster)"
  type        = number
  default     = 2
}

variable "gke_min_nodes" {
  description = "Minimum worker nodes (cluster autoscaler)"
  type        = number
  default     = 1
}

variable "gke_max_nodes" {
  description = "Maximum worker nodes (cluster autoscaler)"
  type        = number
  default     = 3
}

variable "gke_node_disk_size" {
  description = "GKE node boot disk size in GiB"
  type        = number
  default     = 40
}

variable "gke_release_channel" {
  description = "GKE release channel: RAPID, REGULAR or STABLE. The Kubernetes version follows the channel."
  type        = string
  default     = "REGULAR"
}

# ============================================
# Cloud SQL for MySQL
# ============================================

variable "sql_database_version" {
  description = "Cloud SQL engine version. Cloud SQL has no MariaDB; MySQL 8.4 is the closest supported engine."
  type        = string
  default     = "MYSQL_8_4"
}

variable "sql_tier" {
  description = "Cloud SQL machine tier. db-g1-small is a shared-core tier; use db-custom-1-3840 if it is rejected in your project/region."
  type        = string
  default     = "db-g1-small"
}

variable "sql_disk_size" {
  description = "Initial Cloud SQL disk size in GB"
  type        = number
  default     = 20
}

variable "sql_disk_autoresize_limit" {
  description = "Maximum Cloud SQL disk size in GB when autoresize kicks in"
  type        = number
  default     = 50
}

variable "sql_backup_retention_days" {
  description = "Number of automated backups to keep"
  type        = number
  default     = 3
}

variable "db_name" {
  description = "Student registration database name"
  type        = string
  default     = "student_registration"
}

variable "db_username" {
  description = "Cloud SQL application user"
  type        = string
  default     = "studentadmin"
}

variable "db_password" {
  description = "Cloud SQL application password"
  type        = string
  sensitive   = true
}

# ============================================
# Alerting
# ============================================

variable "alert_email" {
  description = "Email address that receives Cloud Monitoring alerts"
  type        = string
}

variable "cpu_alert_threshold" {
  description = "CPU utilization alert threshold as a fraction (0.8 = 80 %)"
  type        = number
  default     = 0.8
}

variable "sql_disk_alert_threshold" {
  description = "Cloud SQL disk utilization alert threshold as a fraction"
  type        = number
  default     = 0.85
}
