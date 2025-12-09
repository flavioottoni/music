import boto3
import requests
from requests_aws4auth import AWS4Auth
import os
import json

region = 'us-east-1'
service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

# Endpoint do domínio OpenSearch (gerenciado pelo Terraform)
host = os.environ 
index = 'tracks'
url = f'{host}/{index}/_doc/'

def lambda_handler(event, context):
    count = 0
    for record in event:
        # ID do documento no DynamoDB
        doc_id = record['dynamodb']['Keys']['track_id']

        if record['eventName'] == 'REMOVE':
            # Remove do índice de busca se deletado no banco
            r = requests.delete(url + doc_id, auth=awsauth)
        else:
            # Insere ou Atualiza
            dynamo_image = record['dynamodb']['NewImage']
            
            # Transforma formato DynamoDB JSON para JSON padrão
            document = {
                "title": dynamo_image['title'],
                "artist": dynamo_image['artist'],
                "album": dynamo_image['album'],
                "lyrics": dynamo_image.get('lyrics', {}).get('S', ""), # Campo chave para busca de trechos
                "genre": dynamo_image.get('genre', {}).get('S', "Unknown")
            }
            
            headers = { "Content-Type": "application/json" }
            r = requests.put(url + doc_id, auth=awsauth, json=document, headers=headers)
            
        count += 1
    return f'{count} records processed.'