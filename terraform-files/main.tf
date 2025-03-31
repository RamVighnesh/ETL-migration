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
  pilot_dataset = "BETA"
  pilot_dataset_stg = "BETA_STG"
  pilot_dataset_land = "BETA_LANDING"
  }

  buckets ={
    pilot_bucket = "beta-bucket"
  }

  schemas = {
    pilot = fileset(path.module, "./schemas/BETA/*.json")
    pilot_stg = fileset(path.module, "./schemas/BETA_STG/*.json")
    pilot_land = fileset(path.module, "./schemas/BETA_LAND/*.json")
  }

  admins = {
    ram = "ramvighnesh124@gmail.com"
    ratna = "ratna.kumar62@gmailcom"
  }
}