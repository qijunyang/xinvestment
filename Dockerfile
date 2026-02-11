# Multi-stage build for Node.js application
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Build client assets
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Copy dependencies from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy package.json
COPY package*.json ./

# Copy server code
COPY src/app.js ./src/
COPY src/init.js ./src/
COPY src/config ./src/config
COPY src/controllers ./src/controllers
COPY src/middleware ./src/middleware
COPY src/routes ./src/routes
COPY src/services ./src/services

# Copy built client assets
COPY --from=builder /app/dist ./dist

# Copy client source files (needed for serving)
COPY src/client ./src/client

# Create a non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start application
CMD ["node", "src/app.js"]
