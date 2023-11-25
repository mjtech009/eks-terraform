data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# need to add data source for openvpn 20.04

data "aws_ami" "ubuntu-ovpn" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "kubectl" {
  name   = "${local.name_prefix}-kubectl_bastion"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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
    Name = "${local.name_prefix}-kubectl_bastion"
  }
}

resource "aws_instance" "kubectl" {
  depends_on = [
    #aws_eks_node_group.eks_ng_private,
    resource.local_file.pem_key,
  ]
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet[0].id
  vpc_security_group_ids      = [aws_security_group.kubectl.id]
  key_name                    = aws_key_pair.pem.key_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.id
  root_block_device {
    volume_size           = "10"
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = false
  }

  tags = {
    Name = "${local.name_prefix}-kubectl_bastion"
  }
  user_data = <<EOF
#!/bin/bash -ex
apt-get update -y
apt install awscli docker.io unzip wget curl git -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --bin-dir /usr/bin --install-dir /usr/bin --update
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -o root -g root -m 0755 kubectl /usr/bin/kubectl
kubectl version --client
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/bin
eksctl version
EOF



  lifecycle {
    ignore_changes = [
      # Ignore changes to tags,ami e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags, ami
    ]
  }

}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${local.name_prefix}-kubectl_bastion"
  role = aws_iam_role.eks_ec2_role.name
}
