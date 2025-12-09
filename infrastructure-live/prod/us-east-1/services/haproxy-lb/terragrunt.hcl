terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=5.5.0"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "ecs" {
  config_path = "../ecs-cluster"
  mock_outputs = {
    cluster_name = "soundwave-cluster-prod"
  }
}

inputs = {
  name = "soundwave-haproxy"

  instance_type          = "t2.micro" # Free Tier elegível
  key_name               = "soundwave-prod-key"
  monitoring             = false
  vpc_security_group_ids = [dependency.vpc.outputs.default_security_group_id]
  subnet_id              = element(dependency.vpc.outputs.public_subnets, 0) # Subnet Pública
  associate_public_ip_address = true

  # Política IAM para permitir que o HAProxy descubra os IPs dos nós ECS
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for HAProxy Service Discovery"
  iam_role_policies = {
    EC2ReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  }

  # Script de Instalação e Configuração Dinâmica do HAProxy
  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y haproxy python3-pip cronie
pip3 install boto3

# Criar script Python para descoberta dinâmica de nós ECS
cat << 'PY_SCRIPT' > /usr/local/bin/update_haproxy.py
import boto3
import os

ec2 = boto3.client('ec2', region_name='us-east-1')

def get_ecs_instances():
    # Busca instâncias com a tag do Cluster ECS
    response = ec2.describe_instances(
        Filters=},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    ips =
    for r in response:
        for i in r['Instances']:
            if 'PrivateIpAddress' in i:
                ips.append(i['PrivateIpAddress'])
    return ips

ips = get_ecs_instances()

cfg_content = """
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend main
    bind *:80
    default_backend app_nodes

backend app_nodes
    balance roundrobin
"""

for i, ip in enumerate(ips):
    # Assume que a app roda na porta 80 do Host (Port Mapping do ECS)
    cfg_content += f"    server app{i} {ip}:80 check\n"

with open('/etc/haproxy/haproxy.cfg', 'w') as f:
    f.write(cfg_content)

os.system("systemctl reload haproxy")
PY_SCRIPT

# Configurar Cron para atualizar o HAProxy a cada 2 minutos (Simple Service Discovery)
chmod +x /usr/local/bin/update_haproxy.py
echo "*/2 * * * * root /usr/bin/python3 /usr/local/bin/update_haproxy.py" >> /etc/crontab
systemctl start crond
systemctl enable haproxy
systemctl start haproxy
EOF

  tags = {
    Role = "loadbalancer"
    Env  = "prod"
  }
}