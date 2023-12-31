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

module "elb" {
  source = "./modules/elb/nlb"

  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnets
}

module "bastion" {
  source = "./modules/ec2"

  project          = var.project
  environment      = var.environment
  lb_arn           = module.elb.aws_lb_arn
  target_group_arn = module.elb.aws_lb_target_group_arn
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

module "master" {
  source = "./modules/ec2"

  project          = var.project
  environment      = var.environment
  lb_arn           = module.elb.aws_lb_arn
  target_group_arn = module.elb.aws_lb_target_group_arn
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
  depends_on = [module.bastion]
}

module "worker" {
  source = "./modules/ec2"

  project          = var.project
  environment      = var.environment
  lb_arn           = module.elb.aws_lb_arn
  target_group_arn = module.elb.aws_lb_target_group_arn
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
  depends_on = [module.bastion]
}
