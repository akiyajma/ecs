#locals {
#  app_name = "puppet"
#}
#
#data "template_file" "ecs-puppet" {
#  template = file("./template/ecs_puppet_user_data.sh")
#  vars = {
#    ecs_cluster = local.app_name
#    s3_bucket   = aws_s3_bucket.ecs-puppet.id
#  }
#}
#
#resource "aws_launch_template" "ecs-puppet" {
#  name_prefix   = "${local.app_name}-"
#  image_id      = data.aws_ami.ecs-puppet.id
#  instance_type = "t2.small"
#  key_name      = "test1"
#  user_data     = base64encode(data.template_file.ecs-puppet.rendered)
#
#  iam_instance_profile {
#    name = aws_iam_instance_profile.ecs_puppet.name
#  }
#
#  block_device_mappings {
#    device_name = "/dev/xvda"
#    ebs {
#      volume_size = 30
#      volume_type = "gp2"
#    }
#  }
#
#  network_interfaces {
#    security_groups = [aws_security_group.ecs-puppet.id]
#  }
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}
#
#resource "aws_launch_configuration" "ecs-puppet" {
#  name_prefix                 = "${local.app_name}-"
#  image_id                    = data.aws_ami.ecs-puppet.id
#  instance_type               = "t2.micro"
#  security_groups             = [aws_security_group.ecs-puppet.id]
#  enable_monitoring           = true
#  iam_instance_profile        = aws_iam_instance_profile.ecs_puppet.name
#  user_data                   = base64encode(data.template_file.ecs-puppet.rendered)
#  associate_public_ip_address = false
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}
#
#
#resource "aws_autoscaling_group" "ecs-puppet" {
#  name                  = local.app_name
#  min_size              = 1
#  max_size              = 3
#  desired_capacity      = 3
#  protect_from_scale_in = true
#
#  launch_template {
#    id      = aws_launch_template.ecs-puppet.id
#    version = "$Latest"
#  }
#
#  vpc_zone_identifier = [
#    for subnet in aws_subnet.private :
#    subnet.id
#  ]
#
#  lifecycle {
#    create_before_destroy = true
#    ignore_changes        = [desired_capacity]
#  }
#  tag {
#    key                 = "Name"
#    value               = local.app_name
#    propagate_at_launch = true
#  }
#}
#
#####
## ECS Cluster
#####
#resource "aws_ecs_cluster" "puppet" {
#  name = local.app_name
#}
#
#resource "aws_ecs_capacity_provider" "puppet" {
#  name = local.app_name
#
#  auto_scaling_group_provider {
#    auto_scaling_group_arn         = aws_autoscaling_group.ecs-puppet.arn
#    managed_termination_protection = "ENABLED"
#
#    managed_scaling {
#      maximum_scaling_step_size = 1
#      minimum_scaling_step_size = 1
#      status                    = "ENABLED"
#      target_capacity           = 100
#    }
#  }
#}
#
#resource "aws_ecs_cluster_capacity_providers" "puppet" {
#  cluster_name = aws_ecs_cluster.puppet.name
#
#  capacity_providers = [aws_ecs_capacity_provider.puppet.name]
#
#  default_capacity_provider_strategy {
#    base              = 1
#    weight            = 100
#    capacity_provider = aws_ecs_capacity_provider.puppet.name
#  }
#}
#
####
## Service discovery
####
#resource "aws_service_discovery_private_dns_namespace" "puppet" {
#  name        = local.app_name
#  description = local.app_name
#  vpc         = aws_vpc.main.id
#}
#
#resource "aws_service_discovery_service" "postgres" {
#  name = "postgres"
#
#  dns_config {
#    namespace_id = aws_service_discovery_private_dns_namespace.puppet.id
#
#    dns_records {
#      ttl  = 10
#      type = "A"
#    }
#
#    routing_policy = "MULTIVALUE"
#  }
#}
#
#resource "aws_service_discovery_service" "puppetdb" {
#  name = "puppetdb"
#
#  dns_config {
#    namespace_id = aws_service_discovery_private_dns_namespace.puppet.id
#
#    dns_records {
#      ttl  = 10
#      type = "A"
#    }
#
#    routing_policy = "MULTIVALUE"
#  }
#}
#resource "aws_service_discovery_service" "puppetserver" {
#  name = "puppetserver"
#
#  dns_config {
#    namespace_id = aws_service_discovery_private_dns_namespace.puppet.id
#
#    dns_records {
#      ttl  = 10
#      type = "A"
#    }
#
#    routing_policy = "MULTIVALUE"
#  }
#}
#
#resource "aws_service_discovery_service" "puppetcompile" {
#  name = "puppetcompile"
#
#  dns_config {
#    namespace_id = aws_service_discovery_private_dns_namespace.puppet.id
#
#    dns_records {
#      ttl  = 10
#      type = "A"
#    }
#
#    routing_policy = "MULTIVALUE"
#  }
#}
#
##resource "aws_service_discovery_service" "puppetboard" {
##  name = "puppetboard"
##
##  dns_config {
##    namespace_id = aws_service_discovery_private_dns_namespace.puppet.id
##
##    dns_records {
##      ttl  = 10
##      type = "A"
##    }
##
##    routing_policy = "MULTIVALUE"
##  }
##}
#
####
## ECS Task
####
#resource "aws_ecs_task_definition" "postgres" {
#  family                   = "postgres"
#  network_mode             = "awsvpc"
#  requires_compatibilities = ["EC2"]
#  cpu                      = 256
#  memory                   = 512
#  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
#
#  volume {
#    name = "test"
#    host_path = "/etc/rclone/mount"
#  }
#
#  container_definitions = jsonencode([
#    {
#      name  = "postgres"
#      image = "${aws_ecr_repository.postgres.repository_url}:12"
#      environment = [
#        {
#          "name" : "PGDATA",
#          "value" : "/var/lib/postgresql/data/pgdata"
#        },
#        {
#          "name" : "PGPORT",
#          "value" : "5432"
#        }
#      ],
#      secrets = [
#        {
#          "name" : "POSTGRES_USER",
#          "valueFrom" : "${aws_ssm_parameter.puppet_postgres_user.arn}"
#        },
#        {
#          "name" : "POSTGRES_PASSWORD",
#          "valueFrom" : "${aws_ssm_parameter.puppet_postgres_password.arn}"
#        },
#        {
#          "name" : "POSTGRES_DB",
#          "valueFrom" : "${aws_ssm_parameter.puppet_postgres_db.arn}"
#        }
#      ]
#      mountPoints = [
#        {
#          "sourceVolume": "test",
#          "containerPath": "/tmp/test"
#        }
#      ]
#      healthCheck = {
#        "command" : ["CMD-SHELL", "psql --username=$${POSTGRES_USER} -c ''"],
#        "interval" : 10,
#        "timeout" : 5,
#        "retries" : 5
#      }
#      portMappings = [{ containerPort : 5432 }]
#      logConfiguration = {
#        logDriver = "awslogs"
#        options = {
#          awslogs-region : "ap-northeast-1"
#          awslogs-group : aws_cloudwatch_log_group.puppet.name
#          awslogs-stream-prefix : "postgres"
#        }
#      }
#    }
#  ])
#}
#
#resource "aws_ecs_task_definition" "puppetdb" {
#  family                   = "puppetdb"
#  network_mode             = "awsvpc"
#  requires_compatibilities = ["EC2"]
#  cpu                      = 256
#  memory                   = 512
#  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
#  container_definitions = jsonencode([
#    {
#      name  = "puppetdb"
#      image = "${aws_ecr_repository.puppetdb.repository_url}:7.10.0"
#      environment = [
#        {
#          "name" : "PUPPETDB_POSTGRES_HOSTNAME",
#          "value" : "postgres.puppet"
#        },
#        {
#          "name" : "PUPPETSERVER_HOSTNAME",
#          "value" : "puppetserver.puppet"
#        },
#        {
#          "name" : "DNS_ALT_NAMES",
#          "value" : "puppetdb.puppet"
#        },
#        {
#          "name" : "PUPPETSERVER_PORT",
#          "value" : "8140"
#        },
#        {
#          "name" : "PUPPETDB_POSTGRES_PORT",
#          "value" : "5432"
#        }
#      ],
#      secrets = [
#        {
#          "name" : "PUPPETDB_USER",
#          "valueFrom" : "${aws_ssm_parameter.puppet_postgres_user.arn}"
#        },
#        {
#          "name" : "PUPPETDB_PASSWORD",
#          "valueFrom" : "${aws_ssm_parameter.puppet_postgres_password.arn}"
#        },
#        {
#          "name" : "PUPPETDB_POSTGRES_DATABASE",
#          "valueFrom" : "${aws_ssm_parameter.puppet_postgres_db.arn}"
#        }
#      ]
#      portMappings = [
#        { containerPort : 8080 },
#        { containerPort : 8081 }
#      ]
#      logConfiguration = {
#        logDriver = "awslogs"
#        options = {
#          awslogs-region : "ap-northeast-1"
#          awslogs-group : aws_cloudwatch_log_group.puppet.name
#          awslogs-stream-prefix : "puppetdb"
#        }
#      }
#    }
#  ])
#}
#
#resource "aws_ecs_task_definition" "puppetserver" {
#  family                   = "puppetserver"
#  network_mode             = "awsvpc"
#  requires_compatibilities = ["EC2"]
#  cpu                      = 512
#  memory                   = 1024
#  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
#
#  volume {
#    name = "puppetserver-ca"
#    host_path = "/etc/rclone/mount/puppetserver-ca"
#  }
#
#  volume {
#    name = "puppetserver-config"
#    host_path = "/etc/rclone/mount/puppetserver-config"
#  }
#
#
#  volume {
#    name = "puppetserver-data"
#    host_path = "/etc/rclone/mount/puppetserver-data"
#  }
#
#  volume {
#    name = "puppetserver-code"
#    host_path = "/etc/rclone/mount/puppetserver-code"
#  }
#
#  container_definitions = jsonencode([
#    {
#      name  = "puppetserver"
#      image = "${aws_ecr_repository.puppetserver.repository_url}:7.9.2"
#      environment = [
#        {
#          "name" : "PUPPETSERVER_HOSTNAME",
#          "value" : "puppetserver.puppet"
#        },
#        {
#          "name" : "DNS_ALT_NAMES",
#          "value" : "puppetserver.puppet"
#        },
#        {
#          "name" : "PUPPET_MASTERPORT",
#          "value" : "8140"
#        },
#        {
#          "name" : "CA_HOSTNAME",
#          "value" : "puppetserver.puppet"
#        },
#        {
#          "name" : "CA_MASTERPORT",
#          "value" : "8140"
#        },
#        {
#          "name" : "CA_ALLOW_SUBJECT_ALT_NAMES",
#          "value" : "true"
#        },
#        {
#          "name" : "PUPPETDB_SERVER_URLS",
#          "value" : "https://puppetdb.puppet:8081"
#        }
#      ]
#      mountPoints = [
#        {
#          "sourceVolume": "puppetserver-ca",
#          "containerPath": "/etc/puppetlabs/puppetserver/ca"
#        },
#        {
#          "sourceVolume": "puppetserver-config",
#          "containerPath": "/etc/puppetlabs/puppet"
#        },
#        {
#          "sourceVolume": "puppetserver-data",
#          "containerPath": "/opt/puppetlabs/server/data/puppetserver"
#        },
#        {
#          "sourceVolume": "puppetserver-code",
#          "containerPath": "/etc/puppetlabs/code/enviroments"
#        }
#      ]
#      portMappings = [{ containerPort : 8140 }]
#      logConfiguration = {
#        logDriver = "awslogs"
#        options = {
#          awslogs-region : "ap-northeast-1"
#          awslogs-group : aws_cloudwatch_log_group.puppet.name
#          awslogs-stream-prefix : "puppetserver"
#        }
#      }
#    }
#  ])
#}
#
#resource "aws_ecs_task_definition" "puppetcompile1" {
#  family                   = "puppetcompile1"
#  network_mode             = "awsvpc"
#  requires_compatibilities = ["EC2"]
#  cpu                      = 512
#  memory                   = 1024
#  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
#
#  container_definitions = jsonencode([
#    {
#      name  = "puppetcompile"
#      image = "${aws_ecr_repository.puppetserver.repository_url}:7.9.2"
#      environment = [
#        {
#          "name" : "PUPPETSERVER_HOSTNAME",
#          "value" : "puppetcompile.puppet"
#        },
#        {
#          "name" : "DNS_ALT_NAMES",
#          "value" : "puppetcompile.puppet"
#        },
#        {
#          "name" : "PUPPET_MASTERPORT",
#          "value" : "8140"
#        },
#        {
#          "name" : "CA_ENABLED",
#          "value" : "false"
#        },
#        {
#          "name" : "CA_HOSTNAME",
#          "value" : "puppetserver.puppet"
#        },
#        {
#          "name" : "CA_MASTERPORT",
#          "value" : "8140"
#        },
#        {
#          "name" : "PUPPETDB_SERVER_URLS",
#          "value" : "https://puppetdb.puppet:8081"
#        }
#      ]
#      portMappings = [{ containerPort : 8140 }]
#      logConfiguration = {
#        logDriver = "awslogs"
#        options = {
#          awslogs-region : "ap-northeast-1"
#          awslogs-group : aws_cloudwatch_log_group.puppet.name
#          awslogs-stream-prefix : "puppetcompile1"
#        }
#      }
#    }
#  ])
#}
#
#resource "aws_ecs_task_definition" "puppetcompile2" {
#  family                   = "puppetcompile2"
#  network_mode             = "awsvpc"
#  requires_compatibilities = ["EC2"]
#  cpu                      = 512
#  memory                   = 1024
#  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
#
#  container_definitions = jsonencode([
#    {
#      name  = "puppetcompile"
#      image = "${aws_ecr_repository.puppetserver.repository_url}:7.9.2"
#      environment = [
#        {
#          "name" : "PUPPETSERVER_HOSTNAME",
#          "value" : "puppetcompile.puppet"
#        },
#        {
#          "name" : "DNS_ALT_NAMES",
#          "value" : "puppetcompile.puppet"
#        },
#        {
#          "name" : "PUPPET_MASTERPORT",
#          "value" : "8140"
#        },
#        {
#          "name" : "CA_ENABLED",
#          "value" : "false"
#        },
#        {
#          "name" : "CA_HOSTNAME",
#          "value" : "puppetserver.puppet"
#        },
#        {
#          "name" : "CA_MASTERPORT",
#          "value" : "8140"
#        },
#        {
#          "name" : "PUPPETDB_SERVER_URLS",
#          "value" : "https://puppetdb.puppet:8081"
#        }
#      ]
#      portMappings = [{ containerPort : 8140 }]
#      logConfiguration = {
#        logDriver = "awslogs"
#        options = {
#          awslogs-region : "ap-northeast-1"
#          awslogs-group : aws_cloudwatch_log_group.puppet.name
#          awslogs-stream-prefix : "puppetcompile2"
#        }
#      }
#    }
#  ])
#}
#
##resource "aws_ecs_task_definition" "puppetboard" {
##  family                   = "puppetboard"
##  network_mode             = "awsvpc"
##  requires_compatibilities = ["EC2"]
##  cpu                      = 256
##  memory                   = 512
##  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
##  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
##  container_definitions = jsonencode([
##    {
##      name  = "puppetboard"
##      image = "${aws_ecr_repository.puppetboard.repository_url}:4.2.1"
##      environment = [
##        {
##          "name" : "PUPPETDB_HOST",
##          "value" : "puppetdb.puppet"
##        },
##        {
##          "name" : "PUPPETDB_PORT",
##          "value" : "8080"
##        },
##        {
##          "name" : "PUPPETBOARD_PORT",
##          "value" : "9090"
##        }
##      ]
##      portMappings = [
##        { containerPort : 9090 }
##      ]
##      logConfiguration = {
##        logDriver = "awslogs"
##        options = {
##          awslogs-region : "ap-northeast-1"
##          awslogs-group : aws_cloudwatch_log_group.puppet.name
##          awslogs-stream-prefix : "puppetdb"
##        }
##      }
##    }
##  ])
##}
#
####
## ECS Cluster Service
####
#resource "aws_ecs_service" "postgres" {
#  name                               = "postgres"
#  cluster                            = aws_ecs_cluster.puppet.id
#  task_definition                    = aws_ecs_task_definition.postgres.arn
#  desired_count                      = 1
#  deployment_minimum_healthy_percent = 100
#  deployment_maximum_percent         = 200
#  propagate_tags                    = "NONE"
#  enable_execute_command             = true
#  launch_type                       = "EC2"
#
#  deployment_controller {
#    type = "ECS"
#  }
#
#  deployment_circuit_breaker {
#    enable   = true
#    rollback = true
#  }
#
#  network_configuration {
#    subnets = [
#      for subnet in aws_subnet.private :
#      subnet.id
#    ]
#    security_groups = [
#      aws_security_group.postgres.id,
#    ]
#  }
#
#  service_registries {
#    registry_arn = aws_service_discovery_service.postgres.arn
#  }
#
#  tags = {
#    Name = "postgres"
#  }
#}
#
#resource "aws_ecs_service" "puppetdb" {
#  name                               = "puppetdb"
#  cluster                            = aws_ecs_cluster.puppet.id
#  task_definition                    = aws_ecs_task_definition.puppetdb.arn
#  desired_count                      = 1
#  deployment_minimum_healthy_percent = 100
#  deployment_maximum_percent         = 200
#  propagate_tags                    = "NONE"
#  enable_execute_command             = true
#  launch_type                       = "EC2"
#
#  deployment_controller {
#    type = "ECS"
#  }
#
#  deployment_circuit_breaker {
#    enable   = true
#    rollback = true
#  }
#
#  network_configuration {
#    subnets = [
#      for subnet in aws_subnet.private :
#      subnet.id
#    ]
#    security_groups = [
#      aws_security_group.puppetdb.id,
#    ]
#  }
#
#  service_registries {
#    registry_arn = aws_service_discovery_service.puppetdb.arn
#  }
#
#  tags = {
#    Name = "postgres"
#  }
#}
#
#resource "aws_ecs_service" "puppetserver" {
#  name                               = "puppetserver"
#  cluster                            = aws_ecs_cluster.puppet.id
#  task_definition                    = aws_ecs_task_definition.puppetserver.arn
#  desired_count                      = 1
#  deployment_minimum_healthy_percent = 100
#  deployment_maximum_percent         = 200
#  propagate_tags                    = "NONE"
#  enable_execute_command             = true
#  launch_type                       = "EC2"
#
#  deployment_controller {
#    type = "ECS"
#  }
#
#  deployment_circuit_breaker {
#    enable   = true
#    rollback = true
#  }
#
#  network_configuration {
#    subnets = [
#      for subnet in aws_subnet.private :
#      subnet.id
#    ]
#    security_groups = [
#      aws_security_group.puppetserver.id,
#    ]
#  }
#
#  service_registries {
#    registry_arn = aws_service_discovery_service.puppetserver.arn
#  }
#
#  tags = {
#    Name = "puppetserver"
#  }
#}
#
#resource "aws_ecs_service" "puppetcompile1" {
#  name                               = "puppetcompile1"
#  cluster                            = aws_ecs_cluster.puppet.id
#  task_definition                    = aws_ecs_task_definition.puppetcompile1.arn
#  desired_count                      = 1
#  deployment_minimum_healthy_percent = 100
#  deployment_maximum_percent         = 200
#  propagate_tags                    = "NONE"
#  enable_execute_command             = true
#  launch_type                       = "EC2"
#
#  deployment_controller {
#    type = "ECS"
#  }
#
#  deployment_circuit_breaker {
#    enable   = true
#    rollback = true
#  }
#
#  network_configuration {
#    subnets = [
#      for subnet in aws_subnet.private :
#      subnet.id
#    ]
#    security_groups = [
#      aws_security_group.puppetserver.id,
#    ]
#  }
#
#  service_registries {
#    registry_arn = aws_service_discovery_service.puppetcompile.arn
#  }
#
#  tags = {
#    Name = "puppetcompile1"
#  }
#}
#
#resource "aws_ecs_service" "puppetcompile2" {
#  name                               = "puppetcompile2"
#  cluster                            = aws_ecs_cluster.puppet.id
#  task_definition                    = aws_ecs_task_definition.puppetcompile2.arn
#  desired_count                      = 1
#  deployment_minimum_healthy_percent = 100
#  deployment_maximum_percent         = 200
#  propagate_tags                    = "NONE"
#  enable_execute_command             = true
#  launch_type                       = "EC2"
#
#  deployment_controller {
#    type = "ECS"
#  }
#
#  deployment_circuit_breaker {
#    enable   = true
#    rollback = true
#  }
#
#  network_configuration {
#    subnets = [
#      for subnet in aws_subnet.private :
#      subnet.id
#    ]
#    security_groups = [
#      aws_security_group.puppetserver.id,
#    ]
#  }
#
#  service_registries {
#    registry_arn = aws_service_discovery_service.puppetcompile.arn
#  }
#
#  tags = {
#    Name = "puppetcompile2"
#  }
#}
#resource "aws_ecs_service" "puppetboard" {
#  name                               = "puppetboard"
#  cluster                            = aws_ecs_cluster.puppet.id
#  task_definition                    = aws_ecs_task_definition.puppetboard.arn
#  desired_count                      = 1
#  deployment_minimum_healthy_percent = 100
#  deployment_maximum_percent         = 200
#  propagate_tags                    = "NONE"
#  enable_execute_command             = true
#  launch_type                       = "EC2"
#  deployment_controller {
#    type = "ECS"
#  }
#
#  deployment_circuit_breaker {
#    enable   = true
#    rollback = true
#  }
#
#  network_configuration {
#    subnets = [
#      for subnet in aws_subnet.private :
#      subnet.id
#    ]
#    security_groups = [
#      aws_security_group.puppetboard.id,
#    ]
#  }
#
#  service_registries {
#    registry_arn = aws_service_discovery_service.puppetboard.arn
#  }
#
#  tags = {
#    Name = "puppetboard"
#  }
#}
##
# ALB
##
#resource "aws_eip" "puppetboard" {
#  tags = {
#    Name = "puppetboard"
#  }
#}
#
#resource "aws_lb" "puppetboard" {
#  name                       = "puppetboard"
#  subnets                    = [for subnet in aws_subnet.public : subnet.id]
#  internal                   = false
#  load_balancer_type         = "network"
#  ip_address_type            = "ipv4"
#  enable_deletion_protection = false
#}
#
#resource "aws_lb_listener" "puppetboard" {
#  load_balancer_arn = aws_lb.puppetboard.arn
#  port              = "9090"
#  protocol          = "TCP"
#
#  default_action {
#    target_group_arn = aws_lb_target_group.puppetboard.arn
#    type             = "forward"
#  }
#}
#
#resource "aws_lb_target_group" "puppetboard" {
#  target_type          = "ip"
#  name                 = "puppetboard"
#  port                 = 9090
#  protocol             = "TCP"
#  vpc_id               = aws_vpc.main.id
#  deregistration_delay = 180
#
#  health_check {
#    interval            = 30
#    port                = "traffic-port"
#    protocol            = "TCP"
#    healthy_threshold   = 3
#    unhealthy_threshold = 3
#  }
#}

