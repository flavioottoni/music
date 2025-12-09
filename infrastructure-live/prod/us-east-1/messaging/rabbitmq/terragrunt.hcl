terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=5.5.0"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../../vpc"
}

inputs = {
  name          = "soundwave-rabbitmq"
  instance_count = 3

  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t3.micro" # Compute optimized para throughput de mensagens
  key_name      = "soundwave-prod-key"
  
  vpc_security_group_ids = [dependency.vpc.outputs.default_security_group_id]
  subnet_id     = dependency.vpc.outputs.private_subnets

  tags = {
    Role = "rabbitmq"
    Env  = "prod"
  }
}