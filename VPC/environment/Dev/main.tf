module "vpc_vm" {
  source = "../.."

  region              = var.region
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone  = var.availability_zone
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  ssh_public_key_path = var.ssh_public_key_path

  #  enable_ssm_access = true
  additional_public_instance_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
  additional_private_instance_policies = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}

output "public_instance_public_ip" {
  value = module.vpc_vm.public_instance_public_ip
}

output "private_instance_private_ip" {
  value = module.vpc_vm.private_instance_private_ip
}

output "alb_dns_name" {
  value = module.vpc_vm.alb_dns_name
}

output "s3_bucket_name" {
  value = module.vpc_vm.s3_bucket_name
}


