variable "name" {
  description = "Name prefix for all resources created by this module"
  type        = string
  default     = null
}

variable "source_bucket_name" {
  description = "Name of the source bucket"
  type        = string
}

variable "lambda_layer_arn" {
  description = "ARN of the Lambda layer containing Sharp library"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the CloudFront distribution"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the CloudFront distribution"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
