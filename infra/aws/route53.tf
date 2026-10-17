# DNS-validated ACM cert — the hosted zone (var.hosted_zone_id) must already
# exist; this doesn't create the zone itself, just records inside it.

resource "aws_acm_certificate" "backend" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-cert" }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.backend.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = var.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "backend" {
  certificate_arn         = aws_acm_certificate.backend.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# The record your Flutter apps' API_BASE_URL and the backend's
# PLATFORM_CALLBACK_URL should actually point at.
resource "aws_route53_record" "backend" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.backend.dns_name
    zone_id                = aws_lb.backend.zone_id
    evaluate_target_health = true
  }
}
