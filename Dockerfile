# Etapa 1: instalar dependencias y ejecutar pruebas
FROM node:24-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci

COPY server.js db.js server.test.js ./
COPY public ./public

RUN npm test


# Etapa 2: imagen final de producción
FROM node:24-alpine

ENV NODE_ENV=production

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev \
    && npm cache clean --force \
    && rm -rf /usr/local/lib/node_modules/npm \
               /usr/local/bin/npm \
               /usr/local/bin/npx

COPY --from=builder /app/server.js ./server.js
COPY --from=builder /app/db.js ./db.js
COPY --from=builder /app/public ./public

RUN mkdir -p /app/data \
    && chown -R node:node /app

USER node

EXPOSE 3000

CMD ["node", "server.js"]
