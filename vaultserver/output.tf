#Creating vault IP address
output "vault_ip" {
  value = aws_instance.vault.public_ip
}