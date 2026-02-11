# CloudFront + S3 Static Asset Deployment Guide

This document explains how static assets (HTML, CSS, JS bundles) are served via CloudFront CDN while the API remains on ECS.

## Architecture Overview

```
┌─────────┐
│  User   │
└────┬────┘
     │
     ├─────── Static Assets (HTML, CSS, JS) ────→ CloudFront → S3
     │
     └─────── API Calls (/api/*)  ──────────────→ ALB → ECS → Express
```

### Separation of Concerns

- **CloudFront + S3**: Serves all static content (login/index.html, home/index.html, JS bundles, CSS)
- **ALB + ECS**: Serves only API endpoints (/api/auth, /api/households, /api/features, etc.)

## Benefits

1. **Performance**: Static assets cached globally via CloudFront edge locations
2. **Cost Savings**: Reduced bandwidth costs on ECS/ALB
3. **Scalability**: S3 + CloudFront handle high traffic automatically
4. **Reliability**: Static assets served even if ECS is updating
5. **Best Practice**: Industry-standard separation of static vs dynamic content

## Deployment Flow

### 1. Build Static Assets
```bash
npm run build
```
This creates the `dist/` folder with:
- `login/` - Login page bundle
- `home/` - Home page bundle  
- `dist/` - Webpack bundles (login.bundle.js, home.bundle.js)

### 2. Deploy Static Assets to S3/CloudFront
```bash
# Using PowerShell script
cd deploy/scripts
.\deploy-static.ps1 -Environment qa

# Using Bash script
./deploy-static.sh qa
```

This script:
1. Uploads all files from `dist/` to S3 bucket
2. Sets cache headers:
   - JS/CSS bundles: 1 year cache (`max-age=31536000`)
   - HTML files: 5 minutes cache (`max-age=300`)
3. Creates CloudFront invalidation to clear CDN cache
4. Outputs the CDN URL

### 3. Deploy API Infrastructure (ECS)
```bash
cd deploy/scripts
.\deploy-image.ps1 -Environment qa

cd ../terraform
terraform apply -var-file=terraform-qa.tfvars
```

## TLS Notes

- **CloudFront** uses ACM certificates that must be in **us-east-1** if you use a custom CDN domain.
- **ALB** uses ACM certificates in the **aws_region** (the region where ALB/ECS are deployed).

Two TLS terminations are expected:
- **CloudFront TLS** for static assets
- **ALB TLS** for API endpoints

## Configuration

### CloudFront Settings (in terraform-*.tfvars)

```hcl
# Price Class (coverage vs cost tradeoff)
cloudfront_price_class = "PriceClass_100"  # US, Canada, Europe
# cloudfront_price_class = "PriceClass_200"  # Above + Asia, Africa, Oceania
# cloudfront_price_class = "PriceClass_All"  # Global (most expensive)

# Custom domain for CDN (optional)
cloudfront_aliases = []  # Use default CloudFront domain
# cloudfront_aliases = ["cdn.example.com"]  # Custom domain

# ACM Certificate for custom domain (must be in us-east-1!)
cloudfront_certificate_arn = ""  # Leave empty for default CloudFront cert
# cloudfront_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/..."
```

### Cache Behavior

**Static Assets (JS, CSS, images):**
- Cache-Control: `public, max-age=31536000, immutable`
- CloudFront caches for 1 year
- Use versioned filenames for cache busting (Webpack handles this)

**HTML Files:**
- Cache-Control: `public, max-age=300`
- CloudFront caches for 5 minutes
- Short cache allows quick updates

## Application Changes Required

### Update HTML Files to Reference CDN

Your HTML files need to load assets from the CloudFront URL instead of local paths.

**Before (local serving):**
```html
<script src="/dist/login.bundle.js"></script>
<link rel="stylesheet" href="/dist/login.css">
```

**After (CloudFront):**
```html
<script src="https://d111111abcdef8.cloudfront.net/dist/login.bundle.js"></script>
<link rel="stylesheet" href="https://d111111abcdef8.cloudfront.net/dist/login.css">
```

### Environment Variable for CDN URL

Set `CDN_URL` environment variable in Terraform task definition:

