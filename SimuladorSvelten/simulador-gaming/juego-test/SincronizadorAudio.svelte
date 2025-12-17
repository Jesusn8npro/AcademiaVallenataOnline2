<script lang="ts">
  import { createEventDispatcher, onMount, onDestroy } from 'svelte';
  import type { CancionCompleta, SecuenciaCancion, NotaCancion } from '$lib/services/cancionesJuegoService';
  
  const dispatch = createEventDispatcher();
  
  // ===========================================
  // 🎵 PROPS DEL COMPONENTE
  // ===========================================
  
  export let cancionCompleta: CancionCompleta | null = null;
  export let secuenciaActual: SecuenciaCancion | null = null;
  export let notasCancion: NotaCancion[] = [];
  export let reproduciendo: boolean = false;
  export let pausado: boolean = false;
  export let tiempoActual: number = 0;
  export let toleranciaTiming: number = 150; // ms
  export let anticipacionNota: number = 2000; // ms - tiempo antes de mostrar la nota
  export let offsetSincronizacion: number = 100; // ms - compensación para sincronización perfecta
  export let anticipacionAcordeonGuia: number = 2000; // ms - tiempo que el acordeón guía se adelanta
  
  // ===========================================
  // 🎮 ESTADO INTERNO
  // ===========================================
  
  let audioElement: HTMLAudioElement | null = null;
  let intervaloActualizacion: NodeJS.Timeout | null = null;
  let notasActivas = new Map<string, NotaCancion>();
  let notasProximas = new Map<string, NotaCancion>();
  let ultimaNotaProcesada: number = 0;
  
  // 🎵 SISTEMA DE TIMEOUTS COMO EN EDITOR MAX
  let tiemposReproduccion: NodeJS.Timeout[] = [];
  let reproduccionActiva = false;
  
  // ===========================================
  // 🎵 GESTIÓN DE AUDIO
  // ===========================================
  
  function configurarAudio() {
    if (!cancionCompleta?.url_audio) {
      console.error('No hay URL de audio disponible');
      return;
    }
    
    console.log('🎵 Configurando audio:', cancionCompleta.url_audio);
    
    // Limpiar audio anterior
    if (audioElement) {
      audioElement.pause();
      audioElement.removeEventListener('timeupdate', manejarActualizacionTiempo);
      audioElement.removeEventListener('ended', manejarFinAudio);
      audioElement.removeEventListener('error', manejarErrorAudio);
    }
    
    // Crear nuevo elemento de audio
    audioElement = new Audio(cancionCompleta.url_audio);
    
    // Configurar eventos
    audioElement.addEventListener('timeupdate', manejarActualizacionTiempo);
    audioElement.addEventListener('ended', manejarFinAudio);
    audioElement.addEventListener('error', manejarErrorAudio);
    
    // Evento de carga exitosa
    audioElement.addEventListener('loadeddata', () => {
      console.log('✅ Audio cargado exitosamente');
      console.log('Duración:', audioElement?.duration, 'segundos');
    });
    
    // Evento de carga de metadatos
    audioElement.addEventListener('loadedmetadata', () => {
      console.log('📊 Metadatos del audio cargados');
    });
    
    // Configurar propiedades
    audioElement.preload = 'auto';
    audioElement.volume = 0.8;
    
    console.log('🎵 Audio configurado correctamente');
  }
  
  function manejarActualizacionTiempo() {
    if (!audioElement) return;
    
    const nuevoTiempo = audioElement.currentTime * 1000; // Convertir a ms
    tiempoActual = nuevoTiempo;
    
    procesarNotasEnTiempo(nuevoTiempo);
  }
  
  function manejarFinAudio() {
    console.log('Audio terminado');
    dispatch('audioTerminado');
  }
  
  function manejarErrorAudio(error: Event) {
    console.error('Error en audio:', error);
    console.error('URL que falló:', cancionCompleta?.url_audio);
    console.error('Elemento audio:', audioElement);
    
    if (audioElement) {
      console.error('Error code:', audioElement.error?.code);
      console.error('Error message:', audioElement.error?.message);
    }
    
    dispatch('errorAudio', { error });
  }
  
  // ===========================================
  // 🎼 PROCESAMIENTO DE NOTAS - LÓGICA EDITOR MAX
  // ===========================================
  
  function programarNotasSincronizadas(tiempoInicioMs: number) {
    if (!notasCancion.length) return;
    
    console.log('🎵 Programando notas sincronizadas desde:', tiempoInicioMs, 'ms');
    
    // Limpiar timeouts anteriores
    limpiarTimeouts();
    
    // Filtrar notas que deben reproducirse desde el tiempo actual
    const notasOrdenadas = notasCancion
      .filter(nota => nota.timestamp_ms >= tiempoInicioMs)
      .sort((a, b) => a.timestamp_ms - b.timestamp_ms);
    
    console.log('🎵 Notas a programar:', notasOrdenadas.length);
    
    // Programar cada nota individualmente
    notasOrdenadas.forEach((nota, index) => {
      const tiempoNota = nota.timestamp_ms;
      const tiempoEspera = tiempoNota - tiempoInicioMs;
      const idNota = `${nota.nota_id}-${nota.timestamp_ms}`;
      
      // 🎯 TIMING CORRECTO: Acordeón guía se adelanta, jugador suena en tiempo real
      const tiempoEsperaAcordeonGuia = Math.max(0, tiempoEspera - anticipacionAcordeonGuia + offsetSincronizacion);
      const tiempoEsperaJugadorReal = Math.max(0, tiempoEspera + offsetSincronizacion);
      
      // 📌 Debug log programación
      console.log(`🎵 Programando nota ${index + 1}:`, {
        nota_id: nota.nota_id,
        timestamp: tiempoNota,
        tiempoEspera: tiempoEspera,
        tiempoEsperaAcordeonGuia: tiempoEsperaAcordeonGuia,
        tiempoEsperaJugadorReal: tiempoEsperaJugadorReal,
        anticipacionAcordeonGuia: anticipacionAcordeonGuia,
        offsetAplicado: offsetSincronizacion,
        duracion: nota.duracion_ms,
        fuelle: nota.fuelle_direccion
      });
      
      // 🎯 ACTIVAR ACORDEÓN GUÍA CON ANTICIPACIÓN (para mostrar visual + lanzar nota voladora)
      const timeoutInicioGuia = setTimeout(() => {
        if (!reproduccionActiva) return;
        iniciarNotaSincronizada(nota);
      }, tiempoEsperaAcordeonGuia);
      
      // 🎯 DESACTIVAR ACORDEÓN GUÍA (después de mostrar la nota)
      const timeoutFinGuia = setTimeout(() => {
        if (!reproduccionActiva) return;
        detenerNotaSincronizada(nota);
      }, tiempoEsperaAcordeonGuia + nota.duracion_ms);
      
      // 🎯 NOTA PRÓXIMA (para debug/preview)
      const timeoutProxima = setTimeout(() => {
        if (!reproduccionActiva) return;
        dispatch('notaProxima', { 
          nota, 
          tiempoRestante: nota.duracion_ms,
          tiempoActual: tiempoInicioMs + tiempoEspera,
          tiempoRealSonido: tiempoEsperaJugadorReal
        });
      }, Math.max(0, tiempoEspera - anticipacionNota));
      
      // Guardar todos los timeouts para poder limpiarlos
      tiemposReproduccion.push(timeoutInicioGuia, timeoutFinGuia, timeoutProxima);
    });
    
    reproduccionActiva = true;
  }
  
  function iniciarNotaSincronizada(nota: NotaCancion) {
    // Verificar que la reproducción sigue activa
    if (!reproduccionActiva) {
      console.log('🛑 Reproducción no activa, saltando nota:', nota.nota_id);
      return;
    }
    
    const idNota = `${nota.nota_id}-${nota.timestamp_ms}`;
    
    // 📌 Debug log detallado
    const direccionFuelle = nota.fuelle_direccion === 'empujar' ? 'OUT' : 'IN';
    const colorFuelle = nota.fuelle_direccion === 'empujar' ? 'verde' : 'rojo';
    
    console.log(`🎵 NOTA INICIADA:`, {
      timestamp: nota.timestamp_ms,
      direccionFuelle: direccionFuelle,
      idBoton: nota.nota_id,
      colorFuelle: colorFuelle,
      tipoNota: nota.tipo_nota,
      duracion: nota.duracion_ms
    });
    
    // Marcar nota como activa
    notasActivas.set(idNota, nota);
    
    // Disparar evento
    dispatch('notaActivada', { 
      nota, 
      tiempoActual: (audioElement?.currentTime || 0) * 1000,
      diferenciaTiempo: 0,
      direccionFuelle,
      colorFuelle
    });
  }
  
  function detenerNotaSincronizada(nota: NotaCancion) {
    // Verificar que la reproducción sigue activa
    if (!reproduccionActiva) {
      console.log('🛑 Reproducción no activa, saltando desactivación:', nota.nota_id);
      return;
    }
    
    const idNota = `${nota.nota_id}-${nota.timestamp_ms}`;
    
    // Verificar que la nota aún esté activa
    if (!notasActivas.has(idNota)) {
      console.log(`⚠️ Nota ya no está activa: ${nota.nota_id}`);
      return;
    }
    
    // 📌 Debug log desactivación
    console.log(`🎵 NOTA DETENIDA:`, {
      timestamp: nota.timestamp_ms,
      idBoton: nota.nota_id,
      duracionTotal: nota.duracion_ms
    });
    
    // Remover nota activa
    notasActivas.delete(idNota);
    
    // Disparar evento
    dispatch('notaDesactivada', { 
      nota, 
      tiempoActual: (audioElement?.currentTime || 0) * 1000,
      diferenciaTiempo: 0
    });
  }
  
  function limpiarTimeouts() {
    console.log('🧹 Limpiando timeouts:', tiemposReproduccion.length);
    tiemposReproduccion.forEach(timeout => clearTimeout(timeout));
    tiemposReproduccion = [];
    reproduccionActiva = false;
    
    // Limpiar todas las notas activas y disparar eventos de desactivación
    const notasActivasArray = Array.from(notasActivas.values());
    notasActivasArray.forEach(nota => {
      const idNota = `${nota.nota_id}-${nota.timestamp_ms}`;
      console.log(`🧹 Limpiando nota activa: ${nota.nota_id}`);
      
      // Disparar evento de desactivación
      dispatch('notaDesactivada', { 
        nota, 
        tiempoActual: (audioElement?.currentTime || 0) * 1000,
        diferenciaTiempo: 0
      });
    });
    
    // Limpiar mapas
    notasActivas.clear();
    notasProximas.clear();
  }
  
  // Función legacy para mantener compatibilidad
  function procesarNotasEnTiempo(tiempoMs: number) {
    // Esta función ahora solo actualiza el tiempo, las notas se manejan con timeouts
    // Mantenemos para compatibilidad con el intervalo existente
  }
  
  // ===========================================
  // 🎮 CONTROLES PÚBLICOS
  // ===========================================
  
  export async function iniciarReproduccion() {
    if (!audioElement) {
      console.error('❌ Audio no configurado');
      throw new Error('Audio no configurado');
    }
    
    if (!cancionCompleta?.url_audio) {
      console.error('❌ No hay URL de audio');
      throw new Error('No hay URL de audio disponible');
    }
    
    try {
      console.log('🎵 Intentando iniciar reproducción...');
      console.log('URL del audio:', cancionCompleta.url_audio);
      console.log('Estado del audio:', audioElement.readyState);
      
      // Obtener tiempo actual del audio
      const tiempoActualMs = audioElement.currentTime * 1000;
      
      // Programar notas sincronizadas como en editor max
      programarNotasSincronizadas(tiempoActualMs);
      
      await audioElement.play();
      console.log('✅ Reproducción iniciada exitosamente');
      return true;
    } catch (error) {
      console.error('❌ Error iniciando reproducción:', error);
      
      if (error instanceof DOMException) {
        console.error('Código de error:', error.code);
        console.error('Mensaje de error:', error.message);
        
        if (error.name === 'NotSupportedError') {
          console.error('El formato de audio no es soportado');
        } else if (error.name === 'NotAllowedError') {
          console.error('Reproducción bloqueada por política del navegador');
        } else if (error.name === 'AbortError') {
          console.error('Reproducción abortada');
        }
      }
      
      throw error;
    }
  }
  
  export function pausarReproduccion() {
    if (audioElement) {
      audioElement.pause();
      console.log('Reproducción pausada');
    }
    
    // Limpiar timeouts al pausar
    limpiarTimeouts();
  }
  
  export function reiniciarReproduccion() {
    // Limpiar timeouts al reiniciar (esto ya limpia las notas activas)
    limpiarTimeouts();
    
    if (audioElement) {
      audioElement.currentTime = 0;
      ultimaNotaProcesada = 0;
      console.log('Reproducción reiniciada');
    }
  }
  
  export function cambiarTiempo(segundos: number) {
    if (audioElement) {
      audioElement.currentTime = segundos;
      notasActivas.clear();
      notasProximas.clear();
      
      // Reprogramar notas desde el nuevo tiempo
      const tiempoActualMs = segundos * 1000;
      programarNotasSincronizadas(tiempoActualMs);
    }
  }
  
  export function cambiarVolumen(volumen: number) {
    if (audioElement) {
      audioElement.volume = Math.max(0, Math.min(1, volumen));
    }
  }
  
  // ===========================================
  // 📊 INFORMACIÓN PÚBLICA
  // ===========================================
  
  export function obtenerEstadoAudio() {
    if (!audioElement) return null;
    
    return {
      duracion: audioElement.duration,
      tiempoActual: audioElement.currentTime,
      volumen: audioElement.volume,
      pausado: audioElement.paused,
      cargando: audioElement.readyState < 4,
      buffered: audioElement.buffered
    };
  }
  
  export function obtenerNotasActivas() {
    return Array.from(notasActivas.values());
  }
  
  export function obtenerNotasProximas() {
    return Array.from(notasProximas.values());
  }
  
  export function obtenerEstadisticasRealTime() {
    return {
      notasActivas: notasActivas.size,
      notasProximas: notasProximas.size,
      tiempoTranscurrido: tiempoActual,
      porcentajeCompletado: audioElement ? (audioElement.currentTime / audioElement.duration) * 100 : 0
    };
  }
  
  // ===========================================
  // 🔄 REACTIVIDAD
  // ===========================================
  
  // Reconfigurar audio cuando cambie la canción
  $: if (cancionCompleta) {
    configurarAudio();
  }
  
  // Actualizar tolerancia cuando cambie
  $: if (secuenciaActual?.tolerancia_timing_ms) {
    toleranciaTiming = secuenciaActual.tolerancia_timing_ms;
  }
  
  // ===========================================
  // 🚀 LIFECYCLE
  // ===========================================
  
  onMount(() => {
    console.log('SincronizadorAudio montado');
  });
  
  onDestroy(() => {
    console.log('SincronizadorAudio destruido');
    
    // Limpiar timeouts de notas programadas
    limpiarTimeouts();
    
    // Limpiar audio
    if (audioElement) {
      audioElement.pause();
      audioElement.removeEventListener('timeupdate', manejarActualizacionTiempo);
      audioElement.removeEventListener('ended', manejarFinAudio);
      audioElement.removeEventListener('error', manejarErrorAudio);
    }
    
    // Limpiar intervalos
    if (intervaloActualizacion) {
      clearInterval(intervaloActualizacion);
    }
    
    // Limpiar mapas
    notasActivas.clear();
    notasProximas.clear();
  });
</script>

<!-- Este componente no renderiza nada, solo maneja lógica -->
<div style="display: none;">
  Sincronizador de Audio - 
  Tiempo: {Math.round(tiempoActual)}ms - 
  Notas activas: {notasActivas.size} - 
  Notas próximas: {notasProximas.size}
</div>

<style>
  /* Estilos para el debug invisible */
  div {
    position: fixed;
    top: 0;
    left: 0;
    z-index: 9999;
    background: rgba(0, 0, 0, 0.8);
    color: white;
    padding: 0.5rem;
    font-size: 0.8rem;
    border-radius: 0 0 8px 0;
    pointer-events: none;
    opacity: 0.7;
  }
</style> 