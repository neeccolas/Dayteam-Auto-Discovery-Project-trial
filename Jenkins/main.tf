provider "aws" {
  region  = "eu-west-3"
  profile = "euteam1"
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-07d1e0a32156d0d21"
  instance_type               = "t2.large"
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  key_name                    = aws_key_pair.public-key.id
  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.id
  associate_public_ip_address = true
  user_data                   = file("./jenkins-script.sh")

  root_block_device {
    volume_size = 30    # Size in GB
    volume_type = "gp3" # Optional: General Purpose SSD
  }

  tags = {
    Name = "jenkins-server"
  }
}

# dynamic keypair resource
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private-key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "jenkins-key.pem"
  file_permission = 660
}

resource "aws_key_pair" "public-key" {
  key_name   = "jenkins-key-trial"
  public_key = tls_private_key.keypair.public_key_openssh
}

resource "aws_security_group" "jenkins-sg" {
  name = "jenkins-sg2"
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
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

  tags = {
    Name = "jenkins-sg2"
  }
}

data "aws_route53_zone" "route53" {
  name         = "dobetabeta.shop"
  private_zone = false
}

#IP address of jenkins is linked directly to route53
resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.route53.zone_id
  name    = "jenkins.dobetabeta.shop"
  type    = "A"
  ttl     = 300
  records = [aws_instance.jenkins.public_ip]
}