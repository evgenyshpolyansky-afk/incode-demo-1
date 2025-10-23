data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  iam_instance_profile         = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = var.associate_public_ip
  user_data                   = var.user_data

  tags = merge(var.tags, { Name = var.instance_name })

  lifecycle {
    create_before_destroy = false
  }
}
