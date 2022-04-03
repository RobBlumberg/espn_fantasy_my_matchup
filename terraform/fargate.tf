locals {
  app_name  = "espn-my-matchup"
  task_name = "espn-my-matchup-task"
  schedule = "rate(2 minutes)"
}

resource "aws_ecs_cluster" "this" {
  name = "espn-fantasy-cluster"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# ECS Task Resources

resource "aws_cloudwatch_log_group" "this" {
  name = format("%s-log-group", local.task_name)
}

resource "aws_iam_role" "task" {
  name = format("%s-task-role", local.task_name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "task" {
  name = format("%s-role-policy", local.task_name)
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Effect = "Allow",
            Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ],
            Resource = "*"
        },
        {
            Effect = "Allow",
            Action = [
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketVersions",
            "s3:GetObjectVersion",
            "s3:GetObjectTagging",
            "s3:GetObjectVersionTagging",
            "s3:PutObject"
            ],
            Resource = [
            module.metaflow-datastore.s3_bucket_arn,
            "${module.metaflow-datastore.s3_bucket_arn}/*"
            ]
        },
        {
            "Sid": "ExampleStmt",
            "Action": "*",
            "Effect": "Allow",
            "Resource": [
                "arn:aws:kms:us-west-2:978072805127:key/a5bed68d-a77b-466c-be22-ea4e6faf84db",
                "arn:aws:kms:us-west-2:978072805127:key/d180762c-1b60-4eca-ad23-9a088f9e741c"
            ]
        }
    ]
  })
}

resource "aws_iam_role" "execution" {
  name = format("%s-execution-role", local.task_name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "execution" {
  name = format("%s-execution-role-policy", local.task_name)
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
        Resource = ["*"]
      },
      {
        Sid      = "ExampleStmt",
        Effect   = "Allow",
        Action   = "*",
        Resource = [
          "arn:aws:kms:us-west-2:978072805127:key/a5bed68d-a77b-466c-be22-ea4e6faf84db",
          "arn:aws:kms:us-west-2:978072805127:key/d180762c-1b60-4eca-ad23-9a088f9e741c",
        ]
      },
    ]
  })
}

resource "aws_ecs_task_definition" "this" {
  depends_on = [
    null_resource.ecr_image
  ]

  family                   = local.task_name
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  requires_compatibilities = ["FARGATE"]
  cpu                 = 1024
  memory              = 8192
  network_mode             = "awsvpc"

  container_definitions = jsonencode([
    {
      name        = local.task_name
      image       = "${aws_ecr_repository.repository.repository_url}@${data.aws_ecr_image.lambda_image.id}"
      networkMode = "awsvpc"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = "us-west-2"
          awslogs-stream-prefix = local.task_name
        }
      }
      environment = [
        {
          name  = "LEAGUE_ESPN_S2",
          value = local.my_league_creds.LEAGUE_ESPN_S2
        },
        {
          name  = "LEAGUE_SWID",
          value = local.my_league_creds.LEAGUE_SWID
        },
        {
          name  = "LEAGUE_YEAR",
          value = local.my_league_creds.LEAGUE_YEAR
        },
        {
          name  = "LEAGUE_ID",
          value = local.my_league_creds.LEAGUE_ID
        }
      ]
    }
  ])

  lifecycle {
    create_before_destroy = true
  }
}

# Cloudwatch Event Scheduling Resources
resource "aws_iam_role" "cloudwatch_schedule" {
  count = local.schedule != null ? 1 : 0
  name  = format("%s-cw-sch-role", local.task_name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_schedule" {
  count = local.schedule != null ? 1 : 0
  name  = format("%s-cw-sch-role-policy", local.task_name)
  role  = aws_iam_role.cloudwatch_schedule[count.index].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["ecs:RunTask"],
        Resource = [aws_ecs_task_definition.this.arn],
        Effect   = "Allow"
      },
      {
        Action   = ["iam:PassRole"]
        Resource = [aws_iam_role.task.arn, aws_iam_role.execution.arn]
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "cloudwatch_schedule" {
  count               = local.schedule != null ? 1 : 0
  name                = format("%s-cw-sch", local.task_name)
  description         = format("Cloudwatch event schedule for Fargate task %s", local.task_name)
  schedule_expression = local.schedule
}

resource "aws_cloudwatch_event_target" "cloudwatch_schedule" {
  count    = local.schedule != null ? 1 : 0
  rule     = aws_cloudwatch_event_rule.cloudwatch_schedule[count.index].name
  arn      = aws_ecs_cluster.this.arn
  role_arn = aws_iam_role.cloudwatch_schedule[count.index].arn

  ecs_target {
    task_count          = 1
    launch_type         = "FARGATE"
    task_definition_arn = aws_ecs_task_definition.this.arn
    network_configuration {
      security_groups = [aws_default_security_group.default_security_group.id]
      subnets         = [element(module.vpc_espn.private_subnets, 0)]
    }
  }
}