locals {
  nginx_value_path = file("../k8s/internal-ingress.yaml")
  elastic_values   = file("../k8s/elasticsearch-values.yaml")
  filebeat_values  = file("../k8s/filebeat-values.yaml")
  logstash_values  = file("../k8s/logstash-values.yaml")
  kibana_values    = file("../k8s/kibana-values.yaml")
  ns               = "logging"
}

resource "helm_release" "ingress_controller" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.9.0"
  namespace        = "nginx-ingress"
  create_namespace = true
  values           = [local.nginx_value_path]

  set {
    name  = "controller.replicaCount"
    value = 2
  }
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "helm_release" "elastic" {
  name             = "elastic"
  repository       = "https://helm.elastic.co"
  chart            = "elasticsearch"
  version          = "8.5.1"
  namespace        = local.ns
  create_namespace = true
  values           = [local.elastic_values]

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "helm_release" "filebeat" {
  name             = "filebeat"
  repository       = "https://helm.elastic.co"
  chart            = "filebeat"
  version          = "8.5.1"
  namespace        = local.ns
  create_namespace = true
  values           = [local.filebeat_values]

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "helm_release" "logstash" {
  name             = "logstash"
  repository       = "https://helm.elastic.co"
  chart            = "logstash"
  version          = "8.5.1"
  namespace        = local.ns
  create_namespace = true
  values           = [local.logstash_values]

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "helm_release" "kibana" {
  name             = "kibana"
  repository       = "https://helm.elastic.co"
  chart            = "kibana"
  version          = "8.5.1"
  namespace        = local.ns
  create_namespace = true
  values           = [local.kibana_values]

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "helm_release" "tomcat" {
  name = "tomcat"
  repository = "../k8s/tomcat"
  chart = "tomcat"
  namespace = local.ns
  create_namespace = true

  depends_on = [ azurerm_kubernetes_cluster.aks_cluster ]
}