<img width="1307" height="898" alt="diagram-export-10-24-2025-12_42_01-AM" src="https://github.com/user-attachments/assets/8bdf14cd-115d-45fd-9a61-bcb4a7b8582f" />

# Hosting a Static Website on AWS Using S3 and CloudFront

This guide provides a comprehensive, step-by-step process for hosting a static website on AWS using Amazon S3 for storage and Amazon CloudFront for content delivery. It is designed for DevOps engineers and frontend developers deploying simple HTML/CSS sites or more complex single-page applications (SPAs) like React apps. Static sites are serverless, cost-effective, and scalable, making this setup ideal for portfolios, landing pages, or documentation sites.

## 1. Overview

### Brief Explanation of Static Site Hosting
Static site hosting involves serving pre-built HTML, CSS, JavaScript, images, and other assets directly from storage without server-side processing. Unlike dynamic sites (e.g., those using Node.js or PHP), static sites are rendered in the browser, reducing latency and operational overhead. AWS S3 acts as the storage bucket for your files, while CloudFront provides a global content delivery network (CDN) to cache and distribute content closer to users.

### Benefits of Using AWS S3 and CloudFront
- **Cost-Effective**: Pay only for storage and data transfer; S3 starts at ~$0.023/GB/month, and CloudFront offers a free tier for the first 1 TB/month.
- **Scalability**: Handles unlimited traffic with auto-scaling; S3 can store petabytes of data.
- **Performance**: CloudFront's edge locations reduce latency by caching content globally, often achieving sub-100ms load times.
- **Security**: Built-in HTTPS support, DDoS protection via AWS Shield, and integration with AWS WAF for web application firewall rules.
- **Reliability**: 99.99% durability for S3 objects; CloudFront ensures high availability.
- **Ease of Integration**: Works seamlessly with CI/CD pipelines for automated deployments, and supports custom domains via Route 53.

## 2. Prerequisites

### AWS Account Setup
- Sign up for an AWS account at [aws.amazon.com](https://aws.amazon.com) if you don't have one.
- Enable multi-factor authentication (MFA) for security.
- Set up billing alerts to monitor costs, as this setup incurs charges for storage, requests, and data transfer.

### IAM Permissions Required
Create an IAM user or role with the following minimum permissions (use least privilege principle):
- S3: `s3:PutObject`, `s3:GetObject`, `s3:ListBucket`, `s3:DeleteObject` for bucket management.
- CloudFront: `cloudfront:CreateDistribution`, `cloudfront:UpdateDistribution`, `cloudfront:CreateInvalidation` for CDN setup.
- Route 53 (optional): `route53:ChangeResourceRecordSets`, `route53:ListHostedZones` for domain configuration.
- CodePipeline (optional): Permissions for pipeline creation, source integration, and deployment actions.
Attach these to a custom policy or use managed policies like `AmazonS3FullAccess` and `CloudFrontFullAccess` for simplicity (narrow them down in production).

Sample IAM Policy (JSON):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "cloudfront:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### React Build or Static Files Ready
- For HTML/CSS sites: Prepare your files (e.g., `index.html`, `styles.css`).
- For React apps: Run `npm run build` to generate the `/build` folder containing optimized static assets.
- Ensure your app handles client-side routing (e.g., React Router) correctly, as S3 doesn't support server-side redirects natively.

## 3. Step-by-Step Implementation

### Step 1: Create an S3 Bucket
1. Log in to the AWS Management Console and navigate to S3.
2. Click "Create bucket".
   - Bucket name: Choose a globally unique name (e.g., `my-static-site-bucket`).
   - Region: Select a region close to your users (e.g., us-east-1).
   - Disable "ACLs" and uncheck "Block all public access" (we'll secure it via policy).
3. Enable static website hosting:
   - In the bucket properties, scroll to "Static website hosting" and enable it.
   - Set "Index document" to `index.html`.
   - Set "Error document" to `error.html` (or `index.html` for SPAs like React to handle 404s via routing).
4. Set bucket policy for public read access:
   - Go to Permissions > Bucket policy.
   - Add this policy (replace `my-static-site-bucket`):
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Sid": "PublicReadGetObject",
           "Effect": "Allow",
           "Principal": "*",
           "Action": "s3:GetObject",
           "Resource": "arn:aws:s3:::my-static-site-bucket/*"
         }
       ]
     }
     ```
5. Configure index and error documents (already done in step 3).

### Step 2: Upload Static Files
1. Upload via AWS Console:
   - In the S3 bucket, click "Upload".
   - Drag and drop your files or folders (e.g., React's `/build` contents).
   - For React: Upload the entire folder structure, ensuring `index.html` is at the root.
2. Upload via CLI (recommended for automation):
   - Install AWS CLI: `pip install awscli` or download from AWS.
   - Configure: `aws configure` (enter access key, secret, region).
   - Sync files: `aws s3 sync ./build/ s3://my-static-site-bucket/ --delete` (for React; use your local path).
