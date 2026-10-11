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

