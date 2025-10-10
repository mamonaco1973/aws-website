# ------------------------------------------------------------------------------------------
# ORIGIN ACCESS CONTROL (OAC) - Secure S3 Access
# ------------------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${local.root_domain}-oac"
  description                       = "OAC for ${local.root_domain} CloudFront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ------------------------------------------------------------------------------------------
# CLOUD FRONT DISTRIBUTION - HTTPS Web Delivery
# ------------------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "Static site for ${local.root_domain}"

  # ----------------------------------------------------------------------------------------
  # ORIGIN CONFIGURATION - Connect to S3 bucket
  # ----------------------------------------------------------------------------------------
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # ----------------------------------------------------------------------------------------
  # DEFAULT CACHE BEHAVIOR - Redirect HTTP to HTTPS
  # ----------------------------------------------------------------------------------------
  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # ----------------------------------------------------------------------------------------
  # CUSTOM DOMAIN SETTINGS - Use ACM Certificate
  # ----------------------------------------------------------------------------------------
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # ----------------------------------------------------------------------------------------
  # ALIASES - Custom Domain for CloudFront
  # ----------------------------------------------------------------------------------------
  aliases = ["www.${local.root_domain}"]

  # ----------------------------------------------------------------------------------------
  # GENERAL SETTINGS
  # ----------------------------------------------------------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"

  tags = {
    Name        = "cdn-${local.root_domain}"
    Environment = "prod"
  }
}

# ------------------------------------------------------------------------------------------
# ROUTE 53 ALIAS RECORD - www -> CloudFront
# ------------------------------------------------------------------------------------------
resource "aws_route53_record" "www_alias" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
