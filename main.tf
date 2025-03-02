###############################################################################
# Locals
###############################################################################
locals {
  transformed_bucket_name  = "${var.name}-cdn-transformed-images"
  lambda_function_name     = "${var.name}-image-processor"
  cloudfront_function_name = "${var.name}-url-rewrite"

  default_tags = {
    ManagedBy = "terraform"
    Module    = "image-optimization-cdn"
  }

  tags = merge(local.default_tags, var.tags)
}

###############################################################################
# S3 Buckets
###############################################################################
data "aws_s3_bucket" "source" {
  bucket = var.source_bucket_name
}

resource "aws_s3_bucket" "transformed" {
  bucket = local.transformed_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "transformed" {
  bucket = aws_s3_bucket.transformed.id

  rule {
    id     = "expire-transformed-images"
    status = "Enabled"

    expiration {
      days = var.transformed_image_expiration_days
    }
  }
}

# Enable versioning for transformed images bucket
resource "aws_s3_bucket_versioning" "transformed" {
  bucket = aws_s3_bucket.transformed.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to transformed images bucket
resource "aws_s3_bucket_public_access_block" "transformed" {
  bucket = aws_s3_bucket.transformed.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create CloudFront origin access control for S3
resource "aws_cloudfront_origin_access_control" "transformed" {
  name                              = "${var.name}-s3-oac"
  description                       = "Origin Access Control for transformed images bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Allow CloudFront to access the transformed images bucket
data "aws_iam_policy_document" "transformed_bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.transformed.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.image_delivery.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "transformed" {
  bucket = aws_s3_bucket.transformed.id
  policy = data.aws_iam_policy_document.transformed_bucket_policy.json
}

###############################################################################
# Lambda Function
###############################################################################
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/functions/image-processing"
  output_path = "${path.module}/functions/image-processing.zip"
}

resource "aws_lambda_function" "image_processor" {
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  function_name    = local.lambda_function_name
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  layers           = [var.lambda_layer_arn]

  environment {
    variables = {
      originalImageBucketName    = data.aws_s3_bucket.source.id
      transformedImageBucketName = aws_s3_bucket.transformed.id
      transformedImageCacheTTL   = var.transformed_image_cache_ttl
      maxImageSize               = var.max_image_size
    }
  }

  tags = local.tags
}

resource "aws_lambda_function_url" "image_processor" {
  function_name      = aws_lambda_function.image_processor.function_name
  authorization_type = "NONE"
}

###############################################################################
# CloudFront Function
###############################################################################
resource "aws_cloudfront_function" "url_rewrite" {
  name    = local.cloudfront_function_name
  runtime = "cloudfront-js-2.0"
  code    = file("${path.module}/functions/url-rewrite/index.js")
}

###############################################################################
# CloudFront Distribution
###############################################################################
resource "aws_cloudfront_cache_policy" "image_cache" {
  name        = "${var.name}-image-cache"
  min_ttl     = 0
  default_ttl = 86400    # 24 hours
  max_ttl     = 31536000 # 365 days

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Accept"]
      }
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "cors" {
  count = var.enable_cors ? 1 : 0
  name  = "${var.name}-cors"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET"]
    }
    access_control_allow_origins {
      items = ["*"]
    }
    access_control_max_age_sec = 600
    origin_override            = false
  }

  custom_headers_config {
    items {
      header   = "x-aws-image-optimization"
      value    = "v1.0"
      override = true
    }
    items {
      header   = "vary"
      value    = "accept"
      override = true
    }
  }
}

resource "aws_cloudfront_distribution" "image_delivery" {
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = var.enable_acm_certificate ? [var.domain_name] : []
  comment             = "Image optimization CDN"
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false
  tags                = local.tags

  # Primary origin - S3 bucket for transformed images
  origin {
    domain_name              = aws_s3_bucket.transformed.bucket_regional_domain_name
    origin_id                = "S3"
    origin_access_control_id = aws_cloudfront_origin_access_control.transformed.id
  }

  # Lambda origin for image processing
  origin {
    domain_name              = replace(replace(aws_lambda_function_url.image_processor.function_url, "https://", ""), "/", "")
    origin_id                = "Lambda"
    origin_access_control_id = aws_cloudfront_origin_access_control.lambda.id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = aws_cloudfront_cache_policy.image_cache.id
    response_headers_policy_id = var.enable_cors ? aws_cloudfront_response_headers_policy.cors[0].id : null

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.url_rewrite.arn
    }
  }

  # Origin group for failover
  origin_group {
    origin_id = "ImageOriginGroup"

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = "S3"
    }

    member {
      origin_id = "Lambda"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.enable_acm_certificate ? var.acm_certificate_arn : null
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = !var.enable_acm_certificate
  }
}

###############################################################################
# IAM Roles and Policies
###############################################################################
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-cdn-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${data.aws_s3_bucket.source.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.transformed.arn}/*"]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "${var.name}-lambda-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create CloudFront origin access control for Lambda
resource "aws_cloudfront_origin_access_control" "lambda" {
  name                              = "${var.name}-lambda-oac"
  description                       = "Origin Access Control for Lambda function URL"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Add Lambda permission for CloudFront
resource "aws_lambda_permission" "cloudfront" {
  statement_id  = "AllowCloudFrontInvoke"
  action        = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "cloudfront.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.image_delivery.arn
}
