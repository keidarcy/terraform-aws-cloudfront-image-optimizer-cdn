variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "source_bucket_name" {
  description = "Name of the source S3 bucket where original images are stored"
  type        = string
}

variable "lambda_layer_arn" {
  description = "ARN of the Lambda layer to use for the image processor"
  type        = string
}

variable "transformed_image_expiration_days" {
  description = "Number of days after which transformed images are deleted"
  type        = number
  default     = 90
}

variable "enable_bucket_versioning" {
  description = "Whether to enable versioning for the transformed images bucket"
  type        = bool
  default     = true
}

variable "transformed_image_cache_ttl" {
  description = "Cache-Control header value for transformed images"
  type        = string
  default     = "max-age=31622400"
}

variable "max_image_size" {
  description = "Maximum size of transformed images in bytes"
  type        = number
  default     = 4700000
}

variable "lambda_memory" {
  description = "Memory allocation for Lambda function in MB"
  type        = number
  default     = 1500
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 60
}

variable "enable_cors" {
  description = "Whether to enable CORS for the CloudFront distribution"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the CloudFront distribution"
  type        = string
}

variable "enable_acm_certificate" {
  description = "Whether to enable ACM certificate for the CloudFront distribution"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for the CloudFront distribution"
  type        = string
}
