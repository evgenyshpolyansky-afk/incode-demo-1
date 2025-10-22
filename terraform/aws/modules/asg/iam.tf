# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.asg_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach ECR read-only policy
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Optional: attach CloudWatch Agent policy
resource "aws_iam_role_policy_attachment" "cw_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.asg_name}-profile"
  role = aws_iam_role.ec2_role.name
}

# Optional inline policy to allow reading a specific Secrets Manager secret
resource "aws_iam_role_policy" "secrets_read" {
  count = var.db_secret_arn != null && var.db_secret_arn != "" ? 1 : 0

  name = "${var.asg_name}-secrets-read"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = var.db_secret_arn
      }
    ]
  })
}
