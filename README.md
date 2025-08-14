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