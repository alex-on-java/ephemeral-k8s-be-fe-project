# Multi-stage build for Bun + Vite + React with Nginx serving

# ============================================
# Stage 1: Base
# ============================================
FROM oven/bun:1 AS base
WORKDIR /app

# ============================================
# Stage 2: Install dependencies
# ============================================
FROM base AS deps

# Copy package files and bun config
COPY package.json bun.lock bunfig.toml ./

# Set npm registry to public (override corporate registry)
ENV BUN_INSTALL_REGISTRY="https://registry.npmjs.org/"

# Install dependencies with frozen lockfile
RUN bun install --frozen-lockfile

# ============================================
# Stage 3: Build application
# ============================================
FROM base AS builder

# Copy dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy source files
COPY . .

# Build argument for API base URL
ARG VITE_API_BASE_URL=""
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

# Set production environment
ENV NODE_ENV=production

# Build the Vite application
RUN bun run build

# ============================================
# Stage 4: Production runtime with Nginx
# ============================================
FROM nginx:alpine AS runner

# Copy built static files
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Nginx runs as default CMD from base image
