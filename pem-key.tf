resource "tls_private_key" "pem" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "pem" {
  # key_name   = var.key_name
  key_name   = "${local.name_prefix}-${var.key_name}"
  public_key = tls_private_key.pem.public_key_openssh
}

resource "local_file" "pem_key" {
  filename = "${aws_key_pair.pem.key_name}.pem"
  content  = tls_private_key.pem.private_key_pem
}