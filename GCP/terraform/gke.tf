# ============================================
# GKE cluster
# Zonal, VPC-native, private nodes. The API endpoint is public but restricted to your IP
# (and the cluster's own ranges), so kubectl/helm work from your laptop or Cloud Shell.
# ============================================

resource "google_container_cluster" "main" {
  name     = "${local.name_prefix}-gke"
  location = var.zone # zonal cluster: one control plane, nodes in one zone

  network    = google_compute_network.main.self_link
  subnetwork = google_compute_subnetwork.gke.self_link

  networking_mode     = "VPC_NATIVE"
  deletion_protection = var.deletion_protection
  resource_labels     = local.labels

  # The node pool is managed separately below
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = var.gke_release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.gke_master_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "administrator"
      cidr_block   = var.admin_cidr
    }

    cidr_blocks {
      display_name = "gke-nodes"
      cidr_block   = var.gke_subnet_cidr
    }

    cidr_blocks {
      display_name = "gke-pods"
      cidr_block   = var.gke_pods_cidr
    }
  }

  # Required for GKE Ingress (external Application Load Balancer)
  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  # Pods can use Google APIs as Kubernetes service accounts instead of node-wide credentials
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Everything lands in Cloud Logging
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "APISERVER",
      "SCHEDULER",
      "CONTROLLER_MANAGER",
      "WORKLOADS",
    ]
  }

  # Google Cloud Managed Service for Prometheus: scrapes the backend's /actuator/prometheus
  # through the PodMonitoring resource in the Helm chart.
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = true
    }
  }

  depends_on = [
    google_project_service.required,
    google_compute_router_nat.main,
  ]
}

# ============================================
# Node pool (autoscaling)
# ============================================

resource "google_container_node_pool" "main" {
  name               = "${local.name_prefix}-nodes"
  cluster            = google_container_cluster.main.name
  location           = var.zone
  initial_node_count = var.gke_initial_nodes

  autoscaling {
    min_node_count = var.gke_min_nodes
    max_node_count = var.gke_max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type    = var.gke_machine_type
    disk_size_gb    = var.gke_node_disk_size
    disk_type       = "pd-balanced"
    image_type      = "COS_CONTAINERD"
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    tags            = [local.gke_node_tag]
    labels          = local.labels

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
