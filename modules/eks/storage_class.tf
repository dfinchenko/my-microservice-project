# EKS only ships gp2 with the legacy in-tree provisioner, and marks nothing as
# default. Jenkins and Prometheus both claim volumes from this class.

resource "kubernetes_storage_class" "gp3" {
  count = var.create_storage_class ? 1 : 0

  metadata {
    name = var.storage_class_name

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = tostring(var.storage_class_default)
    }

    labels = {
      ManagedBy = "Terraform"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

  # Create the volume in the same AZ as the pod that claims it.
  volume_binding_mode = "WaitForFirstConsumer"

  # Delete, not Retain: volumes must not outlive terraform destroy.
  reclaim_policy         = "Delete"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}
