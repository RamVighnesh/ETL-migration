provider "google" {
  credentials = file("gcp-key.json")
  project     = var.project_id
  region      = var.region
}

locals {

  labels = {
    "terraform" : "true"
    "lifecycle":"legacytransition"
  }

  datasets = {
  pilot_dataset = "BETA_DATASET"
  }

  buckets ={
    pilot_bucket = "beta-bucket"
  }

  schemas = {
    pilot = fileset(path.module, "./schemas/BETA/*.json")
  }

  admins = {
    ram = "ramvighnesh124@gmail.com"
    ratna = "ratna.kumar62@gmailcom"
  }
}