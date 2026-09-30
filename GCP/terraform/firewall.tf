# ============================================
# Jenkins VM: SSH, Jenkins UI, SonarQube - administrator IP only
# ============================================

resource "google_compute_firewall" "jenkins_admin" {
  name          = "${local.name_prefix}-allow-jenkins-admin"
  network       = google_compute_network.main.name
  direction     = "INGRESS"
  priority      = 1000
  description   = "SSH, Jenkins (8080) and SonarQube (9000) from the administrator"
  source_ranges = [var.admin_cidr]
  target_tags   = ["jenkins"]

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "9000"]
  }
}

# Optional: SSH through Identity-Aware Proxy
resource "google_compute_firewall" "iap_ssh" {
  count = var.enable_iap_ssh ? 1 : 0

  name          = "${local.name_prefix}-allow-iap-ssh"
  network       = google_compute_network.main.name
  direction     = "INGRESS"
  priority      = 1000
  description   = "SSH from Google IAP TCP forwarding"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["jenkins"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# ============================================
# Load balancer health checks -> GKE nodes (container-native load balancing hits Pod ports directly)
# ============================================

resource "google_compute_firewall" "lb_health_checks" {
  name          = "${local.name_prefix}-allow-lb-health-checks"
  network       = google_compute_network.main.name
  direction     = "INGRESS"
  priority      = 1000
  description   = "Google Cloud load balancer and health check ranges to the frontend (80) and backend (8080) Pods"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [local.gke_node_tag]

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }
}
