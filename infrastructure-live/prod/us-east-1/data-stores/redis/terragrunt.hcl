terraform {
  source = "tfr:///terraform-aws-modules/elasticache/aws?version=1.2.0"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../../vpc"
}

inputs = {
  cluster_id           = "soundwave-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 2
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_ids           = dependency.vpc.outputs.private_subnets
  vpc_id               = dependency.vpc.outputs.vpc_id
  
  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}