```hcl
environment = [
  {
    name  = "CDN_URL"
    value = "https://${aws_cloudfront_distribution.static_assets.domain_name}"
  }
]
```

Then inject it into HTML templates or use a build-time replacement.

### Remove Static Serving from Express

Update `src/app.js` to remove static file serving:

```javascript
// REMOVE THIS (no longer needed):
// app.use('/dist', express.static(path.join(__dirname, 'client/dist')));

// Keep only API routes:
app.use('/api/auth', authRoutes);
app.use('/api/households', householdRoutes);
// etc...
```

## Monitoring

### CloudFront Metrics
- AWS Console → CloudFront → Monitoring
- Metrics: Requests, Data Transfer, Error Rate, Cache Hit Ratio

### S3 Storage
- AWS Console → S3 → Bucket → Metrics
- Track storage size and request count

### Costs
```
CloudFront Pricing (example US/Europe):
- First 10 TB/month: $0.085/GB
- Data transfer out: Free from S3 to CloudFront
- Requests: $0.0075 per 10,000 HTTP requests

S3 Pricing:
- Storage: $0.023/GB/month
- Requests: Minimal (CloudFront caches)
```

## Troubleshooting

### Assets not updating after deployment

**Issue**: Deployed new version but seeing old files

**Solution**: CloudFront invalidation takes a few minutes
```bash
# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id E1234567890ABC \
  --id I1234567890ABC

# Or create manual invalidation
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

### 403 Forbidden errors from S3

**Issue**: CloudFront can't access S3 bucket

**Solution**: Check S3 bucket policy allows CloudFront OAC
```bash
# Verify bucket policy
aws s3api get-bucket-policy --bucket xinvestment-qa-static-assets
```

### CORS errors in browser

**Issue**: API calls from CloudFront-served HTML fail

**Solution**: Ensure Express has CORS configured for CloudFront domain
```javascript
app.use(cors({
  origin: [
    'https://d111111abcdef8.cloudfront.net',
    'https://cdn.example.com'
  ],
  credentials: true
}));
```

### Custom domain not working

**Issue**: CloudFront alternate domain shows certificate error

**Solution**: 
1. ACM certificate **must** be in us-east-1 region
2. Certificate must include the domain name
3. DNS CNAME or A record must point to CloudFront

## Development Workflow

### Local Development (No CloudFront)
```bash
npm run build:dev
npm run dev
# Access at http://localhost:3000
# Assets served locally from Express
```

### QA/Production (With CloudFront)
```bash
# 1. Deploy static assets
npm run build
./deploy-static.ps1 -Environment qa

# 2. Deploy API
./deploy-image.ps1 -Environment qa
cd ../terraform
terraform apply -var-file=terraform-qa.tfvars

# Access:
# - Static assets: https://d111111abcdef8.cloudfront.net
# - API: https://xinvestment-qa.example.com/api/*
```

## Rollback

### Rollback Static Assets

CloudFront doesn't support versioning directly, but S3 does:

```bash
# List versions
aws s3api list-object-versions \
  --bucket xinvestment-qa-static-assets \
  --prefix dist/login.bundle.js

# Restore previous version
aws s3api copy-object \
  --copy-source xinvestment-qa-static-assets/dist/login.bundle.js?versionId=VERSION_ID \
  --bucket xinvestment-qa-static-assets \
  --key dist/login.bundle.js

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/dist/login.bundle.js"
```

## Security

### S3 Bucket Security
- ✅ Block all public access
- ✅ Only CloudFront OAC can read
- ✅ Versioning enabled
- ✅ Server-side encryption (AES256)

### CloudFront Security
- ✅ HTTPS only (redirects HTTP to HTTPS)
- ✅ TLS 1.2 minimum
- ✅ Restricted to specific S3 bucket
- ✅ No public S3 access

### Content Security
- Consider adding signed URLs for sensitive content
- WAF rules can be applied to CloudFront (additional cost)

## Next Steps

1. **Create ACM Certificate in us-east-1** (if using custom domain)
2. **Update HTML files** to load assets from CloudFront URL
3. **Update Express app** to remove static file serving
4. **Test deployment** in dev environment first
5. **Monitor CloudFront metrics** after deployment

## Additional Resources

- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [Best Practices for CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/BestPractices.html)