###
# ALB
###
#resource "aws_acm_certificate" "cert" {
#  domain_name               = "*.puppetboard.com"
#  subject_alternative_names = ["puppetboard.com"]
#  validation_method         = "DNS"
#  lifecycle {
#    create_before_destroy = true
#  }
#}
#
## サブドメイン(auth.hoge.com)の証明書発行
#resource "aws_acm_certificate" "cert_sub" {
#  domain_name       = "auth.puppetboard.com"
#  validation_method = "DNS"
#  #provider          = aws.virginia
#  lifecycle {
#    create_before_destroy = true
#  }
#}
#
#resource "aws_cognito_user_pool" "main" {
#  name = "puppetboard-auth"
#
#  # パスワード認証だけで良いなら OFFにする
#  mfa_configuration = "ON"
#  software_token_mfa_configuration {
#    enabled = true
#  }
#
#  account_recovery_setting {
#    recovery_mechanism {
#      name     = "verified_phone_number"
#      priority = 1
#    }
#  }
#
#  admin_create_user_config {
#    allow_admin_create_user_only = true
#    invite_message_template {
#      email_message = "{username}さん、あなたの初期パスワードは {####} です。初回ログインの後パスワード変更が必要です。"
#      email_subject = "puppetへの招待"
#      sms_message   = "{username}さん、あなたの初期パスワードは {####} です。初回ログインの後パスワード変更が必要です。"
#    }
#  }
#
#  # ユーザー名の他にemailでの認証を許可
#  alias_attributes = ["email"]
#}
#
#resource "aws_cognito_user_pool_domain" "main" {
#  domain          = "auth.puppetboard.com"
#  certificate_arn = aws_acm_certificate.cert_sub.arn
#  user_pool_id    = aws_cognito_user_pool.main.id
#}
#
#resource "aws_cognito_user_pool_client" "main" {
#  name            = "puppetboard-client"
#  user_pool_id    = aws_cognito_user_pool.main.id
#  generate_secret = true
#  # CallBackUrlにALBのドメイン + oauth2/idpresponseの付与が必要
#  callback_urls = [
#    "https://puppetboard/oauth2/idpresponse"
#  ]
#  allowed_oauth_flows = ["code"]
#  explicit_auth_flows = [
#    "ALLOW_REFRESH_TOKEN_AUTH",
#    "ALLOW_USER_PASSWORD_AUTH",
#  ]
#  supported_identity_providers = [
#    "COGNITO"
#  ]
#  allowed_oauth_scopes                 = ["openid"]
#  allowed_oauth_flows_user_pool_client = true
#}
