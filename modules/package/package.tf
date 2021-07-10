locals {
  package_output_path = data.external.package_archive.result.outputFile
  package_archive_md5 = filemd5(local.package_output_path)
}

data "external" "package_archive" {
  program = concat(
    [
      "bash",
      abspath("${path.module}/package.sh"),
      abspath(var.target_path),
    ],
    var.target_include,
    length(var.target_exclude) > 0 ? ["-x"] : [],
    var.target_exclude
  )
  working_dir = var.sources_path
}
