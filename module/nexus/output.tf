output "nexus-ip" {
  value = aws_instance.nexus.public_ip
}

output "nexus-sg" {
  value = aws_security_group.nexus_sg.id
}