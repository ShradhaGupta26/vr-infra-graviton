data "aws_ssm_parameter" "rabbit_endpoint" {
  depends_on = [
    module.message_queue
  ]
  name = "/${local.workspace.environment_name}/rabbit/ENDPOINT"
}
data "aws_ssm_parameter" "rabbit_password" {
  depends_on = [
    module.message_queue
  ]
  name = "/${local.workspace.environment_name}/rabbit/PASSWORD"
}
data "aws_ssm_parameter" "rabbit_username" {
  depends_on = [
    module.message_queue
  ]
  name = "/${local.workspace.environment_name}/rabbit/USERNAME"
}
provider "rabbitmq" {
  endpoint = "http://${data.aws_ssm_parameter.rabbit_endpoint.value}:15672"
  username = data.aws_ssm_parameter.rabbit_username.value
  password = data.aws_ssm_parameter.rabbit_password.value
}

#resource "time_sleep" "wait_2_minutes" {
#  depends_on = [module.message_queue]

# create_duration = "120s"
#}

# This resource will create (at least) 30 seconds after null_resource.previous
resource "null_resource" "next" {
  depends_on = [time_sleep.wait_300_seconds]
}
resource "rabbitmq_queue" "queues_create" {
  depends_on = [
    time_sleep.wait_300_seconds
  ]
  count = length(local.workspace.rabbit_addons.queue_list)
  name  = local.workspace.rabbit_addons.queue_list[count.index]
  vhost = "/"
  settings {
    durable     = false
    auto_delete = true
  }
}

resource "rabbitmq_exchange" "exchange_create" {
  depends_on = [
    time_sleep.wait_300_seconds
  ]
  count = length(local.workspace.rabbit_addons.exchange_list)
  name  = local.workspace.rabbit_addons.exchange_list[count.index]
  settings {
    type        = "fanout"
    durable     = false
    auto_delete = true
  }
}