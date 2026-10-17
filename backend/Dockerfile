# --- Build stage ---
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npx prisma generate
RUN npm run build

# --- Runtime stage ---
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev && npx prisma generate
COPY --from=build /app/dist ./dist

# Run as non-root — never run a production container as root.
RUN addgroup -S moka && adduser -S moka -G moka
USER moka

EXPOSE 4000
CMD ["node", "dist/server.js"]
