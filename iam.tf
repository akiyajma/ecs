###
# ECS for AMI
###
resource "aws_iam_policy" "ecs_s3_policy" {
  name = "ecs_s3_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListAllMyBuckets"
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${aws_s3_bucket.ecs-puppet.id}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::${aws_s3_bucket.ecs-puppet.id}/*"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs_instance_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    aws_iam_policy.ecs_s3_policy.arn
  ]
}

resource "aws_iam_instance_profile" "ecs_puppet" {
  name = "ecs_puppet_instance_profile"
  role = aws_iam_role.ecs_instance_role.name
}

###
# ECS for Exec
###
resource "aws_iam_policy" "ecs_ssm_policy" {
  name = "ecs_exec_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_ssm_parameter_policy" {
  name = "ecs_task_execution_role_policy_kms"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : [
          aws_ssm_parameter.puppet_postgres_user.arn,
          aws_ssm_parameter.puppet_postgres_password.arn,
          aws_ssm_parameter.puppet_postgres_db.arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    aws_iam_policy.ecs_ssm_policy.arn,
    aws_iam_policy.ecs_ssm_parameter_policy.arn,
  ]
}
