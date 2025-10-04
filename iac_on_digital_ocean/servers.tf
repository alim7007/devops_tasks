# Web Droplets (Nginx demo)
resource "digitalocean_droplet" "web" {
  count    = var.droplet_count
  image    = var.image
  name     = "web-${var.name}-${var.region}-${count.index + 1}"
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = digitalocean_vpc.web.id
  tags     = ["${var.name}-webserver"]

  # Inject your SSH key (looked up by name in data.tf)
  ssh_keys = [data.digitalocean_ssh_key.main.id]

  # cloud-init to install nginx and drop a tiny marker page
  user_data = <<EOF
#cloud-config
packages:
  - nginx
runcmd:
  - [ sh, -xc, "echo '<h1>web-${var.region}-${count.index + 1}</h1>' > /var/www/html/index.html" ]
  - [ systemctl, enable, --now, nginx ]
EOF

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP-only Load Balancer (no TLS, no domain)
resource "digitalocean_loadbalancer" "web" {
  name        = "web-${var.region}"
  region      = var.region
  vpc_uuid    = digitalocean_vpc.web.id
  droplet_ids = digitalocean_droplet.web.*.id

  # Only HTTP -> HTTP
  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"
    target_port     = 80
    target_protocol = "http"
  }

  # Optional: simple health check
  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_firewall" "web" {
  name        = "${var.name}-web-fw"
  droplet_ids = digitalocean_droplet.web[*].id

  # Inbound from VPC only
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"  # LB -> app
    source_addresses = [digitalocean_vpc.web.ip_range]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"  # bastion -> SSH
    source_addresses = [digitalocean_vpc.web.ip_range]
  }
  inbound_rule {
    protocol         = "icmp"  # ping from VPC
    source_addresses = [digitalocean_vpc.web.ip_range]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "3000"
    source_addresses = ["192.168.22.0/24"]  # Only from VPC
  }

  # Outbound within VPC
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

  # Internet essentials (apt, docker pulls, APIs, ping)
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
  outbound_rule {
    protocol              = "icmp" # ping
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}






