# 読込時に渡される変数
variable "prefix" {}
variable "dynamodb_data_table_arn" {}
variable "dynamodb_data_table_name" {}

############################################################
#       IAM Role - IoT Rule
############################################################
resource "aws_iam_role" "iot_rule_role" {
  name = "${var.prefix}-iot-rule-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_rule_dynamodb" {
  name = "${var.prefix}-iot-dynamodb-policy"
  role = aws_iam_role.iot_rule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = var.dynamodb_data_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_rule_cloudwatch" {
  name = "${var.prefix}-iot-cloudwatch-policy"
  role = aws_iam_role.iot_rule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.iot_errors.arn}:*"
      }
    ]
  })
}

############################################################
#       CloudWatch Log Group（エラーログ用）
############################################################
resource "aws_cloudwatch_log_group" "iot_errors" {
  name              = "/aws/iot/${var.prefix}/errors"
  retention_in_days = 14
}

############################################################
#       IoT Rule
############################################################
resource "aws_iot_topic_rule" "save_to_dynamodb" {
  name        = "${replace(var.prefix, "-", "_")}_save_to_dynamodb"
  description = "IoTデータをDynamoDBに保存"
  enabled     = true
  sql         = "SELECT * FROM 'devices/+/data'"
  sql_version = "2016-03-23"

  dynamodbv2 {
    role_arn = aws_iam_role.iot_rule_role.arn
    put_item {
      table_name = var.dynamodb_data_table_name
    }
  }

  error_action {
    cloudwatch_logs {
      log_group_name = aws_cloudwatch_log_group.iot_errors.name
      role_arn       = aws_iam_role.iot_rule_role.arn
    }
  }
}

############################################################
#       IoT Policy
############################################################
resource "aws_iot_policy" "pubsub" {
  name = "${var.prefix}_pubsub_anytopic"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iot:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

output "iot_pubsub_policy_name" {
  value = aws_iot_policy.pubsub.name
}
