output "source_bucket_name" {
  description = "The name of the S3 bucket containing original images"
  value       = data.aws_s3_bucket.source.id
}

output "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  value       = data.aws_s3_bucket.source.arn
}

output "transformed_bucket_name" {
  description = "The name of the S3 bucket containing transformed images"
  value       = aws_s3_bucket.transformed.id
}

output "transformed_bucket_arn" {
  description = "ARN of the transformed images S3 bucket"
  value       = aws_s3_bucket.transformed.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function that processes images"
  value       = aws_lambda_function.image_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.image_processor.arn
}

output "lambda_function_url" {
  description = "The URL of the Lambda function"
  value       = aws_lambda_function_url.image_processor.url_id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.image_delivery.domain_name
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.image_delivery.id
}

output "cloudfront_function_name" {
  description = "The name of the CloudFront function that rewrites URLs"
  value       = aws_cloudfront_function.url_rewrite.name
}
