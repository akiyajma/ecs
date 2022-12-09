###
# ECS Task Container Log Groups
###

resource "aws_cloudwatch_log_group" "puppet" {
  name              = "/ecs/puppet"
  retention_in_days = 1
}
