<!-- 🚀 COMPONENTE INSTALADOR PWA ACADEMIA VALLENATA -->
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { 
    estadoPWA, 
    promptInstalacion, 
    funcionesPWA,
    estaOnline,
    funcionesOfflineDisponibles 
  } from '$lib/stores/pwa-store';

  // 🎯 VARIABLES REACTIVAS
  let mostrarBannerInstalacion = false;
  let mostrarModalInstalacion = false;
  let instalacionEnProceso = false;
  let unsubscribe: (() => void)[] = [];

  // 🎨 CONFIGURACIÓN DE ANIMACIONES
  let bannerVisible = false;
  let modalVisible = false;

  onMount(() => {
    // Suscribirse a cambios en el estado PWA
    const unsubEstado = estadoPWA.subscribe(estado => {
      mostrarBannerInstalacion = estado.puedeInstalar && !estado.estaInstalado;
    });

    // Mostrar banner automáticamente después de 10 segundos
    const timerBanner = setTimeout(() => {
      if (mostrarBannerInstalacion) {
        bannerVisible = true;
      }
    }, 10000);

    unsubscribe.push(unsubEstado);
    
    return () => {
      clearTimeout(timerBanner);
    };
  });

  onDestroy(() => {
    unsubscribe.forEach(unsub => unsub());
  });

  // 🚀 MANEJAR INSTALACIÓN
  async function instalarApp() {
    instalacionEnProceso = true;
    
    try {
      const instalado = await funcionesPWA.instalar();
      
      if (instalado) {
        mostrarBannerInstalacion = false;
        mostrarModalInstalacion = false;
        bannerVisible = false;
        modalVisible = false;
        
        // Mostrar mensaje de éxito
        alert('🎉 ¡Academia Vallenata instalada exitosamente!');
      }
    } catch (error) {
      console.error('❌ Error en instalación:', error);
      alert('❌ Error instalando la app. Intenta de nuevo.');
    } finally {
      instalacionEnProceso = false;
    }
  }

  // 🔔 SOLICITAR NOTIFICACIONES
  async function habilitarNotificaciones() {
    const habilitadas = await funcionesPWA.solicitarNotificaciones();
    
    if (habilitadas) {
      alert('🔔 ¡Notificaciones habilitadas! Te recordaremos practicar.');
    } else {
      alert('ℹ️ Puedes habilitar notificaciones desde configuración del navegador.');
    }
  }

  // 🎨 CONTROLAR MODAL
  function abrirModal() {
    mostrarModalInstalacion = true;
    modalVisible = true;
  }

  function cerrarModal() {
    modalVisible = false;
    setTimeout(() => {
      mostrarModalInstalacion = false;
    }, 300);
  }

  function cerrarBanner() {
    bannerVisible = false;
    setTimeout(() => {
      mostrarBannerInstalacion = false;
    }, 300);
  }
</script>

