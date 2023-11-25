resource "aws_instance" "ovpn" {
  depends_on = [
    #aws_eks_node_group.eks_ng_private,
    resource.local_file.pem_key,
  ]
  ami                         = data.aws_ami.ubuntu-ovpn.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet[0].id
  vpc_security_group_ids      = [aws_security_group.ovpn.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.pem.key_name
  root_block_device {
    volume_size           = "10"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = false
  }

  tags = {
    Name = "${local.name_prefix}-ovpn"
  }
  user_data = <<EOF
#!/bin/bash -ex
sudo apt -y update &&  sudo apt -y install ca-certificates wget net-tools gnupg
sudo wget https://as-repository.openvpn.net/as-repo-public.asc -qO /etc/apt/trusted.gpg.d/as-repository.asc
sudo su -c "echo 'deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/as-repository.asc] http://as-repository.openvpn.net/as/debian focal main'>/etc/apt/sources.list.d/openvpn-as-repo.list"
sudo apt -y update && sudo apt -y install openvpn-as
username=$(sudo cat /usr/local/openvpn_as/init.log|egrep "password|^Admin"|tail -2)
echo $user
echo "***    Please use Public IP with https    ***"

EOF


  lifecycle {
    ignore_changes = [
      # Ignore changes to tags,ami e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags, ami
    ]
  }


}
resource "aws_eip" "eip_ovpn" {
  instance = aws_instance.ovpn.id
  domain   = "vpc"

  tags = {
    Name = "${local.name_prefix}-ovpn"
  }
}
resource "aws_eip_association" "eip_a" {
  instance_id   = aws_instance.ovpn.id
  allocation_id = aws_eip.eip_ovpn.id
}

resource "aws_security_group" "ovpn" {
  name   = "${local.name_prefix}-ovpn"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${local.var.vpc-cidr}.0.0/16"]
  }
  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.name_prefix}-ovpn"
  }
}

output "ovpn_endpoint" {
  value = aws_eip.eip_ovpn.public_ip
}
