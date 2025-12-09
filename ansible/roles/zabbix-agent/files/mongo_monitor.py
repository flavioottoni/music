#!/usr/bin/env python3
import subprocess
import json

# Simulação de coleta de status do Mongo
# Em produção, usaria pymongo para checar 'rs.status()'
mongo_status = {
    "replication_lag": 0.045,
    "connections": 512,
    "oplog_window": 24.5
}

# Enviar dados para o Zabbix Server (Trapper)
def send_metric(key, value):
    cmd =
    subprocess.run(cmd)

send_metric("mongo.repl.lag", mongo_status["replication_lag"])
send_metric("mongo.conn.active", mongo_status["connections"])