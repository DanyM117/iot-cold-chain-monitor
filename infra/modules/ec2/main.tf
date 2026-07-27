data "aws_ami" "debian_12" {
  most_recent = true
  owners      = ["136693071363"] # Debian

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "server" {
  ami                         = data.aws_ami.debian_12.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = var.iam_instance_profile_name
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  metadata_options {
    http_tokens   = "required" # IMDSv2 only
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    curl -fsSL https://get.docker.com | sh
    curl -fsSL https://tailscale.com/install.sh | sh
    systemctl enable --now tailscaled docker
  EOF

  tags = merge(var.tags, { Name = "${var.name_prefix}-server" })
}
