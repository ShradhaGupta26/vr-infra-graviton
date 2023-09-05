module mongodb {
  source              = "git::https://github.com/ShradhaGupta26/terraform-aws-mongodb.git"
  region              = local.workspace["aws"]["region"]
  secondary_node_type = local.workspace["mongodb"]["secondary_node_type"]
  num_secondary_nodes = local.workspace.mongodb.create_secondary
  primary_node_type   = local.workspace["mongodb"]["primary_node_type"]
  vpc_id              = data.aws_vpc.selected.id
  mongo_database      = local.workspace["mongodb"]["db_name"]
  mongo_subnet_id = data.aws_subnets.private.ids[0]
  #jumpbox_subnet_id = data.aws_subnets.public.ids[0]
  key_name = "${local.workspace.project_name}-${local.workspace["mongodb"]["key_name"]}"
  mongo_ami=data.aws_ami.jumpbox.id
  environment = local.workspace.environment_name
  project_name = local.workspace.project_name
}
resource "aws_ssm_parameter" "vr_mongo_db" {
  name        = "/${local.workspace.environment_name}/MongoDB/MONGO_DB_NAME"
  description = "mongodb database"
  type        = "String"
  value       = "vr_search"
  tags        =  { 
		   "Project"     = "${local.workspace.project_name}",
   		   "Environment" = "${local.workspace.environment_name}"
 		 }
}
