provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "my_website" {
  bucket = "neequu-iu-cloud-programming-bucket"
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

# IAM policy for S3 public access
resource "aws_s3_bucket_policy" "make_public" {
  depends_on = [aws_s3_bucket_public_access_block.public_access]
  
  bucket = aws_s3_bucket.my_website.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.my_website.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.my_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket versioning for better practices
resource "aws_s3_bucket_versioning" "website_versioning" {
  bucket = aws_s3_bucket.my_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket logging for monitoring
resource "aws_s3_bucket" "access_logs" {
  bucket = "neequu-iu-cloud-programming-access-logs"
}

resource "aws_s3_bucket_logging" "website_logging" {
  bucket = aws_s3_bucket.my_website.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"
}

# Block public access to logs bucket
resource "aws_s3_bucket_public_access_block" "logs_private" {
  bucket = aws_s3_bucket.access_logs.id

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

# Outputs
output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "S3 static website URL"
}

output "bucket_name" {
  value = aws_s3_bucket.my_website.bucket
  description = "S3 bucket name"
}

output "logs_bucket" {
  value = aws_s3_bucket.access_logs.bucket
  description = "Access logs bucket name"
}