provider "aws" {
    region = var.region
}

terraform {
  backend "s3" {
    bucket  = "${var.project}-state"  # 新的存储桶名称
    key     = "${var.project}-tf-state.tfstate"  # 新的状态文件名称
    region  = var.region
    encrypt = true
  }
}

module "s3_module" {
  source = "./s3.tf"
  
}

module "lambda_module" {
  source = "./lambda.tf"
  
}
