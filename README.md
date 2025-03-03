# AWS CloudFront Image Optimizer CDN

This Terraform module sets up a serverless image optimization and delivery pipeline using AWS CloudFront, Lambda, and S3.

## Features

- Configures a complete image optimization CDN:
  - Uses existing S3 bucket as source for original images
  - Creates a new S3 bucket for transformed images with lifecycle management
  - Sets up Lambda function for on-the-fly image processing
  - Deploys CloudFront distribution with URL-based transformations
  - Implements CloudFront Function for URL rewriting
- Supports multiple image transformations:
  - Format conversion (JPEG, WebP, AVIF, PNG, GIF)
  - Automatic format selection based on browser support
  - Resizing (width/height)
  - Quality adjustment
- Implements proper IAM roles and permissions
- Configures CORS support (optional)
- Supports custom domain names with ACM certificates

## Prerequisites

- AWS account with appropriate permissions
- Terraform >= 0.13
- Existing S3 bucket with source images
- Lambda layer with Sharp library for image processing

## Usage

```hcl
module "image_optimizer_cdn" {
  source = "keidarcy/cloudfront-image-optimizer-cdn/aws"

  name               = "my-image-cdn"
  source_bucket_name = "my-original-images"
  lambda_layer_arn   = "arn:aws:lambda:region:account:layer:sharp:1"

  domain_name          = "images.example.com"
  acm_certificate_arn  = "arn:aws:acm:us-east-1:account:certificate/xxx"
  enable_acm_certificate = true

  # Optional: Configure bucket versioning and lifecycle
  enable_bucket_versioning         = true # Enable versioning (default: true)
  transformed_image_expiration_days = 90  # Days until transformed images expire

  tags = {
    Environment = "production"
    Project     = "image-processing"
  }
}
```

After applying the Terraform configuration:
1. Access your images through the CloudFront URL with transformation parameters
2. Example URLs:
   - Original image: `/images/example.jpg/original`
   - Resized WebP: `/images/example.jpg/format=webp,width=800`
   - Auto format with quality: `/images/example.jpg/format=auto,quality=80`

## How it Works

1. When you apply this Terraform configuration:
   - Creates a new S3 bucket for transformed images
   - Sets up Lambda function with Sharp library for image processing
   - Deploys CloudFront Function for URL rewriting
   - Configures CloudFront distribution with proper origins and behaviors

2. When an image is requested:
   - CloudFront Function parses the URL parameters
   - First checks transformed images bucket
   - If not found, forwards to Lambda function
   - Lambda processes the image according to parameters
   - Stores result in transformed bucket
   - CloudFront delivers the optimized image

## Lambda Function Details

The Lambda function uses:
- Node.js 20.x runtime
- Sharp library for image processing
- AWS SDK v3 for S3 operations
- 1500MB memory allocation (default)
- 60-second timeout (default)

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| name | Name prefix for all resources | string | yes |
| source_bucket_name | Name of existing S3 bucket with source images | string | yes |
| lambda_layer_arn | ARN of Lambda layer containing Sharp library | string | yes |
| domain_name | Custom domain name for CloudFront | string | no |
| acm_certificate_arn | ACM certificate ARN for custom domain | string | no |
| enable_acm_certificate | Whether to use custom domain with ACM | bool | no |
| transformed_image_expiration_days | Days until transformed images expire | number | no |
| enable_bucket_versioning | Whether to enable versioning for transformed images bucket | bool | no |
| transformed_image_cache_ttl | Cache-Control header for transformed images | string | no |
| max_image_size | Maximum size of transformed images in bytes | number | no |
| lambda_memory | Memory allocation for Lambda function | number | no |
| lambda_timeout | Timeout for Lambda function | number | no |
| enable_cors | Whether to enable CORS | bool | no |
| tags | Tags to apply to all resources | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| source_bucket_name | Name of the source S3 bucket |
| source_bucket_arn | ARN of the source S3 bucket |
| transformed_bucket_name | Name of the transformed images bucket |
| transformed_bucket_arn | ARN of the transformed images bucket |
| lambda_function_name | Name of the image processor Lambda function |
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_url | URL of the Lambda function |
| cloudfront_domain_name | Domain name of the CloudFront distribution |
| cloudfront_distribution_id | ID of the CloudFront distribution |
| cloudfront_function_name | Name of the URL rewrite function |

## License

MIT


