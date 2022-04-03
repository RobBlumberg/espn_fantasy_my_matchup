data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# ECR Repo & Image

resource "aws_ecr_repository" "repository" {
  name                 = var.task_name
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "ecr_image" {
  depends_on = [
    aws_ecr_repository.repository
  ]

  triggers = {
    image_version = var.image_version
  }

  provisioner "local-exec" {
    command = <<EOF
      cd ..
      make push_image
    EOF
  }
}

data "aws_ecr_image" "fargate_image" {
  depends_on = [
    null_resource.ecr_image
  ]
  repository_name = aws_ecr_repository.repository.name
  image_tag       = var.image_version
}

# ECS Task Resources

resource "aws_cloudwatch_log_group" "this" {
  name = format("%s-log-group", var.task_name)
}

resource "aws_iam_role" "task" {
  name = format("%s-task-role", var.task_name)

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
  name = format("%s-role-policy", var.task_name)
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
  name = format("%s-execution-role", var.task_name)

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
  name = format("%s-execution-role-policy", var.task_name)
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
      }
    ]
  })
}

resource "aws_ecs_task_definition" "this" {
  depends_on = [
    null_resource.ecr_image
  ]

  family                   = var.task_name
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"

  container_definitions = jsonencode([
    {
      name        = var.task_name
      image       = "${aws_ecr_repository.repository.repository_url}@${data.aws_ecr_image.fargate_image.id}"
      networkMode = "awsvpc"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.task_name
        }
      }
      environment = [
        for key in keys(var.environment_vars) :
        {
          name  = key,
          value = lookup(var.environment_vars, key)
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
  count = var.schedule != null ? 1 : 0
  name  = format("%s-cw-sch-role", var.task_name)

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
  count = var.schedule != null ? 1 : 0
  name  = format("%s-cw-sch-role-policy", var.task_name)
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
  count               = var.schedule != null ? 1 : 0
  name                = format("%s-cw-sch", var.task_name)
  description         = format("Cloudwatch event schedule for Fargate task %s", var.task_name)
  schedule_expression = var.schedule
}

resource "aws_cloudwatch_event_target" "cloudwatch_schedule" {
  count    = var.schedule != null ? 1 : 0
  rule     = aws_cloudwatch_event_rule.cloudwatch_schedule[count.index].name
  arn      = var.cluster_arn
  role_arn = aws_iam_role.cloudwatch_schedule[count.index].arn

  ecs_target {
    task_count          = 1
    launch_type         = "FARGATE"
    task_definition_arn = aws_ecs_task_definition.this.arn
    network_configuration {
      security_groups = [var.security_group_id]
      subnets         = var.subnet_ids
    }
  }
}