provider "aws" {
    region = var.aws_region
}

resource "tls_private_key" "bastion_rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_public_key" {
  key_name = "${var.key_name}"
  public_key = tls_private_key.bastion_rsa_key.public_key_openssh
}

resource "local_file" "bastion_private_key" {
  content  = tls_private_key.bastion_rsa_key.private_key_pem
  filename = "cert.pem"
}

# BUG NOT EXECUTED !!
resource "null_resource" "private_key_permissions" {
  depends_on = [local_file.bastion_private_key]
  provisioner "local-exec" {
    command = "chmod 600 cert.pem"
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter { 
    name   = "name"
    #values = ["al2023-ami-2023.3.20240219.0-kernel-6.1-x86_64"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240223"]
  }
}

resource "aws_instance" "broker" {
    count = var.instance_count["broker"]
    ami = data.aws_ami.ubuntu.id
    instance_type = var.aws_instance_type
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = aws_subnet.default.id
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-broker-${var.instance_prefix}-${format("%02d", count.index+1)}"
    }
}

resource "aws_instance" "zookeeper" {
    count = var.instance_count["zookeeper"]
    ami = data.aws_ami.ubuntu.id
    instance_type = var.aws_instance_type
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = aws_subnet.default.id
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-zookeeper-${var.instance_prefix}-${format("%02d", count.index+1)}"
    }
}

resource "aws_instance" "connect" {
    count = var.instance_count["connect"]
    ami = data.aws_ami.ubuntu.id
    instance_type = var.aws_instance_type
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = aws_subnet.default.id
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "kafka-connect-${var.instance_prefix}-${format("%02d", count.index+1)}"
    }
}

resource "aws_instance" "akhq" {
    count = 1
    ami = data.aws_ami.ubuntu.id
    instance_type = var.aws_instance_type
    key_name = var.key_name
    vpc_security_group_ids = ["${aws_security_group.kafka_sg.id}"] 
    subnet_id = aws_subnet.default.id
    associate_public_ip_address = true
    source_dest_check = false
    tags = {
        Name = "Akhq-${var.instance_prefix}-${format("%02d", count.index+1)}"
    }
}

resource "local_file" "generate_inventory_ansible" {
  content = templatefile("inventory.tmpl", {
    zk_hosts_ansible = aws_instance.zookeeper.*.public_dns
    kafka_hosts_ansible = aws_instance.broker.*.public_dns
    kafka_connect_hosts_ansible = aws_instance.connect.*.public_dns
    akhq_hosts_ansible = aws_instance.akhq.*.public_dns
  })
  filename = "../ansible/generated_hosts.yml"
  depends_on = [ aws_instance.zookeeper, aws_instance.broker, aws_instance.connect, aws_instance.akhq ]
}