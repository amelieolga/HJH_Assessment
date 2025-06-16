output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
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