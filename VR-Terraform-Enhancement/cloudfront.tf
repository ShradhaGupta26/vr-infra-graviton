resource "aws_cloudfront_origin_access_identity" "origin_identity" {
  comment = "access-identity"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.datastore.bucket_regional_domain_name
    origin_id   = local.workspace.cdn.s3_origin_id

    s3_origin_config {
      origin_access_identity = format("origin-access-identity/cloudfront/%s", aws_cloudfront_origin_access_identity.origin_identity.id)
    }
  }

  enabled             = true
  comment             = "cdn"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.workspace.cdn.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = {
    "Project"     = local.workspace.project_name
    "ManagedBy"   = "Terraform"
    "Environment" = local.workspace.environment_name
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [
    aws_cloudfront_origin_access_identity.origin_identity,
    aws_s3_bucket.datastore
  ]
}




# #creating Cloudfront distribution :
# resource "aws_cloudfront_distribution" "cf_dist" {
#   enabled             = true
#   aliases             = local.workspace.cdn.domain_name
#   origin {
#     domain_name = local.workspace.cdn.alb_dns_name
#     origin_id   = local.workspace.cdn.alb_dns_name
#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "http-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }
#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods         = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id       = local.workspace.cdn.alb_dns_name
#     viewer_protocol_policy = "redirect-to-https"
#     forwarded_values {
#       headers      = []
#       query_string = true
#       cookies {
#         forward = "all"
#       }
#     }
#   }
#   restrictions {
#     geo_restriction {
#       restriction_type = "whitelist"
#       locations        = ["IN", "US", "CA"]
#     }
#   }
#   tags = {
#     "Project"     = local.workspace.project_name
#     "ManagedBy"   = "Terraform"
#     "Environment" = local.workspace.environment_name
#   }
#   viewer_certificate {
#     acm_certificate_arn      = local.workspace.cdn.cert_arn
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1.2_2018"
#   }
# }