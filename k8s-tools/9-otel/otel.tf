resource "kubernetes_namespace" "otel" {
  metadata {
    name = "otel"
  }
}
resource "kubernetes_manifest" "otel-collector-cm" {
  manifest = yamldecode(file("./${path.module}/manifests/otel-collector-cm.yaml"))
  depends_on = [
    kubernetes_namespace.otel
  ]
}
resource "kubernetes_manifest" "otel-collector-deploy" {
  manifest = yamldecode(file("./${path.module}/manifests/otel-collector-deploy.yaml"))
  depends_on = [
    kubernetes_namespace.otel
  ]
}
resource "kubernetes_manifest" "otel-collector-svc" {
  manifest = yamldecode(file("./${path.module}/manifests/otel-collector-svc.yaml"))
  depends_on = [
    kubernetes_namespace.otel
  ]
}
