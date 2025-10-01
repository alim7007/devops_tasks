variable "do_token" {
  type        = string
  description = "Digital Ocean personal access token"
  sensitive   = true
}

variable "name" {
  type        = string
  description = "Infrastructure project name"
  default     = "tf-digitalocean"
}

variable "region" {
  type    = string
  description = "DigitalOcean region"
  default = "ams3"
}

variable "ip_range" {
  type        = string
  description = "IP range for VPC"
  default     = "192.168.22.0/24"
}

###

variable "droplet_count" {
  type    = number
  description = "How many web servers to create"
  default = 2
}

variable "image" {
  type        = string
  description = "OS to install on the servers"
  default     = "ubuntu-25-04-x64"
}

variable "droplet_size" {
  type    = string
  description = "Droplet size slug"
  default = "s-2vcpu-2gb"
}

variable "ssh_key" {
  type = string
  description = "DigitalOcean SSH key name to inject into droplets"
  default = "alim_mac" # DO > Settings > Security > SSH Keys
}

# variable "subdomain" {
#   type = string
# }

# variable "domain_name" {
#   type = string
# }

# Managed Postgres
variable "db_count" {
  type    = number
  description = "Managed DB node count"
  default = 1
}

variable "database_size" {
  type    = string
  description = "Managed DB size slug"
  default = "db-s-1vcpu-1gb"
}

variable "bastion_size" {
  type    = string
  description = "Managed DB size slug"
  default = "s-1vcpu-1gb"
}

variable "db_region" {
  type    = string
  description = "DigitalOcean region"
  default = "ams3"
}

# Bastion SSH allowlist (CIDRs). Defaults open for quick start; tighten later.
variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH into bastion (use /32 for your IP)"
  default     = ["95.0.73.247/32"]
}
