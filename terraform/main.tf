# ==========================================
# 1. NETWORK INFRASTRUCTURE & ROUTING
# ==========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "employee-portal-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "employee-portal-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet" }
}

resource "aws_subnet" "private_backend" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_backend_cidr
  availability_zone = "ap-south-1b"
  tags              = { Name = "backend-private-subnet" }
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_cidr
  availability_zone = "ap-south-1c"
  tags              = { Name = "db-private-subnet" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "employee-portal-nat" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-route-table" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "private-route-table" }
}

resource "aws_route_table_association" "backend" {
  subnet_id      = aws_subnet.private_backend.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db" {
  subnet_id      = aws_subnet.private_db.id
  route_table_id = aws_route_table.private.id
}

# ==========================================
# 2. IAM ROLE FOR SSM (Secure Access)
# ==========================================

resource "aws_iam_role" "ssm_role" {
  name = "employee-portal-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "employee-portal-ec2-profile"
  role = aws_iam_role.ssm_role.name
}

# ==========================================
# 3. BOOTSTRAP SCRIPT (Install Docker & SSM)
# ==========================================

locals {
  docker_setup = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release snapd
              
              # Install Docker
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              
              # Enable and start Docker
              systemctl enable docker
              systemctl start docker
              
              # Add ubuntu user to docker group
              usermod -aG docker ubuntu
              
              # Ensure SSM Agent is active
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              EOF
}

# ==========================================
# 4. SECURITY GROUPS
# ==========================================

# Jenkins SG
resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "Allow Jenkins Dashboard Access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Frontend SG
resource "aws_security_group" "frontend" {
  name        = "frontend-sg"
  description = "Allow public web traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
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
}

# Backend SG
resource "aws_security_group" "backend" {
  name        = "backend-sg"
  description = "Allow traffic from Frontend and Jenkins"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id, aws_security_group.jenkins.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database SG
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Allow traffic from Backend and Jenkins"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id, aws_security_group.jenkins.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# 5. EC2 INSTANCES
# ==========================================

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

# 1. Jenkins Server (Public Subnet)
resource "aws_instance" "jenkins" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.jenkins_instance_type
  subnet_id            = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  user_data            = local.docker_setup

  tags = { Name = "Jenkins-Server" }
}

# 2. Frontend Server (Public Subnet)
resource "aws_instance" "frontend" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend.id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  user_data            = local.docker_setup

  tags = { Name = "Frontend-Server" }
}

# 3. Backend Server (Private Subnet)
resource "aws_instance" "backend" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.private_backend.id
  vpc_security_group_ids = [aws_security_group.backend.id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  user_data            = local.docker_setup

  tags = { Name = "Backend-Server" }
}

# 4. Database Server (Private Subnet)
resource "aws_instance" "database" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.private_db.id
  vpc_security_group_ids = [aws_security_group.db.id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  user_data            = local.docker_setup

  tags = { Name = "Database-Server" }
}
