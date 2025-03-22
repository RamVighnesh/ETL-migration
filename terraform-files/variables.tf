variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-central1"
}

varaible "backend_bucket" {
    type        = string
    description = "backend bucket to store terraform state"
    default     = "backend-teraform"
}