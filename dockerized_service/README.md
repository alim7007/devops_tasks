- ✅ 15. Dockerized Service Task from https://roadmap.sh/projects/dockerized-service-deployment

# Node.js Dockerized Service with CI/CD

A simple Node.js service with Basic Authentication, containerized with Docker and automatically deployed using GitHub Actions.

## Features

- Simple Express.js API with two routes
- Basic Authentication for protected endpoint
- Dockerized application
- Automated deployment via GitHub Actions
- Secrets management

## Project Structure

```
.
├── .github/workflows/deploy.yml    # CI/CD pipeline
├── .dockerignore                   # Docker ignore file
├── .env                           # Environment variables (not committed)
├── Dockerfile                     # Docker configuration
├── index.js                       # Main application
├── package.json                   # Dependencies
└── README.md                      # Documentation
```

## Local Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Create .env File

```env
PORT=3000
USERNAME=admin
PASSWORD=your_password
SECRET_MESSAGE=This is a secret!
```

### 3. Run Locally

```bash
npm start
```

Test the endpoints:
```bash
# Home route
curl http://localhost:3000/

# Protected route (requires auth)
curl -u admin:your_password http://localhost:3000/secret
```

## Docker Setup

### Build Image

```bash
docker build -t node-service .
```

### Run Container

```bash
docker run -d \
  --name node-service \
  -p 3000:3000 \
  -e USERNAME="admin" \
  -e PASSWORD="your_password" \
  -e SECRET_MESSAGE="This is secret!" \
  node-service
```

### Test Container

```bash
curl http://localhost:3000/
curl -u admin:your_password http://localhost:3000/secret
```

## Remote Server Setup

### 1. Create a Linux Server

Use DigitalOcean, AWS, or any VPS provider with Ubuntu 22.04.

### 2. Install Docker on Server

```bash
ssh root@YOUR_SERVER_IP

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Configure firewall
ufw allow OpenSSH
ufw allow 3000/tcp
ufw enable
```

### 3. Setup SSH Key

On your **local machine**:

```bash
# Generate SSH key (no passphrase)
ssh-keygen -t ed25519 -f ~/.ssh/github_actions -N ""

# Copy to server
ssh-copy-id -i ~/.ssh/github_actions.pub root@YOUR_SERVER_IP

# Test connection
ssh -i ~/.ssh/github_actions root@YOUR_SERVER_IP
```

## GitHub Actions Deployment

### 1. Add GitHub Secrets

Go to: **Repository Settings → Secrets and variables → Actions**

Add these secrets:

| Secret Name | Value | Example |
|------------|-------|---------|
| `SSH_PRIVATE_KEY` | Private key content | Copy from `cat ~/.ssh/github_actions` |
| `SERVER_HOST` | Server IP | `165.232.123.45` |
| `SERVER_USER` | SSH username | `root` |
| `APP_USERNAME` | Basic auth user | `admin` |
| `APP_PASSWORD` | Basic auth password | `secure_pass` |
| `SECRET_MESSAGE` | Secret message | `Welcome!` |

**Important:** When copying `SSH_PRIVATE_KEY`, include the entire key with `-----BEGIN` and `-----END` lines.

### 2. Deploy

Push to main branch:

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

Or trigger manually from GitHub Actions tab.

## API Endpoints

### GET /
Returns "Hello, world!"

```bash
curl http://YOUR_SERVER_IP:3000/
```

### GET /secret
Protected endpoint requiring Basic Authentication.

```bash
curl -u username:password http://YOUR_SERVER_IP:3000/secret
```

Response:
```json
{
  "message": "This is a secret message!"
}
```

## Troubleshooting

### SSH Authentication Failed

```bash
# Ensure key has no passphrase
ssh-keygen -t ed25519 -f ~/.ssh/new_key -N ""

# Copy to server
ssh-copy-id -i ~/.ssh/new_key.pub root@YOUR_SERVER_IP

# Test locally first
ssh -i ~/.ssh/new_key root@YOUR_SERVER_IP

# Copy entire private key to GitHub (including BEGIN/END lines)
cat ~/.ssh/new_key
```

### Container Won't Start

```bash
# Check logs
docker logs node-service

# Verify environment variables
docker exec node-service env | grep -E 'USERNAME|PASSWORD'
```

### Can't Access from Browser

```bash
# Check if running
docker ps

# Check firewall
ufw status

# Test locally on server
curl http://localhost:3000/
```

## Technologies Used

- Node.js + Express
- Docker
- GitHub Actions
- GitHub Container Registry