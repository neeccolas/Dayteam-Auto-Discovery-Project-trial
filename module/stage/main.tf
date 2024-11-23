#create target group for stage asg
# Creating load balancer Target Group for stage asg
resource "aws_lb_target_group" "lb-tg-stage" {
  name     = "${var.name}-lb-tg-stage"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc-id

  health_check {
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}

# Creating Application Load Balancer for stage asg
resource "aws_lb" "alb-stage" {
  name                       = "${var.name}-asg-stage-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.stage-sg.id]
  subnets                    = var.subnets
  enable_deletion_protection = false

  tags = {
    Name = "${var.name}-alb-stage"
  }
}

#Importing acm certificate form our AWS account
data "aws_acm_certificate" "certificate" {
  domain      = var.domain_name
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

#Creating Load Balancer Listener for https
resource "aws_lb_listener" "lb_lsnr-https" {
  load_balancer_arn = aws_lb.alb-stage.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg-stage.arn
  }
}

# Creating Load Balancer Listener for http
resource "aws_lb_listener" "lb_lsnr-http" {
  load_balancer_arn = aws_lb.alb-stage.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg-stage.arn
  }
}

# Create Launch Template
resource "aws_launch_template" "stage_lt" {
  image_id               = var.redhat
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.stage-sg.id]
  key_name               = var.pub-key
  user_data = base64encode(templatefile("./module/stage-env/script.sh", {
    nexus-ip             = var.nexus-ip,
    newrelic-license-key = var.newrelic-user-licence,
    newrelic-account-id  = var.newrelic-acct-id,
    newrelic-region      = var.newrelic-region
  }))
}

#Create AutoScaling Group
resource "aws_autoscaling_group" "stage-asg" {
  name                      = "${var.name}-stage-asg"
  desired_capacity          = 1
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  force_delete              = true
  vpc_zone_identifier       = var.vpc-zone-identifier
  target_group_arns         = [aws_lb_target_group.lb-tg-stage.arn]
  launch_template {
    id = aws_launch_template.stage_lt.id
  }
  tag {
    key                 = "Name"
    value               = "${var.name}-stage-asg"
    propagate_at_launch = true
  }
}

#Create ASG Policy
resource "aws_autoscaling_policy" "stage-asg-policy" {
  name                   = "${var.name}-stage-asg-policy"
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.stage-asg.id
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

# Auto Scaling Group SG for stage
resource "aws_security_group" "stage-sg" {
  name        = "${var.name}-stage-sg"
  description = "stage security group"
  vpc_id      = var.vpc-id

  # Inbound Rules
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http port 1"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http port 2"
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
    Name = "${var.name}-stage-sg"
  }
}