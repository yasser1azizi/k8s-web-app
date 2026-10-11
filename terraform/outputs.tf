output "cluster_name" {
  description = "Name of the Kind cluster"
  value       = var.cluster_name
}

output "kind_config_path" {
  description = "Path to the generated Kind configuration"
  value       = local_file.kind_config.filename
}