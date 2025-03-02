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
  dest_bucket_name   = var.dest_bucket_name

  tags = {
    Project   = var.name
    ManagedBy = "terraform"
  }
}

output "source_bucket" {
  description = "Name of the bucket where you should upload HEIC files"
  value       = module.heic_converter.source_bucket_name
}

output "processed_bucket" {
  description = "Name of the bucket where you will find the converted JPEG files"
  value       = module.heic_converter.processed_bucket_name
}
