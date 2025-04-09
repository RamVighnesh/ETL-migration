terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

resource "google_cloudfunctions2_function" "default" {
  name        = "usc1-api-to-bq-test"
  location    = var.region
  description = "test through terraform"

  build_config {
    runtime     = "python312"
    entry_point = "hello_http" # Set the entry point
    source {
      storage_source {
        bucket = "run-sources-project-beta-000002-us-central1"
        object = "services/usc1-api-to-bq-test/86541697314.zip"
      }
    }
  }

  service_config {
    min_instance_count = 0
    max_instance_count = 1
    available_cpu = "1"
    available_memory   = "1Gi"
    timeout_seconds    = 60
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = var.region
  service  = google_cloudfunctions2_function.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "function_uri" {
  value = google_cloudfunctions2_function.default.service_config[0].uri
}