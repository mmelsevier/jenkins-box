resource "aws_route53_record" "jenkins_site_subdomain" {
  zone_id = data.aws_ssm_parameter.domain_route53_zone_id.value
  name    = data.aws_ssm_parameter.subdomain.value
  type    = "A"
  alias {
    name                   = aws_lb.jenkins_instance_load_balancer.dns_name
    zone_id                = aws_lb.jenkins_instance_load_balancer.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb" "jenkins_instance_load_balancer" {
  name               = "jenkins-instance-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = data.aws_subnets.vpc_subnets.ids

  lifecycle {
    replace_triggered_by = [
      aws_security_group.alb_security_group.name
    ]
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.jenkins_instance_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.issued.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }
}

resource "aws_lb_target_group" "jenkins" {
  name_prefix = "lb-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_ssm_parameter.jenkins_vpc_id.value

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_lb_target_group_attachment" "jenkins_instance_load_balancer_target_group_attachment" {
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = aws_instance.jenkins_instance.private_ip
  port             = 8080
}

resource "aws_lb_listener" "jenkins_instance_load_balancer_listener" {
  load_balancer_arn = aws_lb.jenkins_instance_load_balancer.arn
  port              = 80
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
