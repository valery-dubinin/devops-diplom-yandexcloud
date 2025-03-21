output "cluster_id" {
  description = "Kubernetes cluster ID."
  value       = try(yandex_kubernetes_cluster.k8s-regional.id, null)
}

output "cluster_name" {
  description = "Kubernetes cluster name."
  value       = try(yandex_kubernetes_cluster.k8s-regional.name, null)
}

output "external_v4_address" {
  description = "Kubernetes cluster external IP address."
  value       = yandex_kubernetes_cluster.k8s-regional.master[0].external_v4_address
}

output "external_cluster_cmd" {
  description = <<EOF
    Kubernetes cluster public IP address.
    Use the following command to download kube config and start working with Yandex Managed Kubernetes cluster:
    `$ yc managed-kubernetes cluster get-credentials --id <cluster_id> --external`
    This command will automatically add kube config for your user; after that, you will be able to test it with the
    `kubectl get cluster-info` command.
  EOF
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.k8s-regional.id} --external"
}