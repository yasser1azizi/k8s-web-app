terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {}

resource "terraform_data" "kind_cluster" {
  input = var.cluster_name

  provisioner "local-exec" {
    command = <<-EOT
      if kind get clusters | grep -Fxq "${var.cluster_name}"; then
        echo "Kind cluster '${var.cluster_name}' already exists. Leaving it unchanged."
      else
        kind create cluster --name "${var.cluster_name}"
      fi
    EOT
  }
}

resource "local_file" "kind_config" {

  filename = "${path.module}/kind-config.yaml"

  content = <<-EOT
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    name: ${var.cluster_name}
    nodes:
      - role: control-plane
        extraPortMappings:
          - containerPort: 30080
            hostPort: 8080
            protocol: TCP
    networking:
      apiServerAddress: "127.0.0.1"
      apiServerPort: ${var.api_host_port}
  EOT
}