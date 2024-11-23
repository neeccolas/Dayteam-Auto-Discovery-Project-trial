# create baston_host
resource "aws_instance" "bastion-host" {
  ami                         = var.redhat
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet-id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  key_name                    = var.public-key-name
  user_data                   = <<-EOF
#!/bin/bash
echo "${var.private-key}" >> /home/ec2-user/.ssh/id_rsa
chmod 400 /home/ec2-user/.ssh/id_rsa
sudo chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
sudo hostnamectl set-hostname bastion
EOF
  tags = {
    Name = "${var.name}-bastion-server"
  }
}

# Bastion SG
resource "aws_security_group" "bastion-sg" {
  name        = "${var.name}-bastion-sg"
  description = "bastion Security Group"
  vpc_id      = var.vpc-id

  # Inbound Rules
  ingress {
    description = "ssh access"
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
  tags = {
    Name = "${var.name}-bastion-sg"
  }
}