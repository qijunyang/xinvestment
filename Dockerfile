# Multi-stage build for Node.js application
# Assumes client bundles are pre-built locally before docker build

# Stage 1: Dependencies installation
FROM node:18-alpine AS deps

WORKDIR /app

COPY package*.json ./

# Install only production dependencies
RUN npm config set strict-ssl false && npm install --production --legacy-peer-deps

# Final production image
FROM node:18-alpine

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Copy production dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

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

# Copy public assets
COPY public ./public

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

# Build-time sanity checks for dependencies
RUN ls -la /app \
    && ls -la /app/node_modules \
    && test -d /app/node_modules/express

# Start application
CMD ["node", "src/app.js"]
