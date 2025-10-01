output "load_balancer_ip" {
  description = "Public IP of the Load Balancer (visit http://IP)"
  value       = digitalocean_loadbalancer.web.ip
}

output "web_private_ips" {
  description = "Private IPs of web droplets in the VPC"
  value       = [for d in digitalocean_droplet.web : d.ipv4_address_private]
}

output "web_public_ips" {
  description = "Public IPs of web droplets (not used for ingress)"
  value       = [for d in digitalocean_droplet.web : d.ipv4_address]
}

output "bastion_public_ip" {
  description = "Public IP of the bastion (SSH: root@IP)"
  value       = digitalocean_droplet.bastion.ipv4_address
}

output "bastion_private_ip" {
  description = "Private IP of the bastion (inside VPC)"
  value       = digitalocean_droplet.bastion.ipv4_address_private
}

# Managed DB useful connection info (using try() so outputs don't crash if attrs vary)
output "db_private_host" {
  description = "Private hostname of the Managed DB (use inside VPC)"
  value       = try(digitalocean_database_cluster.postgres-cluster.private_host, null)
}

output "db_port" {
  description = "Managed DB port"
  value       = try(digitalocean_database_cluster.postgres-cluster.port, 5432)
}

output "db_user" {
  description = "Managed DB admin user"
  value       = try(digitalocean_database_cluster.postgres-cluster.user, null)
  sensitive   = true
}

output "db_password" {
  description = "Managed DB password"
  value       = try(digitalocean_database_cluster.postgres-cluster.password, null)
  sensitive   = true
}

output "db_private_uri" {
  description = "Private URI for connecting from inside VPC"
  value       = try(digitalocean_database_cluster.postgres-cluster.private_uri, null)
  sensitive   = true
}
