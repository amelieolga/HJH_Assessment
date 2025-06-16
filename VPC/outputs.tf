output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

# All public subnets as a list
output "public_subnet_ids" {
  description = "IDs of all public subnets"
  value       = aws_subnet.public[*].id
}

# All private subnets as a list
output "private_subnet_ids" {
  description = "IDs of all private subnets"
  value       = aws_subnet.private[*].id
}

# Specific important subnets
output "first_public_subnet_id" {
  description = "ID of the first public subnet"
  value       = aws_subnet.public[0].id
}

# ALB needs at least 2 subnets, so we can output them specifically
output "alb_subnet_ids" {
  description = "Subnet IDs suitable for ALBs"
  value       = slice(aws_subnet.public[*].id, 0, 2)
}
output "public_instance_public_ip" {
  description = "Public IP address of the public instance"
  value       = aws_instance.public.public_ip
}

output "private_instance_private_ip" {
  description = "Private IP address of the private instance"
  value       = aws_instance.private.private_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "s3_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.assets.bucket
}

output "public_instance_iam_role_arn" {
  description = "ARN of the IAM role for public instances"
  value       = aws_iam_role.ec2_public_role.arn
}

output "private_instance_iam_role_arn" {
  description = "ARN of the IAM role for private instances"
  value       = aws_iam_role.ec2_private_role.arn
}

output "public_instance_profile_name" {
  description = "Name of the IAM instance profile for public instances"
  value       = aws_iam_instance_profile.public_instance.name
}

output "private_instance_profile_name" {
  description = "Name of the IAM instance profile for private instances"
  value       = aws_iam_instance_profile.private_instance.name
}