# ============================================
# Private Service Access
# Gives Cloud SQL a private IP inside this VPC, so the database is never exposed to the internet.
# ============================================

resource "google_compute_global_address" "psa" {
  name          = "${local.name_prefix}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.psa_prefix_length
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa.name]

  # Avoids the "producer services are still using this connection" error on terraform destroy
  deletion_policy = "ABANDON"

  depends_on = [google_project_service.required]
}

# ============================================
# Cloud SQL for MySQL
# ============================================

resource "google_sql_database_instance" "main" {
  name                = "${local.name_prefix}-mysql"
  region              = var.region
  database_version    = var.sql_database_version
  deletion_protection = var.deletion_protection

  settings {
    tier                  = var.sql_tier
    edition               = "ENTERPRISE"
    availability_type     = "ZONAL"
    disk_type             = "PD_SSD"
    disk_size             = var.sql_disk_size
    disk_autoresize       = true
    disk_autoresize_limit = var.sql_disk_autoresize_limit
    user_labels           = local.labels

    # Private IP only - no public address
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.self_link
    }

    backup_configuration {
      enabled    = true
      start_time = "21:00"

      backup_retention_settings {
        retained_backups = var.sql_backup_retention_days
        retention_unit   = "COUNT"
      }
    }
  }

  # Waits for the Private Service Access peering
  depends_on = [google_service_networking_connection.psa]
}

resource "google_sql_database" "main" {
  name      = var.db_name
  instance  = google_sql_database_instance.main.name
  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

resource "google_sql_user" "app" {
  name     = var.db_username
  instance = google_sql_database_instance.main.name
  password = var.db_password
  host     = "%"
}
