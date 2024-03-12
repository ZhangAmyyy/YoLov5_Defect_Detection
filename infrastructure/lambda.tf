resource "aws_iam_role" "yolov5_image_process_lambda_execution_role" {
    name = "${var.project}-image-process-lambda-execution-role"

    assume_role_policy = jsondecode({
        "Version" ="2012-10-17",
        Statement = [{
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        }]
    })
  
}

resource "aws_lambda_function" "yolov5_image_process_lambda" {
  function_name = "${var.project}-lambda-function"
  runtime = "python3.8"
  handler="index.handler"
  role = aws_iam_role.yolov5_image_process_lambda_execution_role.arn
  memory_size = 256
  timeout = 10
  filename = ""
  source_code_hash = ""
}

# 创建 Lambda 函数的触发器（例如 S3 触发器）
resource "aws_lambda_permission" "yolov5_s3_trigger_permission" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.yolov5_image_process_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.yolov5_bucket.id}/*"  # 替换为你的 S3 存储桶 ARN
}

# 创建 S3 存储桶的事件通知，以触发 Lambda 函数
resource "aws_s3_bucket_notification" "yolov5_bucket_notification" {
  bucket = aws_s3_bucket.yolov5_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.yolov5_image_process_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}