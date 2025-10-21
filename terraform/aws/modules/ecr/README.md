ECR module

Usage example:

```hcl
module "ecr" {
  source = "../modules/ecr"
  name   = "my-app-repo"
  tags = {
    Environment = "dev"
  }
}
```

Notes:
- By default the repository uses AES256 encryption. To use KMS provide `encryption_type = "KMS"` and `kms_key = "arn:aws:kms:..."`.
- `scan_on_push` defaults to true; set to false to disable.
