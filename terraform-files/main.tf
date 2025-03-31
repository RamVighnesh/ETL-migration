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
  pilot_dataset_stg = "BETA_STG_DATASET"
  }

  buckets ={
    pilot_bucket = "beta-bucket"
  }

  schemas = {
    pilot = fileset(path.module, "./schemas/BETA/*.json")
    pilot_stg = fileset(path.module, "./schemas/BETA_STG/*.json")
  }

  admins = {
    ram = "ramvighnesh124@gmail.com"
    ratna = "ratna.kumar62@gmailcom"
  }
}