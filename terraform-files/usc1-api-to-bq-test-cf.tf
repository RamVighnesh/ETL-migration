terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}


resource "google_storage_bucket_object" "object" {
  name   = "86541697314.zip"
  bucket = "run-sources-project-beta-000002-us-central1"
  source = services/usc1-api-to-bq-test/ # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "default" {
  name        = "usc1-api-to-bq-test"
  location    = var.region
  description = "test through terraform"

  build_config {
    runtime     = "python3.12"
    entry_point = "hello_http" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "1GiB"
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