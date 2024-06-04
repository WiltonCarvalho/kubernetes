# https://betterprogramming.pub/opentelemetry-sending-traces-from-ingress-nginx-to-multi-tenant-grafana-tempo-e98d482c733
resource "helm_release" "ingress-nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  namespace        = "ingress-nginx"
  create_namespace = true
  values           = [file("./${path.module}/values.yaml")]
  // set {
  //   name  = "controller.hostPort.enabled"
  //   value = "true"
  // }
  // set {
  //   name  = "controller.service.type"
  //   value = "NodePort"
  // }
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.service.annotations.\"metallb\\.universe\\.tf/loadBalancerIPs\""
    value = "172.31.255.254"
  }
}
