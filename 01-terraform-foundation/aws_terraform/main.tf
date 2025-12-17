provider "aws" {
  region = var.aws_region

  # Optional: specify an AWS profile or a specific credentials file via variables
  # If these are empty strings, the provider will fall back to default env/credential chain.
  profile                  = var.aws_profile
  shared_credentials_files = var.aws_shared_credentials_file != "" ? [var.aws_shared_credentials_file] : null

}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "devops-vpc"
  cidr = "10.0.0.0/16"

  # Keep AZs aligned to the number of private/public subnet CIDRs provided.
  # Using two AZs to match the two private subnet CIDRs defined below.
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_dns_hostnames = true

}



# Dedicated security group for the application instances (created below)
resource "aws_security_group" "app_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for app server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_http_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# IAM role and instance profile so the instance can be managed using AWS Systems Manager (SSM)
data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ssm_role" {
  name               = "${var.instance_name}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = module.vpc.private_subnets[0]

  # Optional SSH key_name (set via var.key_name). If empty, will be omitted.
  key_name = var.key_name != "" ? var.key_name : null

  # Attach an instance profile so SSM can manage the instance (see IAM resources below).
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  tags = {
    Name = var.instance_name
  }
}
