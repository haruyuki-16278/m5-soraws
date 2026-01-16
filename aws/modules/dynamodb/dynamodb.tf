variable "prefix" {}

############################################################
#       DynamoDB - data table
############################################################
resource "aws_dynamodb_table" "m5_soraws_data" {
  name           = "${var.prefix}-iot-data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "device_id"
  range_key      = "timestamp"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }
}

output "dynamodb_data_table" {
  value = aws_dynamodb_table.m5_soraws_data
}