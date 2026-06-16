resource "aws_lb" "alb" {
    name               = "alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.sg_alb.id]
    subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet2.id]
}

resource "aws_lb_target_group" "tg_frontend" {
  name     = "tg-frontend"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.medishare_vpc.id
  health_check { path = "/" }
}

resource "aws_lb_target_group" "tg_backend" {
  name     = "tg-backend"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.medishare_vpc.id

  health_check { 
    path                = "/api/doctor/login" 
    # Accepte les codes de 200 à 499 (évite le Unhealthy sur un 401 ou 404)
    matcher             = "200-499" 
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_frontend.arn
  }
}

resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern { values = ["/api/*"] }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_backend.arn
  }
}