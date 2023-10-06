output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = values(aws_subnet.public)[*].id
}

output "private_subnets" {
  value = values(aws_subnet.private)[*].id
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion.id
}

output "master_security_group_id" {
  value = aws_security_group.master.id
}

output "worker_security_group_id" {
  value = aws_security_group.worker.id
}
