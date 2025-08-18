# AWS STATIC WEBSITE DEPLOYMENT
```bash
/
├── error.html       # error page
├── index.html       # main page
├── main.tf          # main terraform config
├── outputs.tf       # outputs config
├── terraform.tfvars # variable values
└── variables.tf     # variable def
```
```bash
# DEPLOYMENT COMMANDS
$ terraform init     # initialize terraform
$ terraform plan     # check what will be created
$ terraform apply    # deploy

```
# CLEAN UP
```bash
$ terraform destroy  # remove all resources
```
# Architectural note
Current version does not use CloudFront CDN by default due to in-progress AWS request for account limitation removal. 
For running the code with the CloudFront CDN and other full features there are 2 options:
  1. Run `terraform apply -var="enable_cloudfront=true"`
  2. Change default `enable_cloudfront` value from `false` to `true` in `terraform.tfvars`

Some key points on the current version:
- Feature flag implementation showing professional Terraform practices
- Currently deployed in S3-only mode due to AWS verification requirements
- Ready to scale to full CDN when account verification completes

Setup differences:

With `enable_cloudfront=false` (default):

- S3 static website hosting
- Public bucket policy for direct access
- File versioning
- Error handling

With `enable_cloudfront=true`:

- Everything above PLUS:
- CloudFront CDN distribution
- Origin Access Control
- Security headers
- Access logging
- IAM roles
- Private S3 bucket (CloudFront-only access)
