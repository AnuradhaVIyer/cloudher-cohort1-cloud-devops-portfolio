# ---------------------------------------------------------
# Dynamic Data Source for latest Ubuntu 24.04 LTS AMI
# ---------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS Account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------
resource "aws_vpc" "devops-lab-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env_prefix}-${var.project_prefix}-vpc"
  }
}

# ---------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------
resource "aws_internet_gateway" "devops-lab-igw" {
  vpc_id = aws_vpc.devops-lab-vpc.id
  tags = {
    Name = "${var.env_prefix}-${var.project_prefix}-igw"
  }
}


# ---------------------------------------------------------
# Public Subnet
# ---------------------------------------------------------

resource "aws_subnet" "devops-lab-subnet-public" {
  vpc_id                  = aws_vpc.devops-lab-vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env_prefix}-${var.project_prefix}-subnet-public"
  }
}

# ---------------------------------------------------------
# Route Table
# ---------------------------------------------------------
resource "aws_route_table" "devops-lab-route-table" {
  vpc_id = aws_vpc.devops-lab-vpc.id
  tags = {
    Name = "${var.env_prefix}-${var.project_prefix}-route-table"
  }
}

# ---------------------------------------------------------
# Default Route -> Internet Gateway
# ---------------------------------------------------------
resource "aws_route" "devops-lab-route" {
  route_table_id         = aws_route_table.devops-lab-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.devops-lab-igw.id
}

# ---------------------------------------------------------
# Route Table Association
# ---------------------------------------------------------

resource "aws_route_table_association" "devops-lab-public-subnet" {
  subnet_id      = aws_subnet.devops-lab-subnet-public.id
  route_table_id = aws_route_table.devops-lab-route-table.id
}


# ---------------------------------------------------------
# Security Group
# No need to open SSH port as we will use SSM to connect to 
# the EC2 instance
# ---------------------------------------------------------
resource "aws_security_group" "devops-lab-sg" {
  name        = "devops-lab-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.devops-lab-vpc.id

  ingress {
    description = "HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["110.226.182.107/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env_prefix}-${var.project_prefix}-sg"
  }

}

# ---------------------------------------------------------
# AWS Key Pair for SSH access to EC2 instance
# ---------------------------------------------------------
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "dev-devops-lab-ec2-key"
  public_key = var.ec2_public_key
}

# ---------------------------------------------------------
# EC2 Instance (Ubuntu 24.04 LTS)
# ---------------------------------------------------------

resource "aws_instance" "devops-lab-web-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.devops-lab-subnet-public.id
  vpc_security_group_ids = [aws_security_group.devops-lab-sg.id]
  key_name               = aws_key_pair.ec2_key_pair.key_name

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
  tags = {
    Name = "${var.env_prefix}-${var.project_prefix}-web-server"
  }

}

