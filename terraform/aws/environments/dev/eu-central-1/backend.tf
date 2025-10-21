terraform {
  backend "s3" {
    # Replace the bucket, key, and region with your values or pass them via -backend-config in CI
    bucket = "evgeny-shpolyansky-incode-demo-1-state-bucket"
    key    = "terraform/aws/environments/dev/eu-central-1/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "evgeny-shpolyansky-incode-demo-1-terraform-locks"
  }
}
