output "public-key-id" {
  description = "The public keypair id"
  value = aws_key_pair.public-key.id
}

output "private-key-pem" {
  description = "Private key data in PEM (RFC 1421) format"
  value = tls_private_key.keypair.private_key_pem
}