Bootstrap
---------

This folder contains a small Terraform configuration that creates the S3 bucket and DynamoDB table used for remote state and locking.

Usage
1. Ensure you have AWS credentials configured locally (or use a role).
2. cd into this folder:

   cd terraform/bootstrap

3. Initialize and apply (this uses local state):

   terraform init
   terraform apply

4. After the bucket and table exist, run `terraform init` in your environment folder (e.g., `environments/dev/eu-central-1`) to switch to the S3 backend.

Notes
- The bootstrap config uses the AWS region `eu-central-1` and will create:
  - S3 bucket: `evgeny-shpolyansky-incode-demo-1-state-bucket`
  - DynamoDB table: `evgeny-shpolyansky-incode-demo-1-terraform-locks`
- This is intended to be a one-time operation. Protect access to the bootstrap files and the created resources.
