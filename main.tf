provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "my_website" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket" "cloudfront_logs" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = var.logs_bucket_name
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.my_website.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_versioning" "website_versioning" {
  bucket = aws_s3_bucket.my_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  count                             = var.enable_cloudfront ? 1 : 0
  name                              = "s3-oac"
  description                       = "Origin Access Control for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website_cdn" {
  count = var.enable_cloudfront ? 1 : 0

  origin {
    domain_name              = aws_s3_bucket.my_website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac[0].id
    origin_id                = "S3-${aws_s3_bucket.my_website.bucket}"
  }

  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs[0].bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.my_website.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    response_headers_policy_id = var.enable_cloudfront ? aws_cloudfront_response_headers_policy.security_headers[0].id : null
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  count   = var.enable_cloudfront ? 1 : 0
  name    = "security-headers-policy"
  comment = "Security headers for static website"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
  }
}

resource "aws_iam_role" "cloudfront_role" {
  count = var.enable_cloudfront ? 1 : 0
  name  = "cloudfront-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "CloudFront S3 Access Role"
  }
}

resource "aws_s3_bucket_public_access_block" "website_public_access" {
  count  = var.enable_cloudfront ? 0 : 1
  bucket = aws_s3_bucket.my_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_policy" {
  depends_on = [aws_s3_bucket_public_access_block.website_public_access]
  bucket     = aws_s3_bucket.my_website.id

  policy = var.enable_cloudfront ? jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "cloudfront.amazonaws.com"
      },
      Action   = "s3:GetObject",
      Resource = "${aws_s3_bucket.my_website.arn}/*",
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.website_cdn[0].arn
        }
      }
    }]
  }) : jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.my_website.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_policy" "cloudfront_logs_policy" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "cloudfront.amazonaws.com"
      },
      Action   = "s3:PutObject",
      Resource = "${aws_s3_bucket.cloudfront_logs[0].arn}/*",
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.website_cdn[0].arn
        }
      }
    }]
  })
}

resource "aws_s3_bucket_public_access_block" "private_access" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.my_website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs_private_access" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.my_website.bucket
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  etag         = filemd5("index.html")
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.my_website.bucket
  key          = "error.html"
  source       = "error.html"
  content_type = "text/html"
  etag         = filemd5("error.html")
}

