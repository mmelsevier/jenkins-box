resource "aws_security_group" "jenkins_ec2_security_group" {
  name   = "jenkins-ec2-security-group"
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

resource "aws_security_group_rule" "allow_access_from_alb_to_jenkins_on_ec2" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_security_group.id
  security_group_id        = aws_security_group.jenkins_ec2_security_group.id
}

resource "aws_security_group_rule" "allow_ssh_access_from_ip_to_jenkins_on_ec2" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${data.aws_ssm_parameter.jenkins_allow_inbound_access_from_ip.value}/32"]
  security_group_id = aws_security_group.jenkins_ec2_security_group.id
}
