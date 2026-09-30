# ============================================
# Jenkins VM (Jenkins + SonarQube + Docker + Maven + Node.js + gcloud)
# ============================================

resource "google_compute_address" "jenkins" {
  name         = "${local.name_prefix}-jenkins-ip"
  region       = var.region
  address_type = "EXTERNAL"

  depends_on = [google_project_service.required]
}

resource "google_compute_instance" "jenkins" {
  name         = "${local.name_prefix}-jenkins"
  machine_type = var.jenkins_machine_type
  zone         = var.zone
  tags         = ["jenkins"] # matched by the firewall rules
  labels       = merge(local.labels, { role = "jenkins" })

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.jenkins_disk_size
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vm.self_link

    access_config {
      nat_ip = google_compute_address.jenkins.address
    }
  }

  # The VM authenticates to Google Cloud as this service account (no key files).
  service_account {
    email  = google_service_account.jenkins.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/scripts/jenkins-startup.sh")
  }
}
