variable "project_name" {
  description = "Short project name used to prefix every resource."
  type        = string
  default     = "synfra-app"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,18}$", var.project_name))
    error_message = "project_name must be 2-19 characters of lowercase letters, digits or hyphens, and start with a letter or digit."
  }
}

variable "environment" {
  description = "Deployment environment. Also used in resource names."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Extra tags merged onto every resource."
  type        = map(string)
  default     = {}
}

# ── Network ──────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet. Must sit inside vpc_cidr."
  type        = string
  default     = "10.0.1.0/24"
}

variable "assign_public_ip" {
  description = "Give the instance a public IP. Turn off once you front it with a load balancer."
  type        = bool
  default     = true
}

variable "ingress_cidr" {
  description = "CIDR allowed to reach the instance. Narrow this to your own range — the default is the whole internet."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Port the instance serves traffic on."
  type        = number
  default     = 80
}

# ── Instance ─────────────────────────────────────────────────────────────────

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "detailed_monitoring" {
  description = "Enable 1-minute CloudWatch metrics instead of the default 5-minute interval. Costs extra."
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Cloud-init script run on first boot. Replace with your own bootstrap."
  type        = string
  default     = <<-EOT
    #!/bin/bash
    set -euo pipefail
    dnf install -y nginx
    echo "<h1>Hello from $(hostname)</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOT
}
