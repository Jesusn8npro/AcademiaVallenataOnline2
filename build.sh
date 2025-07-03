#!/bin/bash
set -e

echo "🔧 Starting build process..."

echo "📦 Installing dependencies..."
npm ci

echo "🔄 Syncing SvelteKit..."
npx svelte-kit sync

echo "🏗️ Building application..."
npm run build

echo "✅ Build completed successfully!"

echo "📁 Checking build output..."
ls -la build/

echo "�� Ready to start!" 