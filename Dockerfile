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

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=3000

# Build de la aplicación
RUN npm run build

# Limpiar devDependencies para reducir tamaño
RUN npm prune --production

# Exponer puerto
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["node", "build/index.js"] 