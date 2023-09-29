locals {
  subnet_for_jenkins = data.aws_subnets.vpc_subnets.ids[0]
}

resource "aws_key_pair" "jenkins_ec2_key_pair" {
  key_name   = "jenkins-ec2-key-pair"
  public_key = data.aws_ssm_parameter.jenkins_public_key.value
}

resource "aws_instance" "jenkins_instance" {
  ami                    = data.aws_ssm_parameter.ubuntu_20_ami_id.value
  instance_type          = var.ec2_instance_size_type
  key_name               = aws_key_pair.jenkins_ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_ec2_security_group.id]

  user_data = templatefile("init.sh", {
    EFS_DNS = aws_efs_file_system.efs_for_jenkins.dns_name
  })

  # replace instance upon any changes in init.sh file
  user_data_replace_on_change = true

  # associate with subnet to enable aws_efs_file_system to be created first
  subnet_id = local.subnet_for_jenkins

  lifecycle {
    # unblocks any updates to the security group: https://github.com/hashicorp/terraform-provider-aws/issues/265#issuecomment-1462631019
    replace_triggered_by = [
      aws_security_group.jenkins_ec2_security_group.name
    ]
  }

  depends_on = [
    # enables init.sh to mount EFS
    aws_efs_file_system.efs_for_jenkins
  ]
}
