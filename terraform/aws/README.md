# Terraform AWS layout

This folder contains a minimal Terraform scaffold for AWS environments.

Structure
- environments/: environment-specific root modules (one folder per env/region)
- modules/: reusable modules (e.g. vpc)
- examples/: example usages of modules

Quick start (local)
1. Edit `environments/dev/eu-central-1/backend.tf` to set your S3 bucket and (optional) DynamoDB table for locking, or pass backend values during `terraform init` with `-backend-config`.
2. cd into `environments/dev/eu-central-1`
3. terraform init -upgrade
4. terraform plan -var-file=dev.tfvars

Notes
- Do not check secrets or long-lived credentials into Git.
- Prefer CI-driven runs with proper roles and remote state.
