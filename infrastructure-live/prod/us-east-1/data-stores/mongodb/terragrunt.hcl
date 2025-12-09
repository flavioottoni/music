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
  name          = "soundwave-mongo-node"
  instance_count = 3 # Cluster de 3 nós

  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS
  instance_type = "t3.micro" # Otimizado para Memória (MongoDB)
  key_name      = "soundwave-prod-key"
  
  vpc_security_group_ids = [dependency.vpc.outputs.default_security_group_id]
  subnet_id     = dependency.vpc.outputs.private_subnets # Em prod, distribuir entre subnets, , 

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 50
    }
  ]
  
  # Volume de dados separado para persistência
  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "io2"
      volume_size = 500
      iops        = 3000
    }
  ]

  tags = {
    Role = "mongodb"
    Env  = "prod"
  }
}