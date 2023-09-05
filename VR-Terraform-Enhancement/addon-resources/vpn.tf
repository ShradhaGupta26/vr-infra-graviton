
module "vpn" {
  source                           = "git::https://github.com/sumittiwari022/terraform-aws-vpn"
  create_aws_vpn                   = false
  create_aws_ec2_pritunl           = true
  vpc_id                           = data.aws_vpc.selected.id
  project_name_prefix              = local.workspace.environment_name
  key_name                         = local.workspace.key_name
  instance_type                    = local.workspace.vpn.instance_type
  subnet_id                        = data.aws_subnets.public.ids[0]
  volume_type                      = local.workspace.vpn.volume_type
  root_volume_size                 = local.workspace.vpn.root_volume_size
  vpn_port                         = local.workspace.vpn.vpn_port
  common_tags = {
    "Project"     = "${local.workspace.project_name}",
    "Environment" = "${local.workspace.environment_name}"
  }
}

