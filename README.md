# AWS STATIC WEBSITE DEPLOYMENT
```bash
/
├── main.tf          # main terraform config
├── outputs.tf       # outputs config
├── variables.tf     # variable def
├── terraform.tfvars # variable values
├── index.html       # main page
└── error.html       # error page
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