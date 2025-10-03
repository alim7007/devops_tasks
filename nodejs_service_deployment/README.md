- ✅ 14. Node.js Service Deployment Task from https://roadmap.sh/projects/nodejs-service-deployment


later example for raport shortly for all details of steps:
1.3 Bastion Firewall Update - INCOMPLETE
terraform# In iac_on_digital_ocean/variables.tf
default = ["95.0.73.247/32", "cicd_runner_ip_later will be added/32"]
Problem: You can't add the IP before creating the droplet.
Solution: Two-step process:
Step 1: Create CI/CD droplet first:
bashcd nodejs_service_deployment/terraform
terraform init
terraform apply
# Get the output IP
terraform output cicd_public_ip
Step 2: Update bastion firewall:
terraform# In iac_on_digital_ocean/variables.tf
default = ["95.0.73.247/32", "YOUR_CICD_IP/32"]  # Replace with actual IP
bashcd ../../iac_on_digital_ocean
terraform apply

Create /home/github-runner/.ssh/config:
Host do-bastion
    HostName 152.42.135.12
    User root
    IdentityFile ~/.ssh/id_ed25519

Host web1
    HostName 192.168.22.4
    User root
    ProxyJump do-bastion

Host web2
    HostName 192.168.22.3
    User root
    ProxyJump do-bastion
##########################
##########################
##########################


before further check i would like to take sensitive variable to tf.vars or something else
because my ip and cicd_droplet ip is in my code hardcoded and also ip range, but i dont know is it ok for ip range or not, neither would take all of sensitive to somewhere else.

and i thought vpc would not be necessary , because i want cicd-runner outside of vpc, because it comes from after bastion, i think you gonna agree with me , it seems logicaly correct:
data "digitalocean_vpc" "main" {
  name = "tf-digitalocean-vpc"
}

prevousely ~/.ssh/digital-ocean i used ssh -A root@do-bastion and then to ssh root@web1
but now i need github action to take my ~/.ssh/digital-ocean to put inside cicd runner and do the same step
but with ansible, i guess we should use proxyjump, but i dont know how it gonna work out.
the way you are saying , i need to create another ssh key  ~/.ssh/id_ed25519 but i dont want that

i chose Option 2: Clone and move (Hacky)

and i did create another node.conf.j2 but should i specify it somewhere somehow?
i mean like what i did with dafault.conf.j2 in roles/nginx/template/tasks/main.yaml
- name: Deploy default server block (conf.d)
  ansible.builtin.template:
    src: default.conf.j2
    dest: /etc/nginx/conf.d/default.conf
    owner: root
    group: root
    mode: '0644'
  notify: restart nginx

##########################
check for PHASE 4: CI/CD Runner Setup