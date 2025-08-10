# VPC & Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "two-tier-VPC" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = { Name = "Public-Subnet" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "Private-Subnet" }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for backend internet access
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "frontend" {
  name   = "frontend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "backend" {
  name   = "backend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
# Step 1: Frontend (Public)
resource "aws_instance" "frontend" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  associate_public_ip_address = true
  tags                        = { Name = "FRONTEND" }

  # Copy PEM file to frontend
  provisioner "file" {
    source      = "~/.ssh/two-tier.pem"
    destination = "/home/ubuntu/.ssh/two-tier.pem"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/two-tier.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ubuntu/.ssh/two-tier.pem",
      "sudo apt update -y",
      "sudo apt install -y docker.io",
      "sudo usermod -aG docker ubuntu"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/two-tier.pem")
      host        = self.public_ip
    }
  }
}

# Step 2: Backend (Private via NAT + bastion)
resource "aws_instance" "backend" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private.id
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.backend.id]
  associate_public_ip_address = false
  tags                        = { Name = "BACKEND" }

  depends_on = [aws_instance.frontend]

  provisioner "file" {
    source      = "../scripts/backend.sh"
    destination = "/home/ubuntu/backend.sh"
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file("~/.ssh/two-tier.pem")
      host                = self.private_ip
      bastion_host        = aws_instance.frontend.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("~/.ssh/two-tier.pem")
      timeout             = "5m"
    }
  }

  provisioner "file" {
    source      = "../backend/init.sql"
    destination = "/home/ubuntu/init.sql"
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file("~/.ssh/two-tier.pem")
      host                = self.private_ip
      bastion_host        = aws_instance.frontend.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("~/.ssh/two-tier.pem")
      timeout             = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/backend.sh",
      "sudo /home/ubuntu/backend.sh ${var.dockerhub_username}"
    ]
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file("~/.ssh/two-tier.pem")
      host                = self.private_ip
      bastion_host        = aws_instance.frontend.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("~/.ssh/two-tier.pem")
      timeout             = "5m"
    }
  }
}

# Step 3: Configure frontend after backend
resource "null_resource" "configure_frontend" {
  depends_on = [aws_instance.backend]

  provisioner "file" {
    source      = "../scripts/frontend.sh"
    destination = "/home/ubuntu/frontend.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/two-tier.pem")
      host        = aws_instance.frontend.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/frontend.sh",
      "sudo /home/ubuntu/frontend.sh ${aws_instance.backend.private_ip} ${var.dockerhub_username}"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/two-tier.pem")
      host        = aws_instance.frontend.public_ip
    }
  }
}

