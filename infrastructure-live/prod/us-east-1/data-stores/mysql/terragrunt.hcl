terraform {
  source = "tfr:///terraform-aws-modules/rds/aws?version=6.1.1"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "sg" {
  config_path = "../../security-groups/db-sg"
}

inputs = {
  identifier = "soundwave-mysql-prod"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"

  allocated_storage     = 100
  max_allocated_storage = 500

  db_name  = "soundwave_billing"
  username = "admin_master"
  port     = 3306

  multi_az               = true
  subnet_ids             = dependency.vpc.outputs.database_subnets
  vpc_security_group_ids = [dependency.sg.outputs.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  
  # Habilita logs para CloudWatch para compliance
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}