resource "aws_autoscaling_group" "this" {
  name                      = var.asg_name
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnets
  health_check_type         = "EC2"

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }
  target_group_arns         = [var.target_group_arn]

  tag {
    key                 = "Name"
    value               = var.asg_name
    propagate_at_launch = true
  }

  depends_on = [
    aws_launch_template.this
  ]

  # Perform rolling instance refreshes when the launch template changes
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }
}
