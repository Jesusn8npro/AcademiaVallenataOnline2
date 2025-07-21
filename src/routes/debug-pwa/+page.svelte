<!-- 🧪 PÁGINA DEBUG PWA - ACADEMIA VALLENATA -->
<script lang="ts">
  import { onMount } from 'svelte';
  import { estadoPWA, funcionesPWA, estaOnline, funcionesOfflineDisponibles } from '$lib/stores/pwa-store';

  // 🔍 Variables de estado
  let resultadosVerificacion = {
    manifestCargado: false,
    serviceWorkerRegistrado: false,
    cacheDisponible: false,
    notificacionesSoportadas: false,
    instalacionDisponible: false,
    modoStandalone: false
  };

  let estadisticasCache: any = null;
  let infoNavegador = '';
  let logsPWA: string[] = [];

  // 🧪 Ejecutar verificaciones
  onMount(async () => {
    await verificarPWA();
    obtenerInfoNavegador();
  });

  // 🔍 Función principal de verificación
  async function verificarPWA() {
    logsPWA = [];
    log('🚀 Iniciando verificación PWA...');

    // 1. Verificar Manifest
    try {
      const response = await fetch('/manifest.json');
      if (response.ok) {
        const manifest = await response.json();
        resultadosVerificacion.manifestCargado = true;
        log(`✅ Manifest cargado: ${manifest.name}`);
      }
    } catch (error) {
      log(`❌ Error cargando manifest: ${error}`);
    }

    // 2. Verificar Service Worker  
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.getRegistration();
        if (registration) {
          resultadosVerificacion.serviceWorkerRegistrado = true;
          log(`✅ Service Worker registrado: ${registration.scope}`);
        } else {
          log('❌ Service Worker no registrado');
        }
      } catch (error) {
        log(`❌ Error verificando SW: ${error}`);
      }
    } else {
      log('❌ Service Workers no soportados en este navegador');
    }

    // 3. Verificar Cache
    if ('caches' in window) {
      try {
        const cacheNames = await caches.keys();
        if (cacheNames.length > 0) {
          resultadosVerificacion.cacheDisponible = true;
          log(`✅ ${cacheNames.length} caches disponibles: ${cacheNames.join(', ')}`);
        } else {
          log('⚠️ No hay caches creados aún');
        }
      } catch (error) {
        log(`❌ Error verificando cache: ${error}`);
      }
    }

    // 4. Verificar Notificaciones
    if ('Notification' in window) {
      resultadosVerificacion.notificacionesSoportadas = true;
      log(`✅ Notificaciones soportadas. Permiso: ${Notification.permission}`);
    } else {
      log('❌ Notificaciones no soportadas');
    }

    // 5. Verificar modo Standalone
    if (window.matchMedia('(display-mode: standalone)').matches) {
      resultadosVerificacion.modoStandalone = true;
      log('✅ Ejecutándose como PWA instalada (standalone)');
    } else {
      log('ℹ️ Ejecutándose en navegador (no instalada)');
    }

    // 6. Obtener estadísticas de cache
    try {
      estadisticasCache = await funcionesPWA.estadisticas();
      log(`📊 Estadísticas de cache obtenidas`);
    } catch (error) {
      log(`⚠️ No se pudieron obtener estadísticas de cache`);
    }

    log('🎯 Verificación PWA completada');
  }

  // 📝 Helper para logs
  function log(mensaje: string) {
    logsPWA = [...logsPWA, `[${new Date().toLocaleTimeString()}] ${mensaje}`];
  }

  // 🌐 Obtener información del navegador
  function obtenerInfoNavegador() {
    infoNavegador = `
      User Agent: ${navigator.userAgent}
      Online: ${navigator.onLine}
      Service Worker: ${'serviceWorker' in navigator ? 'Soportado' : 'No soportado'}
      Notifications: ${'Notification' in window ? 'Soportado' : 'No soportado'}
      Cache API: ${'caches' in window ? 'Soportado' : 'No soportado'}
      Display Mode: ${window.matchMedia('(display-mode: standalone)').matches ? 'Standalone' : 'Browser'}
    `;
  }

  // 🔄 Funciones de prueba
  async function probarInstalacion() {
    log('📱 Probando instalación PWA...');
    const resultado = await funcionesPWA.instalar();
    log(resultado ? '✅ Instalación iniciada' : '❌ No se pudo instalar');
  }

  async function probarNotificacion() {
    log('🔔 Probando notificaciones...');
    const habilitadas = await funcionesPWA.solicitarNotificaciones();
    if (habilitadas) {
      await funcionesPWA.notificarLogro('Test PWA', 'Las notificaciones funcionan correctamente');
      log('✅ Notificación de prueba enviada');
    } else {
      log('❌ No se pudieron habilitar notificaciones');
    }
  }

  async function probarCache() {
    log('💾 Probando sistema de cache...');
    const stats = await funcionesPWA.estadisticas();
    estadisticasCache = stats;
    log(`📊 Cache actualizado: ${JSON.stringify(stats)}`);
  }

  async function limpiarTodo() {
    log('🗑️ Limpiando datos PWA...');
    
    // Limpiar caches
    const cacheNames = await caches.keys();
    for (const cacheName of cacheNames) {
      await caches.delete(cacheName);
      log(`🗑️ Cache eliminado: ${cacheName}`);
    }

    // Desregistrar SW
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      for (const registration of registrations) {
        await registration.unregister();
        log(`🗑️ Service Worker desregistrado`);
      }
    }

    log('✅ Limpieza completada - recarga la página');
  }
