variable "enable_cloudfront" {
  description = "enable CloudFront CDN (disabled by default because of AWS account verification)"
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "bucket description"
  type        = string
  default     = "neequu-iu-cloud-programming-bucket"
}

variable "logs_bucket_name" {
  description = "logs description"
  type        = string
  default     = "neequu-iu-cloud-programming-logs"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "AWS project name"
  type        = string
  default     = "cloud-programming"
}