output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of the instance, or null when assign_public_ip is false."
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the instance."
  value       = aws_instance.web.private_ip
}

output "instance_url" {
  description = "URL the instance serves on, when it has a public address."
  value       = var.assign_public_ip ? "http://${aws_instance.web.public_ip}:${var.app_port}" : null
}

output "session_manager_command" {
  description = "Open a shell on the instance without SSH."
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the instance security group."
  value       = aws_security_group.web.id
}
