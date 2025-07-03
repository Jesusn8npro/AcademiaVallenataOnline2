# Usar imagen oficial de Node.js
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de package
COPY package*.json ./

# Instalar todas las dependencias (incluidas dev para build)
RUN npm ci

# Copiar código fuente
COPY . .

# Build de la aplicación (sin variables sensibles)
ENV NODE_ENV=production
RUN npm run build

# Limpiar devDependencies para reducir tamaño
RUN npm prune --production

# Variables de runtime
ENV PORT=3000

# Exponer puerto
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["node", "build/index.js"] 