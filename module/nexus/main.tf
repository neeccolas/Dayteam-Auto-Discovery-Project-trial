# Creating Nexus server
resource "aws_instance" "nexus" {
  ami                         = "ami-0574a94188d1b84a1"
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.nexus_sg.id]
  subnet_id                   = var.subnet_id
  key_name                    = var.keypair
  user_data                   =file("./userdata.sh")
   
  tags = {
    Name = "${var.name}-nexus"
  }
}

# Security Group
resource "aws_security_group" "nexus_sg" {
  name = "${var.name}-nexus-sg"
  description = "nexus-sg"
  vpc_id = var.vpc_id

  ingress {   
    description = "ssh-port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "nexus-defaultport"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "docker-registryport"
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "httpsport"
    from_port   = 443
    to_port     = 443
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


#creating nexus elb
resource "aws_elb" "nexus-elb" {
  name            = "nexus-elb"
  security_groups = [aws_security_group.nexus_sg.id]
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

  instances                   = [aws_instance.nexus.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "nexus-elb"
  }
}

//Retrieve ACM Certificate from AS account
data "aws_acm_certificate" "certificate" {
  domain      = var.domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

# Retrieve Route 53 Zone
data "aws_route53_zone" "nexus_zone" {
  name         = var.domain # Replace with your Route 53 zone name
  private_zone = false          # Set to true if using a private zone
}

#Create Route 53 Alias Record for Load Balancer
resource "aws_route53_record" "nexus_alias" {
  zone_id = data.aws_route53_zone.nexus_zone.zone_id
  name    = var.nexus-domain # Replace with your desired subdomain
  type    = "A"

  alias {
    name                   = aws_elb.nexus-elb.dns_name
    zone_id                = aws_elb.nexus-elb.zone_id
    evaluate_target_health = true
  }
}