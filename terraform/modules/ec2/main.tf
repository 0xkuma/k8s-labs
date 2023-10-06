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

  provisioner "local-exec" {
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    command = var.node.name == "master" ? "${local.bCommand} --extra-vars='bastion_host=${var.node.ansible.bastion.ip} remote_host=${aws_instance.main.*.private_ip[count.index]} remote_user=${var.node.ansible.remote.username} remote_key=${var.node.ansible.remote.private_key} hostname=${var.node.name}${count.index + 1}'" : var.node.name == "worker" ? "${local.bCommand}  --extra-vars='bastion_host=${var.node.ansible.bastion.ip} remote_host=${aws_instance.main.*.private_ip[count.index]} remote_user=${var.node.ansible.remote.username} remote_key=${var.node.ansible.remote.private_key} remote_master_host=${var.node.ansible.remote.remote_master_host} hostname=${var.node.name}${count.index + 1}'" : "echo 'No playbook to run'"
  }

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-${var.node.name}"
    }
  )
}
