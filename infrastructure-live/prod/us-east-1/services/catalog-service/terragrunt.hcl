terraform {
  source = "tfr:///terraform-aws-modules/ecs/aws//modules/service?version=5.2.0"
}

include {
  path = find_in_parent_folders()
}

dependency "cluster" {
  config_path = "../ecs-cluster"
}

inputs = {
  name        = "soundwave-catalog-service"
  cluster_arn = dependency.cluster.outputs.cluster_arn

  # Configuração para EC2 (Free Tier)
  launch_type     = "EC2"
  desired_count   = 2
  
  # --- Configurações de Rede (Bridge Mode para EC2) ---
  network_mode = "bridge"

  # Definição do Contêiner
  container_definitions = {
    catalog-app = {
      image     = "nginx:latest" # Substituir pela sua imagem ECR: "12345.dkr.ecr.../app:latest"
      cpu       = 256
      memory    = 256 # t2.micro tem 1GB, cuidado para não estourar
      essential = true
      
      # Mapeamento de Porta: Host 80 -> Container 80
      # O HAProxy enviará tráfego para o IP Privado do EC2 na porta 80
      port_mappings = [
        {
          containerPort = 80
          hostPort      = 80 
          protocol      = "tcp"
        }
      ]
      
      environment =
    }
  }

  # Ignorar load balancer do ECS, pois estamos usando HAProxy manual
  load_balancer = {}

  subnet_ids = # Não necessário em modo bridge (usa a rede do host)
  security_group_ids = 
}