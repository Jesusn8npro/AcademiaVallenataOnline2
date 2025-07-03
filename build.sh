#!/bin/bash

echo "🚀 Iniciando build de Academia Online..."

# Verificar que Node.js esté instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado"
    exit 1
fi

echo "✅ Node.js versión: $(node --version)"
echo "✅ NPM versión: $(npm --version)"

# Limpiar cache de npm
echo "🧹 Limpiando cache..."
npm cache clean --force

# Instalar dependencias
echo "📦 Instalando dependencias..."
npm ci --production=false

# Sincronizar SvelteKit
echo "🔄 Sincronizando SvelteKit..."
npm run prepare

# Construir aplicación
echo "🏗️ Construyendo aplicación..."
npm run build

echo "✅ Build completado exitosamente!"
echo "📁 Archivos de salida en: ./build/"

# Verificar que el build existe
if [ -d "build" ]; then
    echo "✅ Directorio build creado correctamente"
    echo "📊 Tamaño del build:"
    du -sh build/
else
    echo "❌ Error: No se pudo crear el directorio build"
    exit 1
fi 