locals {
  my_league_creds = jsondecode(data.aws_secretsmanager_secret_version.league_creds.secret_string)
  region          = "us-west-2"
  allowed_cidrs = [
    "76.64.94.2/32", #Rob
  ]
  resource_prefix = "espn-fantasy-"
  resource_suffix = "-test"
  batch_s3_task_role_name   = "${local.resource_prefix}batch_s3_task_role${local.resource_suffix}"
  metaflow_batch_image_name = "${local.resource_prefix}batch${local.resource_suffix}"
  metadata_service_container_image  = "netflixoss/metaflow_metadata_service:v2.2.2"
}

