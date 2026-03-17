provider "aws" {
  region = "ap-southeast-1"
}

# use existing VPC
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["ce-learner-vpc"]
  }
}

# get subnet from VPC
data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

# select first subnet
data "aws_subnet" "subnet" {
  id = data.aws_subnets.subnets.ids[0]
}

# get latest AMI for Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# create EC2 instance
resource "aws_instance" "ec2" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.subnet.id

  tags = {
    Name = "faizal-ec2-tf"
  }
}

# create 1 GB EBS volume in same AZ
resource "aws_ebs_volume" "ebs" {
  availability_zone = data.aws_subnet.subnet.availability_zone
  size              = 1

  tags = {
    Name = "faizal-ebs-tf"
  }
}

# attach EBS volume to EC2
resource "aws_volume_attachment" "attach" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ebs.id
  instance_id = aws_instance.ec2.id
}