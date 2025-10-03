output "cicd_public_ips" {
  description = "Public IPs of cicd droplet"
  value       = [for d in digitalocean_droplet.cicd : d.ipv4_address]
}

output "cicd_private_ips" {
  description = "Public IPs of cicd droplet"
  value       = [for d in digitalocean_droplet.cicd : d.ipv4_address_private]
}