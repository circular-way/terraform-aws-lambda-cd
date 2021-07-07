locals {
  package_is_local      = var.package_local_path != null
  package_is_local_only = var.package_target_s3 == null && local.package_is_local
  package_is_upload_s3  = var.package_target_s3 != null && local.package_is_local

  package_local = {
    filename         = local.package_is_local_only ? data.archive_file.package[0].output_path : null
    source_code_hash = local.package_is_local_only ? data.archive_file.package[0].output_base64sha256 : null
  }

  package_s3 = {
    bucket         = try(aws_s3_bucket_object.package_upload[0].bucket, var.package_s3.bucket, null)
    key            = try(aws_s3_bucket_object.package_upload[0].key, var.package_s3.key, null)
    object_version = try(aws_s3_bucket_object.package_upload[0].version_id, var.package_s3.version_id, null)
  }
}

# Dist package for the lambda
data "archive_file" "package" {
  count       = local.package_is_local ? 1 : 0
  type        = "zip"
  source_dir  = var.package_local_path
  output_path = ".terraform/tmp/lambda/${var.meta_name}.zip"
}

# upload local package to s3
resource "aws_s3_bucket_object" "package_upload" {
  count  = local.package_is_upload_s3 ? 1 : 0
  key    = "${var.package_target_s3.prefix}${lower(var.meta_name)}_${data.archive_file.package[0].output_md5}.zip"
  bucket = var.package_target_s3.bucket
  source = data.archive_file.package[0].output_path
  etag   = data.archive_file.package[0].output_base64sha256
  acl    = "private"
}
