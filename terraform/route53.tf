data "aws_route53_zone" "subdomain_name" {
  name = var.subdomain_name
}

## ALB

resource "aws_route53_record" "alb_record" {
  zone_id = data.aws_route53_zone.subdomain_name.zone_id
  name    = var.subdomain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb_dragan.dns_name
    zone_id                = aws_lb.alb_dragan.zone_id
    evaluate_target_health = true
  }
}


## API Gateway
resource "aws_route53_record" "api_gateway_record" {
  zone_id = data.aws_route53_zone.subdomain_name.zone_id
  name    = "api.${var.subdomain_name}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_custom_subdomain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_custom_subdomain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.subdomain_name
  subject_alternative_names = ["api.${var.subdomain_name}", "alb.${var.subdomain_name}"]
  validation_method         = "DNS"

  tags = {
    Name        = "acm-cert-${var.subdomain_name}"
    Environment = "prod"
  }
  lifecycle {
    create_before_destroy = true
  }
}


### dynamicly generetes a list of records for the ACM certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.subdomain_name.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]

  lifecycle {
    ignore_changes = [records] # Optional safety
  }
}
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


