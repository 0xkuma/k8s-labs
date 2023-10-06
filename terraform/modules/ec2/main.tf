resource "aws_instance" "main" {
  count                       = var.node.num_instances
  ami                         = var.node.ami
  instance_type               = var.node.instance_type
  key_name                    = var.node.key_name
  subnet_id                   = var.node.subnet_id[(length(var.node.subnet_id) % count.index) - 1]
  vpc_security_group_ids      = var.node.vpc_security_group_ids
  associate_public_ip_address = var.node.associate_public_ip_address
  iam_instance_profile        = var.node.iam_instance_profile

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = var.node.volume_size
    volume_type           = "gp3"
  }

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-${var.node.name}"
    }
  )
}

resource "time_sleep" "main" {
  count = var.node.name == "bastion" ? 1 : 0
  triggers = {
    bastion_ip = aws_instance.main.*.public_ip[count.index]
  }
  create_duration = "30s"
  depends_on      = [aws_instance.main]
}

resource "null_resource" "update_known_hosts" {
  count = var.node.name == "bastion" ? 1 : 0
  triggers = {
    bastion_ip = aws_instance.main.*.public_ip[count.index]
  }
  provisioner "local-exec" {
    command = "ssh-keyscan -H ${aws_instance.main.*.public_ip[count.index]} >> ~/.ssh/known_hosts"
  }
  depends_on = [time_sleep.main]
}

resource "null_resource" "ansible_bastion" {
  count = var.node.name == "bastion" ? 1 : 0
  triggers = {
    bastion_ip = aws_instance.main.*.public_ip[count.index]
  }
  provisioner "local-exec" {
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    command = var.node.ansible.playbook == "" ? "echo 'No playbook to run'" : "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${aws_instance.main.*.public_ip[count.index]},' -u ${var.node.ansible.bastion.username} --private-key ${var.node.ansible.bastion.private_key} ${var.node.ansible.playbook}"
  }
  depends_on = [null_resource.update_known_hosts]
}

resource "null_resource" "ansible" {
  count = var.node.name != "bastion" ? var.node.num_instances : 0
  triggers = {
    private_ip = aws_instance.main.*.private_ip[count.index]
  }
  provisioner "local-exec" {
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    command = var.node.ansible.playbook == "" ? "echo 'No playbook to run'" : var.node.name == "master" ? "${local.bCommand} --extra-vars='bastion_host=${var.node.ansible.bastion.ip} remote_host=${aws_instance.main.*.private_ip[count.index]} remote_user=${var.node.ansible.remote.username} remote_key=${var.node.ansible.remote.private_key} hostname=${var.node.name}${count.index + 1}'" : var.node.name == "worker" ? "${local.bCommand}  --extra-vars='bastion_host=${var.node.ansible.bastion.ip} remote_host=${aws_instance.main.*.private_ip[count.index]} remote_user=${var.node.ansible.remote.username} remote_key=${var.node.ansible.remote.private_key} remote_master_host=${var.node.ansible.remote.remote_master_host} hostname=${var.node.name}${count.index + 1}'" : local.bCommand
  }
}
