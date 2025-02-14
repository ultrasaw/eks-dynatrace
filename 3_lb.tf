resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path = "/"
  }
}

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh_and_ports.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_autoscaling_attachment" "autoscaling_attachment" {
  for_each = {for name, value in module.eks.eks_managed_node_groups : name => value.node_group_resources[0].autoscaling_groups[0].name}

  autoscaling_group_name = each.value
  lb_target_group_arn    = aws_lb_target_group.app_tg.arn
  depends_on = [module.eks]
}

resource "aws_security_group_rule" "allow_alb_to_instance" {
  type              = "ingress"
  from_port         = 80
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_ssh_and_ports.id
  cidr_blocks       = ["0.0.0.0/0"] # from anywhere
}
