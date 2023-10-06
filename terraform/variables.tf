variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "subnets" {
  type = object({
    public  = list(string)
    private = list(string)
  })
}

variable "bastion" {
  type = object({
    num_instances               = number
    instance_type               = string
    ami                         = string
    volume_size                 = number
    key_name                    = string
    associate_public_ip_address = bool
    ansible = object({
      playbook = string
      bastion = object({
        username    = string
        private_key = string
      })
      remote = object({
        username    = string
        private_key = string
      })
    })
  })
}

variable "nodes" {
  type = object({
    master = object({
      num_instances               = number
      instance_type               = string
      ami                         = string
      volume_size                 = number
      key_name                    = string
      associate_public_ip_address = bool
      ansible = object({
        playbook = string
        bastion = object({
          username    = string
          private_key = string
        })
        remote = object({
          username    = string
          private_key = string
        })
      })
    })
    worker = object({
      num_instances               = number
      instance_type               = string
      ami                         = string
      volume_size                 = number
      key_name                    = string
      associate_public_ip_address = bool
      ansible = object({
        playbook = string
        bastion = object({
          username    = string
          private_key = string
        })
        remote = object({
          username    = string
          private_key = string
        })
      })
    })
  })
}
