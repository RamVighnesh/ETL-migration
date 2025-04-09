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

module "pilot_stg_dataset" {
  source     = "terraform-google-modules/bigquery/google"
  version    = "6.1.1"
  project_id = var.project_id
  location   = var.region
  dataset_id = local.datasets.pilot_dataset_stg

  tables = [
    for filepath in local.schemas.pilot_stg :
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


module "pilot_land_dataset" {
  source     = "terraform-google-modules/bigquery/google//modules/dataset"
  version    = "6.1.1"

  project_id     = var.project_id
  dataset_id     = local.datasets.pilot_dataset_land
  location       = var.region
  dataset_labels = merge(local.labels, { "access" : "protected" })
}

resource "google_bigquery_table" "pilot_landing_tables" {

  for_each = {
    for file_path in local.schemas.pilot_land :
    trimsuffix(basename(file_path), ".json") => file_path
  }

  project    = var.project_id
  dataset_id = module.pilot_land_dataset.dataset_id
  table_id   = each.key

  schema = jsonencode(jsondecode(file(each.value))["schema"]["fields"])

  range_partitioning {
    field = try(jsondecode(file(each.value)).rangePartitioning.field, null)
    range {
      start    = try(jsondecode(file(each.value)).rangePartitioning.range.start, null)
      end      = try(jsondecode(file(each.value)).rangePartitioning.range.end, null)
      interval = try(jsondecode(file(each.value)).rangePartitioning.range.interval, null)
    }
  }

  expiration_time = try(jsondecode(file(each.value)).expirationTime, null)

  dynamic "time_partitioning" {
    for_each = try([jsondecode(file(each.value)).timePartitioning], [])
    content {
      type                     = try(time_partitioning.value.type, null)
      field                    = try(time_partitioning.value.field, null)
      expiration_ms           = try(time_partitioning.value.expirationMs, null)
      require_partition_filter = try(time_partitioning.value.requirePartitionFilter, false)
    }
  }

  clustering = try(jsondecode(file(each.value)).clustering.fields, [])

  labels             = local.labels

}
