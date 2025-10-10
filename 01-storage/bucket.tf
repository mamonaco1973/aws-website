# ------------------------------------------------------------------------------------------
# DATA: Retrieve AWS Account Info
# ------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------------------
# LOCALS: Build Valid, Unique Bucket Name
# ------------------------------------------------------------------------------------------
locals {
  # Replace dots with dashes to comply with S3 DNS rules
  normalized_domain = replace(var.domain_name, ".", "-")

  # Combine domain and AWS Account ID
  bucket_name = "${local.normalized_domain}${data.aws_caller_identity.current.account_id}"
}

# ------------------------------------------------------------------------------------------
# S3 BUCKET: Private Website Content Bucket
# ------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name

  tags = {
    Name = local.bucket_name
  }
}

# ------------------------------------------------------------------------------------------
# Enable Versioning
# ------------------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------------------
# Enable Default Server-Side Encryption (AES256)
# ------------------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------------------------------------
# Block All Public Access (CloudFront will handle HTTPS delivery)
# ------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------------------
# S3 OBJECT: Upload index.html
# ------------------------------------------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"        # Object name inside the bucket
  source       = "${path.module}/index.html"  # Local path relative to this .tf file
  etag         = filemd5("${path.module}/index.html")
  content_type = "text/html"

  # Optional: Set caching behavior
  cache_control = "max-age=300"

  # Optional: Tags for tracking
  tags = {
    Name = "index.html"
  }
}