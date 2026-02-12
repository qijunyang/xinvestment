# Docker Development Guide

## Local Development with Docker

### Prerequisites
- Docker Desktop installed
- Docker Compose installed (included with Docker Desktop)

### Quick Start

1. **Build and start the application:**
   ```bash
   docker-compose up --build
   
   # Or using npm script
   npm run docker:up
   
   # Or using PowerShell helper script
   .\docker-run.ps1 up
   ```

2. **Access the application:**
   - App: http://localhost:3000
   - Health check: http://localhost:3000/api/health

3. **Stop the application:**
   ```bash
   docker-compose down
   
   # Or using npm script
   npm run docker:down
   ```

### Docker Commands

**Using npm scripts (recommended):**
```bash
npm run docker:up      # Build and start
npm run docker:down    # Stop
npm run docker:logs    # View logs
npm run docker:clean   # Clean up volumes
```

**Using PowerShell helper script:**
```bash
.\docker-run.ps1 up       # Start
.\docker-run.ps1 down     # Stop
.\docker-run.ps1 logs     # View logs
.\docker-run.ps1 restart  # Restart
.\docker-run.ps1 clean    # Clean up
```

**Using docker-compose directly:**

**Build the image:**
```bash
docker-compose build
```

**Start in detached mode (background):**
```bash
docker-compose up -d
```

**View logs:**
```bash
docker-compose logs -f app
```

**Restart the service:**
```bash
docker-compose restart app
```

**Stop and remove containers:**
```bash
docker-compose down
```

**Remove volumes (clean slate):**
```bash
docker-compose down -v
```

### Development vs Production

**Development mode** (current docker-compose.yml):
- Source code mounted as volume
- Changes reflect immediately
- Suitable for local testing

**Production-like testing:**
Comment out the volumes section in docker-compose.yml to test the actual built image.

### Build Without Compose

**Build the Docker image directly:**
```bash
docker build -t xinvestment:local .
```

**Run the container:**
```bash
docker run -p 3000:3000 \
  -e NODE_ENV=development \
  -e PORT=3000 \
  -e ENV=dev \
  --name xinvestment-app \
  xinvestment:local
```

**Stop the container:**
```bash
docker stop xinvestment-app
docker rm xinvestment-app
```

### Troubleshooting

**Port already in use:**
```bash
# Stop local Node.js process
Stop-Process -Name node -Force -ErrorAction SilentlyContinue

# Or change the port in docker-compose.yml
ports:
  - "3001:3000"
```

**Container won't start:**
```bash
# Check logs
docker-compose logs app

# Check if container is running
docker ps -a

# Remove and rebuild
docker-compose down
docker-compose up --build
```

**Permission issues:**
```bash
# On Windows, ensure Docker Desktop is running with proper permissions
# On Linux, you may need to add your user to the docker group
sudo usermod -aG docker $USER
```

### Health Check

The container includes a health check that runs every 30 seconds:
```bash
# Check container health status
docker ps

# Manually test health endpoint
curl http://localhost:3000/api/health
```

### Environment Variables

Copy `.env.example` to `.env` and customize:
```bash
cp .env.example .env
```

Then update docker-compose.yml to use the .env file:
```yaml
env_file:
  - .env
```

### Multi-stage Build

The Dockerfile uses multi-stage builds:
1. **Builder stage**: Installs dependencies and builds assets
2. **Production stage**: Copies only necessary files, runs as non-root user

This results in a smaller, more secure image.

### Image Size

Check the built image size:
```bash
docker images xinvestment
```

Expected size: ~200-300 MB (Node.js Alpine based)
