output "aws_lb_arn" {
  value = aws_lb.main.arn
}

output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.main.arn
}
