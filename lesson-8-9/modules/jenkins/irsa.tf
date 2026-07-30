# IRSA role for Jenkins build agents: lets Kaniko push to ECR without static keys.

locals {
  oidc_host = replace(var.oidc_provider_url, "https://", "")
}

data "aws_iam_policy_document" "agent_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.agent_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "agent" {
  name               = "${var.release_name}-agent-ecr-role"
  description        = "Assumed by Jenkins Kaniko agents to push images to ECR"
  assume_role_policy = data.aws_iam_policy_document.agent_assume.json

  tags = {
    Name      = "${var.release_name}-agent-ecr-role"
    ManagedBy = "Terraform"
  }
}

data "aws_iam_policy_document" "agent_ecr" {
  # GetAuthorizationToken is not resource-scoped in the ECR API.
  statement {
    sid       = "AuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushPullToRepository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_iam_policy" "agent_ecr" {
  name        = "${var.release_name}-agent-ecr-policy"
  description = "Push/pull rights on the Django ECR repository"
  policy      = data.aws_iam_policy_document.agent_ecr.json

  tags = {
    Name      = "${var.release_name}-agent-ecr-policy"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "agent_ecr" {
  role       = aws_iam_role.agent.name
  policy_arn = aws_iam_policy.agent_ecr.arn
}
