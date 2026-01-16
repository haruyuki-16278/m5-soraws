############################################################
#       provider
############################################################
provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket = "m5-soraws-20260117"
    region = "ap-northeast-1"
    encrypt = false
  }
}

############################################################
#       変数宣言
############################################################
# terraform.tfvars で設定済みの値
variable "prefix" {}

############################################################
#       module読み込み
############################################################
module "dynamodb" {
  source = "./modules/dynamodb"
  prefix = var.prefix
}

module "iot" {
  source = "./modules/iot"
  prefix = var.prefix
  dynamodb_data_table_arn = module.dynamodb.dynamodb_data_table.arn
  dynamodb_data_table_name = module.dynamodb.dynamodb_data_table.name
}
output "iot_pubsub_policy_name" {
  value = module.iot.iot_pubsub_policy_name
}