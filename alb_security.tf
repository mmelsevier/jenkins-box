resource "aws_security_group" "alb_security_group" {
  name   = "jenkins-alb-security-group"
  vpc_id = data.aws_ssm_parameter.jenkins_vpc_id.value

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  timeouts {
    delete = "2m"
  }
}

resource "aws_security_group_rule" "allow_https_access_to_alb_from_ip" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${data.aws_ssm_parameter.jenkins_allow_inbound_access_from_ip.value}/32"]
  security_group_id = aws_security_group.alb_security_group.id
}

resource "aws_security_group_rule" "allow_http_access_to_alb_from_ip" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${data.aws_ssm_parameter.jenkins_allow_inbound_access_from_ip.value}/32"]
  security_group_id = aws_security_group.alb_security_group.id
}
