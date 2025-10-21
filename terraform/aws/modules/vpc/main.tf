resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.name
  }
}

output "vpc_id" {
  value = aws_vpc.this.id
}
