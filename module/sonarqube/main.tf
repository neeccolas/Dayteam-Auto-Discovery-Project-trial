resource "aws_instance" "sonarqube" {
  ami           = var.ami
  instance_type = "t2.medium"
  associate_public_ip_address = true
  subnet_id = var.subnet_id
  key_name = var.keypair
  user_data     = file("./sonarqube/userdata.sh")
  vpc_security_group_ids = [aws_security_group.sonarqube_sg.id]
  tags = {
    Name = "${var.name}-SonarQube-Server"
  }
}

# creating a security group
resource "aws_security_group" "sonarqube_sg" {
  name = "${var.name}-sonarqube-sg"
  vpc_id = var.vpc_id
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "sonarqube access"
    from_port   = 9000
    to_port     = 9000
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

#creating sonarqube elb
resource "aws_elb" "sonarqube-elb" {
  name            = "sonarqube-elb"
  security_groups = [aws_security_group.sonarqube_sg.id]
  subnets         = var.subnets

  listener {
    instance_port      = 9000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = data.aws_acm_certificate.certificate.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "tcp:9000"
    interval            = 30
  }

  instances                   = [aws_instance.sonarqube.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  tags = {
    Name = "${var.name}-sonarqube-elb"
  }
}

#Retrieve ACM Certificates from AS account
data "aws_acm_certificate" "certificate" {
  domain      = var.domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

# Retrieve Route 53 Zone
data "aws_route53_zone" "sonarqube_zone" {
  name         = var.domain # Replace with your Route 53 zone name
  private_zone = false          # Set to true if using a private zone
}

#Create Route 53 Alias Record for Load Balancer
resource "aws_route53_record" "sonarqube_alias" {
  zone_id = data.aws_route53_zone.sonarqube_zone.zone_id
  name    = var.sonarqube-domain # Replace with your desired subdomain
  type    = "A"

  alias {
    name                   = aws_elb.sonarqube-elb.dns_name
    zone_id                = aws_elb.sonarqube-elb.zone_id
    evaluate_target_health = true
  }
}