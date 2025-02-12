# eks-dynatrace
Example EKS &lt;> Dynatrace integration 

## Project overview
*TBA*

## Architecture diagram
![Diagram Description](assets/infra.drawio.svg)

## Prerequisites
Ensure access to the aforementioned AWS services, then:

Create a bucket for Terraform state:
```bash
export PREREQUISITES_BUCKET="prerequisites-eks-dynatrace-infra" # name has to be gloally unique
aws s3api create-bucket --bucket $PREREQUISITES_BUCKET --region us-east-1
aws s3api put-bucket-versioning --bucket $PREREQUISITES_BUCKET --versioning-configuration Status=Enabled
```
Fork the repository, clone it, change line **29** in `8_oidc.tf` to your GH account and create the infrastructure from your local shell at least once to set up OIDC for GitHub Actions:
```bash
export AWS_ACCESS_KEY_ID="YOUR_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET"
terraform init && terraform plan && terraform apply --auto-approve
```

To connect to the cluster, run the following command in your local shell to update the Kubernetes context:
```bash
aws eks update-kubeconfig --name eks-dynatrace --region us-east-1
```

In the GitHub repository, define the following Repository Variables:
```bash
AWS_ROLE_TO_ASSUME="arn:aws:iam::YOUR_ACCOUNT_ID:role/github_oidc_role"
AWS_REGION="us-east-1"
```

## Deployment
After addressing the **Prerequisites** section, push to the main branch of your forked repository to update the infrastructure via the following jobs (sequantial):
- Terraform code validation with `terraform validate`
- Terraform plan creation with `terraform plan`
- Terraform infrastructure provisioning with `terraform apply`

The `terraform destroy` job is also available, and can be triggered manually. Pushing to any other branch will only trigger the `terraform validate` and `terraform plan` jobs.
