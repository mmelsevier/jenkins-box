resource "aws_efs_file_system" "efs_for_jenkins" {
  creation_token = "jenkins-efs"
}

resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.efs_for_jenkins.id
  subnet_id       = local.subnet_for_jenkins
  security_groups = [aws_security_group.efs_sg.id]
}
