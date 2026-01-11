# ---------- Build stage ----------
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY src ./src

# ---------- Runtime stage ----------
FROM node:18-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -S nodejs && adduser -S nodejs -G nodejs

# Copy app files
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src

# FIX: create logs directory and set permissions
RUN mkdir logs && chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

CMD ["node", "src/index.js"]
