output "production-asg-id" {
  value = aws_autoscaling_group.production-asg.id
}

output "production-asg-name" {
  value = aws_autoscaling_group.production-asg.name
}

output "production_lt-id" {
  value = aws_launch_template.production_lt
}

output "production-lb-dns" {
  value = aws_lb.alb-production.dns_name
}

output "production-zone-id" {
  value = aws_lb.alb-production.zone_id
}