data "aws_ssm_parameter" "jenkins_public_key" {
  name = "/jenkins-box/instance/ssh-public-key"
}

data "aws_ssm_parameter" "jenkins_vpc_id" {
  name = "/jenkins-box/security/vpc-id"
}

data "aws_ssm_parameter" "jenkins_allow_inbound_access_from_ip" {
  name = "/jenkins-box/security/allow-ip"
}

data "aws_ssm_parameter" "ubuntu_20_ami_id" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/arm64/hvm/ebs-gp2/ami-id"
}

data "aws_ssm_parameter" "domain_route53_zone_id" {
  name = "/jenkins-box/domain/route53-zone-id"
}

data "aws_ssm_parameter" "domain" {
  name = "/jenkins-box/domain/name"
}

data "aws_ssm_parameter" "subdomain" {
  name = "/jenkins-box/domain/subdomain"
}

data "aws_acm_certificate" "issued" {
  domain   = data.aws_ssm_parameter.domain.value
  statuses = ["ISSUED"]
}

data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.jenkins_vpc_id.value]
  }
}
