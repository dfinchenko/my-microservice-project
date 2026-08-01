# metrics-server — required for the HPA to report CPU utilisation.

resource "aws_eks_addon" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "metrics-server"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]

  tags = {
    Name      = "${var.cluster_name}-metrics-server"
    ManagedBy = "Terraform"
  }
}
