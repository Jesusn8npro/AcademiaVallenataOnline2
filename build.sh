#!/bin/bash
set -e

echo "🚀 Iniciando build personalizado..."

# Instalar dependencias
echo "📦 Instalando dependencias..."
npm install

# Verificar que vite esté instalado
echo "🔍 Verificando Vite..."
npx vite --version

# Build de la aplicación
echo "🏗️ Building aplicación..."
NODE_ENV=production npx vite build

echo "✅ Build completado!" 