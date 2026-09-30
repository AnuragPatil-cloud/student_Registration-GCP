# ============================================
# Alerting (Cloud Monitoring)
# Email channel + alert policies for the Jenkins VM and the database.
# Google sends a verification email to alert_email when the channel is created.
# ============================================

resource "google_monitoring_notification_channel" "email" {
  display_name = "${local.name_prefix}-alerts-email"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }

  depends_on = [google_project_service.required]
}

resource "google_monitoring_alert_policy" "jenkins_cpu" {
  display_name = "${local.name_prefix}-jenkins-high-cpu"
  combiner     = "OR"

  conditions {
    display_name = "Jenkins VM CPU utilization above threshold"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND resource.labels.instance_id = \"${google_compute_instance.jenkins.instance_id}\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.cpu_alert_threshold
      duration        = "600s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    mime_type = "text/markdown"
    content   = "Jenkins VM CPU has been above the threshold for 10 minutes. Check running builds and the SonarQube container."
  }
}

resource "google_monitoring_alert_policy" "sql_cpu" {
  display_name = "${local.name_prefix}-cloudsql-high-cpu"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL CPU utilization above threshold"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${var.project_id}:${google_sql_database_instance.main.name}\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.cpu_alert_threshold
      duration        = "600s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    mime_type = "text/markdown"
    content   = "Cloud SQL CPU has been above the threshold for 10 minutes."
  }
}

resource "google_monitoring_alert_policy" "sql_disk" {
  display_name = "${local.name_prefix}-cloudsql-high-disk"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL disk utilization above threshold"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${var.project_id}:${google_sql_database_instance.main.name}\" AND metric.type = \"cloudsql.googleapis.com/database/disk/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.sql_disk_alert_threshold
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    mime_type = "text/markdown"
    content   = "Cloud SQL disk utilization is above the threshold. Storage autoresize is on up to the configured limit."
  }
}
