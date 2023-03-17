terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.58.0"
    }
  }
}


provider "aws" {
  region  = "us-east-1"
  # access_key = "my-access-key"
  # secret_key = "my-secret-key"
  ## profile = "my-profile"
}

variable "hosted_zone_id" {
    type = string
    default = "Z0560287VR7SABYIXT3A"
  
}
variable "hosted_zone" {
  type = string
  default = "ahmetmesutal.click"
  description = "select your hosted zone."
}

variable "domain_name" {
  type = string
  default = "www.ahmetmesutal.click"
  description = "select your domain name."
}

resource "aws_s3_bucket" "kittens_bucket" {
    bucket = var.domain_name
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.kittens_bucket.id
  acl    = "public-read"
}
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.kittens_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = aws_s3_bucket.kittens_bucket.id
    policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    actions = ["s3:GetObject" ]
    sid = "PublicReadGetObject"
    effect = "Allow"
    principals {
        type        = "*"
        identifiers = ["*"]
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.kittens_bucket.bucket}/*",
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "s3_block" {
  bucket = aws_s3_bucket.kittens_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_s3_bucket_acl" "kittens_bucket" {
  bucket = aws_s3_bucket.kittens_bucket.id
  acl    = "private"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.kittens_bucket.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    custom_origin_config {
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      http_port = 80
      https_port = 443
    }
  }
  restrictions {
    geo_restriction {
      locations = []
      restriction_type = "none"
    }
  }
  enabled             = true
  default_root_object = "index.html"
  aliases = [var.domain_name]
  http_version = "http2"
    default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    compress = true
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }
  price_class = "PriceClass_All"
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
  }
}

 resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  validation_option {
  domain_name = var.domain_name
  validation_domain = var.hosted_zone
}
} 

resource "aws_route53_record" "www" {
  zone_id = var.hosted_zone_id
  name = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

