module "pilot_dataset" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "6.1.1"
  project_id = var.project_id
  location   = var.region
  dataset_id = local.datasets.pilot_dataset

  tables = [
    for filepath in local.schemas.pilot :
    {
      description = tostring(trimsuffix(basename(tostring(filepath)), ".json")),
      table_name  = tostring(trimsuffix(basename(tostring(filepath)), ".json")),
      table_id    = tostring(trimsuffix(basename(tostring(filepath)), ".json")),
      schema      = jsonencode(jsondecode(file(filepath))["schema"]["fields"]),

      range_partitioning = null,
      expiration_time    = null,
      time_partitioning  = null,
      clustering         = [],
      labels             = local.labels
    }
  ]
  dataset_labels = merge(local.labels, { "access" : "protected" })
  access         = []
}