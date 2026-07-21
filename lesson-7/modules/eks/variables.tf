variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version."
  type        = string
  default     = "1.30"
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
  description = "Maximum number of worker nodes (must be > 1 so HPA pods can schedule)."
  type        = number
  default     = 3
}
