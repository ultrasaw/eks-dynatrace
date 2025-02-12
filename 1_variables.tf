variable "region" {
  type    = string
  default = "us-east-1"
}

variable "az1" {
  type    = string
  default = "us-east-1a"
}

variable "az2" {
  type    = string
  default = "us-east-1b"
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

variable "eks_cluster_name" {
  type    = string
  default = "eks-dynatrace"
}
