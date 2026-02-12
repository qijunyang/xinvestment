resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-${var.environment}-static-assets"

  tags = {
    Name = "${var.project_name}-${var.environment}-static-assets"
  }
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "static_assets" {
  provider                          = aws.frontend
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${var.project_name} static assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "optimized" {
  provider = aws.frontend
  name     = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "disabled" {
  provider = aws.frontend
  name     = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "cors_s3" {
  provider = aws.frontend
  name     = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  provider = aws.frontend
  name     = "Managed-AllViewer"
}

resource "aws_cloudfront_function" "static_rewrite" {
  provider = aws.frontend
  name     = "${var.project_name}-${var.environment}-static-rewrite"
  runtime  = "cloudfront-js-1.0"
  comment  = "Rewrite friendly paths to index.html"
  publish  = true

  code = <<-EOF
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri === '/home' || uri === '/home/') {
    request.uri = '/home/index.html';
    return request;
  }

  if (uri === '/login' || uri === '/login/') {
    request.uri = '/login/index.html';
    return request;
  }

  return request;
}
EOF
}

resource "aws_cloudfront_distribution" "static_assets" {
  provider            = aws.frontend
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment} CDN"
  default_root_object = var.default_root_object
  price_class         = var.cloudfront_price_class

  origin {
    domain_name              = aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.static_assets.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.static_assets.id
  }

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-${var.alb_id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.static_assets.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.static_rewrite.arn
    }

    cache_policy_id          = data.aws_cloudfront_cache_policy.optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3.id
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${var.alb_id}"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/login/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/login/index.html"
    error_caching_min_ttl = 300
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
    Name = "${var.project_name}-${var.environment}-cdn"
  }
}

resource "aws_s3_bucket_policy" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.static_assets.arn
          }
        }
      }
    ]
  })
}
