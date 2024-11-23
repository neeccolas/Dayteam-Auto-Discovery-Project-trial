output "stage-asg-id" {
  value = aws_autoscaling_group.stage-asg.id
}

output "stage-asg-name" {
  value = aws_autoscaling_group.stage-asg.name
}

output "stage-lt-id" {
  value = aws_launch_template.stage_lt.image_id
}

output "stage-lb-dns" {
  value = aws_lb.alb-stage.dns_name
}

output "stage-zone-id" {
  value = aws_lb.alb-stage.zone_id
}