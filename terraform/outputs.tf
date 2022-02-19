output "metaflow_profile_json" {
  value = jsonencode(
    {
    "METAFLOW_DATASTORE_SYSROOT_S3"       = module.metaflow-datastore.METAFLOW_DATASTORE_SYSROOT_S3,
    "METAFLOW_DATATOOLS_S3ROOT"           = module.metaflow-datastore.METAFLOW_DATATOOLS_S3ROOT,
    "METAFLOW_BATCH_JOB_QUEUE"            = module.metaflow-computation.METAFLOW_BATCH_JOB_QUEUE,
    "METAFLOW_SERVICE_URL"                = module.metaflow-metadata-service.METAFLOW_SERVICE_URL,
    "METAFLOW_SERVICE_INTERNAL_URL"       = module.metaflow-metadata-service.METAFLOW_SERVICE_INTERNAL_URL,
    "METAFLOW_SFN_STATE_MACHINE_PREFIX"   = replace("${local.resource_prefix}${local.resource_suffix}", "--", "-"),
    "METAFLOW_DEFAULT_DATASTORE"          = "s3",
    "METAFLOW_DEFAULT_METADATA"           = "service"
    }
  )
  description = "Metaflow profile JSON object that can be used to communicate with this Metaflow Stack. Store this in `~/.metaflow/config_[stack-name]` and select with `$ export METAFLOW_PROFILE=[stack-name]`."
}