#!/bin/bash
set -ex

# Install Docker and jq
dnf update -y
dnf install -y docker jq
systemctl enable docker
systemctl start docker

# Login to ECR
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${region}.amazonaws.com

# Pull and run image (ecr_repo is expected to be the full ECR URI or repository)
docker pull ${ecr_repo}:${app_version}

# If a Secrets Manager ARN is provided, fetch secret at boot and extract username/password
if [ -n "${db_secret_arn}" ] && [ -z "$${db_username}" -o -z "$${db_password}" ]; then
	echo "Fetching DB credentials from Secrets Manager: ${db_secret_arn}"
	# Fetch the secret string JSON
	secret_json=$(aws secretsmanager get-secret-value --secret-id "${db_secret_arn}" --query SecretString --output text --region ${region} 2>/dev/null || true)
	if [ -n "$${secret_json}" ]; then
	# Use jq to parse the JSON and safely extract fields (preferred over python for small shell scripts)
	db_user_from_secret=$(echo "$${secret_json}" | jq -r '.username // .user // empty')
	db_pass_from_secret=$(echo "$${secret_json}" | jq -r '.password // .pass // empty')
		# Only set if values were found and not already provided
		if [ -n "$${db_user_from_secret}" ] && [ -z "$${db_username}" ]; then
			db_username="$${db_user_from_secret}"
		fi
		if [ -n "$${db_pass_from_secret}" ] && [ -z "$${db_password}" ]; then
			db_password="$${db_pass_from_secret}"
		fi
	else
		echo "Warning: could not retrieve secret ${db_secret_arn} or secret is empty"
	fi
fi

# Build optional environment flags for DB vars
DB_ENV_FLAGS=""
if [ -n "${db_endpoint}" ]; then
	DB_ENV_FLAGS="$DB_ENV_FLAGS -e DB_ENDPOINT=${db_endpoint}"
fi
if [ -n "$${db_username}" ]; then
	DB_ENV_FLAGS="$DB_ENV_FLAGS -e DB_USERNAME=$${db_username}"
fi
if [ -n "$${db_password}" ]; then
	DB_ENV_FLAGS="$DB_ENV_FLAGS -e DB_PASSWORD=$${db_password}"
fi

# Run container (map host port to container port)
docker run -d -p ${container_port}:${container_port} $DB_ENV_FLAGS ${ecr_repo}:${app_version}
