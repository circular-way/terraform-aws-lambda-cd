locals {
  package_is_existing_s3 = var.package_sources_s3 != null
  package_is_local       = var.package_sources_path != null

  package_sources = local.package_is_local ? aws_s3_bucket_object.package_sources[0] : data.aws_s3_bucket_object.package_existing_sources[0]
}

# Sources package to upload to the worker for building
data "archive_file" "package_sources" {
  count       = local.package_is_local ? 1 : 0
  type        = "zip"
  source_dir  = var.package_sources_path
  output_path = ".terraform/tmp/lambda/${var.meta_name}.zip"
}

# upload local package to s3
resource "aws_s3_bucket_object" "package_sources" {
  count    = local.package_is_local ? 1 : 0
  key      = "${var.package_target_s3.prefix}${lower(var.meta_name)}_${data.archive_file.package_sources[0].output_md5}.sources.zip"
  bucket   = var.package_target_s3.bucket
  source   = data.archive_file.package_sources[0].output_path
  etag     = data.archive_file.package_sources[0].output_md5
  acl      = "private"
  tags     = {}
  metadata = {}

  lifecycle {
    create_before_destroy = true
  }
}

# existing s3 archive of sources
data "aws_s3_bucket_object" "package_existing_sources" {
  count      = local.package_is_existing_s3 ? 1 : 0
  bucket     = var.package_sources_s3.bucket
  key        = var.package_sources_s3.key
  version_id = var.package_sources_s3.version_id
}

resource "time_static" "package_sources_updated" {
  triggers = {
    sources_hash = local.package_sources.etag
  }
}
