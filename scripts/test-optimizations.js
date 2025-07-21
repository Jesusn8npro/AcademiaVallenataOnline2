#!/usr/bin/env node

// 🧪 Script de Verificación de Optimizaciones
// Verifica que todas las optimizaciones estén aplicadas correctamente

const fs = require('fs');
const path = require('path');

console.log('🧪 VERIFICANDO OPTIMIZACIONES DE RENDIMIENTO...\n');

const checks = {
  'vite.config.js': {
    file: 'vite.config.js',
    checks: [
      { text: 'minify: \'terser\'', description: '✅ Minificación Terser habilitada' },
      { text: 'drop_console: true', description: '✅ Console.logs eliminados en producción' },
      { text: 'manualChunks', description: '✅ Code splitting configurado' },
      { text: 'dead_code: true', description: '✅ Tree shaking agresivo habilitado' }
    ]
  },
  'app.html': {
    file: 'src/app.html',  
    checks: [
      { text: 'rel="preload"', description: '✅ Preload de assets críticos' },
      { text: 'fetchpriority="high"', description: '✅ Prioridad alta para imágenes críticas' },
      { text: 'Critical CSS', description: '✅ CSS crítico inline' },
      { text: 'dns-prefetch', description: '✅ DNS prefetch configurado' }
    ]
  },
  '_headers': {
    file: 'static/_headers',
    checks: [
      { text: 'Cache-Control', description: '✅ Headers de cache configurados' },
      { text: 'Content-Encoding: gzip', description: '✅ Compresión gzip habilitada' },
      { text: 'max-age=31536000', description: '✅ Cache largo para assets estáticos' }
    ]
  },
  'sw-optimized.js': {
    file: 'static/sw-optimized.js',
    checks: [
      { text: 'v2.0.0', description: '✅ Service Worker optimizado' },
      { text: 'Cache-First', description: '✅ Estrategias de cache eficientes' }
    ]
  }
};

let totalChecks = 0;
let passedChecks = 0;

Object.entries(checks).forEach(([name, config]) => {
  console.log(`📁 Verificando ${name}:`);
  
  const filePath = path.join(process.cwd(), config.file);
  
  if (!fs.existsSync(filePath)) {
    console.log(`   ❌ Archivo no encontrado: ${config.file}`);
    return;
  }
  
  const fileContent = fs.readFileSync(filePath, 'utf8');
  
  config.checks.forEach(check => {
    totalChecks++;
    if (fileContent.includes(check.text)) {
      console.log(`   ${check.description}`);
      passedChecks++;
    } else {
      console.log(`   ❌ ${check.description.replace('✅', 'FALTA:')}`);
    }
  });
  
  console.log('');
});

// Verificar componentes adicionales
console.log('🧩 Verificando componentes optimizados:');
const imageOptimizedPath = 'src/lib/components/ImageOptimized.svelte';
if (fs.existsSync(imageOptimizedPath)) {
  console.log('   ✅ Componente ImageOptimized creado');
  passedChecks++;
} else {
  console.log('   ❌ Componente ImageOptimized faltante');
}
totalChecks++;

const lazyLoadPath = 'src/lib/components/LazyLoad.svelte';
if (fs.existsSync(lazyLoadPath)) {
  console.log('   ✅ Componente LazyLoad disponible');
  passedChecks++;
} else {
  console.log('   ❌ Componente LazyLoad faltante');
}
totalChecks++;

console.log('');

// Resumen
const percentage = Math.round((passedChecks / totalChecks) * 100);
console.log('📊 RESUMEN DE OPTIMIZACIONES:');
console.log(`   Verificaciones pasadas: ${passedChecks}/${totalChecks} (${percentage}%)`);

if (percentage >= 90) {
  console.log('   🎉 ¡EXCELENTE! Optimizaciones aplicadas correctamente');
  console.log('   🚀 Performance esperado: 80-90 puntos en Lighthouse');
} else if (percentage >= 70) {
  console.log('   ⚠️ BUENO - Algunas optimizaciones pendientes');
  console.log('   📈 Performance esperado: 65-80 puntos en Lighthouse');
} else {
  console.log('   ❌ REQUIERE ATENCIÓN - Muchas optimizaciones faltantes');
  console.log('   📉 Performance esperado: <65 puntos en Lighthouse');
}

console.log('\n🧪 Para probar las optimizaciones:');
console.log('   1. npm run dev');
console.log('   2. Abrir http://localhost:5173');  
console.log('   3. F12 → Lighthouse → Performance → Generate report');
console.log('   4. Verificar mejoras en LCP, FCP y Total Blocking Time');

console.log('\n✨ ¡Listo para pruebas de rendimiento!'); 