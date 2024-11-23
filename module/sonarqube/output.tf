output "instance_public_ip" {
  value       = aws_instance.sonarqube.public_ip
}