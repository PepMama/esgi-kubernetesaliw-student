variable "cluster_name" {
  type        = string
  default     = "salleenfrance"
  description = "Nom du cluster kind"
}

variable "kubernetes_version" {
  type        = string
  default     = "v1.30.0"
  description = "Version K8s ; doit correspondre à un tag d'image kindest/node disponible"
}

variable "ingress_chart_version" {
  type        = string
  default     = "4.11.2"
  description = "Version du chart ingress-nginx"
}

variable "cert_manager_chart_version" {
  type        = string
  default     = "v1.15.3"
  description = "Version du chart cert-manager"
}
