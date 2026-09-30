# ============================================
# VPC
# ============================================

resource "google_compute_network" "main" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.required]
}

# ============================================
# Subnets
# ============================================

# Jenkins VM (gets an external IP, so this is the "public" subnet)
resource "google_compute_subnetwork" "vm" {
  name                     = "${local.name_prefix}-vm-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.vm_subnet_cidr
  private_ip_google_access = true
}

# Private GKE nodes. Pods and Services use secondary ranges (VPC-native cluster).
resource "google_compute_subnetwork" "gke" {
  name                     = "${local.name_prefix}-gke-subnet"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.gke_subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.gke_services_cidr
  }
}

# ============================================
# Static IP for the Ingress (HTTP load balancer)
# ============================================

resource "google_compute_global_address" "ingress" {
  name = "${local.name_prefix}-ingress-ip"

  depends_on = [google_project_service.required]
}
