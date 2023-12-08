provider "aws" {
    profile = "AdministratorAccess-395067379223"
    region = "us-east-2"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "brandon-chesser-cloud-resume-challenge"
  
}

resource "aws_s3_bucket_policy" "allow_access_from_CloudFront" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_CloudFront.json
}

data "aws_iam_policy_document" "allow_access_from_CloudFront" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = ["arn:aws:s3:::brandon-chesser-cloud-resume-challenge/*"]
    principals {
      type = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::395067379223:distribution/E1D5RQ6IBQN8N8"]
    }
  }
}


resource "aws_dynamodb_table" "my_table" {
  name              = "cloud-resume"
  billing_mode      = "PAY_PER_REQUEST"
  hash_key          = "id"
  attribute {
    name = "id"
    type = "S"
  }
}


resource "aws_cloudfront_distribution" "my_distribution" {
    enabled             = true
    aliases             = ["resume.chssr.com"]
    default_root_object = "index.html"
    price_class         = "PriceClass_100"
    is_ipv6_enabled     = true
    viewer_certificate {
      acm_certificate_arn      = "arn:aws:acm:us-east-1:395067379223:certificate/c283a72a-c149-47d5-bfa5-ce6b5feaf5d3"
      minimum_protocol_version = "TLSv1.2_2021"
      ssl_support_method       = "sni-only"
    }

    restrictions {
      geo_restriction {
        locations        = []
        restriction_type = "none"
      }
    }

    origin {
      domain_name              = "brandon-chesser-cloud-resume-challenge.s3.us-east-2.amazonaws.com"
      origin_id                = "brandon-chesser-cloud-resume-challenge.s3.us-east-2.amazonaws.com"
      origin_access_control_id = "EAOVOSNXH1R3J"
      connection_attempts      = 3
      connection_timeout       = 10
    }

    default_cache_behavior {
        target_origin_id       = "brandon-chesser-cloud-resume-challenge.s3.us-east-2.amazonaws.com"
        allowed_methods        = ["GET", "HEAD"]
        cached_methods         = ["GET", "HEAD"]
        viewer_protocol_policy = "redirect-to-https"
        cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
        compress               = true
    }
  
}


resource "aws_lambda_function" "myfunc" {
    filename         = data.archive_file.zip.output_path
    source_code_hash = data.archive_file.zip.output_base64sha256
    function_name    = "myfunc"
    role             = aws_iam_role.iam_for_lambda.arn
    handler          = "func.lambda_handler"
    runtime          = "python3.8"
}

resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_resume_project" {
  name        = "aws_iam_policy_for_terraform_resume_project_policy"
  path        = "/"
  description = "AWS IAM Policy for managing the resume project role"
    policy = jsonencode(
        {
            "Version": "2012-10-17",
            "Statement" : [
                {
                    "Effect" : "Allow",
                    "Action" : "logs:CreateLogGroup",
                    "Resource" : "arn:aws:logs:*:*:*"
                },

                {
                    "Effect" : "Allow",
                    "Action" : [
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Resource": [
                         "arn:aws:logs:us-east-2:*:log-group:/aws/lambda/myfunc:*"
                    ]
                },
                
                {
                    "Effect" : "Allow",
                    "Action" : [
                        "dynamodb:*"
                    ],
                    "Resource" : "arn:aws:dynamodb:us-east-2:395067379223:table/cloud-resume"
                }
            ]
        }
    )  
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
    role       = aws_iam_role.iam_for_lambda.name
    policy_arn = aws_iam_policy.iam_policy_for_resume_project.arn
}

data "archive_file" "zip" {
    type        = "zip"
    source_dir  = "${path.module}/lambda/"
    output_path = "${path.module}/packedlambda.zip"
}

resource "aws_lambda_function_url" "url1" {
    function_name      = aws_lambda_function.myfunc.function_name
    authorization_type = "NONE"

    cors {
        allow_credentials = null
        allow_origins     = ["*"]
    }
}