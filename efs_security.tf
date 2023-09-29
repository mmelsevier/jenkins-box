resource "aws_security_group" "efs_sg" {
  name_prefix = "efs-sg-"
}

resource "aws_security_group_rule" "efs_ingress" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins_ec2_security_group.id
  security_group_id        = aws_security_group.efs_sg.id
}

resource "aws_security_group_rule" "efs_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.jenkins_ec2_security_group.id
  security_group_id        = aws_security_group.efs_sg.id
}
