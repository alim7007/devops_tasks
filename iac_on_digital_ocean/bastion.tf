resource "digitalocean_droplet" "bastion" {
  image    = var.image
  name     = "bastion-${var.name}-${var.region}"
  region   = var.region
  size     = var.bastion_size
  vpc_uuid = digitalocean_vpc.web.id
  tags     = ["${var.name}-webserver"] # tag also grants DB access via DB firewall
  ssh_keys = [data.digitalocean_ssh_key.main.id]

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion firewall
resource "digitalocean_firewall" "bastion" {
  name        = "${var.name}-only-ssh-bastion"
  droplet_ids = [digitalocean_droplet.bastion.id]

  # SSH from your IP(s). Default open for quick start; tighten later.
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_cidrs
  }

  # Bastion can reach anything in VPC (SSH to apps, connect to DB)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = [digitalocean_vpc.web.ip_range]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = [digitalocean_vpc.web.ip_range]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = [digitalocean_vpc.web.ip_range]
  }

  # Let bastion update packages / fetch tools
  outbound_rule {
    protocol              = "udp"
    port_range            = "53"  # DNS
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"  # HTTP
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "443" # HTTPS
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}


