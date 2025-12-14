# Конфігурація провайдера
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- 1. IAM Ролі ---

# 1.1. IAM Роль для AWS Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Політика дозволів для Lambda (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 1.2. IAM Роль для Step Function (State Machine)
resource "aws_iam_role" "sfn_exec_role" {
  name = "${var.project_name}-sfn-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# --- 2. CloudWatch Log Group для Step Function ---
# Рекомендований префікс /aws/vendedlogs/states/ для Step Functions
resource "aws_cloudwatch_log_group" "sfn_log_group" {
  name              = "/aws/vendedlogs/states/${var.project_name}-training-pipeline"
  retention_in_days = 7
}

# Політика дозволів для Step Function:
# - invoke Lambda
# - CloudWatch Logs delivery permissions (щоб роль могла писати в log_destination)
resource "aws_iam_policy" "sfn_lambda_invoke_policy" {
  name        = "${var.project_name}-sfn-lambda-invoke-policy"
  description = "Allow Step Function to invoke Lambdas and deliver logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Виклик Lambda (для спрощення - все)
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = "*"
      },

      # ✅ Права, потрібні Step Functions для CloudWatch Logs log delivery
      # Важливо: ці CloudWatch Logs API не підтримують resource-level permissions,
      # тому Resource має бути "*"
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_policy_attach" {
  role       = aws_iam_role.sfn_exec_role.name
  policy_arn = aws_iam_policy.sfn_lambda_invoke_policy.arn
}

# --- 3. AWS Lambda Функції ---

resource "aws_lambda_function" "validate" {
  function_name    = "${var.project_name}-validate"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "validate.lambda_handler"
  runtime          = "python3.11"
  filename         = "lambda/validate.zip"
  source_code_hash = filebase64sha256("lambda/validate.zip")
  timeout          = 30
}

resource "aws_lambda_function" "log_metrics" {
  function_name    = "${var.project_name}-log-metrics"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "log_metrics.lambda_handler"
  runtime          = "python3.11"
  filename         = "lambda/log_metrics.zip"
  source_code_hash = filebase64sha256("lambda/log_metrics.zip")
  timeout          = 30
}

# --- 4. AWS Step Function (State Machine) ---

locals {
  sfn_definition = jsonencode({
    Comment = "MLOps Training Automation Pipeline",
    StartAt = "ValidateData",
    States = {
      ValidateData = {
        Type     = "Task",
        Resource = aws_lambda_function.validate.arn,
        Next     = "LogMetrics"
      },
      LogMetrics = {
        Type     = "Task",
        Resource = aws_lambda_function.log_metrics.arn,
        End      = true
      }
    }
  })
}

resource "aws_sfn_state_machine" "training_pipeline" {
  name       = "${var.project_name}-training-pipeline"
  role_arn   = aws_iam_role.sfn_exec_role.arn
  definition = local.sfn_definition

  logging_configuration {
    level                  = "ALL"
    include_execution_data = true

    # ✅ правильний формат: "<log-group-arn>:*"
    log_destination = "${aws_cloudwatch_log_group.sfn_log_group.arn}:*"
  }
}
