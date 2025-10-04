- ✅ 15. Dockerized Service Task from https://roadmap.sh/projects/dockerized-service-deployment



curl -u admin:alimchik http://localhost:3000/secret
# -> {"message":"This is the secret"}

curl -u admin:wrong http://localhost:3000/secret -i
# -> HTTP/1.1 401 Unauthorized
# -> {"error":"Unauthorized: invalid username or password."}


ssh root@your-server-ip

# Update packages
   apt update && apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Start Docker service
   systemctl start docker
   systemctl enable docker
   
   # Verify installation
   docker --version


docker login ghcr.io -u USERNAME -p YOUR_PAT