- ✅ 16. Multi-Container Application Task from https://roadmap.sh/projects/multi-container-service

# Todo API with Docker Compose

A multi-container Todo API application using Node.js, MongoDB, and Nginx reverse proxy, deployed with Docker Compose and GitHub Actions.

## Features

- RESTful API for todo management
- MongoDB for data persistence
- Nginx reverse proxy (works with IP address)
- Docker Compose for multi-container orchestration
- Automated CI/CD with GitHub Actions

## Project Structure

```
.
├── .github/workflows/deploy.yml
├── .dockerignore
├── docker-compose.yml
├── Dockerfile
├── nginx.conf
├── index.js
├── package.json
└── README.md
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Health check |
| GET | `/todos` | Get all todos |
| POST | `/todos` | Create a new todo |
| GET | `/todos/:id` | Get a single todo |
| PUT | `/todos/:id` | Update a todo |
| DELETE | `/todos/:id` | Delete a todo |

## Local Development

### Prerequisites

- Docker and Docker Compose installed
- Node.js 20+ (for local development without Docker)

### Run with Docker Compose

```bash
# Build and start all containers
docker-compose up -d

# View logs
docker-compose logs -f

# Stop containers
docker-compose down

# Stop and remove volumes (deletes data)
docker-compose down -v
```

Access the API:
- **With Nginx:** http://localhost
- **Direct API:** http://localhost:3000

### Run Locally (without Docker)

```bash
# Install dependencies
npm install

# Start MongoDB (requires MongoDB installed)
mongod

# Start API
npm run dev
```

## Testing the API

### Create a todo
```bash
curl -X POST http://localhost/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Docker Compose", "completed": false}'
```

### Get all todos
```bash
curl http://localhost/todos
```

### Get a single todo
```bash
curl http://localhost/todos/<todo_id>
```

### Update a todo
```bash
curl -X PUT http://localhost/todos/<todo_id> \
  -H "Content-Type: application/json" \
  -d '{"completed": true}' 
```

### Delete a todo
```bash
curl -X DELETE http://localhost/todos/<todo_id>
```

## Remote Deployment

### Step 1: Server Setup (Reusing Existing Server)

Since you already have a server from the previous project:

```bash
# SSH into your server
ssh root@YOUR_SERVER_IP

# Install Docker Compose if not already installed
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version

# Update firewall (add port 80 for Nginx)
ufw allow 80/tcp
ufw status
```

### Step 2: GitHub Secrets

You can reuse most secrets from the previous project. Ensure you have:

| Secret Name | Value |
|------------|-------|
| `SSH_PRIVATE_KEY` | Your SSH private key |
| `SERVER_HOST` | Your server IP |
| `SERVER_USER` | SSH username (e.g., `root`) |

The `GITHUB_TOKEN` is automatically available in GitHub Actions.

### Step 3: Deploy

```bash
git add .
git commit -m "Add todo API with docker-compose"
git push origin main
```

### Step 4: Access the Application

**With Nginx (Port 80):**
```bash
# Health check
curl http://YOUR_SERVER_IP/health

# API endpoints
curl http://YOUR_SERVER_IP/todos
```

**Direct API (Port 3000):**
```bash
curl http://YOUR_SERVER_IP:3000/todos
```

## Docker Compose Services

### MongoDB
- **Image:** mongo:7-jammy
- **Port:** 27017 (internal only)
- **Volume:** Persistent data storage
- **Network:** todo-network

### API
- **Build:** From local Dockerfile
- **Port:** 3000 (exposed)
- **Environment:**
  - PORT=3000
  - MONGODB_URI=mongodb://mongodb:27017/todos
- **Depends on:** MongoDB (with health check)

### Nginx
- **Image:** nginx:alpine
- **Port:** 80 (exposed)
- **Configuration:** Custom nginx.conf
- **Purpose:** Reverse proxy to API

## Nginx Reverse Proxy

### Why use Nginx with IP address?

✅ **Works without domain:**
- `server_name _;` accepts any hostname/IP
- Access via http://YOUR_SERVER_IP

✅ **Benefits:**
- Single port (80) for all traffic
- Load balancing capability
- Static file serving
- SSL/TLS termination (if you add certificate)
- Request logging and monitoring

### Configuration Highlights

```nginx
server {
    listen 80;
    server_name _;  # Accepts any IP/hostname
    
    location / {
        proxy_pass http://api:3000;
        # Headers for proper proxying
    }
}
```

## Data Persistence

MongoDB data is stored in a Docker volume:

```bash
# View volumes
docker volume ls

# Inspect volume
docker volume inspect todo-app_mongodb_data

# Backup data
docker run --rm -v todo-app_mongodb_data:/data -v $(pwd):/backup mongo:7-jammy tar czf /backup/mongodb-backup.tar.gz /data

# Restore data
docker run --rm -v todo-app_mongodb_data:/data -v $(pwd):/backup mongo:7-jammy tar xzf /backup/mongodb-backup.tar.gz -C /
```

## Troubleshooting

### Containers won't start

```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs api
docker-compose logs mongodb

# Restart services
docker-compose restart
```

### MongoDB connection error

```bash
# Check if MongoDB is healthy
docker-compose ps

# Wait for MongoDB to be ready
docker-compose up -d mongodb
sleep 10
docker-compose up -d api
```

### Port conflicts

If port 80 or 3000 is already in use:

```bash
# Check what's using the port
sudo lsof -i :80
sudo lsof -i :3000

# Stop conflicting service
docker stop <container_name>
```

### API not accessible via Nginx

```bash
# Check Nginx configuration
docker exec todo-nginx nginx -t

# Check Nginx logs
docker logs todo-nginx

# Test direct API access
curl http://localhost:3000/todos
```

### Data not persisting

```bash
# Check volumes
docker volume ls

# Don't use -v flag when stopping
docker-compose down  # ✅ Keeps data
docker-compose down -v  # ❌ Deletes data
```

## CI/CD Pipeline

The GitHub Actions workflow:

1. **Build Phase**
   - Builds Docker image
   - Pushes to GitHub Container Registry

2. **Deploy Phase**
   - SSHs to remote server
   - Creates docker-compose.yml and nginx.conf
   - Pulls latest image
   - Starts all containers with docker-compose

## Production Considerations

### Security
- [ ] Add authentication to API endpoints
- [ ] Use MongoDB with authentication
- [ ] Setup HTTPS with Let's Encrypt (if you get a domain)
- [ ] Implement rate limiting

### Monitoring
- [ ] Add logging aggregation
- [ ] Setup health check endpoints
- [ ] Monitor container metrics

### Backup
- [ ] Automate MongoDB backups
- [ ] Store backups off-server
- [ ] Test restore procedures

## Technologies

- **Node.js** - Runtime
- **Express** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration
- **Nginx** - Reverse proxy
- **GitHub Actions** - CI/CD