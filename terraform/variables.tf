variable "cluster_name" {
  description = "Name of the local Kind Kubernetes cluster"
  type        = string
  default     = "devops-cluster"
}

variable "api_host_port" {
  description = "Port for the local Kind Kubernetes cluster"
  type        = number
  default     = 6443
}
