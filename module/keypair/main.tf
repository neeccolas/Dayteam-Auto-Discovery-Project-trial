# dynamic keypair resource
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private-key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = var.private-file
  file_permission = "600"
}

resource "aws_key_pair" "public-key" {
  key_name   = var.public-file
  public_key = tls_private_key.keypair.public_key_openssh
}