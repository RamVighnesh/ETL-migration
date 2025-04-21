module "pilot_stg_dataset" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "6.1.1"
  project_id = var.project_id
  location   = var.region
  dataset_id = local.datasets.pilot_dataset_stg
  tables = [
    for filepath in local.stage_schemas.pilot_stg :
    {
      description = tostring(trimsuffix(basename(tostring(filepath)), ".json")),
      table_name  = tostring(trimsuffix(basename(tostring(filepath)), ".json")),
      table_id    = tostring(trimsuffix(basename(tostring(filepath)), ".json")),
      schema      = jsonencode(jsondecode(file(filepath))["schema"]["fields"]),

      range_partitioning = null,
      expiration_time    = null,
      time_partitioning  = lookup(jsondecode(file(filepath)), "timePartitioning",null) != null ? {
        field = jsondecode(file(filepath)).timePartitioning.field
        type =  jsondecode(file(filepath)).timePartitioning.type
        expiration_ms = null
        require_partition_filter = false
      } : null,
      clustering         = lookup(jsondecode(file(filepath)), "clustering",null) != null ? try(jsondecode(file(filepath))["clustering"]["fields"],[]) : [],
      labels             = local.labels
    }
  ]
  dataset_labels = merge(local.labels, { "access" : "protected" })
  access         = []

}
