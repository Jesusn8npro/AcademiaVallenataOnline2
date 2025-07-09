<!--
🎮 GESTOR DE GAMIFICACIÓN AUTOMÁTICA
====================================
Componente que se ejecuta en background para:
- Procesar actividades pendientes
- Sincronizar datos reales con gaming
- Mostrar notificaciones de logros
- Actualizar XP automáticamente
====================================
-->

<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { estadoUsuarioActual } from '../../supabase/estadoUsuarioActual';
  import GamificacionService from '../../services/gamificacionService';
  import GestorNotificaciones from './GestorNotificaciones.svelte';

  // Estado del gestor
  let usuarioActual: any = null;
  let procesandoActividades = false;
  let ultimaProcesamiento = new Date();
  let errorGamificacion = '';
  let intervaloProcesamiento: any;
  let intervaloSincronizacion: any;

  // Configuración
  const INTERVALO_PROCESAMIENTO = 30000; // 30 segundos
  const INTERVALO_SINCRONIZACION = 300000; // 5 minutos

  // Reactividad
  $: usuarioActual = $estadoUsuarioActual;

  onMount(() => {
    if (usuarioActual) {
      inicializarGamificacion();
    }
  });

  onDestroy(() => {
    if (intervaloProcesamiento) {
      clearInterval(intervaloProcesamiento);
    }
    if (intervaloSincronizacion) {
      clearInterval(intervaloSincronizacion);
    }
  });

  // Observar cambios en el usuario
  $: if (usuarioActual) {
    inicializarGamificacion();
  } else {
    detenerGamificacion();
  }

  /**
   * 🎮 Inicializar gamificación para el usuario actual
   */
  async function inicializarGamificacion() {
    if (!usuarioActual) return;

    try {
      // Procesamiento inicial
      await GamificacionService.inicializarProcesamientoAutomatico(usuarioActual.id);

      // Configurar intervalos
      configurarIntervalos();

      console.log('🎮 Gamificación inicializada correctamente');
    } catch (error) {
      console.error('Error inicializando gamificación:', error);
      errorGamificacion = 'Error al inicializar gamificación';
    }
  }

  /**
   * 🎮 Configurar intervalos de procesamiento
   */
  function configurarIntervalos() {
    if (!usuarioActual) return;

    // Limpiar intervalos existentes
    if (intervaloProcesamiento) clearInterval(intervaloProcesamiento);
    if (intervaloSincronizacion) clearInterval(intervaloSincronizacion);

    // Procesamiento de actividades pendientes cada 30 segundos
    intervaloProcesamiento = setInterval(async () => {
      if (!procesandoActividades && usuarioActual) {
        await procesarActividadesPendientes();
      }
    }, INTERVALO_PROCESAMIENTO);

    // Sincronización completa cada 5 minutos
    intervaloSincronizacion = setInterval(async () => {
      if (!procesandoActividades && usuarioActual) {
        await sincronizarDatosCompletos();
      }
    }, INTERVALO_SINCRONIZACION);
  }

  /**
   * 🎮 Procesar actividades pendientes
   */
  async function procesarActividadesPendientes() {
    if (!usuarioActual || procesandoActividades) return;

    try {
      procesandoActividades = true;
      errorGamificacion = '';

      await GamificacionService.procesarActividadesPendientes(usuarioActual.id);
      
      ultimaProcesamiento = new Date();
    } catch (error) {
      console.error('Error procesando actividades:', error);
      errorGamificacion = 'Error procesando actividades';
    } finally {
      procesandoActividades = false;
    }
  }

  /**
   * 🎮 Sincronizar datos completos
   */
  async function sincronizarDatosCompletos() {
    if (!usuarioActual || procesandoActividades) return;

    try {
      procesandoActividades = true;
      
      await GamificacionService.sincronizarDatosReales(usuarioActual.id);
      
      ultimaProcesamiento = new Date();
    } catch (error) {
      console.error('Error sincronizando datos:', error);
      errorGamificacion = 'Error sincronizando datos';
    } finally {
      procesandoActividades = false;
    }
  }

  /**
   * 🎮 Detener gamificación
   */
  function detenerGamificacion() {
    if (intervaloProcesamiento) {
      clearInterval(intervaloProcesamiento);
      intervaloProcesamiento = null;
    }
    if (intervaloSincronizacion) {
      clearInterval(intervaloSincronizacion);
      intervaloSincronizacion = null;
    }
    procesandoActividades = false;
    errorGamificacion = '';
  }

  /**
   * 🎮 Procesar manualmente (para debug)
   */
  async function procesarManualmente() {
    if (!usuarioActual) return;
    
    try {
      await GamificacionService.forzarSincronizacionCompleta(usuarioActual.id);
      console.log('✅ Procesamiento manual completado');
    } catch (error) {
      console.error('Error en procesamiento manual:', error);
    }
  }

  /**
   * 🎮 Formatear tiempo transcurrido
   */
  function formatearTiempo(fecha: Date): string {
    const ahora = new Date();
    const diff = ahora.getTime() - fecha.getTime();
    const minutos = Math.floor(diff / 60000);
    
    if (minutos === 0) return 'Ahora';
    if (minutos === 1) return 'Hace 1 minuto';
    if (minutos < 60) return `Hace ${minutos} minutos`;
    
    const horas = Math.floor(minutos / 60);
    if (horas === 1) return 'Hace 1 hora';
    if (horas < 24) return `Hace ${horas} horas`;
    
    const dias = Math.floor(horas / 24);
    if (dias === 1) return 'Hace 1 día';
    return `Hace ${dias} días`;
  }
