# VPC for all private traffic
resource "digitalocean_vpc" "web" {
  name     = "${var.name}-vpc"
  region   = var.region
  ip_range = var.ip_range
}