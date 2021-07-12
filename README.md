# terraform-module-lambda-cd

> Terraform module to remote build lambdas and deploy within the context of a terraform plan/apply - build and deploy your code and infrastructure in one pipeline.

- Creates a "worker" lambda which can be used for building and packaging source code for your lambdas
  - build your lambdas in the same environment they will run on
  - additional build dependencies should be loaded at build-time, or as lambda layer(s) on the worker
- Eliminates the need for multiple build pipelines when deploying lambda code with terraform - do everything in 1 set of terraform
  - works best when terraform code is in same repo as application code
- Build logs stored in Cloudwatch logs and available as an output on the module - includes a aws web console link for quick access
- Enables a continuous deployment lifecycle with pre and post deploy testing (TODO)
- Built and tested on [Terraform Cloud](https://www.terraform.io/cloud), but can be used with any terraform runtime (no external dependencies except terraform itself)

## Known issues / quirks

- Only supports nodejs v14.x at this time. If you'd like to use this module with another runtime, please raise an issue or a PR.
- A lambda runtime container only has 512MB of space available to write to the `/tmp` directory mount. This module downloads, extracts, and runs build commands all within the `/tmp` directory, so your build processes, source sizes, and dependencies (and their caches) need to fit in this restriction. Builds are cleaned pre and post every build process, and free space is logged to assist in debugging.
- Cannot install with `npm install --global` due to write permissions. If a global build-time dependency is needed for your project, consider moving it to your project scope, running it with npx, or installing as a lambda layer
- Due to current limitations in the aws terraform provider, the lambda invocation datasource will invoke during a plan when there are no code changes to the lambda. The worker will detect a built package in the s3 bucket you're using, and exit quickly, however this will result in a billed invocation of <200ms. Awaiting PR here for the fix: https://github.com/hashicorp/terraform-provider-aws/pull/19488

<!-- BEGIN_TF_DOCS -->

## Usage:

```hcl
module "my_lambda" {
  source  = "sellalong/lambda-cd/aws"
  version = "1.0.0"

  meta_name            = "my_lambda"
  package_sources_path = "${path.module}/lambda_source"
  package_target_dir   = "dist"

  # S3 bucket with versioning required for storage of package artefacts
  package_target_s3 = {
    bucket = "my_package_s3_bucket"
    prefix = "my_lambda/"
  }

  # Consider allocating more memory/timeout to the worker lambda, as builds may take a while. More memory = more CPU
  worker_lambda_memory_size = 512
  worker_lambda_timeout     = 300

  # Can use npm v7 if desired for build
  worker_lambda_npm_7 = true

  # Customise build commands (defaults below)
  build_commands = [
    "npm ci",
    "npm run build"
  ]
}
```

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1      |
| <a name="requirement_archive"></a> [archive](#requirement_archive)       | >= 2.2.0  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 3.46.0 |
| <a name="requirement_external"></a> [external](#requirement_external)    | 2.1.0     |
| <a name="requirement_time"></a> [time](#requirement_time)                | >= 0.7.2  |

## Providers

| Name                                                | Version   |
| --------------------------------------------------- | --------- |
| <a name="provider_aws"></a> [aws](#provider_aws)    | >= 3.46.0 |
| <a name="provider_time"></a> [time](#provider_time) | >= 0.7.2  |

## Modules

| Name                                                                             | Source                  | Version |
| -------------------------------------------------------------------------------- | ----------------------- | ------- |
| <a name="module_lambda"></a> [lambda](#module_lambda)                            | ./modules/lambda        | n/a     |
| <a name="module_package_archive"></a> [package_archive](#module_package_archive) | ./modules/package       | n/a     |
| <a name="module_worker"></a> [worker](#module_worker)                            | ./modules/lambda-worker | n/a     |

## Resources

| Name                                                                                                                                             | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [aws_iam_role_policy.worker_lambda_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)       | resource    |
| [aws_s3_bucket_object.package_sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object)             | resource    |
| [time_sleep.worker_invoke_iam_s3_access](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep)                     | resource    |
| [time_static.package_sources_updated](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static)                       | resource    |
| [aws_lambda_invocation.worker_invoke_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_invocation)    | data source |
| [aws_s3_bucket_object.package_existing_sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket_object) | data source |

## Inputs

| Name                                                                                                                  | Description                                                                                                                                                                                                          | Type                                                                                    | Default                                             | Required |
| --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | --------------------------------------------------- | :------: |
| <a name="input_build_commands"></a> [build_commands](#input_build_commands)                                           | Commands to run remotely on the worker lambda during build phase, in the directory root of `${var.package_source_path}`                                                                                              | `list(string)`                                                                          | <pre>[<br> "npm ci",<br> "npm run build"<br>]</pre> |    no    |
| <a name="input_build_environment_variables"></a> [build_environment_variables](#input_build_environment_variables)    | A map that defines environment variables to use in the build process while building the lambda in the worker.                                                                                                        | `map(string)`                                                                           | `{}`                                                |    no    |
| <a name="input_cloudwatch_logs_enable"></a> [cloudwatch_logs_enable](#input_cloudwatch_logs_enable)                   | Enable logging to cloudwatch logs for the built lambda                                                                                                                                                               | `bool`                                                                                  | `true`                                              |    no    |
| <a name="input_cloudwatch_logs_retention"></a> [cloudwatch_logs_retention](#input_cloudwatch_logs_retention)          | Log retention in days                                                                                                                                                                                                | `number`                                                                                | `7`                                                 |    no    |
| <a name="input_lambda_environment_variables"></a> [lambda_environment_variables](#input_lambda_environment_variables) | A map that defines environment variables for the built lambda.                                                                                                                                                       | `map(string)`                                                                           | `{}`                                                |    no    |
| <a name="input_lambda_handler"></a> [lambda_handler](#input_lambda_handler)                                           | Handler spec for the built lambda                                                                                                                                                                                    | `string`                                                                                | `"main.handler"`                                    |    no    |
| <a name="input_lambda_layers"></a> [lambda_layers](#input_lambda_layers)                                              | Lambda layers for the built lambda                                                                                                                                                                                   | `list(string)`                                                                          | `[]`                                                |    no    |
| <a name="input_lambda_memory_size"></a> [lambda_memory_size](#input_lambda_memory_size)                               | Memory to allocate for the lambda: 128 MB to 3,008 MB, in 64 MB increments. CPU allocated relative to memory.                                                                                                        | `number`                                                                                | `128`                                               |    no    |
| <a name="input_lambda_role"></a> [lambda_role](#input_lambda_role)                                                    | Existing iam role (name not arn) to allocate to the lambda at runtime                                                                                                                                                | `string`                                                                                | `null`                                              |    no    |
| <a name="input_lambda_runtime"></a> [lambda_runtime](#input_lambda_runtime)                                           | Runtime to use for the built lambda                                                                                                                                                                                  | `string`                                                                                | `"nodejs14.x"`                                      |    no    |
| <a name="input_lambda_timeout"></a> [lambda_timeout](#input_lambda_timeout)                                           | Timeout in seconds for the runtime of the built lambda                                                                                                                                                               | `number`                                                                                | `3`                                                 |    no    |
| <a name="input_meta_name"></a> [meta_name](#input_meta_name)                                                          | Name of the lambda and all resources                                                                                                                                                                                 | `string`                                                                                | n/a                                                 |   yes    |
| <a name="input_package_sources_exclude"></a> [package_sources_exclude](#input_package_sources_exclude)                | Files/directories relative to `${var.package_sources_path}` to exclude from the sources package zip (zip compatible wildcards/pattern matching accepted, see: https://linux.die.net/man/1/zip)                       | `list(string)`                                                                          | `[]`                                                |    no    |
| <a name="input_package_sources_include"></a> [package_sources_include](#input_package_sources_include)                | Files/directories relative to `${var.package_sources_path}` to include in the sources package zip - defaults to all files (zip compatible wildcards/pattern matching accepted, see: https://linux.die.net/man/1/zip) | `list(string)`                                                                          | <pre>[<br> "."<br>]</pre>                           |    no    |
| <a name="input_package_sources_path"></a> [package_sources_path](#input_package_sources_path)                         | Deploy sources from local path to the lambda package. This or package_sources_s3 must be specified.                                                                                                                  | `string`                                                                                | `null`                                              |    no    |
| <a name="input_package_sources_s3"></a> [package_sources_s3](#input_package_sources_s3)                               | Deploy from existing sources package in S3. This or package_sources_path must be specified.                                                                                                                          | <pre>object({<br> bucket = string<br> key = string<br> version_id = string<br> })</pre> | `null`                                              |    no    |
| <a name="input_package_target_dir"></a> [package_target_dir](#input_package_target_dir)                               | Directory relative to the sources path root to package for deployment (eg: "./dist")                                                                                                                                 | `string`                                                                                | `"."`                                               |    no    |
| <a name="input_package_target_exclude"></a> [package_target_exclude](#input_package_target_exclude)                   | Files/directories relative to `${var.package_target_dir}` to exclude from the package zip (zip compatible wildcards/pattern matching accepted, see: https://linux.die.net/man/1/zip)                                 | `list(string)`                                                                          | `[]`                                                |    no    |
| <a name="input_package_target_include"></a> [package_target_include](#input_package_target_include)                   | Files/directories relative to `${var.package_target_dir}` to include in the package zip (zip compatible wildcards/pattern matching accepted, see: https://linux.die.net/man/1/zip)                                   | `list(string)`                                                                          | <pre>[<br> "."<br>]</pre>                           |    no    |
| <a name="input_package_target_s3"></a> [package_target_s3](#input_package_target_s3)                                  | S3 bucket and key prefix for packages and artefacts                                                                                                                                                                  | <pre>object({<br> bucket = string<br> prefix = string<br> })</pre>                      | n/a                                                 |   yes    |
| <a name="input_worker_lambda_function_name"></a> [worker_lambda_function_name](#input_worker_lambda_function_name)    | Use an existing worker lambda                                                                                                                                                                                        | `string`                                                                                | `null`                                              |    no    |
| <a name="input_worker_lambda_layers"></a> [worker_lambda_layers](#input_worker_lambda_layers)                         | Additional lambda layers for the worker lambda                                                                                                                                                                       | `list(string)`                                                                          | `[]`                                                |    no    |
| <a name="input_worker_lambda_memory_size"></a> [worker_lambda_memory_size](#input_worker_lambda_memory_size)          | Memory to allocate for the worker lambda: 128 MB to 3,008 MB, in 64 MB increments. CPU allocated relative to memory.                                                                                                 | `number`                                                                                | `128`                                               |    no    |
| <a name="input_worker_lambda_npm_7"></a> [worker_lambda_npm_7](#input_worker_lambda_npm_7)                            | Enable npm 7 on the worker lambda (installed as a layer)                                                                                                                                                             | `bool`                                                                                  | `false`                                             |    no    |
| <a name="input_worker_lambda_role"></a> [worker_lambda_role](#input_worker_lambda_role)                               | Existing iam role (name not arn) to allocate to the worker lambda at runtime                                                                                                                                         | `string`                                                                                | `null`                                              |    no    |
| <a name="input_worker_lambda_timeout"></a> [worker_lambda_timeout](#input_worker_lambda_timeout)                      | Timeout in seconds for the runtime of an invocation in the worker lambda                                                                                                                                             | `number`                                                                                | `180`                                               |    no    |
| <a name="input_worker_meta_name"></a> [worker_meta_name](#input_worker_meta_name)                                     | Name of worker lambda and all its resources - defaults to: "worker\_${var.meta-name}"                                                                                                                                | `any`                                                                                   | `null`                                              |    no    |

## Outputs

| Name                                                     | Description                                                                               |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| <a name="output_lambda"></a> [lambda](#output_lambda)    | Outputs a map with the built lambda's `arn`, `function_name`, `last_modified`, and `role` |
| <a name="output_package"></a> [package](#output_package) | Outputs a map with the built package's `build_time`, `logs`, and `s3` location            |
| <a name="output_worker"></a> [worker](#output_worker)    | Outputs a map with the worker lambda's `function_name`                                    |

<!-- END_TF_DOCS -->