</script>

<div class="debug-pwa">
  <div class="debug-header">
    <h1>🧪 Debug PWA - Academia Vallenata</h1>
    <p>Herramienta para verificar el estado de tu Progressive Web App</p>
  </div>

  <!-- Estado general -->
  <div class="seccion-estado">
    <h2>📊 Estado General de PWA</h2>
    
    <div class="estados-grid">
      <div class="estado-card" class:activo={resultadosVerificacion.manifestCargado}>
        <div class="estado-icono">📱</div>
        <h3>Manifest</h3>
        <p class="estado-texto">{resultadosVerificacion.manifestCargado ? 'Cargado' : 'No encontrado'}</p>
      </div>

      <div class="estado-card" class:activo={resultadosVerificacion.serviceWorkerRegistrado}>
        <div class="estado-icono">🔄</div>
        <h3>Service Worker</h3>
        <p class="estado-texto">{resultadosVerificacion.serviceWorkerRegistrado ? 'Registrado' : 'No registrado'}</p>
      </div>

      <div class="estado-card" class:activo={resultadosVerificacion.cacheDisponible}>
        <div class="estado-icono">💾</div>
        <h3>Cache</h3>
        <p class="estado-texto">{resultadosVerificacion.cacheDisponible ? 'Disponible' : 'No disponible'}</p>
      </div>

      <div class="estado-card" class:activo={resultadosVerificacion.notificacionesSoportadas}>
        <div class="estado-icono">🔔</div>
        <h3>Notificaciones</h3>
        <p class="estado-texto">{resultadosVerificacion.notificacionesSoportadas ? 'Soportadas' : 'No soportadas'}</p>
      </div>

      <div class="estado-card" class:activo={$estadoPWA.estaInstalado || resultadosVerificacion.modoStandalone}>
        <div class="estado-icono">🏠</div>
        <h3>Instalación</h3>
        <p class="estado-texto">{$estadoPWA.estaInstalado || resultadosVerificacion.modoStandalone ? 'Instalada' : 'No instalada'}</p>
      </div>

      <div class="estado-card" class:activo={$estaOnline}>
        <div class="estado-icono">🌐</div>
        <h3>Conexión</h3>
        <p class="estado-texto">{$estaOnline ? 'Online' : 'Offline'}</p>
      </div>
    </div>
  </div>

  <!-- Stores de PWA -->
  <div class="seccion-stores">
    <h2>📊 Estado de Stores PWA</h2>
    
    <div class="stores-grid">
      <div class="store-card">
        <h3>Estado PWA</h3>
        <pre class="codigo">{JSON.stringify($estadoPWA, null, 2)}</pre>
      </div>

      <div class="store-card">
        <h3>Funciones Offline</h3>
        <pre class="codigo">{JSON.stringify($funcionesOfflineDisponibles, null, 2)}</pre>
      </div>

      {#if estadisticasCache}
        <div class="store-card">
          <h3>Estadísticas Cache</h3>
          <pre class="codigo">{JSON.stringify(estadisticasCache, null, 2)}</pre>
        </div>
      {/if}
    </div>
  </div>

  <!-- Funciones de prueba -->
  <div class="seccion-pruebas">
    <h2>🧪 Funciones de Prueba</h2>
    
    <div class="botones-prueba">
      <button class="btn-prueba" on:click={verificarPWA}>
        🔄 Verificar PWA
      </button>
      
      <button class="btn-prueba" on:click={probarInstalacion}>
        📱 Probar Instalación
      </button>
      
      <button class="btn-prueba" on:click={probarNotificacion}>
        🔔 Probar Notificación
      </button>
      
      <button class="btn-prueba" on:click={probarCache}>
        💾 Probar Cache
      </button>
      
      <button class="btn-prueba peligro" on:click={limpiarTodo}>
        🗑️ Limpiar Todo
      </button>
    </div>
  </div>

  <!-- Logs -->
  <div class="seccion-logs">
    <h2>📝 Logs de Verificación</h2>
    
    <div class="logs-container">
      {#each logsPWA as log}
        <div class="log-line">{log}</div>
      {/each}
    </div>
  </div>

  <!-- Información del navegador -->
  <div class="seccion-navegador">
    <h2>🌐 Información del Navegador</h2>
    <pre class="info-navegador">{infoNavegador}</pre>
  </div>

  <!-- Guía rápida -->
  <div class="seccion-guia">
    <h2>📖 Guía Rápida de Verificación</h2>
    
    <div class="pasos-verificacion">
      <div class="paso">
        <h3>1. Chrome DevTools</h3>
        <p>F12 → Application → Manifest (debe aparecer)</p>
      </div>
      
      <div class="paso">
        <h3>2. Lighthouse Audit</h3>
        <p>DevTools → Lighthouse → PWA → Generate Report (90-100%)</p>
      </div>
      
      <div class="paso">
        <h3>3. Instalación</h3>
        <p>Icono de instalación en barra de direcciones de Chrome</p>
      </div>
      
      <div class="paso">
        <h3>4. Modo Offline</h3>
        <p>Network → Offline → Recarga (debe funcionar)</p>
      </div>
    </div>
  </div>
</div>

<style>
  .debug-pwa {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }

  .debug-header {
    text-align: center;
    margin-bottom: 40px;
    padding: 20px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-radius: 12px;
  }

  .debug-header h1 {
    margin: 0 0 8px 0;
    font-size: 28px;
  }

  .debug-header p {
    margin: 0;
    opacity: 0.9;
  }

  /* Estados */
  .seccion-estado {
    margin-bottom: 30px;
  }

  .seccion-estado h2 {
    margin-bottom: 20px;
    color: #1f2937;
  }

  .estados-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 16px;
    margin-bottom: 20px;
  }

  .estado-card {
    background: #f8fafc;
    border: 2px solid #e5e7eb;
    border-radius: 12px;
    padding: 20px;
    text-align: center;
    transition: all 0.3s;
  }

  .estado-card.activo {
    background: #f0fdf4;
    border-color: #22c55e;
  }

  .estado-icono {
    font-size: 32px;
    margin-bottom: 12px;
  }

  .estado-card h3 {
    margin: 0 0 8px 0;
    font-size: 14px;
    color: #374151;
  }

  .estado-texto {
    margin: 0;
    font-size: 12px;
    color: #6b7280;
    font-weight: 600;
  }

  .estado-card.activo .estado-texto {
    color: #059669;
  }

  /* Stores */
  .seccion-stores {
    margin-bottom: 30px;
  }

  .stores-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
  }

  .store-card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 16px;
  }

  .store-card h3 {
    margin: 0 0 12px 0;
    font-size: 16px;
    color: #1f2937;
  }

  .codigo {
    background: #1f2937;
    color: #f9fafb;
    padding: 12px;
    border-radius: 6px;
    font-size: 12px;
    overflow-x: auto;
    margin: 0;
  }

  /* Pruebas */
  .seccion-pruebas {
    margin-bottom: 30px;
  }

  .botones-prueba {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
  }

  .btn-prueba {
    background: #3b82f6;
    color: white;
    border: none;
    padding: 12px 20px;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-prueba:hover {
    background: #2563eb;
    transform: translateY(-1px);
  }

  .btn-prueba.peligro {
    background: #ef4444;
  }

  .btn-prueba.peligro:hover {
    background: #dc2626;
  }

  /* Logs */
  .logs-container {
    background: #1f2937;
    color: #f9fafb;
    padding: 16px;
    border-radius: 8px;
    max-height: 300px;
    overflow-y: auto;
    font-family: 'Courier New', monospace;
  }

  .log-line {
    padding: 4px 0;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    font-size: 12px;
  }

  /* Información navegador */
  .info-navegador {
    background: #f3f4f6;
    padding: 16px;
    border-radius: 8px;
    font-size: 12px;
    overflow-x: auto;
    margin: 0;
  }

  /* Guía */
  .pasos-verificacion {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 16px;
  }

  .paso {
    background: #fef3c7;
    border: 1px solid #fcd34d;
    border-radius: 8px;
    padding: 16px;
  }

  .paso h3 {
    margin: 0 0 8px 0;
    color: #92400e;
  }

  .paso p {
    margin: 0;
    color: #78350f;
    font-size: 14px;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .debug-pwa {
      padding: 16px;
    }

    .estados-grid {
      grid-template-columns: repeat(2, 1fr);
    }

    .stores-grid,
    .pasos-verificacion {
      grid-template-columns: 1fr;
    }

    .botones-prueba {
      flex-direction: column;
    }
  }
</style> 