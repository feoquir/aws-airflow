##################################################################
########### VPC Creation ###########
module "main_vpc" {
    source = "./modules/3layer_vpc"
    region = var.tf_creds.region
}
##################################################################
########### Load Balancer Creation ###########
### Security Group Creation
resource "aws_security_group" "airflow_alb" {
  name        = "airflow-alb"
  description = "Airflow Application Load Balancer"
  vpc_id      = module.main_vpc.vpc.id

  tags = {
    Name = "airflow-alb"
  }
}
resource "aws_security_group_rule" "airflow_alb-ib1" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = [var.inc_ip]

  security_group_id = aws_security_group.airflow_alb.id
}
resource "aws_security_group_rule" "airflow_alb-ib2" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = [var.inc_ip]

  security_group_id = aws_security_group.airflow_alb.id
}
resource "aws_security_group_rule" "airflow_alb-ob1" {
  type      = "egress"
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"
  source_security_group_id = aws_security_group.airflow_ws.id

  security_group_id = aws_security_group.airflow_alb.id
}
### Load Balancer Creation
resource "aws_lb" "airflow" {
  name               = "airflow"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.airflow_alb.id]
  subnets            = module.main_vpc.public_sn.*.id

  enable_deletion_protection = false
}
### Target Group
resource "aws_lb_target_group" "airflow" {
  name     = "airflow-gui-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.main_vpc.vpc.id
  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 120
  }

  target_type = "ip"

}
### Listener Creation - HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.airflow.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
### Listener Creation - HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.airflow.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.frontend_certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.airflow.arn
  }
}