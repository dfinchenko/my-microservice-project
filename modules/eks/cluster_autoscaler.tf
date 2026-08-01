# The node-level half of autoscaling: the HPA adds pods, and when the node group
# runs out of room those pods stay Pending until this controller grows the ASG.

data "aws_region" "current" {}

data "aws_iam_policy_document" "cluster_autoscaler_assume" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:kube-system:${var.cluster_autoscaler_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name               = "${var.cluster_name}-cluster-autoscaler-role"
  description        = "Assumed by the cluster-autoscaler controller via IRSA"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume[0].json

  tags = {
    Name      = "${var.cluster_name}-cluster-autoscaler-role"
    ManagedBy = "Terraform"
  }
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  # Discovery has to cover every ASG: the controller reads the tags before it can
  # know which group is its own.
  statement {
    sid    = "Discover"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Scale"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name        = "${var.cluster_name}-cluster-autoscaler-policy"
  description = "Lets cluster-autoscaler resize the node group of ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler[0].json

  tags = {
    Name      = "${var.cluster_name}-cluster-autoscaler-policy"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  role       = aws_iam_role.cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
}

# Auto-discovery reads ASG tags, and node group tags do not propagate there.
resource "aws_autoscaling_group_tag" "cluster_autoscaler_enabled" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_cluster" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_chart_version

  timeout = 600
  wait    = true

  values = [
    yamlencode({
      cloudProvider = "aws"
      awsRegion     = data.aws_region.current.name

      autoDiscovery = {
        clusterName = aws_eks_cluster.this.name
      }

      rbac = {
        serviceAccount = {
          create = true
          name   = var.cluster_autoscaler_service_account
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler[0].arn
          }
        }
      }

      extraArgs = {
        # Drop the default 10-minute grace period so a scale-down after a load
        # test is visible while the demo is still running.
        "scale-down-unneeded-time"      = "2m"
        "scale-down-delay-after-add"    = "3m"
        "skip-nodes-with-system-pods"   = "false"
        "skip-nodes-with-local-storage" = "false"
        "balance-similar-node-groups"   = "true"
      }

      resources = {
        requests = { cpu = "100m", memory = "300Mi" }
        limits   = { cpu = "200m", memory = "500Mi" }
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_autoscaler,
    aws_autoscaling_group_tag.cluster_autoscaler_enabled,
    aws_autoscaling_group_tag.cluster_autoscaler_cluster,
  ]
}
