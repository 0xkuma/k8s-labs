variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "lb_arn" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "node" {
  type = object({
    num_instances               = number
    name                        = string
    subnet_id                   = list(string)
    instance_type               = string
    ami                         = string
    volume_size                 = number
    key_name                    = string
    associate_public_ip_address = bool
    vpc_security_group_ids      = list(string)
    iam_instance_profile        = string
    ansible = object({
      playbook = string
      bastion = object({
        ip          = string
        username    = string
        private_key = string
      })
      remote = object({
        username           = string
        private_key        = string
        remote_master_host = string
      })
    })
  })
}
