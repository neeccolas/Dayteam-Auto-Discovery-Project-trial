provider "aws" {
  region = var.region
  profile = "euteam1"
}
#creating Iam policy for my iam role (this policy allows an ec2 to assume a role)
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
#attaching the policy created above to the Iam role
resource "aws_iam_role" "vault-kms-unseal" {
  name               = "vault-kms-role-1"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
#create an Iam policy to access AWS KMS
data "aws_iam_policy_document" "vault-kms-unseal" {
  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = [aws_kms_key.vault.arn]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
  }
}
#attach the KMS policy created above to the IAM role
resource "aws_iam_role_policy" "vault-kms-unseal" {
  name   = "Vault-KMS-Unseal-1"
  role   = aws_iam_role.vault-kms-unseal.id
  policy = data.aws_iam_policy_document.vault-kms-unseal.json
}

#create instance profile which will attach the role to the ec2 instance
resource "aws_iam_instance_profile" "vault-kms-unseal" {
  name = "vault-kms-unseal-1"
  role = aws_iam_role.vault-kms-unseal.name
}

# Creating RSA key of size 4096 bits
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}
resource "local_file" "ssh_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "vault-key.pem"
  file_permission = "600"
}
resource "aws_key_pair" "keypair" {
  key_name   = "vault-key.pem"
  public_key = tls_private_key.key.public_key_openssh
}
#Creating security group for vault
resource "aws_security_group" "Vault-SG" {
  name        = "Vault-SG"
  description = "Allow Inbound Traffic"
  ingress {
    description = "https port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "vault port"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http access"
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
    name = "Vault-SG"
  }
}
# Creating Ec2 for Terraform Vault
resource "aws_instance" "vault" {
  ami                         = var.ami
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.Vault-SG.id]
  key_name                    = aws_key_pair.keypair.key_name
  iam_instance_profile        = aws_iam_instance_profile.vault-kms-unseal.id
  associate_public_ip_address = true
  user_data = templatefile("./vault-script.sh", {
    aws_region = var.region,
    kms_key    = aws_kms_key.vault.id
  })
  tags = {
    Name = "Vault-Server"
  }
}
# Route 53 Hosted Zone
data "aws_route53_zone" "hosted_zone" {
  name         = var.domain-name
  private_zone = false
}
# Create a record for the vault server
resource "aws_route53_record" "vault-record" {
  zone_id = data.aws_route53_zone.hosted_zone.id
  name    = var.domain-name-1
  type    = "A"
  alias {
    name                   = aws_elb.vault_load_balancer.dns_name
    zone_id                = aws_elb.vault_load_balancer.zone_id
    evaluate_target_health = true
  }
}
# SSL Certificate
resource "aws_acm_certificate" "certificate" {
  domain_name               = var.domain-name
  subject_alternative_names = [var.domain-name-2]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "petclinic-SSL-Certificate"
  }
}
# Route53 Validation Record
resource "aws_route53_record" "validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}
# Create acm certificate validition
resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_record : record.fqdn]
}
# Classic Load Balancer
resource "aws_elb" "vault_load_balancer" {
  name               = "vault-load-balancer"
  security_groups    = [aws_security_group.Vault-SG.id]
  availability_zones = ["eu-west-1a", "eu-west-1b"]
  listener {
    lb_port            = 443
    lb_protocol        = "https"
    instance_port      = 8200
    instance_protocol  = "http"
    ssl_certificate_id = aws_acm_certificate.certificate.arn
  }
  health_check {
    target              = "TCP:8200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  instances                   = [aws_instance.vault.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  tags = {
    Name = "Vault-lb"
  }
}
# Creating key vault
resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10
  tags = {
    Name = "vault-kms-unseal"
  }
}
# Creating a time sleep resource to delay the excecution of our local exec which help us to fetch the vault token from the vault server after it has been created.
resource "time_sleep" "wait_5_minutes" {
  depends_on      = [aws_instance.vault]
  create_duration = "300s"
}
resource "null_resource" "fetch-token" {
  depends_on = [aws_instance.vault, time_sleep.wait_5_minutes]
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ./vault-key.pem ubuntu@${aws_instance.vault.public_ip}:/home/ubuntu/token.txt ."
  }
}