# Dockerfile para Academia Vallenata Online - FIXED
FROM node:18-slim

# Instalar dependencias del sistema necesarias
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Establecer directorio de trabajo
WORKDIR /app

# Configurar variables de entorno para Node.js
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias con más memoria
RUN npm ci --production=false --maxsockets 1

# Copiar código fuente
COPY . .

# Build de la aplicación con más memoria y configuración segura
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build

# Remover devDependencies para reducir tamaño
RUN npm prune --production

# Crear usuario no root para seguridad
RUN groupadd -r academia && useradd -r -g academia academia
RUN chown -R academia:academia /app
USER academia

# Exponer puerto
EXPOSE 3000

# Variables de entorno finales
ENV PORT=3000

# Comando de inicio
CMD ["node", "build/index.js"] 