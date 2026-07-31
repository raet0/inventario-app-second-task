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
RUN npm ci --only=production

# ¡AQUÍ ESTABA EL ERROR 2! Copiamos los archivos sueltos porque no tienes carpeta "src"
COPY --from=builder /app/server.js ./
COPY --from=builder /app/db.js ./
COPY --from=builder /app/public ./public

EXPOSE 3000

# Comandos para iniciar la aplicación
CMD ["npm", "start"]
