resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "null_resource" "secrets" {
  provisioner "local-exec" {
    command = "kubectl apply -k ./${path.module}/secrets"
  }
  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

data "kubernetes_secret" "grafana-cert" {
  metadata {
    name = "test-cert"
  }
  depends_on = [
    null_resource.secrets
  ]
}

data "kubernetes_secret" "grafana-admin" {
  metadata {
    name = "grafana-admin"
  }
  depends_on = [
    null_resource.secrets
  ]
}

resource "helm_release" "kube-prometheus-stack" {
  name = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "55.0.0"
  namespace        = "monitoring"
  create_namespace = false
  values = [file("./${path.module}/values.yaml")]
  depends_on = [
    kubernetes_namespace.monitoring,
    data.kubernetes_secret.grafana-cert,
    data.kubernetes_secret.grafana-admin
  ]
}

resource "null_resource" "dashboards" {
  provisioner "local-exec" {
    command = "kubectl apply -k ./${path.module}/dashboards"
  }
  depends_on = [
    helm_release.kube-prometheus-stack
  ]
}