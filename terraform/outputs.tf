output "cluster_name" {
  value = kind_cluster.this.name
}

output "kubeconfig_path" {
  value       = kind_cluster.this.kubeconfig_path
  description = "Chemin du kubeconfig généré par kind. À utiliser dans Freelens."
}

output "endpoint" {
  value = kind_cluster.this.endpoint
}
