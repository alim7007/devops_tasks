- ✅ 14. Node.js Service Deployment Task from https://roadmap.sh/projects/nodejs-service-deployment

1.
i did but used private ip of cicd droplet
# Bastion SSH allowlist (CIDRs). for own ip and do_cicd private ip
variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH into bastion (use /32 for your IP)"
  default     = ["95.0.73.247/32", "192.168.22.7/32"]
}
and applied

2.
i used 
  vpc_uuid = data.digitalocean_vpc.main.id
and
  data "digitalocean_vpc" "main" {
  name = "tf-digitalocean-vpc"
  }

iac_on_digital_ocean
tf output
bastion_private_ip = "192.168.22.2"
bastion_public_ip = "152.42.135.12"
db_password = <sensitive>
db_port = 25060
db_private_host = "private-tf-digitalocean-database-cluster-do-user-26228914-0.k.db.ondigitalocean.com"
db_private_uri = <sensitive>
db_user = <sensitive>
load_balancer_ip = "64.225.82.128"
web_private_ips = [
  "192.168.22.4",
  "192.168.22.3",
]
web_public_ips = [
  "104.248.207.175",
  "142.93.131.30",
]


nodejs_service_deployment/terraform
tf output
cicd_private_ips = [
  "192.168.22.7",
]
cicd_public_ips = [
  "64.227.71.89",
]


3.
if you mean cicd.tf, there is no firewall things
just only 
  ssh_keys = [data.digitalocean_ssh_key.main.id]
variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH into bastion (use /32 for your IP)"
  default     = ["95.0.73.247/32"]
}
i think description is not correct