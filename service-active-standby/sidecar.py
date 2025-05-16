import requests
import os
from kubernetes import client, config

# Load Service Account token
token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
with open(token_path, "r") as f:
    token = f.read()

# Load Kubernetes configuration
config.load_incluster_config(token=token)

# Create Kubernetes client
v1 = client.CoreV1Api()

def monitor_url(url, pod_name, namespace, label_key):
    try:
        response = requests.get(url)
        if response.status_code == 200:
            add_label(pod_name, namespace, label_key, "active")
        else:
            remove_label(pod_name, namespace, label_key)
    except requests.exceptions.RequestException as e:
        remove_label(pod_name, namespace, label_key)

def add_label(pod_name, namespace, label_key, label_value):
    try:
        pod = v1.read_namespaced_pod(pod_name, namespace)
        pod.metadata.labels = {label_key: label_value}
        v1.patch_namespaced_pod(pod_name, namespace, pod)
        print(f"Added label to pod {pod_name}")
    except client.ApiException as e:
        print(f"Error adding label: {e}")

def remove_label(pod_name, namespace, label_key):
    try:
        pod = v1.read_namespaced_pod(pod_name, namespace)
        if label_key in pod.metadata.labels:
            del pod.metadata.labels[label_key]
        v1.patch_namespaced_pod(pod_name, namespace, pod)
        print(f"Removed label from pod {pod_name}")
    except client.ApiException as e:
        print(f"Error removing label: {e}")


url = "http://localhost:8080"
pod_name = os.getenv('POD_NAME')
namespace = "default"
label_key = "status"

while True:
    monitor_url(url, pod_name, namespace, label_key)
    # Sleep for 1 minute
    import time
    time.sleep(60)
