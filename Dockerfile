# --- Etapa 1: Construcción y Pruebas (builder) ---
FROM node:20-alpine AS builder
WORKDIR /app

# Copiamos solo los archivos de dependencias primero para aprovechar la caché de Docker
COPY package*.json ./
RUN npm ci

# ¡AQUÍ ESTABA EL ERROR 1! Faltaba esta línea para copiar el resto del código
COPY . .

# Ejecutar las pruebas
RUN npm test

# --- Etapa 2: Imagen final ligera ---
FROM node:20-alpine
RUN apk upgrade --no-cache
WORKDIR /app

# Copiamos dependencias y configuraciones
COPY package*.json ./
RUN npm ci --omit=dev

# Actualizamos npm global para parchear la vulnerabilidad de 'tar' interna de npm
RUN npm install -g npm@latest

# ¡AQUÍ ESTABA EL ERROR 2! Copiamos los archivos sueltos porque no tienes carpeta "src"
COPY --from=builder /app/server.js ./
COPY --from=builder /app/db.js ./
COPY --from=builder /app/public ./public

EXPOSE 3000

# Comandos para iniciar la aplicación (mejor práctica: usar node directamente)
CMD ["node", "server.js"]
