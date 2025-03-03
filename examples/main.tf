terraform {
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "heic_converter" {
  source = "../"

  # if var.name is not set, use "photo-converter" as the default name
  name = var.name != null ? var.name : "photo-converter"

  source_bucket_name = var.source_bucket_name
  lambda_layer_arn   = var.lambda_layer_arn

  # Domain configuration
  domain_name            = var.domain_name
  acm_certificate_arn    = var.acm_certificate_arn
  enable_acm_certificate = true

  # Optional: Configure bucket versioning and lifecycle
  enable_bucket_versioning          = true # Enable versioning (default: true)
  transformed_image_expiration_days = 90   # Days until transformed images expire

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }
}

output "source_bucket" {
  description = "Name of the bucket where you should upload original images"
  value       = module.heic_converter.source_bucket_name
}

output "transformed_bucket" {
  description = "Name of the bucket where transformed images are stored"
  value       = module.heic_converter.transformed_bucket_name
}

output "cloudfront_domain" {
  description = "Domain name of the CloudFront distribution"
  value       = module.heic_converter.cloudfront_domain_name
}
