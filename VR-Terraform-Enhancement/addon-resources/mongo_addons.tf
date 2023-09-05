data "aws_ssm_parameter" "mongo_host" {
  depends_on = [
    module.mongodb
  ]
  name = "/${local.workspace.environment_name}/MongoDB/MONGODB_HOST"
}
data "aws_ssm_parameter" "mongo_authdb" {
  depends_on = [
    module.mongodb
  ]
  name = "/${local.workspace.environment_name}/MongoDB/ADMIN_DB"
}
data "aws_ssm_parameter" "mongo_admin_user" {
  depends_on = [
    module.mongodb
  ]
  name = "/${local.workspace.environment_name}/MongoDB/ADMIN_USER"
}
data "aws_ssm_parameter" "mongo_admin_password" {
  depends_on = [
    module.mongodb
  ]
  name = "/${local.workspace.environment_name}/MongoDB/MONGODB_ADMIN_PASSWORD"
}


resource "random_string" "mongo_search_password" {
  length  = 34
  special = false
}

resource "null_resource" "mongo-query" {
  depends_on = [ 
                data.aws_ssm_parameter.mongo_host
               ]
  provisioner "local-exec" {
    command = <<EOT
    #!/bin/bash
    mongosh mongodb://$USERNAME:$PASSWORD@$HOST/$AUTH_DB <<EOF
    use $SEARCH_DB_NAME;
    db.createUser(
       {
         user: "$SEARCH_USER",
         pwd: "$SEARCH_PASSWORD",
         roles:
           [
             { role: "dbAdmin", db: "$SEARCH_DB_NAME" }
           ]
       }
    );
    EOF
    EOT
    environment = {
      SEARCH_DB_NAME = local.workspace.mongo_addons.search_db_name
      USERNAME = data.aws_ssm_parameter.mongo_admin_user.value
      PASSWORD = data.aws_ssm_parameter.mongo_admin_password.value
      HOST = data.aws_ssm_parameter.mongo_host.value
      AUTH_DB = data.aws_ssm_parameter.mongo_authdb.value
      SEARCH_USER = local.workspace.mongo_addons.search_user_name
      SEARCH_PASSWORD = random_string.mongo_search_password.result
    }
  }
}

resource "aws_ssm_parameter" "mongo_search_db" {
 depends_on = [
               null_resource.mongo-query
              ]
  name        = "/${local.workspace.environment_name}/MongoDB/SEARCH_DB"
  description = "Mongo search database"
  type        = "String"
  value       = local.workspace.mongo_addons.search_db_name
}
resource "aws_ssm_parameter" "mongo_search_user" {
 depends_on = [
               null_resource.mongo-query
              ]
  name        = "/${local.workspace.environment_name}/MongoDB/SEARCH_USER"
  description = "Mongo search user"
  type        = "String"
  value       = local.workspace.mongo_addons.search_user_name
}
resource "aws_ssm_parameter" "mongo_search_password" {
 depends_on = [
               null_resource.mongo-query
              ]
  name        = "/${local.workspace.environment_name}/MongoDB/SEARCH_PASSWORD"
  description = "Mongo search Password"
  type        = "SecureString"
  value       = random_string.mongo_search_password.result
}
