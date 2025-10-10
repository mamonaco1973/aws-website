# ------------------------------------------------------------------------------------------
# LOCALS: Normalize Domain Name (remove trailing dot)
# ------------------------------------------------------------------------------------------
locals {
  # Some AWS APIs return zone.name with a trailing dot (e.g. "example.com.")
  root_domain = trimsuffix(data.aws_route53_zone.selected.name, ".")
}

# ------------------------------------------------------------------------------------------
# ACM CERTIFICATE: Wildcard + Root Domain
# ------------------------------------------------------------------------------------------
resource "aws_acm_certificate" "site_cert" {
  provider                  = aws.us_east_1
  domain_name               = local.root_domain
  subject_alternative_names = ["*.${local.root_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Wildcard-${local.root_domain}"
  }
}

# ------------------------------------------------------------------------------------------
# DNS VALIDATION RECORDS (Use the same Hosted Zone)
# ------------------------------------------------------------------------------------------
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
   
  allow_overwrite = true
}

# ------------------------------------------------------------------------------------------
# VALIDATE CERTIFICATE
# ------------------------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
