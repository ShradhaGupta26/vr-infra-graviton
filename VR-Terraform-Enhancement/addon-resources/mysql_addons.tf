// Get SSM Parameters

data "aws_ssm_parameter" "rds_endpoint" {
  depends_on = [
    module.create_database
  ]
  name = "/${local.workspace.rds.environment}/RDS/ENDPOINT"
}
data "aws_ssm_parameter" "rds_username" {
  depends_on = [
    module.create_database
  ]
  name = "/${local.workspace.rds.environment}/RDS/USER"
}
data "aws_ssm_parameter" "rds_password" {
  depends_on = [
    module.create_database
  ]
  name = "/${local.workspace.rds.environment}/RDS/PASSWORD"
}
data "aws_ssm_parameter" "rds_db_name" {
  depends_on = [
    module.create_database
  ]
  name = "/${local.workspace.rds.environment}/RDS/NAME"
}

//MySQL Provider

provider "mysql" {
  endpoint = "${module.create_database.endpoint}" 
  username = "${module.create_database.username}"
  password = "${module.create_database.password}"
}

# Create RDS App users

resource "random_string" "app_password" {
  count = length(local.workspace.mysql_addons.app_user_names)
  length  = 34
  special = false
}

resource "time_sleep" "wait_300_seconds" {
  depends_on = [module.create_database,module.message_queue]

  destroy_duration = "300s"
}

resource "mysql_user" "app_user" {
  count = length(local.workspace.mysql_addons.app_user_names)
  user               = local.workspace.mysql_addons.app_user_names[count.index]
  host               = "%"
  plaintext_password = random_string.app_password[count.index].result
  depends_on = [time_sleep.wait_300_seconds]
}
resource "mysql_grant" "app_user" {
  count = length(local.workspace.mysql_addons.app_user_names)
  user       = mysql_user.app_user[count.index].user
  host       = mysql_user.app_user[count.index].host
  database   = data.aws_ssm_parameter.rds_db_name.value
  privileges = ["SELECT", "UPDATE", "INSERT", "DELETE", "CREATE", "ALTER", "REFERENCES"]
  depends_on = [time_sleep.wait_300_seconds]
}
resource "aws_ssm_parameter" "app_username" {
  count = length(local.workspace.mysql_addons.app_user_names)
  name        = "/${local.workspace.environment_name}/RDS/${local.workspace.mysql_addons.app_user_names[count.index]}/USERNAME"
  description = "${local.workspace.mysql_addons.app_user_names[count.index]} Username"
  type        = "String"
  value       = mysql_user.app_user[count.index].user
  
}
resource "aws_ssm_parameter" "app_password" {
  count = length(local.workspace.mysql_addons.app_user_names)
  name        = "/${local.workspace.environment_name}/RDS/${local.workspace.mysql_addons.app_user_names[count.index]}/PASSWORD"
  description = "${local.workspace.mysql_addons.app_user_names[count.index]} Password"
  type        = "SecureString"
  value       = random_string.app_password[count.index].result

}

# Create Search Database
resource "mysql_database" "app" {
    depends_on = [
      time_sleep.wait_300_seconds
      ]
  name = local.workspace.mysql_addons.search_db_name
}
resource "aws_ssm_parameter" "search_db_name" {
  name        = "/${local.workspace.environment_name}/SEARCH_DB/NAME"
  description = "search database name"
  type        = "String"
  value       = mysql_database.app.name
}

# Create and grant access to Search DB Users

resource "random_string" "app_search_password" {
  count = length(local.workspace.mysql_addons.search_user_names)
  length  = 34
  special = false
}
resource "mysql_user" "app_search_user" {
  count = length(local.workspace.mysql_addons.search_user_names)
  user               = local.workspace.mysql_addons.search_user_names[count.index]
  host               = "%"
  plaintext_password = random_string.app_search_password[count.index].result
  depends_on = [time_sleep.wait_300_seconds]
}
resource "mysql_grant" "app_search_user" {
  count = length(local.workspace.mysql_addons.search_user_names)
  user       = mysql_user.app_search_user[count.index].user
  host       = mysql_user.app_search_user[count.index].host
  database   = mysql_database.app.name
  privileges = ["SELECT", "UPDATE", "INSERT", "DELETE", "CREATE", "ALTER", "REFERENCES"]
  depends_on = [time_sleep.wait_300_seconds]
}
resource "aws_ssm_parameter" "app_search_username" {
  count = length(local.workspace.mysql_addons.search_user_names)
  name        = "/${local.workspace.environment_name}/SEARCH_DB/${local.workspace.mysql_addons.search_user_names[count.index]}/USERNAME"
  description = "${local.workspace.mysql_addons.search_user_names[count.index]} Username"
  type        = "String"
  value       = mysql_user.app_search_user[count.index].user

}
resource "aws_ssm_parameter" "app_search_password" {
  count = length(local.workspace.mysql_addons.search_user_names)
  name        = "/${local.workspace.environment_name}/SEARCH_DB/${local.workspace.mysql_addons.search_user_names[count.index]}/PASSWORD"
  description = "${local.workspace.mysql_addons.search_user_names[count.index]} Search Password"
  type        = "SecureString"
  value       = random_string.app_search_password[count.index].result

 }