### METAFLOW INFRA ###

# Create VPC with 3 private/public subnets into which services will de deployed
# and enable NAT gateway for internet connectivity
module "vpc" {

  source = "terraform-aws-modules/vpc/aws"

  name = "metaflow"
  cidr = "10.100.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
  public_subnets  = ["10.100.101.0/24", "10.100.102.0/24", "10.100.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

}

module "metaflow-computation" {
  source = "github.com/outerbounds/terraform-aws-metaflow/modules/computation"

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  batch_type                              = "ec2"
  compute_environment_desired_vcpus       = var.compute_environment_desired_vcpus
  compute_environment_instance_types      = var.compute_environment_instance_types
  compute_environment_max_vcpus           = var.compute_environment_max_vcpus
  compute_environment_min_vcpus           = var.compute_environment_min_vcpus
  enable_step_functions                   = var.enable_step_functions
  iam_partition                           = "aws"
  metaflow_step_functions_dynamodb_policy = ""
  subnet1_id                              = element(module.vpc.private_subnets, 0)
  subnet2_id                              = element(module.vpc.private_subnets, 1)
  metaflow_vpc_id                         = module.vpc.vpc_id

  standard_tags = {
    Terraformed = true
  }
}

module "metaflow-metadata-service" {
  source = "github.com/outerbounds/terraform-aws-metaflow/modules/metadata-service"

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  # access_list_cidr_blocks          = var.access_list_cidr_blocks
  access_list_cidr_blocks          = ["76.64.94.2/32", "54.213.30.138/32"]
  database_password                = module.metaflow-datastore.database_password
  database_username                = module.metaflow-datastore.database_username
  datastore_s3_bucket_kms_key_arn  = module.metaflow-datastore.datastore_s3_bucket_kms_key_arn
  fargate_execution_role_arn       = module.metaflow-computation.ecs_execution_role_arn
  iam_partition                    = var.iam_partition
  metadata_service_container_image = local.metadata_service_container_image
  metaflow_vpc_id                  = module.vpc.vpc_id
  rds_master_instance_endpoint     = module.metaflow-datastore.rds_master_instance_endpoint
  s3_bucket_arn                    = module.metaflow-datastore.s3_bucket_arn
  subnet1_id                       = element(module.vpc.private_subnets, 0)
  subnet2_id                       = element(module.vpc.private_subnets, 1)
  vpc_cidr_block                   = module.vpc.vpc_cidr_block

  standard_tags = {
    Terraformed = true
  }
}

module "metaflow-datastore" {
  source = "github.com/outerbounds/terraform-aws-metaflow/modules/datastore"

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  ecs_execution_role_arn             = module.metaflow-computation.ecs_execution_role_arn
  ecs_instance_role_arn              = module.metaflow-computation.ecs_instance_role_arn
  metadata_service_security_group_id = module.metaflow-metadata-service.metadata_service_security_group_id
  subnet1_id                         = element(module.vpc.private_subnets, 0)
  subnet2_id                         = element(module.vpc.private_subnets, 1)
  metaflow_vpc_id                    = module.vpc.vpc_id

  standard_tags = {
    Terraformed = true
  }
}

### ECR LAMBDA FUNCTION ###

locals {
  metaflow_bucket_policy_statement = {
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
  }
}

# get league secrets from secret manager
data "aws_secretsmanager_secret_version" "league_creds" {
  secret_id = "arn:aws:secretsmanager:us-west-2:978072805127:secret:espn-fantasy-league-creds-IKFhtX"
}

# set up ECR repo for fantasy image
resource "aws_ecr_repository" "repository" {
  name                 = "espn_my_matchup"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

# dummy resource to push image to ECR from local command
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

# grab image for lambda function
data "aws_ecr_image" "lambda_image" {
  depends_on = [
    null_resource.ecr_image
  ]
  repository_name = aws_ecr_repository.repository.name
  image_tag       = var.image_version
}

# create role for lambda function
resource "aws_iam_role" "lambda_role" {
  name               = "test_role"
  assume_role_policy = file("iam/lambda_assume_policy.json")
}

# create policy for lambda role
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_function_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ],
        "Resource" : "*"
      },
      local.metaflow_bucket_policy_statement
    ]
  })
}

module "vpc_espn" {

  source = "terraform-aws-modules/vpc/aws"

  name = "espn_vpc"
  cidr = "10.101.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.101.1.0/24", "10.101.2.0/24", "10.101.3.0/24"]
  public_subnets  = ["10.101.101.0/24", "10.101.102.0/24", "10.101.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

}

# resource "aws_internet_gateway" "gw" {
#   vpc_id = module.vpc_espn.vpc_id

#   tags = {
#     Name = "espn_igw"
#   }
# }

resource "aws_default_security_group" "default_security_group" {
  vpc_id = module.vpc_espn.vpc_id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "espn-default-security-group"
  }
}

# create lambda function
resource "aws_lambda_function" "espn_my_matchup" {
  function_name = "espn_my_matchup_function"
  role          = aws_iam_role.lambda_role.arn
  memory_size   = 1024
  timeout       = 300
  image_uri     = "${aws_ecr_repository.repository.repository_url}@${data.aws_ecr_image.lambda_image.id}"
  package_type  = "Image"
  environment {
    variables = {
      LEAGUE_ESPN_S2 = local.my_league_creds.LEAGUE_ESPN_S2
      LEAGUE_SWID    = local.my_league_creds.LEAGUE_SWID
      LEAGUE_YEAR    = local.my_league_creds.LEAGUE_YEAR
      LEAGUE_ID      = local.my_league_creds.LEAGUE_ID
    }
  }
  vpc_config {
    subnet_ids         = [element(module.vpc_espn.private_subnets, 0)]
    security_group_ids = [aws_default_security_group.default_security_group.id]
  }
}

#resource "aws_cloudwatch_event_rule" "cron_trigger" {
#  name                = "espn_my_matchup_function-trigger"
#  description         = "Triggers lambda every 2 minutes"
#  schedule_expression = "rate(2 minutes)"
#}

#resource "aws_cloudwatch_event_target" "cron_trigger" {
#  rule      = aws_cloudwatch_event_rule.cron_trigger.name
#  target_id = "espn_my_matchup_function"
#  arn       = aws_lambda_function.espn_my_matchup.arn
#  input = jsonencode({
#    "function_name": "espn"
#  })
#}

#resource "aws_lambda_permission" "cron_trigger" {
#  statement_id  = "AllowExecutionFromCloudWatch"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.espn_my_matchup.arn
#  principal     = "events.amazonaws.com"
#  source_arn    = aws_cloudwatch_event_rule.cron_trigger.arn
#}


