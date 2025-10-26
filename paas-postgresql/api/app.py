"""
PaaS PostgreSQL Database Manager API
====================================

Flask-based REST API for managing PostgreSQL database instances on Kubernetes.
Provides endpoints to create, list, view, and delete PostgreSQL StatefulSets.

Author: Reda Doukali
Project: MyCloud - Level 3 Cloud Track
"""

from flask import Flask, request, jsonify
from kubernetes import client, config
from kubernetes.client.rest import ApiException
import yaml
import uuid
import requests
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Load Kubernetes config
try:
    # Try in-cluster config first (when running in K8s)
    config.load_incluster_config()
    logger.info("Loaded in-cluster Kubernetes configuration")
except:
    # Fallback to local kubeconfig (for development)
    config.load_kube_config(config_file="~/.kube/k3s-config")
    logger.info("Loaded local Kubernetes configuration")

v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()

# Database instances storage (in-memory, use Redis/DB for production)
databases = {}

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Kubernetes liveness/readiness probes."""
    return jsonify({'status': 'healthy', 'service': 'paas-postgresql-api'}), 200

@app.route('/api/v1/databases', methods=['POST'])
@app.route('/api/v1/databases', methods=['POST'])
def create_database():
    """
    Create a new PostgreSQL database instance.
    
    Request body:
    {
        "db_name": "database_name",
        "db_user": "username",
        "db_password": "password"
    }
    
    Returns: Database instance details with unique ID
    """
    try:
        data = request.json
        if not data:
            return jsonify({'error': 'Request body is required'}), 400
        
        # Generate unique instance name
        instance_id = str(uuid.uuid4())[:8]
        instance_name = f"db-{instance_id}"
        
        logger.info(f"Creating database instance: {instance_name}")
        
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
                logger.info(f"Created StatefulSet for {instance_name}")
            elif resource['kind'] == 'Service':
                v1.create_namespaced_service(
                    namespace="default",
                    body=resource
                )
                logger.info(f"Created Service for {instance_name}")
        
        # Store database info
        databases[instance_id] = {
            'id': instance_id,
            'name': instance_name,
            'db_name': data.get('db_name', 'postgres'),
            'db_user': data.get('db_user', 'postgres'),
            'status': 'creating'
        }
        
        return jsonify(databases[instance_id]), 201
    
    except ApiException as e:
        logger.error(f"Kubernetes API error: {e}")
        return jsonify({'error': f'Kubernetes API error: {e.reason}'}), 500
    except Exception as e:
        logger.error(f"Error creating database: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/databases', methods=['GET'])
def list_databases():
    """List all database instances."""
    return jsonify(list(databases.values()))

@app.route('/api/v1/databases/<instance_id>', methods=['GET'])
def get_database(instance_id):
    """Get details of a specific database instance."""
    if instance_id not in databases:
        return jsonify({'error': 'Database not found'}), 404
    return jsonify(databases[instance_id])

@app.route('/api/v1/databases/<instance_id>', methods=['DELETE'])
def delete_database(instance_id):
    """Delete a database instance and its Kubernetes resources."""
    if instance_id not in databases:
        return jsonify({'error': 'Database not found'}), 404
    
    instance_name = databases[instance_id]['name']
    logger.info(f"Deleting database instance: {instance_name}")
    
    # Delete StatefulSet
    try:
        apps_v1.delete_namespaced_stateful_set(
            name=f"postgres-{instance_name}",
            namespace="default"
        )
        logger.info(f"Deleted StatefulSet for {instance_name}")
    except ApiException as e:
        logger.warning(f"Error deleting StatefulSet: {e.reason}")
    
    # Delete Service
    try:
        v1.delete_namespaced_service(
            name=f"postgres-{instance_name}",
            namespace="default"
        )
        logger.info(f"Deleted Service for {instance_name}")
    except ApiException as e:
        logger.warning(f"Error deleting Service: {e.reason}")
    
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
