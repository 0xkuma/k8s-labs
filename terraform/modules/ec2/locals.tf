locals {
  bTags = {
    Project     = var.project
    Environment = var.environment
  }
  pTags = "${var.project}-${var.environment}"
}

locals {
  bCommand = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${var.node.ansible.bastion.ip},' -u ${var.node.ansible.bastion.username} --private-key ${var.node.ansible.bastion.private_key} ${var.node.ansible.playbook}"
}
