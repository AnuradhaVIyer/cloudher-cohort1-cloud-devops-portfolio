# ---------------------------------------------------------
# Amazon Linux 2023 AMI
# ---------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
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
# SSM Role and Instance Profile for EC2
# ---------------------------------------------------------

resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.env_prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.env_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ---------------------------------------------------------
# EC2 Instance
# ---------------------------------------------------------

resource "aws_instance" "devops-lab-web-server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.devops-lab-subnet-public.id
  vpc_security_group_ids = [aws_security_group.devops-lab-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

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

