output "public_ips" {
  value = aws_instance.main.*.public_ip
}

output "private_ips" {
  value = aws_instance.main.*.private_ip
}
