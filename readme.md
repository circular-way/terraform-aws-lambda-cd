# terraform-module-lambda-cd

> Terraform module to remote build lambdas and deploy within the context of a terraform plan/apply

- Creates a "worker" lambda which can be used for building and packaging source code for your lambdas
  - build your lambdas in the same environment they will run on
  - additional build dependencies should be loaded at build-time, or as lambda layer(s) on the worker
- Enables a continuous deployment lifecycle with pre and post deploy testing (TODO)
- Built and tested on [Terraform Cloud](https://www.terraform.io/cloud), but can be used with any terraform runtime (no external dependencies except terraform itself)

## Known issues / quirks

- Cannot install with `npm install --global` due to write permissions. If a global build-time dependency is needed for your project, consider moving it to your project scope, running it with npx, or installing as a lambda layer
