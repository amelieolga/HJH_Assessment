# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.environment}-igw"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Associate Public Subnet with Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create Private Subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment}-private-subnet"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "${var.environment}-nat-gw"
  }
}

# Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.environment}-private-rt"
  }
}

# Associate Private Subnet with Route Table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create Security Group for Public Instance
resource "aws_security_group" "public_instance" {
  name        = "${var.environment}-public-instance-sg"
  description = "Allow SSH and HTTP traffic to public instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-public-instance-sg"
  }
}

# Create Security Group for Private Instance
resource "aws_security_group" "private_instance" {
  name        = "${var.environment}-private-instance-sg"
  description = "Allow traffic from public subnet to private instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from public subnet"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = [var.public_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-private-instance-sg"
  }
}

# Create EC2 Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.environment}-key"
  public_key = file(var.ssh_public_key_path)
}

# Create Public EC2 Instance
resource "aws_instance" "public" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public_instance.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.public_instance.name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Public Instance in ${var.environment}</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "${var.environment}-public-instance"
  }
}

# Create Private EC2 Instance
resource "aws_instance" "private" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_instance.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.private_instance.name

  tags = {
    Name = "${var.environment}-private-instance"
  }
}

# Create S3 Bucket for Assets
resource "aws_s3_bucket" "assets" {
  bucket = "${var.environment}-assets-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "${var.environment}-assets-bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Create Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_instance.id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.environment}-alb"
  }
}

# Create ALB Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
}

# Attach Public Instance to Target Group
resource "aws_lb_target_group_attachment" "public" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.public.id
  port             = 80
}

# Create ALB Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# IAM Roles and Policies
resource "aws_iam_role" "ec2_public_role" {
  name               = "${var.environment}-public-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "ec2_private_role" {
  name               = "${var.environment}-private-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = {
    Environment = var.environment
  }
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "public_instance" {
  name = "${var.environment}-public-instance-profile"
  role = aws_iam_role.ec2_public_role.name
}

resource "aws_iam_instance_profile" "private_instance" {
  name = "${var.environment}-private-instance-profile"
  role = aws_iam_role.ec2_private_role.name
}

# Assume Role Policy
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Public Instance Policies
resource "aws_iam_role_policy" "public_instance_s3_read" {
  name   = "${var.environment}-public-s3-read"
  role   = aws_iam_role.ec2_public_role.id
  policy = data.aws_iam_policy_document.public_instance_s3_read.json
}

resource "aws_iam_role_policy" "public_instance_cloudwatch" {
  name   = "${var.environment}-public-cloudwatch"
  role   = aws_iam_role.ec2_public_role.id
  policy = data.aws_iam_policy_document.basic_cloudwatch.json
}

# Private Instance Policies
resource "aws_iam_role_policy" "private_instance_s3_full" {
  name   = "${var.environment}-private-s3-full"
  role   = aws_iam_role.ec2_private_role.id
  policy = data.aws_iam_policy_document.private_instance_s3_full.json
}

resource "aws_iam_role_policy" "private_instance_cloudwatch" {
  name   = "${var.environment}-private-cloudwatch"
  role   = aws_iam_role.ec2_private_role.id
  policy = data.aws_iam_policy_document.basic_cloudwatch.json
}

# Policy Documents
data "aws_iam_policy_document" "public_instance_s3_read" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.assets.arn,
      "${aws_s3_bucket.assets.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "private_instance_s3_full" {
  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.assets.arn,
      "${aws_s3_bucket.assets.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "basic_cloudwatch" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

# Attach SSM Policy for both instances (for management)
resource "aws_iam_role_policy_attachment_public" "public_ssm" {
  role       = aws_iam_role.ec2_public_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment_private" "private_ssm" {
  role       = aws_iam_role.ec2_private_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Conditional SSM Policy Attachment
resource "aws_iam_role_policy_attachment_ssm_public" "public_ssm" {
  count      = var.enable_ssm_access ? 1 : 0
  role       = aws_iam_role.ec2_public_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment_ssm_private" "private_ssm" {
  count      = var.enable_ssm_access ? 1 : 0
  role       = aws_iam_role.ec2_private_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Additional Policies Attachment
resource "aws_iam_role_policy_attachment_public_additional" "public_additional" {
  for_each   = toset(var.additional_public_instance_policies)
  role       = aws_iam_role.ec2_public_role.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment_private_additional" "private_additional" {
  for_each   = toset(var.additional_private_instance_policies)
  role       = aws_iam_role.ec2_private_role.name
  policy_arn = each.value
}