resource "aws_security_group" "main" {
  name        = "${local.pTags}-nlb-sg"
  description = "Alb security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "${local.pTags}-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.main.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "${local.pTags}nalb"
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${local.pTags}-nlb-tg"
  port        = "9092"
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "9092"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}
