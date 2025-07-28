from flask import Flask, request, jsonify
from kubernetes import client, config
import yaml
import uuid
import requests
import os

app = Flask(__name__)

# Load Kubernetes config
try:
    config.load_incluster_config()
except:
    config.load_kube_config(config_file="~/.kube/k3s-config")

v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()

# Database instances storage
databases = {}

@app.route('/api/v1/databases', methods=['POST'])
def create_database():
    data = request.json
    
    # Generate unique instance name
    instance_id = str(uuid.uuid4())[:8]
    instance_name = f"db-{instance_id}"
    
    # Get template from ConfigMap
    template = v1.read_namespaced_config_map(
        name="postgres-template",
        namespace="default"
    ).data["postgres-statefulset.yaml"]
    
    # Replace template variables
    template = template.replace("{{INSTANCE_NAME}}", instance_name)
    template = template.replace("{{DB_NAME}}", data.get('db_name', 'postgres'))
    template = template.replace("{{DB_USER}}", data.get('db_user', 'postgres'))
    template = template.replace("{{DB_PASSWORD}}", data.get('db_password', 'password'))
    
    # Parse YAML
    resources = yaml.safe_load_all(template)
    
    # Create resources
    for resource in resources:
        if resource['kind'] == 'StatefulSet':
            apps_v1.create_namespaced_stateful_set(
                namespace="default",
                body=resource
            )
        elif resource['kind'] == 'Service':
            v1.create_namespaced_service(
                namespace="default",
                body=resource
            )
    
    # Store database info
    databases[instance_id] = {
        'id': instance_id,
        'name': instance_name,
        'db_name': data.get('db_name', 'postgres'),
        'db_user': data.get('db_user', 'postgres'),
        'status': 'creating'
    }
    
    return jsonify(databases[instance_id]), 201

@app.route('/api/v1/databases', methods=['GET'])
def list_databases():
    return jsonify(list(databases.values()))

@app.route('/api/v1/databases/<instance_id>', methods=['GET'])
def get_database(instance_id):
    if instance_id not in databases:
        return jsonify({'error': 'Database not found'}), 404
    return jsonify(databases[instance_id])

@app.route('/api/v1/databases/<instance_id>', methods=['DELETE'])
def delete_database(instance_id):
    if instance_id not in databases:
        return jsonify({'error': 'Database not found'}), 404
    
    instance_name = databases[instance_id]['name']
    
    # Delete StatefulSet
    try:
        apps_v1.delete_namespaced_stateful_set(
            name=f"postgres-{instance_name}",
            namespace="default"
        )
    except:
        pass
    
    # Delete Service
    try:
        v1.delete_namespaced_service(
            name=f"postgres-{instance_name}",
            namespace="default"
        )
    except:
        pass
    
    del databases[instance_id]
    return jsonify({'message': 'Database deleted'})

@app.route('/api/v1/databases/<instance_id>/metrics', methods=['GET'])
def get_database_metrics(instance_id):
    if instance_id not in databases:
        return jsonify({'error': 'Database not found'}), 404
    
    instance_name = databases[instance_id]['name']
    
    # Query Prometheus for metrics
    prometheus_url = "http://prometheus:9090"
    
    # CPU usage query
    cpu_query = f'rate(container_cpu_usage_seconds_total{{pod=~"postgres-{instance_name}.*"}}[5m])'
    cpu_response = requests.get(f"{prometheus_url}/api/v1/query", params={'query': cpu_query})
    
    # Memory usage query
    memory_query = f'container_memory_usage_bytes{{pod=~"postgres-{instance_name}.*"}}'
    memory_response = requests.get(f"{prometheus_url}/api/v1/query", params={'query': memory_query})
    
    metrics = {
        'cpu_usage': cpu_response.json().get('data', {}).get('result', []),
        'memory_usage': memory_response.json().get('data', {}).get('result', []),
        'storage_usage': '1Gi'  # Static for template
    }
    
    return jsonify(metrics)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
