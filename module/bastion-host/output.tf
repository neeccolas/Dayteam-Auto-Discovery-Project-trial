output "bastion-ip" {
  value = aws_instance.bastion-host.public_ip
}

output "bastion-sg" {
  value = aws_security_group.bastion-sg.id
}