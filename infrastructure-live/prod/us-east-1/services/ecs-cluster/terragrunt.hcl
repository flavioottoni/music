terraform {
  source = "tfr:///terraform-aws-modules/ecs/aws?version=5.2.0"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../../vpc"
}

inputs = {
  cluster_name = "soundwave-cluster-prod"

  # --- Capacity Provider (A ponte entre ECS e EC2) ---
  default_capacity_provider_use_fargate = false
  
  autoscaling_capacity_providers = {
    ec2_nodes = {
      auto_scaling_group_arn         = "ARN_PLACEHOLDER_SERA_SUBSTITUIDO_PELO_MODULO_ABAIXO" # O módulo cria o ASG internamente
      managed_termination_protection = "DISABLED"
      
      managed_scaling = {
        maximum_scaling_step_size = 1
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 80 # Tenta manter 80% de utilização
      }
    }
  }
}

# Injeção manual do recurso de Auto Scaling Group (ASG) pois o módulo ECS foca no cluster
generate "asg_resources" {
  path      = "asg_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  
# AMI Otimizada para ECS (Amazon Linux 2)
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# Launch Template define COMO a instância EC2 nasce
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "soundwave-ecs-node-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t2.micro" # Free Tier
  key_name      = "soundwave-prod-key"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_node.name
  }

  network_interfaces {
    associate_public_ip_address = false # Em subnet privada, seguro
    security_groups             = ["${dependency.vpc.outputs.default_security_group_id}"]
  }

  # Script Crítico: Registra a instância no Cluster ECS
  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=soundwave-cluster-prod >> /etc/ecs/ecs.config
  EOT
  )
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                = "soundwave-ecs-asg"
  vpc_zone_identifier = ${jsonencode(dependency.vpc.outputs.private_subnets)}
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

# IAM Role para que o EC2 possa conversar com o ECS
resource "aws_iam_role" "ecs_node" {
  name = "soundwave-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_assume.json
}

data "aws_iam_policy_document" "ecs_node_assume" {
  statement {
    actions =
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_node_policy" {
  role       = aws_iam_role.ecs_node.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name = "soundwave-ecs-node-profile"
  role = aws_iam_role.ecs_node.name
}
EOF
}