module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "main"
  cidr = "10.0.0.0/16"

  azs             = [var.az1, var.az2]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]

  default_security_group_ingress = [
    {
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = "10.0.0.0/16",
      description = "Allow all inbound traffic from within the VPC"
    }
  ]

  default_security_group_egress = [
    {
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = "0.0.0.0/0",
      description = "Allow all outbound traffic"
    }
  ]

  default_security_group_name = "eks-default-vpc-sg"

  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = true # for public IPs
}

resource "aws_security_group" "allow_ssh_and_ports" {
  name        = "allow_ssh_and_ports"
  description = "Allow SSH and specific port range inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port   = 80
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # dynatrace ports
  ingress {
    from_port   = 8000
    to_port     = 10090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # kube-api server port
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K8s ingress rule for ports 30000-40000
  ingress {
    from_port   = 30000
    to_port     = 40000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
