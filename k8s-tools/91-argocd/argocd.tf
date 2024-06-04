resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "null_resource" "secrets" {
  provisioner "local-exec" {
    command = "kubectl apply -k ./${path.module}/secrets"
  }
  depends_on = [
    kubernetes_namespace.argocd
  ]
}

data "kubernetes_secret" "argocd-cert" {
  metadata {
    name = "test-cert"
  }
  depends_on = [
    null_resource.secrets
  ]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.6"
  values           = [file("./${path.module}/values.yaml")]
  depends_on = [
    kubernetes_namespace.argocd,
    data.kubernetes_secret.argocd-cert
  ]
}