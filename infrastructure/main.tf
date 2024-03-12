provider "aws" {
    region = "us-west-2"  # 根据您的需求替换为特定的区域
}

terraform {
  backend "s3" {
    bucket  = "yolov5-state"  # 新的存储桶名称
    key     = "yolov5-tf-state.tfstate"  # 新的状态文件名称
    region  = "us-west-2"  # 根据您的需求替换为特定的区域
    encrypt = true
  }
}

# 首先创建 S3 存储桶及相关配置
resource "aws_s3_bucket" "yolov5_bucket" {
    bucket = "${var.project}-bucket"
}

# 注释掉 ACL 设置，让 S3 存储桶使用默认的 ACL 设置
# resource "aws_s3_bucket_acl" "yolov5_bucket_acl" {
#     bucket = aws_s3_bucket.yolov5_bucket.id
#     acl = "private"
# }

resource "aws_s3_bucket_versioning" "yolov5_bucket_versioning" {
    bucket = aws_s3_bucket.yolov5_bucket.id
    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_policy" "yolov5_bucket_policy" {
  bucket = aws_s3_bucket.yolov5_bucket.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Principal":"*",
            "Action":[
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "${aws_s3_bucket.yolov5_bucket.arn}/*"
        }
    ]
  })
}

# 然后创建 Lambda 函数及相关配置
resource "aws_iam_role" "yolov5_image_process_lambda_execution_role" {
    name = "${var.project}-image-process-lambda-execution-role"

    assume_role_policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          }
        }
      ]
    })
}

resource "aws_lambda_function" "yolov5_image_process_lambda" {
  function_name = "${var.project}-lambda-function"
  runtime = "python3.8"
  role = aws_iam_role.yolov5_image_process_lambda_execution_role.arn
  memory_size = 256
  timeout = 10
  # 请确保 filename 和 source_code_hash 为空字符串，以便稍后动态设置
  filename = ""
  source_code_hash = ""
}

# 创建 Lambda 函数的触发器（例如 S3 触发器）
resource "aws_lambda_function" "yolov5_image_process_lambda" {
  function_name = "${var.project}-lambda-function"
  runtime = "python3.8"
  handler = "handler"  # 设置入口点函数的名称
  role = aws_iam_role.yolov5_image_process_lambda_execution_role.arn
  memory_size = 256
  timeout = 10
  # 设置 filename 和 source_code_hash 为空字符串
  filename = ""
  source_code_hash = ""
}


# 创建 S3 存储桶的事件通知，以触发 Lambda 函数
resource "aws_s3_bucket_notification" "yolov5_bucket_notification" {
  bucket = aws_s3_bucket.yolov5_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.yolov5_image_process_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}
