module "message_queue" {
  source              = "git::https://github.com/ShradhaGupta26/terraform-aws-queue.git"
  create_aws_activemq     = false
  create_aws_ec2_rabbitmq = true
  vpc_id  = data.aws_vpc.selected.id
  ec2_subnet_id =  data.aws_subnets.private.ids[0]
  subnet_ids = data.aws_subnets.private.ids  
  common_tags = local.tags
  worker  = 0
  master  = 1
  key_name = local.workspace["key_name"]
  kms_key_id = aws_kms_key.queue_key.arn
  instance_type = local.workspace["queue"]["instance_type"]
  disable_api_termination = true
  disable_api_stop        = false
  root_volume_size = 50
  vpc_cidr_block = data.aws_vpc.selected.cidr_block
  environment_name = local.workspace.environment_name
  region = local.workspace["aws"]["region"]
  project_name_prefix = local.workspace.account_name
}
resource "aws_kms_key" "queue_key" {
  description             = local.workspace.queue.kms_key_desc
  key_usage               = "ENCRYPT_DECRYPT"
  policy                  = "${data.template_file.kms.rendered}"
  deletion_window_in_days = local.workspace.queue.deletion_window_in_days
  is_enabled              = true
  enable_key_rotation     = false

  tags = {
    "Project"     = local.workspace.project_name
    "ManagedBy"   = "Terraform"
    "Environment" = local.workspace.environment_name
  }
}

resource "aws_kms_alias" "queue_key_alias" {
  name          = "alias/queue-${local.workspace.environment_name}-${local.workspace.project_name}"
  target_key_id = aws_kms_key.queue_key.id
}
