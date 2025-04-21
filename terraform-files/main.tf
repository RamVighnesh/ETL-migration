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
    
  }

  stage_schemas = {
    
    pilot_stg = fileset(path.module, "./schemas/BETA_STG/*.json")
    
  }

  land_schemas = {
    
    pilot_land = fileset(path.module, "./schemas/BETA_LAND/*.json")
  }
  

  admins = {
    ram = "admin1@gmail.com"
    ratna = "admin2@gmailcom"
  }
}
