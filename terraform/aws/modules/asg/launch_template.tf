data "aws_caller_identity" "current" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.asg_name}-lt-"

  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  key_name = var.ssh_key_name

  # Attach instance profile by name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # VPC security group IDs
  vpc_security_group_ids = [var.instance_sg_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    region         = var.region
    account_id     = data.aws_caller_identity.current.account_id
    ecr_repo       = var.ecr_repo
    container_port = var.container_port
    app_version    = var.app_version
    db_endpoint    = var.db_endpoint
    db_secret_arn  = var.db_secret_arn
  }))

  lifecycle {
    create_before_destroy = true
  }
}
