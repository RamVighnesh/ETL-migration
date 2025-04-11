module "pilot_land_dataset" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "6.1.1"
  project_id = var.project_id
  location   = var.region
  dataset_id = local.datasets.pilot_dataset_land

  dataset_labels = merge(local.labels, { "access" : "protected" })
  access         = []
}