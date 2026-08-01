output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Cluster security group created by EKS."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_group_name" {
  description = "Name of the managed node group."
  value       = aws_eks_node_group.this.node_group_name
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider, used to build IRSA trust policies."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL of the cluster."
  value       = aws_iam_openid_connect_provider.this.url
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the IRSA role assumed by the EBS CSI controller."
  value       = aws_iam_role.ebs_csi.arn
}

output "node_security_group_id" {
  description = "Security group attached to the worker nodes. Reference it from the RDS security group so only the cluster can reach the database."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "storage_class_name" {
  description = "Name of the gp3 StorageClass, or null when the module did not create it."
  value       = var.create_storage_class ? var.storage_class_name : null
}

output "node_group_asg_name" {
  description = "Auto Scaling group behind the managed node group — the group cluster-autoscaler resizes."
  value       = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IRSA role assumed by cluster-autoscaler, or null when it is disabled."
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}
