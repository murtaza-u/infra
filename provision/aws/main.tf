terraform {
  cloud {
    organization = "murtaza-u"
    workspaces {
      name = "homelab-aws"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      Name = var.srv_cloud_0.instance_name
    }
  }
}

# fetching AWS AMI image
data "aws_ami" "nixos" {
  owners      = ["427812963091"]
  most_recent = true
  filter {
    name   = "name"
    values = ["nixos/24.11*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"] # or "x86_64"
  }
}

# creating SSH key pair
resource "aws_key_pair" "key_pair" {
  key_name   = var.srv_cloud_0.instance_name
  public_key = var.srv_cloud_0.public_key
}

### security group ###
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.srv_cloud_0.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  description       = "Allow SSH inbound traffic"
  security_group_id = aws_security_group.srv_cloud_0.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  description       = "Allow http inbound traffic"
  security_group_id = aws_security_group.srv_cloud_0.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  description       = "Allow https inbound traffic"
  security_group_id = aws_security_group.srv_cloud_0.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "srv_cloud_0" {
  name        = var.srv_cloud_0.instance_name
  description = "Firewall rules for ${var.srv_cloud_0.instance_name}"
}
### END - security group ###

# creating and associating an elastic IP
resource "aws_eip" "srv_cloud_0" {
  instance = aws_instance.srv_cloud_0.id
  domain   = "vpc"
}

# launching an EC2 instance
resource "aws_instance" "srv_cloud_0" {
  ami           = data.aws_ami.nixos.id
  instance_type = var.srv_cloud_0.instance_type
  root_block_device {
    volume_size           = var.srv_cloud_0.root_block_device.v_size
    volume_type           = var.srv_cloud_0.root_block_device.v_type
    delete_on_termination = true
  }
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.srv_cloud_0.id]
}
