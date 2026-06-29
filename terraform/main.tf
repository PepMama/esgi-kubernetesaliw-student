# =============================================================================
# Cluster kind 2 nœuds + ingress-nginx + cert-manager
#
# Squelette pédagogique : compléter les TODO.
# Validation : `terraform apply` puis `kubectl get nodes` doit montrer 2 nœuds.
# =============================================================================

resource "kind_cluster" "this" {
  name           = var.cluster_name
  node_image     = "kindest/node:${var.kubernetes_version}"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # TODO : déclarer 2 nœuds (1 control-plane + 1 worker).
    # Le worker DOIT publier les ports 80 et 443 vers l'hôte
    # via `extra_port_mappings`. Indice : voir la doc tehcyx/kind.

    node {
      role = "control-plane"
      # extra_port_mappings { ... }    # TODO : 80 et 443
    }

    node {
      role = "worker"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.this.endpoint
    cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
    client_certificate     = kind_cluster.this.client_certificate
    client_key             = kind_cluster.this.client_key
  }
}

provider "kubernetes" {
  host                   = kind_cluster.this.endpoint
  cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
  client_certificate     = kind_cluster.this.client_certificate
  client_key             = kind_cluster.this.client_key
}

# -----------------------------------------------------------------------------
# Ingress NGINX
# -----------------------------------------------------------------------------
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = var.ingress_chart_version

  # TODO : épingler le controller au nœud worker (label `ingress-ready=true`)
  # et exposer en hostNetwork pour profiter des extra_port_mappings de kind.
  # Indices :
  #   set { name = "controller.nodeSelector.ingress-ready" value = "true" }
  #   set { name = "controller.tolerations[0].key" ... }
  #   set { name = "controller.hostPort.enabled" value = "true" }
  #   set { name = "controller.service.type" value = "NodePort" }
}

# -----------------------------------------------------------------------------
# cert-manager
# -----------------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = var.cert_manager_chart_version

  set {
    name  = "installCRDs"
    value = "true"
  }
}
