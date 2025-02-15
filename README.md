# eks-dynatrace
Example EKS &lt;> Dynatrace integration 

## Project overview
This project walks you through the setup of an EKS cluster hosting the [example-voting-app](https://github.com/dockersamples/example-voting-app). The cluster and its workloads are monitored by [Dynatrace](https://docs.dynatrace.com/docs/ingest-from/setup-on-k8s/quickstart). The infrastructure is defined with Terraform and deployed via GitHub Actions. All of the cluster workloads are deplyed via [Flux](https://github.com/fluxcd/flux2).

AWS Services used:
- EKS - managed Kubernetes service.
- EC2 - worker nodes of the Kubernetes clsuter.
- ELB - load balancer for the EKS node-group; created by the ingress-nginx controller. 
- VPC - Kubernetes worker nodes reside within a VPC network.
- S3 - storage for CloudTrail & AWS Config.
- IAM - OIDC for GitHub Actions.

Helm charts used:
- ingress-nginx - expose Kubernetes workloads outside of the cluster.
- dynatrace-operator - enables monitoring via the Dynatrace Kubernetes App.
- fluent-bit - collects logs on each worker node; required by the Dynatrace Kubernetes App.

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

## GitOps
All of the cluster workloads are deployed using the [GitOps](https://about.gitlab.com/topics/gitops/) pattern. A GitOps Kubernetes operator requires access to the source repository.

Generate a GitHub PAT with repository permissions by checking *all permissions* under *repo*. Afterwards export as an environment variable.

```bash
export GITHUB_TOKEN=<GH_PAT>
```

Then, bootstrap the GitOps operator called [Flux](https://github.com/fluxcd/flux2); run the following command locally:

```bash
flux bootstrap github \
  --token-auth \
  --owner=YOUR_GH_USERNAME \
  --repository=eks-dynatrace \
  --branch=main \
  --path=gitops/source \
  --personal
```
As a consequence of running this command, all of the workloads defined within the `gitops` sub-directory will be deployed to your Kubernetes cluster.

---

Let's take the [example-voting-app](https://github.com/dockersamples/example-voting-app/tree/main/k8s-specifications) as an example. First, define the Flux `Kustomization` resource that points to a specific path in the repository:
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: example-voting-app
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./gitops/app/example-voting-app
  prune: false
  suspend: false
  targetNamespace: example-voting-app
```

Add all of the required Kubernetes resources to the `./gitops/app/example-voting-app` sub-directory; then, create a vanilla Kubernetes `Kustomization` resource to include all of the resources within the aforementioned sub-directory:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: example-voting-app
resources:
  - namespace.yml
  - deployment-db.yml
  - deployment-redis.yml
  - deployment-result.yml
  - deployment-vote.yml
  - deployment-worker.yml
  - svc-db.yml
  - svc-redis.yml
  - svc-result.yml
  - svc-vote.yml
  - ingress-result.yml
  - ingress-vote.yml
```

Unfortunately, there is no wildcard selector - you need to specify all of the resources.

---
Deploying **helm** charts is a bit more involved: it requires defining a `HelmRelease` and `HelmRepository` resources. See the `./gitops/service/ingress-nginx` sub-directory for the deployment of the [ingress-nginx helm chart](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx).

---

For more information, check out the [Flux documentation](https://fluxcd.io/flux/get-started/).

## Dynatrace Kubernetes App setup
As mentioned in the **GitOps** section, all workloads, including the Dynatrace ones, are deployed with Flux. The `./service/dynatrace` sub-directory contains the `dynakube.yml` and the `dynatrace-operator` helm chart mentioned in the [Dynatrace Kubernetes guide](https://docs.dynatrace.com/docs/ingest-from/setup-on-k8s/quickstart). When setting up the Dynatrace resources in your own cluster, replace the *operator* and *data ingest* tokens in the `dynakube.yml` file, and the *fluent-bit* token inside the fluent-bit's `helmrelease.yml` file. 

## Assumptions and Limitations
- Dynatrace and fluent-bit tokens were commited as plain text. These tokens will be outdated by the time this repository is made public. In a production environment, consider using AWS KMS or HashiCorp Vault. 
- Once deployed, the ingress-nginx operator creates a load balancer on AWS. Before running `terraform destroy`, delete the aforementioned load balancer either via the COnsole UI or with the `aws` CLI.