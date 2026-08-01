variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version."
  type        = string
  default     = "1.34"
}

variable "node_ami_type" {
  description = "AMI family for the managed node group."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "subnet_ids" {
  description = "Subnets for the EKS control-plane ENIs (public + private)."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets where worker nodes are placed."
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "enable_metrics_server" {
  description = "Install metrics-server as an EKS add-on. Required by the HPA to read CPU utilisation."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

variable "create_storage_class" {
  description = "Create the gp3 StorageClass. Disable if a class of that name already exists in the cluster."
  type        = bool
  default     = true
}

variable "storage_class_name" {
  description = "Name of the gp3 StorageClass used by Jenkins and Prometheus."
  type        = string
  default     = "gp3"
}

variable "storage_class_default" {
  description = "Mark the gp3 StorageClass as the cluster default."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Cluster Autoscaler
# ---------------------------------------------------------------------------

variable "enable_cluster_autoscaler" {
  description = "Install cluster-autoscaler so Pending pods trigger new nodes between node_min_size and node_max_size."
  type        = bool
  default     = true
}

variable "cluster_autoscaler_chart_version" {
  description = "Version of the autoscaler/cluster-autoscaler Helm chart."
  type        = string
  default     = "9.59.0"
}

variable "cluster_autoscaler_service_account" {
  description = "ServiceAccount the cluster-autoscaler controller runs as, in kube-system."
  type        = string
  default     = "cluster-autoscaler"
}
