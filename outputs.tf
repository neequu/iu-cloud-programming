output "website_url" {
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "S3 static website URL"
}

output "cloudfront_url" {
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.website_cdn[0].domain_name : "CloudFront disabled"
  description = "CloudFront distribution domain name (if enabled)"
}

output "cloudfront_distribution_id" {
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.website_cdn[0].id : "CloudFront disabled"
  description = "CloudFront distribution ID (if enabled)"
}

output "deployment_mode" {
  value       = var.enable_cloudfront ? "S3 + CloudFront" : "S3 Only"
  description = "Current deployment configuration"
}