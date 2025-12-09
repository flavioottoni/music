terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.1.0"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../../vpc"
}

inputs = {
  name        = "soundwave-db-sg"
  description = "Security Group compartilhado para camada de dados"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
    },
    {
      from_port   = 27017
      to_port     = 27017
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
    },
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
    },
    {
      from_port   = 5672
      to_port     = 5672
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Role = "security-group"
    Env  = "prod"
  }
}