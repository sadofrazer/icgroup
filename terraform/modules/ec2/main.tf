data "aws_ami" "my_ubuntu_ami" {
  most_recent = true
  owners = ["${var.ubuntu_account_number}"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal*"]
  }
}

resource "aws_instance" "frazer-ec2" {
  ami             = "ami-0149b2da6ceec4bb0"
  key_name        = var.ssh_key
  availability_zone = "${var.az}"
  security_groups = ["${var.sg_name}"]
  tags = {
    Name = "${var.author}-ec2"
  }

  root_block_device {
    delete_on_termination = true
  }

  provisioner "local-exec" {
    command = " echo '${var.author} [ PUBLIC IP: ${var.public_ip} ; ID: ${aws_instance.frazer-ec2.id} ; AZ: ${aws_instance.frazer-ec2.availability_zone} ]' >> infos_ec2.txt"
  }

}

