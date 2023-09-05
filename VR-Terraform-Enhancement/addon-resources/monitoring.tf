resource "kubernetes_namespace" "monitoring" {
  depends_on = [
    module.eks_cluster
  ]
  metadata {
    name = local.workspace.monitoring.namespace
  }
}
resource "helm_release" "kube-prometheus" {
  depends_on = [
        kubernetes_namespace.monitoring
  ]
  name       = local.workspace.monitoring.stack_name
  namespace  = local.workspace.monitoring.namespace
  version    = local.workspace.monitoring.version
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  
  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  } 
  set {
    name  = "grafana.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "alb"
  }
  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }
  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }
  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-protocol"
    value = "HTTP"
  }
}
