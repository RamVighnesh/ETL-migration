resource "google_storage_bucket" "pilot_bucket" {
  name     = "USC1-Landing-Archive"
  project  = var.project_id
  location = var.region

  versioning {
    enabled = true
  }
  

  labels = local.labels
}

resource "google_storage_bucket_iam_binding" "admin" {
  bucket = google_storage_bucket.pilot_bucket.name
  role   = "roles/storage.admin"
  members = [
    "user:ramvighnesh124@gmail.com",
    "user:ratna.kumar62@gmail.com"
  ]
}
