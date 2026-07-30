# gp3 StorageClass backed by the EBS CSI driver.
# EKS only ships gp2 with the legacy in-tree provisioner, and does not mark it default.

resource "kubernetes_storage_class" "gp3" {
  count = var.create_storage_class ? 1 : 0

  metadata {
    name = var.storage_class

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }

    labels = {
      ManagedBy = "Terraform"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

  # Create the volume in the same AZ as the pod that claims it.
  volume_binding_mode = "WaitForFirstConsumer"

  # Delete, не Retain: інакше том Jenkins переживає terraform destroy
  # і залишається осиротілим.
  reclaim_policy         = "Delete"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }
}
