# incode-demo-1

A small Terraform-based demo that provisions a minimal AWS environment and runs a sample Flask application in Docker on EC2 instances.

This repo demonstrates:
- A multi-environment Terraform layout.
- Reusable Terraform modules (VPC, ECR, ALB, ASG, EC2).
- An Auto Scaling Group (ASG) that launches EC2 instances from a Launch Template.
- Runtime secret retrieval from AWS Secrets Manager (secrets fetched by instance user-data, not stored in Terraform state).
- Minimal operational patterns for rolling updates using ASG Instance Refresh.

## Layout

Top-level:
```
README.md
terraform/
	aws/
		environments/
			dev/
				eu-central-1/
					main.tf
					variables.tf
					outputs.tf
		modules/
			vpc/
			ecr/
			alb/
			asg/
			ec2/
```

Key directories:
- `terraform/aws/environments/*` — environment configuration that wires modules together. Each environment folder (for example `dev/eu-central-1`) contains the top-level `main.tf` that instantiates modules for that environment.
- `terraform/aws/modules/*` — reusable Terraform modules used by environments. Notable modules in this repo:
	- `vpc` — creates VPC, public/private subnets and related networking.
	- `ecr` — creates an ECR repository for the sample app.
	- `alb` — Application Load Balancer and target group.
	- `asg` — Auto Scaling Group backed by a Launch Template. User-data pulls a Docker image from ECR and runs the app.
	- `ec2` — single-instance module (used for a bastion host). Accepts security group IDs and instance profile configuration.

## How it operates (high level)

1. Network & infra: The `vpc` module creates the VPC and subnets. Environment `main.tf` wires up security groups and other infra modules.
2. RDS: The environment creates an RDS instance (MySQL) via a registry module. The RDS module creates a Secrets Manager secret that contains the DB credentials and outputs the secret ARN.
3. ECR & app: The `ecr` module contains an ECR repository where you push the sample Flask Docker image.
4. ASG & instances:
	 - The `asg` module creates a Launch Template with a `user_data` script that logs into ECR, pulls the specified image tag and runs it with appropriate environment variables.
	 - The Launch Template is versioned. When the user updates `app_version` in the environment, the Launch Template changes. The ASG is configured to perform an Instance Refresh which performs a rolling replacement of instances (no full ASG replacement), avoiding downtime.
	 - The `user_data` script fetches DB credentials at boot from Secrets Manager (using a secret ARN passed to the module) so credentials are never stored in Terraform state.
5. Bastion: The `ec2` single-instance module can be used for bastion/utility instances. It creates an EC2 instance and attaches an IAM instance profile (ECR read + SecretsManager permissions) so it can pull images and fetch secrets if needed.

## Secrets handling
- DB credentials are stored in AWS Secrets Manager (created by the RDS module).
- The ASG/EC2 instances are given an IAM role with permission to read the secret. The `user_data` script uses the AWS CLI and `jq` to fetch and parse the secret at boot and then starts the container with the credentials in environment variables.
- This keeps credentials out of Terraform state and prevents accidental exposure.

## Deployment / common commands
Run these from an environment folder (for example `terraform/aws/environments/dev/eu-central-1`):

```powershell
# Initialize the working directory (no backend used for quick local validation)
terraform init -backend=false

# Validate the configuration
terraform validate

# Plan (use your environment tfvars as needed)
terraform plan -var-file=dev.tfvars

# Apply (inspect plan first in real usage)
terraform apply -var-file=dev.tfvars
```