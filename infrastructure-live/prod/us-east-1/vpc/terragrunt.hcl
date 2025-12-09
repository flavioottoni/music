terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.1.1"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name = "soundwave-vpc-prod"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false # Alta Disponibilidade: Um NAT por AZ
  one_nat_gateway_per_az = true
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags para integração com Kubernetes/ECS se necessário
  public_subnet_tags = {
    "Tier" = "Public"
  }
  private_subnet_tags = {
    "Tier" = "Private"
  }
}