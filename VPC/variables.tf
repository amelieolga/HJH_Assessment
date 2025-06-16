variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Dev"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}
variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "enable_ssm_access" {
  description = "Whether to enable AWS Systems Manager access for instances"
  type        = bool
  default     = true
}

variable "additional_public_instance_policies" {
  description = "List of additional policy ARNs to attach to public instances"
  type        = list(string)
  default     = []
}

variable "additional_private_instance_policies" {
  description = "List of additional policy ARNs to attach to private instances"
  type        = list(string)
  default     = []
}