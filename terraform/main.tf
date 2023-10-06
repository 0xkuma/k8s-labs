module "vpc" {
  source = "./modules/vpc"

  project     = var.project
  environment = var.environment
  cidr_block  = var.cidr_block
  subnets     = var.subnets
}

module "role" {
  source = "./modules/iam"

  project     = var.project
  environment = var.environment
}

module "bastion" {
  source = "./modules/ec2"

  project     = var.project
  environment = var.environment
  node = merge(
    var.bastion,
    {
      name      = "bastion"
      subnet_id = module.vpc.public_subnets
      vpc_security_group_ids = [
        module.vpc.bastion_security_group_id
      ]
      iam_instance_profile = module.role.instance_profile_name
      ansible = {
        playbook = var.bastion.ansible.playbook
        bastion = {
          ip          = ""
          username    = var.bastion.ansible.bastion.username
          private_key = var.bastion.ansible.bastion.private_key
        }
        remote = {
          username           = var.bastion.ansible.remote.username
          private_key        = var.bastion.ansible.remote.private_key
          remote_master_host = ""
        }
      }
    }
  )
}

resource "time_sleep" "main" {
  triggers = {
    bastion_ip = module.bastion.public_ips[0]
  }
  create_duration = "30s"
  depends_on      = [module.bastion]
}

resource "null_resource" "main" {
  triggers = {
    bastion_ip = module.bastion.public_ips[0]
  }
  provisioner "local-exec" {
    command = "ssh-keyscan -H ${module.bastion.public_ips[0]} >> ~/.ssh/known_hosts"
  }
  depends_on = [time_sleep.main]
}

module "master" {
  source = "./modules/ec2"

  project     = var.project
  environment = var.environment
  node = merge(
    var.nodes.master,
    {
      name                   = "master"
      subnet_id              = module.vpc.private_subnets
      vpc_security_group_ids = [module.vpc.master_security_group_id]
      iam_instance_profile   = module.role.instance_profile_name
      ansible = {
        playbook = var.nodes.master.ansible.playbook
        bastion = {
          ip          = module.bastion.public_ips[0]
          username    = var.nodes.master.ansible.bastion.username
          private_key = var.nodes.master.ansible.bastion.private_key
        }
        remote = {
          username           = var.nodes.master.ansible.remote.username
          private_key        = var.nodes.master.ansible.remote.private_key
          remote_master_host = ""
        }
      }
    }
  )
  depends_on = [null_resource.main]
}

module "worker" {
  source = "./modules/ec2"

  project     = var.project
  environment = var.environment
  node = merge(
    var.nodes.worker,
    {
      name                   = "worker"
      subnet_id              = module.vpc.private_subnets
      vpc_security_group_ids = [module.vpc.worker_security_group_id]
      iam_instance_profile   = module.role.instance_profile_name
      ansible = {
        playbook = var.nodes.worker.ansible.playbook
        bastion = {
          ip          = module.bastion.public_ips[0]
          username    = var.nodes.worker.ansible.bastion.username
          private_key = var.nodes.worker.ansible.bastion.private_key
        }
        remote = {
          username           = var.nodes.worker.ansible.remote.username
          private_key        = var.nodes.worker.ansible.remote.private_key
          remote_master_host = var.nodes.worker.num_instances > 0 ? module.master.private_ips[0] : ""
        }
      }
    }
  )
  depends_on = [null_resource.main]
}
