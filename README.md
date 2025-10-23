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
	bootstrap/
		main.tf
		README.md
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
- `terraform/bootstrap/` — one-time setup for Terraform remote state backend. Creates S3 bucket and DynamoDB table for state storage and locking.
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
4. ALB: The `alb` module creates an Application Load Balancer with target groups that distributes incoming traffic across the EC2 instances in the Auto Scaling Group. The ALB provides health checks and ensures traffic is only routed to healthy instances.
5. ASG & instances:
	 - The `asg` module creates a Launch Template with a `user_data` script that logs into ECR, pulls the specified image tag and runs it with appropriate environment variables.
	 - The Launch Template is versioned. When the user updates `app_version` in the environment, the Launch Template changes. The ASG is configured to perform an Instance Refresh which performs a rolling replacement of instances (no full ASG replacement), avoiding downtime.
	 - The `user_data` script fetches DB credentials at boot from Secrets Manager (using a secret ARN passed to the module) so credentials are never stored in Terraform state.
5. Bastion: The `ec2` single-instance module can be used for bastion/utility instances. It creates an EC2 instance and attaches an IAM instance profile (ECR read + SecretsManager permissions) so it can pull images and fetch secrets if needed.

## Secrets handling
- DB credentials are stored in AWS Secrets Manager (created by the RDS module).
- The ASG/EC2 instances are given an IAM role with permission to read the secret. The `user_data` script uses the AWS CLI and `jq` to fetch and parse the secret at boot and then starts the container with the credentials in environment variables.
- This keeps credentials out of Terraform state and prevents accidental exposure.

## CI/CD Pipeline

This repository includes automated GitHub Actions workflows for continuous integration and deployment:

### Build and Publish Pipeline
- **Workflow**: `build-and-publish.yml`
- **Trigger**: Push to `main` branch
- **Actions**: 
  - Builds the sample Flask application Docker image
  - Publishes the image to AWS ECR
  - Updates the version tag in `apps/version.txt`

### Terraform Deployment Pipeline
- **Workflow**: `terraform-deploy-dev.yml`
- **Trigger**: Automatically runs after successful completion of the build pipeline
- **Environment**: `dev/eu-central-1`
- **Actions**:
  - Reads the updated application version from `apps/version.txt`
  - Runs Terraform apply to update the infrastructure with the new image version
  - Triggers ASG Instance Refresh for zero-downtime deployment

The pipelines work together to provide automated deployment: when code is pushed to `main`, the application is built, published, and automatically deployed to the dev environment.

## Setup and Manual Deployment

### Initial Setup (One-time)
Before deploying environments, set up the Terraform remote state backend:

```powershell
# Navigate to bootstrap folder
cd terraform/bootstrap

# Initialize and apply (uses local state for this one-time setup)
terraform init
terraform apply
```

This creates:
- **S3 bucket**: `evgeny-shpolyansky-incode-demo-1-state-bucket` (with versioning and encryption)
- **DynamoDB table**: `evgeny-shpolyansky-incode-demo-1-terraform-locks` (for state locking)

### Environment Deployment
Run these from an environment folder (for example `terraform/aws/environments/dev/eu-central-1`):

```powershell
# Initialize with remote backend (after bootstrap is complete)
terraform init

# Validate the configuration
terraform validate

# Plan (use your environment tfvars as needed)
terraform plan -var-file=dev.tfvars

# Apply (inspect plan first in real usage)
terraform apply -var-file=dev.tfvars
```

**Note:** EC2 SSH key pairs and account-level IAM users (for personal use and GitHub actions pipelines) are expected to be created and managed outside this repository. Pass an existing SSH key name to the modules via the `ssh_key_name` variable. Modules create instance roles/profiles for EC2 where required, but broader IAM users, policies, or key-pair management should be performed separately and supplied to this Terraform configuration.

## Future Improvements

The following enhancements are identified for future implementation to make this demo more production-ready:

### Security & Networking
- **DNS**: Implement custom domain management with Route 53 for user-friendly URLs
- **HTTPS**: Add SSL/TLS termination at the ALB with certificate management via ACM
- **WAF**: Integrate AWS Web Application Firewall for additional security layer

### Monitoring & Observability
- **Log Management**: Implement comprehensive logging with CloudWatch for both ALB access logs and application logs, including log aggregation, retention policies, and structured logging
- **Enhanced Monitoring**: Enable CloudWatch detailed monitoring for EC2 instances and RDS instances for better performance visibility
- **RDS Performance Insights**: Implement Performance Insights for RDS to monitor database performance, identify bottlenecks, and optimize query performance

### Scalability & Reliability  
- **ASG Scaling Policy**: Implement auto-scaling policies based on CPU, memory, or custom CloudWatch metrics
- **ECR Registry Replication**: Set up cross-region ECR replication for multi-environment deployments, or integrate with external public/private registries

### Development & Operations
- **CI for Pull Requests**: Extend CI/CD pipeline to include:
  - Terraform plan validation and security scanning for infrastructure changes
  - Sample application testing, linting, and security scans
  - Integration tests for the complete stack
- **Variable Management**: Standardize and improve variable management across modules and environments, including consistent naming conventions, proper variable validation, and centralized configuration patterns