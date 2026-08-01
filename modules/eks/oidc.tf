# IAM OIDC provider — required for IRSA (EBS CSI driver, Jenkins agent).

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = {
    Name      = "${var.cluster_name}-oidc"
    ManagedBy = "Terraform"
  }
}

locals {
  # IAM condition keys use the issuer without the scheme.
  oidc_host = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}
