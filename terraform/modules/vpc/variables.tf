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
