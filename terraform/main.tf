locals {
  my_league_creds = jsondecode(data.aws_secretsmanager_secret_version.league_creds.secret_string)
}

data "aws_secretsmanager_secret_version" "league_creds" {
    secret_id = "arn:aws:secretsmanager:us-west-2:978072805127:secret:espn-fantasy-league-creds-IKFhtX"
}

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

data "aws_ecr_image" "lambda_image" {
  depends_on = [
    null_resource.ecr_image
  ]
  repository_name = aws_ecr_repository.repository.name
  image_tag       = var.image_version
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_function_policy"
  role = aws_iam_role.lambda_role.id
  policy = "${file("iam/lambda_function_policy.json")}"
}

resource "aws_iam_role" "lambda_role" {
  name = "test_role"
  assume_role_policy = "${file("iam/lambda_assume_policy.json")}"
}

resource "aws_lambda_function" "espn_my_matchup" {
  function_name          = "espn_my_matchup_function"
  role                   = aws_iam_role.lambda_role.arn
  memory_size            = 1024
  timeout                = 60
  image_uri              = "${aws_ecr_repository.repository.repository_url}@${data.aws_ecr_image.lambda_image.id}"
  package_type           = "Image"
  environment {
    variables = {
      LEAGUE_ESPN_S2 = local.my_league_creds.LEAGUE_ESPN_S2
      LEAGUE_SWID    = local.my_league_creds.LEAGUE_SWID
      LEAGUE_YEAR    = local.my_league_creds.LEAGUE_YEAR
      LEAGUE_ID      = local.my_league_creds.LEAGUE_ID
    }
  }
}