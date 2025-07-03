FROM node:18

# Establece el directorio de trabajo
WORKDIR /app

# Copia los archivos del proyecto
COPY . .

# Instala dependencias
RUN npm install

# Compila el proyecto
RUN npm run build

# Puerto para preview de Vite
EXPOSE 4173

# Comando para correr el servidor
CMD ["npm", "run", "preview"]
