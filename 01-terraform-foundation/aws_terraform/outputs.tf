output "instance_hostname" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.app_server.private_dns

}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance (if assigned)"
  value       = aws_instance.app_server.public_ip
}

output "vpc_id" {
  description = "VPC id from the VPC module"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs from the VPC module"
  value       = module.vpc.private_subnets
}

output "app_security_group_id" {
  description = "Security group created for app instances"
  value       = aws_security_group.app_sg.id
}
