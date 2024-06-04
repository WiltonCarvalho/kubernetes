resource "helm_release" "promtail" {
  name             = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  namespace        = "promtail"
  create_namespace = true
  version          = "6.15.3"
  values           = [file("./${path.module}/values.yaml")]
}