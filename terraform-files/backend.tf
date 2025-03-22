
terraform {
  backend "gcs" {
    bucket = "backend-teraform"
    prefix = "terraform/state"
  }
}