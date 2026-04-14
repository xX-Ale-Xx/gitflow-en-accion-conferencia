FROM node:18-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

COPY pnpm-lock.yaml package.json ./

RUN pnpm install --frozen-lockfile

COPY . .

RUN pnpm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Install dumb-init and pnpm
RUN apk add --no-cache dumb-init && npm install -g pnpm

# Create non-root user with different UID/GID to avoid conflicts
RUN addgroup -g 10001 nestjs && adduser -D -u 10001 -G nestjs nestjs

COPY pnpm-lock.yaml package.json ./

RUN pnpm install --frozen-lockfile --prod && pnpm store prune

COPY --from=builder /app/dist ./dist

COPY --chown=nestjs:nestjs . .

USER nestjs

EXPOSE 3000

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/main.js"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/docs', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"