</script>

<!-- Componente invisible que solo ejecuta lógica -->
{#if usuarioActual}
  <!-- Gestor de notificaciones gaming -->
  <GestorNotificaciones />

  <!-- Panel de debug (solo en desarrollo) -->
  {#if import.meta.env.DEV}
    <div class="debug-gamificacion">
      <div class="debug-header">
        <h4>🎮 Debug Gamificación</h4>
        <button on:click={procesarManualmente} disabled={procesandoActividades}>
          {procesandoActividades ? '⏳' : '🔄'}
        </button>
      </div>
      
      <div class="debug-info">
        <div class="debug-item">
          <span class="debug-label">Usuario:</span>
          <span class="debug-value">{usuarioActual.nombre || usuarioActual.email}</span>
        </div>
        
        <div class="debug-item">
          <span class="debug-label">Estado:</span>
          <span class="debug-value {procesandoActividades ? 'processing' : 'idle'}">
            {procesandoActividades ? 'Procesando...' : 'Activo'}
          </span>
        </div>
        
        <div class="debug-item">
          <span class="debug-label">Último procesamiento:</span>
          <span class="debug-value">{formatearTiempo(ultimaProcesamiento)}</span>
        </div>
        
        {#if errorGamificacion}
          <div class="debug-item error">
            <span class="debug-label">Error:</span>
            <span class="debug-value">{errorGamificacion}</span>
          </div>
        {/if}
      </div>
    </div>
  {/if}
{/if}

<style>
  .debug-gamificacion {
    position: fixed;
    top: 80px;
    right: 20px;
    background: rgba(0, 0, 0, 0.9);
    border: 1px solid #ffd700;
    border-radius: 8px;
    padding: 0.5rem;
    color: #fff;
    font-family: monospace;
    font-size: 0.8rem;
    z-index: 1000;
    max-width: 300px;
  }

  .debug-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
  }

  .debug-header h4 {
    margin: 0;
    color: #ffd700;
    font-size: 0.9rem;
  }

  .debug-header button {
    background: transparent;
    border: 1px solid #ffd700;
    color: #ffd700;
    border-radius: 4px;
    padding: 0.2rem 0.4rem;
    cursor: pointer;
    font-size: 0.8rem;
  }

  .debug-header button:hover {
    background: rgba(255, 215, 0, 0.1);
  }

  .debug-header button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .debug-info {
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
  }

  .debug-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .debug-item.error {
    color: #ff6b6b;
  }

  .debug-label {
    font-weight: bold;
    color: #aaa;
  }

  .debug-value {
    color: #fff;
  }

  .debug-value.processing {
    color: #ffa726;
  }

  .debug-value.idle {
    color: #4caf50;
  }

  /* Ocultar debug en producción */
  @media (max-width: 768px) {
    .debug-gamificacion {
      display: none;
    }
  }
</style> 