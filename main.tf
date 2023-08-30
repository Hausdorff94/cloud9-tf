module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "cloud9-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# --------------------------------------------
# Cloud9 ENVs
# --------------------------------------------

resource "aws_cloud9_environment_ec2" "public_ssh" {
  name                        = "public_ssh_env"
  connection_type             = "CONNECT_SSH"
  instance_type               = "t2.micro"
  image_id                    = "ubuntu-18.04-x86_64"
  subnet_id                   = module.vpc.public_subnets[0]
  automatic_stop_time_minutes = 30
}

# --------------------------------------------
# IAM USERS (EXISTING USERS)
# --------------------------------------------

# Cloud9Access & R/W Member
data "aws_iam_user" "c9_user" {
  user_name = "<IAM_USER>"
}

# --------------------------------------------
# IAM USERS POLICIES
# --------------------------------------------

resource "aws_iam_user_policy_attachment" "c9_attach" {
  user       = data.aws_iam_user.user1.user_name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloud9EnvironmentMember"
}

# --------------------------------------------
# MEBERSHIP
# --------------------------------------------

resource "aws_cloud9_environment_membership" "c9_member" {
  environment_id = aws_cloud9_environment_ec2.public_ssh.id
  permissions    = "read-write"
  user_arn       = data.aws_iam_user.c9_user.arn

  # depends_on = [ aws_iam_user.c9_user ]
}

# --------------------------------------------
# PROVIDER
# --------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.7.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
