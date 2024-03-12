resource "aws_s3_bucket" "yolov5_bucket" {
    bucket = "${var.project}-bucket"
}

resource "aws_s3_bucket_acl" "yolov5_bucket_acl" {
    bucket = aws_s3_bucket.yolov5_bucket.id
    acl = "private"
}

resource "aws_s3_bucket_versioning" "yolov5_bucket_versioning" {
    bucket = aws_s3_bucket.yolov5_bucket.id
    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_policy" "yolov5_bucket_policy" {
  bucket = aws_s3_bucket.yolov5_bucket.id
  policy = jsondecode({
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