3. Folder structure for React apps:
   - Root: `index.html`, `favicon.ico`.
   - Subfolders: `static/` containing `js/`, `css/`, `media/` for bundled assets.
   - Ensure no server-side files; everything should be client-rendered.

### Step 3: Set Up CloudFront Distribution
1. Navigate to CloudFront in the AWS Console.
2. Click "Create distribution".
   - Origin: Select your S3 bucket (e.g., `my-static-site-bucket.s3.amazonaws.com`).
   - Origin access: Use "Origin access control settings" (recommended for security) to restrict direct S3 access.
     - Create an OAC and update your S3 bucket policy to allow CloudFront.
3. Configure behaviors and caching:
   - Default behavior: Path pattern `*`.
   - Viewer protocol policy: "Redirect HTTP to HTTPS".
   - Cache policy: Use "CachingOptimized" or create a custom one with TTLs (e.g., min 1 hour, default 1 day).
   - For SPAs: Add a behavior for `/*` to redirect errors to `index.html` (under Error Pages: Custom error response for 403/404, response page path `/index.html`, HTTP 200).
4. Enable HTTPS with default or custom SSL:
   - Alternate domain names: Add your custom domain (e.g., `www.example.com`) if using Route 53.
   - SSL certificate: Use AWS Certificate Manager (ACM) for free; request a certificate in us-east-1.
   - Default: CloudFront provides a `*.cloudfront.net` domain with HTTPS.
5. Set up cache invalidation:
   - After deployment, invalidate paths: e.g., `/*` for full cache clear.
   - Via CLI: `aws cloudfront create-invalidation --distribution-id EXXXXXXXXXXXXX --paths "/*"`.

### Step 4: (Optional) Configure Route53 for Custom Domain
1. Register or use existing domain:
   - If new, register via Route 53 or transfer an existing one.
2. Create hosted zone and records:
   - In Route 53, create a hosted zone for your domain (e.g., `example.com`).
   - Add an A record: Alias to your CloudFront distribution (select from dropdown).
   - For www subdomain: Add a CNAME or alias record pointing to the same.
3. Point domain to CloudFront:
   - Update your domain's nameservers to Route 53's if registered elsewhere.
   - In CloudFront, add the domain to "Alternate domain names" and associate the ACM certificate.

### Step 5: Automate Deployment with CodePipeline
1. Source from GitHub or CodeCommit:
   - Create a repository (e.g., GitHub) with your site code.
   - In CodePipeline, create a pipeline: Source stage connects to GitHub (OAuth) or CodeCommit.
2. Build stage (optional for React):
   - Use CodeBuild: Specify a `buildspec.yml` for `npm install && npm run build`.
   - Output artifact: The built files.
3. Deploy to S3:
   - Add a deploy stage: Action provider "S3", bucket name, extract files.
   - Use `sync` for efficient updates.
4. Trigger CloudFront invalidation:
   - Add a stage with AWS CLI in CodeBuild or Lambda: Invoke `create-invalidation` post-deploy.
   - Sample Lambda code or use pipeline approvals for manual invalidation.

## 4. Tips & Best Practices

### Cache Control Headers
- Set metadata on S3 objects: e.g., `Cache-Control: max-age=31536000` for static assets like JS/CSS.
- For `index.html`: Use shorter TTLs (e.g., `max-age=300`) to allow quick updates.
- In React: Configure webpack to add cache-busting hashes to filenames.

### Versioning and Rollback
- Enable S3 versioning: Recover previous object versions.
- Use Git for source control; tag releases for easy rollback via pipeline.

### Monitoring with CloudWatch
- Enable CloudWatch metrics for S3 (requests, bytes) and CloudFront (cache hit rate, errors).
- Set alarms for high error rates or traffic spikes.
- Use AWS X-Ray for tracing if integrating with other services.

## 5. Expected Outcome

- Your website will be accessible via the CloudFront domain (e.g., `d1234567890.cloudfront.net`) or custom domain (e.g., `www.example.com`).
- It will load quickly worldwide, with HTTPS enforced, and automatic caching for performance.
- For React apps, client-side routing will work seamlessly, providing a fast, secure, and globally distributed frontend without managing servers.

## 6. Resources & References

### AWS Docs
- S3 Static Website Hosting: [docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- CloudFront Developer Guide: [docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Introduction.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Introduction.html)
- Route 53 Documentation: [docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html)
- CodePipeline User Guide: [docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)

### CLI Commands and Sample Policies
- S3 Sync: `aws s3 sync local_folder s3://bucket-name/`
- CloudFront Invalidation: `aws cloudfront create-invalidation --distribution-id ID --paths "/path/*"`
- Sample S3 Bucket Policy: As shown in Step 1.
- Sample CloudFront OAC Policy: Refer to AWS docs for restricting S3 access to CloudFront only.

For the latest updates, always check the official AWS documentation, as features may evolve. If issues arise, use AWS Support or forums like Stack Overflow.
