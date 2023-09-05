resource "helm_release" "argocd" {
name             = "argocd"
create_namespace = "true"
chart            = local.workspace.eks_cluster.argocd.chart_name
namespace        = local.workspace.eks_cluster.argocd.namespace
version          = local.workspace.eks_cluster.argocd.version
repository       = local.workspace.eks_cluster.argocd.repository
# set {
# name  = "server.service.type"
# value = "LoadBalancer"
# }
set {
name  = "server.extraArgs"
value = "{--insecure}"
}
# set {
# name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal"
# value = "true"
# }
  set {
    name  = "server.ingress.enabled"
    value = "true"
  } 
  set {
    name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "alb"
  }
  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }
  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }
  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-protocol"
    value = "HTTP"
  }
  depends_on = [module.load_balancer_controller]
}
