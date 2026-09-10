/**
 * Data sources and locals only. Resources live in vpc.tf and ec2_instance.tf.
 */

data "aws_availability_zones" "available" {
  state = "available"
}

# Latest Amazon Linux 2023, resolved at plan time rather than pinned to a
# region-specific AMI id that breaks the moment the region changes.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Template    = "aws-ec2"
    },
    var.tags,
  )
}
