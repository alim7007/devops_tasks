resource "digitalocean_droplet" "cicd" {
  count    = var.droplet_count
  image    = var.image
  name     = "cicd-${var.name}-${var.region}-${count.index + 1}"
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = data.digitalocean_vpc.main.id
  tags     = ["${var.name}-cicd-runner"]

  ssh_keys = [data.digitalocean_ssh_key.main.id]

  lifecycle {
    create_before_destroy = true
  }
}