<!-- 🎯 BANNER DE INSTALACIÓN FLOTANTE -->
{#if mostrarBannerInstalacion && bannerVisible}
  <div 
    class="instalacion-banner"
    class:banner-visible={bannerVisible}
    role="banner"
    aria-label="Banner de instalación de app"
  >
    <div class="banner-contenido">
      <div class="banner-icono">
        <img 
          src="/favicon.png" 
          alt="Academia Vallenata" 
          class="banner-logo"
        />
      </div>
      
      <div class="banner-texto">
        <h3>📱 Instala la Academia</h3>
        <p>Accede offline, recibe notificaciones y una experiencia más rápida</p>
      </div>
      
      <div class="banner-acciones">
        <button 
          class="btn-instalar-banner"
          on:click={abrirModal}
          aria-label="Abrir opciones de instalación"
        >
          Instalar
        </button>
        
        <button 
          class="btn-cerrar-banner"
          on:click={cerrarBanner}
          aria-label="Cerrar banner"
          title="Cerrar"
        >
          ✕
        </button>
      </div>
    </div>
  </div>
{/if}

<!-- 🎨 MODAL DE INSTALACIÓN DETALLADO -->
{#if mostrarModalInstalacion}
  <div 
    class="modal-overlay"
    class:modal-visible={modalVisible}
    on:click={cerrarModal}
    role="dialog"
    aria-labelledby="modal-titulo"
    aria-describedby="modal-descripcion"
  >
    <div 
      class="modal-contenido"
      on:click|stopPropagation
    >
      <!-- Header -->
      <div class="modal-header">
        <div class="modal-icono">
          <img 
            src="/Acordeon PRO MAX.png" 
            alt="Academia Vallenata"
            class="modal-logo"
          />
        </div>
        
        <h2 id="modal-titulo">🚀 Instalar Academia Vallenata</h2>
        
        <button 
          class="btn-cerrar-modal"
          on:click={cerrarModal}
          aria-label="Cerrar modal"
        >
          ✕
        </button>
      </div>

      <!-- Beneficios -->
      <div class="modal-body">
        <p id="modal-descripcion" class="modal-subtitle">
          Convierte tu navegador en una app completa
        </p>
        
        <div class="beneficios-grid">
          <div class="beneficio-item">
            <div class="beneficio-icono offline">📱</div>
            <h4>Acceso Offline</h4>
            <p>Usa el simulador y lecciones sin internet</p>
          </div>
          
          <div class="beneficio-item">
            <div class="beneficio-icono">🔔</div>
            <h4>Notificaciones</h4>
            <p>Recordatorios de práctica personalizados</p>
          </div>
          
          <div class="beneficio-item">
            <div class="beneficio-icono">⚡</div>
            <h4>Súper Rápida</h4>
            <p>Carga instantánea, todo cacheado localmente</p>
          </div>
          
          <div class="beneficio-item">
            <div class="beneficio-icono">🏠</div>
            <h4>En tu Inicio</h4>
            <p>Acceso directo desde tu escritorio</p>
          </div>
        </div>

        <!-- Estado de funciones offline -->
        {#if $funcionesOfflineDisponibles}
          <div class="funciones-offline">
            <h4>🎵 Funciones Disponibles Offline:</h4>
            <div class="funciones-lista">
              <span class="funcion-badge activa">
                🎹 Simulador: Siempre disponible
              </span>
              <span class="funcion-badge" class:activa={$funcionesOfflineDisponibles.grabaciones}>
                🎤 Grabaciones: {$funcionesOfflineDisponibles.grabaciones ? 'Disponible' : 'Próximamente'}
              </span>
              <span class="funcion-badge" class:activa={$funcionesOfflineDisponibles.cursos}>
                📚 Cursos: {$funcionesOfflineDisponibles.cursos ? 'Cacheados' : 'Descarga pendiente'}
              </span>
            </div>
          </div>
        {/if}
      </div>

      <!-- Acciones -->
      <div class="modal-footer">
        <button 
          class="btn-principal"
          on:click={instalarApp}
          disabled={instalacionEnProceso}
          aria-describedby="descripcion-instalar"
        >
          {#if instalacionEnProceso}
            <span class="spinner"></span>
            Instalando...
          {:else}
            📱 Instalar Ahora
          {/if}
        </button>
        
        <button 
          class="btn-secundario"
          on:click={habilitarNotificaciones}
          title="Habilitar recordatorios de práctica"
        >
          🔔 Habilitar Notificaciones
        </button>
        
        <div id="descripcion-instalar" class="instalacion-info">
          La instalación es segura y no ocupa espacio adicional
        </div>
      </div>
    </div>
  </div>
{/if}

<!-- 🎨 INDICADOR DE ESTADO OFFLINE -->
{#if !$estaOnline}
  <div class="indicador-offline" role="status" aria-live="polite">
    <span class="offline-icono">📱</span>
    <span class="offline-texto">Modo Offline - Simulador disponible</span>
  </div>
{/if}

<style>
  /* 🎨 BANNER FLOTANTE */
  .instalacion-banner {
    position: fixed;
    bottom: 20px;
    left: 20px;
    right: 20px;
    max-width: 500px;
    margin: 0 auto;
    background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
    color: white;
    border-radius: 16px;
    box-shadow: 0 8px 32px rgba(59, 130, 246, 0.3);
    z-index: 1000;
    transform: translateY(100px);
    opacity: 0;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  }

  .banner-visible {
    transform: translateY(0);
    opacity: 1;
  }

  .banner-contenido {
    display: flex;
    align-items: center;
    padding: 16px 20px;
    gap: 16px;
  }

  .banner-logo {
    width: 48px;
    height: 48px;
    border-radius: 12px;
    flex-shrink: 0;
  }

  .banner-texto {
    flex-grow: 1;
    min-width: 0;
  }

  .banner-texto h3 {
    margin: 0 0 4px 0;
    font-size: 16px;
    font-weight: 600;
  }

  .banner-texto p {
    margin: 0;
    font-size: 14px;
    opacity: 0.9;
    line-height: 1.3;
  }

  .banner-acciones {
    display: flex;
    gap: 8px;
    flex-shrink: 0;
  }

  .btn-instalar-banner {
    background: white;
    color: #1e40af;
    border: none;
    padding: 8px 16px;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-instalar-banner:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }

  .btn-cerrar-banner {
    background: transparent;
    color: white;
    border: none;
    width: 32px;
    height: 32px;
    border-radius: 6px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s;
  }

  .btn-cerrar-banner:hover {
    background: rgba(255, 255, 255, 0.2);
  }

  /* 🎨 MODAL */
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.6);
    backdrop-filter: blur(8px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2000;
    padding: 20px;
    opacity: 0;
    transition: opacity 0.3s;
  }

  .modal-visible {
    opacity: 1;
  }

  .modal-contenido {
    background: white;
    border-radius: 20px;
    max-width: 600px;
    width: 100%;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
    transform: scale(0.9) translateY(20px);
    transition: transform 0.3s;
  }

  .modal-visible .modal-contenido {
    transform: scale(1) translateY(0);
  }

  .modal-header {
    padding: 24px 24px 16px;
    border-bottom: 1px solid #e5e7eb;
    display: flex;
    align-items: center;
    gap: 16px;
    position: relative;
  }

  .modal-logo {
    width: 64px;
    height: 64px;
    border-radius: 16px;
  }

  .modal-header h2 {
    margin: 0;
    font-size: 24px;
    color: #1f2937;
    font-weight: 700;
    flex-grow: 1;
  }

  .btn-cerrar-modal {
    position: absolute;
    top: 16px;
    right: 16px;
    background: transparent;
    border: none;
    width: 40px;
    height: 40px;
    border-radius: 10px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #6b7280;
    font-size: 18px;
    transition: all 0.2s;
  }

  .btn-cerrar-modal:hover {
    background: #f3f4f6;
    color: #1f2937;
  }

  .modal-body {
    padding: 20px 24px;
  }

  .modal-subtitle {
    margin: 0 0 24px 0;
    font-size: 16px;
    color: #6b7280;
    text-align: center;
  }

  .beneficios-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
    gap: 16px;
    margin-bottom: 24px;
  }

  .beneficio-item {
    text-align: center;
    padding: 16px;
    border-radius: 12px;
    background: #f8fafc;
    transition: transform 0.2s;
  }

  .beneficio-item:hover {
    transform: translateY(-2px);
  }

  .beneficio-icono {
    font-size: 32px;
    margin-bottom: 8px;
  }

  .beneficio-item h4 {
    margin: 0 0 4px 0;
    font-size: 14px;
    font-weight: 600;
    color: #1f2937;
  }

  .beneficio-item p {
    margin: 0;
    font-size: 12px;
    color: #6b7280;
    line-height: 1.3;
  }

  .funciones-offline {
    background: #f0f9ff;
    border: 1px solid #e0f2fe;
    border-radius: 12px;
    padding: 16px;
    margin-top: 20px;
  }

  .funciones-offline h4 {
    margin: 0 0 12px 0;
    font-size: 14px;
    color: #0f172a;
  }

  .funciones-lista {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .funcion-badge {
    padding: 8px 12px;
    border-radius: 8px;
    font-size: 12px;
    background: #e2e8f0;
    color: #475569;
    transition: all 0.2s;
  }

  .funcion-badge.activa {
    background: #dcfce7;
    color: #166534;
    border: 1px solid #bbf7d0;
  }

  .modal-footer {
    padding: 20px 24px 24px;
    border-top: 1px solid #e5e7eb;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .btn-principal {
    background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
    color: white;
    border: none;
    padding: 14px 24px;
    border-radius: 12px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
  }

  .btn-principal:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 8px 25px rgba(59, 130, 246, 0.4);
  }

  .btn-principal:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .btn-secundario {
    background: transparent;
    color: #1e40af;
    border: 1px solid #e5e7eb;
    padding: 12px 24px;
    border-radius: 10px;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-secundario:hover {
    background: #f8fafc;
    border-color: #1e40af;
  }

  .instalacion-info {
    text-align: center;
    font-size: 12px;
    color: #6b7280;
    margin-top: 8px;
  }

  /* 🎨 INDICADOR OFFLINE */
  .indicador-offline {
    position: fixed;
    top: 20px;
    right: 20px;
    background: #f59e0b;
    color: white;
    padding: 8px 16px;
    border-radius: 20px;
    font-size: 14px;
    font-weight: 500;
    z-index: 1000;
    display: flex;
    align-items: center;
    gap: 8px;
    box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
  }

  .offline-icono {
    font-size: 16px;
  }

  /* 🎨 SPINNER */
  .spinner {
    width: 16px;
    height: 16px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-top: 2px solid white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  /* 📱 RESPONSIVE */
  @media (max-width: 640px) {
    .instalacion-banner {
      bottom: 16px;
      left: 16px;
      right: 16px;
    }

    .banner-contenido {
      padding: 12px 16px;
      gap: 12px;
    }

    .banner-logo {
      width: 40px;
      height: 40px;
    }

    .banner-texto h3 {
      font-size: 14px;
    }

    .banner-texto p {
      font-size: 12px;
    }

    .modal-contenido {
      margin: 10px;
      border-radius: 16px;
    }

    .modal-header {
      padding: 20px 20px 16px;
    }

    .modal-header h2 {
      font-size: 20px;
    }

    .modal-body {
      padding: 16px 20px;
    }

    .beneficios-grid {
      grid-template-columns: repeat(2, 1fr);
      gap: 12px;
    }

    .modal-footer {
      padding: 16px 20px 20px;
    }
  }
</style> 