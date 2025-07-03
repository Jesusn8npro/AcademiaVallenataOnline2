# Usar imagen oficial de Node.js
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de package
COPY package*.json ./

# Instalar TODAS las dependencias (dev + production)
RUN npm install

# Copiar código fuente
COPY . .

# Build de la aplicación
ENV NODE_ENV=production
RUN npm run build

# Limpiar devDependencies después del build
RUN npm prune --production

# Variables de runtime
ENV PORT=3000

# Exponer puerto
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["node", "build/index.js"] 