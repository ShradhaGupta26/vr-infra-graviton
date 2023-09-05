module "elasticsearch" {
  source                       = "git::https://github.com/sumittiwari022/terraform-aws-elasticsearch.git"
  create_aws_elasticsearch     = false
  create_aws_ec2_elasticsearch = true
  instance_count               = local.workspace.elasticsearch.instance_count
  instance_type                = local.workspace.elasticsearch.instance_type
  project_name_prefix          = local.workspace.environment_name
  subnet_ids                   = data.aws_subnets.private.ids
  volume_size                  = local.workspace["elasticsearch"]["volume_size"]
  vpc_id                       = data.aws_vpc.selected.id
  key_name                     = local.workspace["key_name"]
  volume_type                  = local.workspace["elasticsearch"]["volume_type"]
  kms_key_id                   = local.workspace.elasticsearch.kms_key_id
}
