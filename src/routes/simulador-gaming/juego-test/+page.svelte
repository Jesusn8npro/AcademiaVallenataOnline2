<script>
  // @ts-nocheck
  import { onMount } from 'svelte';
  import { cancionesJuegoService } from '$lib/services/cancionesJuegoService';
  import AcordeonSimulador from '$lib/components/SimuladorDefinitivo/components/simulador/AcordeonSimulador.svelte';
  import FondoEspacial from '$lib/components/SimuladorDefinitivo/components/efectos/FondoEspacial.svelte';
  import { audioManager } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
  import SincronizadorAudio from './SincronizadorAudio.svelte';
  import AnimacionesNotas from './AnimacionesNotas.svelte';
  
  // ===========================================
  // 🎮 ESTADO DEL JUEGO
  // ===========================================
  
  let cancionesDisponibles = [];
  let cancionSeleccionada = null;
  let secuenciaActual = null;
  let notasCancion = [];
  
  // Estados de reproducción
  let reproduciendo = false;
  let pausado = false;
  let tiempoActual = 0;
  let audioElement = null;
  
  // Estados del acordeón guía
  let botonesGuiaActivos = {};
  let acordeonGuiaRef = null;
  let sincronizadorRef = null;
  
  // 🎮 Estados del acordeón del jugador
  let botonesJugadorActivos = {};
  let acordeonJugadorRef = null;
  let timeoutsDesactivacion = new Map(); // Para evitar notas pegadas
  
  // Estados de debug
  let mostrarDebug = true;
  let mostrarAnimaciones = true;
  let estadisticasCancion = null;
  let notaActual = null;
  let notasProximas = [];
  let offsetSincronizacion = 100; // ms - ajuste de sincronización
  let anticipacionAcordeonGuia = 2000; // ms - tiempo que el acordeón guía se adelanta

  // ===========================================
  // 🎯 FUNCIÓN PARA OBTENER COORDENADAS DINÁMICAS
  // ===========================================
  
  /**
   * Obtiene las coordenadas exactas de un botón en el acordeón del jugador
   * @param {string} notaId - ID de la nota
   * @returns {object} - Coordenadas { top, left, width, height }
   */
  function obtenerCoordenadasBotonJugador(notaId) {
    console.log('🎯 Obteniendo coordenadas para nota:', notaId);
    
    if (!acordeonJugadorRef) {
      console.warn('⚠️ acordeonJugadorRef no disponible');
      return null;
    }
    
    // 🔍 Estrategia de búsqueda múltiple para encontrar el botón correcto
    let botonJugador = null;
    
    // 1. Buscar con ID exacto
    const idBusquedaExacto = `jugador-${notaId}`;
    botonJugador = document.getElementById(idBusquedaExacto);
    
    if (!botonJugador) {
      // 2. Extraer la base de la nota (sin dirección del fuelle)
      const notaBase = notaId.replace(/-empujar|-halar/g, '');
      console.log('🔄 Intentando buscar con nota base:', notaBase);
      
      // 3. Obtener la dirección actual del fuelle del acordeón del jugador
      let direccionActualJugador = 'halar'; // Por defecto
      if (acordeonJugadorRef && acordeonJugadorRef.direccion) {
        direccionActualJugador = acordeonJugadorRef.direccion;
      }
      
      console.log('🎮 Dirección actual del jugador:', direccionActualJugador);
      
      // 4. Buscar prioritariamente con la dirección actual del jugador
      const idPrioritario = `jugador-${notaBase}-${direccionActualJugador}`;
      botonJugador = document.getElementById(idPrioritario);
      
      if (!botonJugador) {
        // 5. Si no encuentra con la dirección actual, buscar con la dirección opuesta
        const direccionOpuesta = direccionActualJugador === 'empujar' ? 'halar' : 'empujar';
        const idAlternativo = `jugador-${notaBase}-${direccionOpuesta}`;
        botonJugador = document.getElementById(idAlternativo);
      }
      
      if (botonJugador) {
        console.log('✅ Botón encontrado con dirección alternativa:', botonJugador.id);
      }
    }
    
    if (!botonJugador) {
      // 6. Buscar cualquier botón que contenga la nota base
      const notaBase = notaId.replace(/-empujar|-halar/g, '');
      const todosBotonesJugador = document.querySelectorAll(`[id*="jugador-${notaBase}"]`);
      
      if (todosBotonesJugador.length > 0) {
        botonJugador = todosBotonesJugador[0];
        console.log('✅ Botón encontrado con búsqueda parcial:', botonJugador.id);
      }
    }
    
    if (!botonJugador) {
      console.warn('⚠️ Botón del jugador no encontrado para:', notaId);
      // Debug: mostrar todos los botones disponibles
      const todosBotonesJugador = document.querySelectorAll('[id^="jugador-"]');
      console.log('🔍 Botones del jugador disponibles:', Array.from(todosBotonesJugador).map(btn => btn.id));
      
      // 🚨 Fallback: usar el centro del acordeón del jugador como destino
      const acordeonJugadorDOM = document.querySelector('.acordeon-jugador .disposicion-acordeon');
      if (acordeonJugadorDOM) {
        const rect = acordeonJugadorDOM.getBoundingClientRect();
        console.log('🔧 Usando centro del acordeón como fallback');
        return {
          top: rect.top + rect.height / 2,
          left: rect.left + rect.width / 2,
          width: 50,
          height: 50,
          centerX: rect.left + rect.width / 2,
          centerY: rect.top + rect.height / 2
        };
      }
      
      return null;
    }
    
    const rect = botonJugador.getBoundingClientRect();
    
    const coordenadas = {
      top: rect.top,
      left: rect.left,
      width: rect.width,
      height: rect.height,
      centerX: rect.left + rect.width / 2,
      centerY: rect.top + rect.height / 2
    };
    
    console.log('✅ Coordenadas obtenidas para', botonJugador.id, ':', coordenadas);
    return coordenadas;
  }
  
  /**
   * Función auxiliar para pasar coordenadas al acordeón guía
   */
  function configurarCoordenadasJugador() {
    console.log('🔧 Configurando coordenadas del jugador...', {
      acordeonGuiaRef: !!acordeonGuiaRef,
      acordeonJugadorRef: !!acordeonJugadorRef
    });
    
    if (acordeonGuiaRef && acordeonJugadorRef) {
      acordeonGuiaRef.establecerCoordenadasAcordeonJugador(obtenerCoordenadasBotonJugador);
      console.log('✅ Coordenadas configuradas exitosamente');
    } else {
      console.warn('⚠️ No se pudieron configurar las coordenadas:', {
        acordeonGuiaRef: !!acordeonGuiaRef,
        acordeonJugadorRef: !!acordeonJugadorRef
      });
    }
  }

  /**
   * 🎵 ACTIVAR NOTA AUTOMÁTICAMENTE EN EL ACORDEÓN DEL JUGADOR
   * Esta función se ejecuta cuando una nota voladora llega al acordeón del jugador
   */
  function activarNotaAutomaticamenteEnJugador(notaCompleta, fuelleDireccion, duracionMs = 400) {
    // 🔄 CONVERTIR ID DEL ACORDEÓN GUÍA AL ACORDEÓN DEL JUGADOR
    // El acordeón guía pasa IDs como "guia-Do-empujar", pero necesitamos "jugador-Do-empujar"
    let notaJugador = notaCompleta;
    
    // Si el ID viene del acordeón guía, convertirlo para el jugador
    if (notaCompleta.startsWith('guia-')) {
      notaJugador = notaCompleta.replace('guia-', 'jugador-');
    } else if (!notaCompleta.startsWith('jugador-')) {
      // Si no tiene prefijo, agregarlo
      notaJugador = `jugador-${notaCompleta}`;
    }
    
    // 🛡️ Forzar duración corta para evitar acumulación
    duracionMs = Math.min(duracionMs || 400, 800); // Máximo 800ms
    
    console.log('🎵 ACTIVANDO NOTA DEL JUGADOR:', 
      '\n  - Nota original:', notaCompleta, 
      '\n  - Nota convertida:', notaJugador,
      '\n  - Dirección:', fuelleDireccion,
      '\n  - Duración:', duracionMs, 'ms'
    );
    
    if (!acordeonJugadorRef) {
      console.warn('⚠️ acordeonJugadorRef no disponible');
      return;
    }
    
    // 🚨 LIMPIAR ESTA NOTA ESPECÍFICA ANTES DE ACTIVAR
    limpiarNotaEspecifica(notaJugador);
    
    try {
      // 🎮 1. Activar la nota en el acordeón del jugador usando el ID convertido
      // Necesitamos extraer solo la parte de la nota sin el prefijo para la función interna
      const notaSinPrefijo = notaJugador.replace('jugador-', '');
      acordeonJugadorRef.simularActivacionNota(notaSinPrefijo, fuelleDireccion, duracionMs);
      
      // 🎯 2. Actualizar estado con el ID del jugador
      botonesJugadorActivos = {
        ...botonesJugadorActivos,
        [notaJugador]: {
          activo: true,
          direccionFuelle: fuelleDireccion,
          colorFuelle: fuelleDireccion === 'empujar' ? 'verde' : 'rojo',
          tiempoActivacion: Date.now(),
          duracionMs: duracionMs,
          activacionAutomatica: true
        }
      };
      
      console.log('✅ NOTA ACTIVADA EN JUGADOR:', notaJugador, 'Estado:', botonesJugadorActivos[notaJugador]);
      
      // ⏰ 3. Programar desactivación automática
      const timeoutDesactivacion = setTimeout(() => {
        console.log('⏰ DESACTIVANDO NOTA DEL JUGADOR:', notaJugador);
        limpiarNotaEspecifica(notaJugador);
      }, duracionMs);
      
      // 💾 4. Guardar timeout para poder limpiarlo después
      timeoutsDesactivacion.set(notaJugador, timeoutDesactivacion);
      
    } catch (error) {
      console.error('💥 Error activando nota en jugador:', error);
    }
  }

  /**
   * 🧹 LIMPIAR UNA NOTA ESPECÍFICA DEL JUGADOR
   */
  function limpiarNotaEspecifica(notaJugador) {
    try {
      console.log('🧹 LIMPIANDO NOTA ESPECÍFICA:', notaJugador);
      
      // 1. Limpiar timeout si existe
      if (timeoutsDesactivacion.has(notaJugador)) {
        clearTimeout(timeoutsDesactivacion.get(notaJugador));
        timeoutsDesactivacion.delete(notaJugador);
        console.log('⏰ Timeout limpiado para:', notaJugador);
      }
      
      // 2. Desactivar físicamente la nota si está activa
      if (botonesJugadorActivos[notaJugador] && acordeonJugadorRef) {
        // Extraer la parte de la nota sin el prefijo para la función interna
        const notaSinPrefijo = notaJugador.replace('jugador-', '');
        acordeonJugadorRef.simularDesactivacionNota(notaSinPrefijo);
        console.log('🔇 Nota desactivada físicamente:', notaSinPrefijo);
      }
      
      // 3. Limpiar del estado
      if (botonesJugadorActivos[notaJugador]) {
        const nuevosBotones = { ...botonesJugadorActivos };
        delete nuevosBotones[notaJugador];
        botonesJugadorActivos = nuevosBotones;
        console.log('✅ Nota limpiada del estado:', notaJugador);
      }
      
    } catch (error) {
      console.error('💥 Error limpiando nota específica:', error);
    }
  }

  /**
   * 🔥 LIMPIAR TODAS LAS NOTAS DEL JUGADOR
   */
  function limpiarTodasLasNotasJugador() {
    console.log('🔥 LIMPIANDO TODAS LAS NOTAS DEL JUGADOR');
    
    try {
      // 1. Limpiar todos los timeouts
      timeoutsDesactivacion.forEach((timeout, notaJugador) => {
        clearTimeout(timeout);
        console.log('⏰ Timeout limpiado:', notaJugador);
      });
      timeoutsDesactivacion.clear();
      
      // 2. Desactivar físicamente todas las notas
      Object.keys(botonesJugadorActivos).forEach(notaJugador => {
        if (acordeonJugadorRef) {
          const notaSinPrefijo = notaJugador.replace('jugador-', '');
          acordeonJugadorRef.simularDesactivacionNota(notaSinPrefijo);
          console.log('🔇 Nota desactivada físicamente:', notaSinPrefijo);
        }
      });
      
      // 3. Limpiar estado completamente
      botonesJugadorActivos = {};
      
      console.log('✅ TODAS LAS NOTAS DEL JUGADOR LIMPIADAS');
      
    } catch (error) {
      console.error('💥 Error limpiando todas las notas:', error);
    }
  }

  /**
   * 🧹 Función para limpiar todos los timeouts de desactivación
   */
  function limpiarTimeoutsDesactivacion() {
    console.log('🧹 LIMPIANDO TIMEOUTS...');
    
    timeoutsDesactivacion.forEach((timeout) => {
      clearTimeout(timeout);
    });
    
    timeoutsDesactivacion.clear();
    console.log('✅ TIMEOUTS LIMPIADOS');
  }

  /**
   * 🧹 Función para limpiar notas pegadas manualmente
   */
  function limpiarNotasPegadas() {
    console.log('🧹 LIMPIANDO NOTAS PEGADAS...');
    
    const notasAntes = Object.keys(botonesJugadorActivos).length;
    const timeoutsAntes = timeoutsDesactivacion.size;
    
    // Usar la función simple para limpiar todo
    limpiarTodasLasNotasJugador();
    
    console.log(`✅ LIMPIEZA COMPLETA - Notas: ${notasAntes}→0, Timeouts: ${timeoutsAntes}→0`);
  }

  /**
   * 📊 Función para diagnosticar el estado de las notas
   */
  function diagnosticarEstadoNotas() {
    console.log('📊 DIAGNÓSTICO COMPLETO:');
    console.log('========================');
    
    // Estado acordeón jugador (lo importante)
    console.log('🎮 ACORDEÓN JUGADOR:');
    console.log(`- Notas activas: ${Object.keys(botonesJugadorActivos).length}`);
    console.log(`- Timeouts activos: ${timeoutsDesactivacion.size}`);
    
    if (Object.keys(botonesJugadorActivos).length > 0) {
      console.log('- Detalle de notas activas:');
      Object.keys(botonesJugadorActivos).forEach(notaId => {
        const info = botonesJugadorActivos[notaId];
        const tiempoVida = Date.now() - info.tiempoActivacion;
        console.log(`  • ${notaId}: ${tiempoVida}ms / ${info.duracionMs}ms`);
      });
    }
    
    // Estado acordeón guía (menos importante)
    console.log(`🎯 ACORDEÓN GUÍA: ${Object.keys(botonesGuiaActivos).length} notas`);
    
    // Estado de reproducción
    console.log(`🎵 REPRODUCCIÓN: ${reproduciendo ? 'ACTIVA' : 'PARADA'}`);
    
    console.log('========================');
  }

  /**
   * Función auxiliar para configurar todos los callbacks necesarios
   */
  function configurarCallbacksJugador() {
    console.log('🔧 Configurando callbacks del jugador...', {
      acordeonGuiaRef: !!acordeonGuiaRef,
      acordeonJugadorRef: !!acordeonJugadorRef
    });
    
    if (acordeonGuiaRef && acordeonJugadorRef) {
      // Configurar coordenadas
      acordeonGuiaRef.establecerCoordenadasAcordeonJugador(obtenerCoordenadasBotonJugador);
      
      // Configurar callback de activación automática
      acordeonGuiaRef.establecerCallbackActivacionJugador(activarNotaAutomaticamenteEnJugador);
      
      console.log('✅ Todos los callbacks configurados exitosamente');
    } else {
      console.warn('⚠️ No se pudieron configurar los callbacks:', {
        acordeonGuiaRef: !!acordeonGuiaRef,
        acordeonJugadorRef: !!acordeonJugadorRef
      });
    }
  }
  
  // ===========================================
  // 🎵 EVENTOS DEL SINCRONIZADOR
  // ===========================================
  
  function manejarNotaActivada(event) {
    const { nota, tiempoActual, diferenciaTiempo, direccionFuelle, colorFuelle } = event.detail;
    
    // 📌 Debug detallado
    console.log('🎮 Manejando nota activada:', {
      nota_id: nota.nota_id,
      direccionFuelle,
      colorFuelle,
      diferenciaTiempo,
      tiempoActual,
      duracion_ms: nota.duracion_ms
    });
    
    // Actualizar acordeón guía con información completa
    botonesGuiaActivos = {
      ...botonesGuiaActivos,
      [nota.nota_id]: {
        ...nota,
        activo: true,
        direccionFuelle: nota.fuelle_direccion,
        colorFuelle: colorFuelle,
        tiempoActivacion: tiempoActual,
        diferenciaTiempo: diferenciaTiempo
      }
    };
    
    // 🎯 Activar SOLO la visualización en el acordeón guía (SIN SONIDO) CON ANTICIPACIÓN
    if (acordeonGuiaRef) {
      try {
        // Simular activación visual con anticipación - solo para mostrar el botón volador
        // El sonido real se reproduce cuando la nota voladora llega al acordeón del jugador
        // Pasar la duración real de la nota para el callback
        acordeonGuiaRef.simularActivacionNota(nota.nota_id, nota.fuelle_direccion, nota.duracion_ms);
        console.log('✅ Visualización activada correctamente en acordeón guía (anticipada)');
      } catch (error) {
        console.warn('Error activando visualización en acordeón guía:', error);
      }
    }
    
    // Actualizar nota actual para debug
    notaActual = nota;
  }
  
  function manejarNotaDesactivada(event) {
    const { nota, tiempoActual, diferenciaTiempo } = event.detail;
    
    // 📌 Debug detallado
    console.log('🎮 Manejando nota desactivada:', {
      nota_id: nota.nota_id,
      tiempoActual,
      diferenciaTiempo
    });
    
    // 🎯 Desactivar visualización del acordeón guía PRIMERO
    if (acordeonGuiaRef) {
      try {
        acordeonGuiaRef.simularDesactivacionNota(nota.nota_id);
        console.log('✅ Visualización desactivada correctamente en acordeón guía');
      } catch (error) {
        console.warn('Error desactivando visualización en acordeón guía:', error);
      }
    }
    
    // Remover del acordeón guía DESPUÉS de desactivar el sonido
    const nuevosBotones = { ...botonesGuiaActivos };
    delete nuevosBotones[nota.nota_id];
    botonesGuiaActivos = nuevosBotones;
    
    // Limpiar nota actual si es la misma
    if (notaActual?.nota_id === nota.nota_id) {
      notaActual = null;
    }
  }
  
  function manejarNotaProxima(event) {
    const { nota, tiempoRestante } = event.detail;
    console.log('Nota próxima:', nota.nota_id, 'en', tiempoRestante, 'ms');
    
    // Aquí se pueden agregar las animaciones después
    notasProximas = [...notasProximas, { ...nota, tiempoRestante }];
  }
  
  function manejarAudioTerminado() {
    console.log('Audio terminado');
    
    // Limpiar el estado de ambos acordeones
    limpiarEstadoAcordeon();
    
    reproduciendo = false;
    pausado = false;
  }
  
  function manejarErrorAudio(event) {
    console.error('Error en audio:', event.detail.error);
    alert('Error reproduciendo audio');
  }
  
  // ===========================================
  // 🎮 CONTROLES DE REPRODUCCIÓN
  // ===========================================
  
  async function iniciarReproduccion() {
    if (!cancionSeleccionada || !secuenciaActual) {
      alert('Por favor selecciona una canción primero');
      return;
    }
    
    try {
      audioManager.clickBoton();
      await sincronizadorRef.iniciarReproduccion();
      reproduciendo = true;
      pausado = false;
      
    } catch (error) {
      console.error('Error iniciando reproducción:', error);
      alert('Error al reproducir audio');
    }
  }
  
  async function pausarReproduccion() {
    if (sincronizadorRef) {
      // Limpiar el estado del acordeón guía PRIMERO
      limpiarEstadoAcordeon();
      
      sincronizadorRef.pausarReproduccion();
      pausado = true;
      reproduciendo = false;
      audioManager.clickGeneral();
    }
  }
  
  async function reiniciarReproduccion() {
    if (sincronizadorRef) {
      // Limpiar el estado del acordeón guía PRIMERO
      limpiarEstadoAcordeon();
      
      sincronizadorRef.reiniciarReproduccion();
      botonesGuiaActivos = {};
      notaActual = null;
      notasProximas = [];
      
      if (reproduciendo) {
        await sincronizadorRef.iniciarReproduccion();
      }
      
      audioManager.exito();
    }
  }
  
  // Función para limpiar completamente el estado del acordeón
  function limpiarEstadoAcordeon() {
    console.log('🧹 LIMPIANDO ESTADO COMPLETO');
    
    // 🎯 LIMPIAR ACORDEÓN GUÍA
    Object.keys(botonesGuiaActivos).forEach(notaId => {
      if (acordeonGuiaRef) {
        try {
          acordeonGuiaRef.simularDesactivacionNota(notaId);
        } catch (error) {
          console.warn('Error desactivando nota guía:', error);
        }
      }
    });
    
    // 🎮 LIMPIAR ACORDEÓN DEL JUGADOR
    limpiarTodasLasNotasJugador();
    
    // 🧹 LIMPIAR ESTADOS
    botonesGuiaActivos = {};
    notaActual = null;
    notasProximas = [];
    
    console.log('✅ ESTADO LIMPIADO');
  }
  
  // ===========================================
  // 🎵 GESTIÓN DE CANCIONES
  // ===========================================

  // Estados de carga
  let cargandoCanciones = false;
  let errorCargaCanciones = null;

  // Función de diagnóstico
  async function diagnosticoBaseDatos() {
    try {
      console.log('🔍 Iniciando diagnóstico de base de datos...');
      
      // Importar supabase directamente
      const { supabase } = await import('$lib/supabase/clienteSupabase');
      
      // Verificar configuración
      console.log('🔗 URL Supabase:', import.meta.env.VITE_SUPABASE_URL);
      console.log('🔑 Llave configurada:', import.meta.env.VITE_SUPABASE_ANON_KEY ? 'Sí' : 'No');
      
      // Probar conexión básica
      const { data: todasCanciones, error: errorTodas } = await supabase
        .from('canciones_simulador_acordeon')
        .select('*');
      
      console.log('📊 Total canciones en BD:', todasCanciones?.length || 0);
      if (errorTodas) {
        console.error('❌ Error obteniendo todas las canciones:', errorTodas);
      }
      
      // Probar filtros específicos
      const { data: cancionesActivas, error: errorActivas } = await supabase
        .from('canciones_simulador_acordeon')
        .select('*')
        .eq('estado', 'activa');
      
      console.log('🟢 Canciones activas:', cancionesActivas?.length || 0);
      if (errorActivas) {
        console.error('❌ Error obteniendo canciones activas:', errorActivas);
      }
      
      const { data: cancionesPublicas, error: errorPublicas } = await supabase
        .from('canciones_simulador_acordeon')
        .select('*')
        .eq('es_publica', true);
      
      console.log('🌐 Canciones públicas:', cancionesPublicas?.length || 0);
      if (errorPublicas) {
        console.error('❌ Error obteniendo canciones públicas:', errorPublicas);
      }
      
      // Mostrar estructura de tabla
      if (todasCanciones && todasCanciones.length > 0) {
        console.log('📋 Estructura primera canción:', Object.keys(todasCanciones[0]));
        console.log('📝 Ejemplo canción:', todasCanciones[0]);
      }
      
         } catch (error) {
       console.error('💥 Error en diagnóstico:', error);
     }
   }

  // Función para crear canción de ejemplo
  async function crearCancionEjemplo() {
    try {
      console.log('➕ Creando canción de ejemplo...');
      
      const { supabase } = await import('$lib/supabase/clienteSupabase');
      
      // Obtener usuario actual (temporal - usar un ID fijo para pruebas)
      const creadorId = '00000000-0000-0000-0000-000000000001'; // ID temporal
      
      // Crear canción de ejemplo
      const cancionEjemplo = {
        titulo: 'Prueba Sincronización',
        artista: 'Editor Max',
        genero: 'vallenato',
        nivel_dificultad: 1,
        duracion_segundos: 30,
        bpm: 80,
        afinacion: 'FBE',
        url_audio: '/audio/bgm/aurora.mp3',
        url_audio_backing: '/audio/bgm/beyond.mp3',
        descripcion: 'Canción de prueba para sincronización perfecta',
        dificultad_tecnica: 'principiante',
        estado: 'activa',
        es_publica: true,
        orden_mostrar: 1,
        creador_id: creadorId,
        xp_recompensa: 50,
        monedas_recompensa: 25
      };
      
      const { data: cancionCreada, error: errorCancion } = await supabase
        .from('canciones_simulador_acordeon')
        .insert([cancionEjemplo])
        .select()
        .single();
      
      if (errorCancion) {
        console.error('❌ Error creando canción:', errorCancion);
        alert('Error creando canción: ' + errorCancion.message);
        return;
      }
      
      console.log('✅ Canción creada:', cancionCreada);
      
      // Crear secuencia de ejemplo
      const secuenciaEjemplo = {
        cancion_id: cancionCreada.id,
        nombre_secuencia: 'Secuencia principal',
        descripcion: 'Secuencia de prueba para sincronización perfecta - 7 notas con timing exacto',
        tolerancia_timing_ms: 150,
        notas_secuencia: [
          {
            timestamp_ms: 3000,
            duracion_ms: 1000,
            nota_id: 'Do',
            fuelle_direccion: 'empujar',
            es_acorde: false,
            notas_acorde: [],
            intensidad: 'normal',
            es_opcional: false,
            tipo_nota: 'melodia'
          },
          {
            timestamp_ms: 5000,
            duracion_ms: 1000,
            nota_id: 'Re',
            fuelle_direccion: 'halar',
            es_acorde: false,
            notas_acorde: [],
            intensidad: 'normal',
            es_opcional: false,
            tipo_nota: 'melodia'
          },
          {
            timestamp_ms: 7000,
            duracion_ms: 1000,
            nota_id: 'Mi',
            fuelle_direccion: 'empujar',
            es_acorde: false,
            notas_acorde: [],
            intensidad: 'normal',
            es_opcional: false,
            tipo_nota: 'melodia'
          },
          {
            timestamp_ms: 9000,
            duracion_ms: 1000,
            nota_id: 'Fa',
            fuelle_direccion: 'halar',
            es_acorde: false,
            notas_acorde: [],
            intensidad: 'normal',
            es_opcional: false,
            tipo_nota: 'melodia'
          },
          {
            timestamp_ms: 11000,
            duracion_ms: 1000,
            nota_id: 'Sol',
            fuelle_direccion: 'empujar',
            es_acorde: false,
            notas_acorde: [],
            intensidad: 'normal',
            es_opcional: false,
            tipo_nota: 'melodia'
          },
          {
            timestamp_ms: 13000,
            duracion_ms: 1000,
            nota_id: 'La',
            fuelle_direccion: 'halar',
            es_acorde: false,
            notas_acorde: [],
            intensidad: 'normal',
            es_opcional: false,
            tipo_nota: 'melodia'
          },
          {
            timestamp_ms: 15000,
            duracion_ms: 1500,
            nota_id: 'Si',
            fuelle_direccion: 'empujar',
            es_acorde: false,
            notas_acorde: [],
            intensidad: 'normal',
            es_opcional: false,
            tipo_nota: 'melodia'
          }
        ],
        marcadores_tiempo: {
          intro_hasta_segundo: 10,
          verso_desde_segundo: 10,
          verso_hasta_segundo: 60,
          coro_desde_segundo: 60,
          coro_hasta_segundo: 120
        },
        es_secuencia_principal: true,
        estado: 'activa'
      };
      
      const { data: secuenciaCreada, error: errorSecuencia } = await supabase
        .from('secuencias_canciones_acordeon')
        .insert([secuenciaEjemplo])
        .select()
        .single();
      
      if (errorSecuencia) {
        console.error('❌ Error creando secuencia:', errorSecuencia);
        alert('Error creando secuencia: ' + errorSecuencia.message);
        return;
      }
      
      console.log('✅ Secuencia creada:', secuenciaCreada);
      alert('✅ Canción de ejemplo creada exitosamente');
      
      // Recargar canciones
      await cargarCanciones();
      
    } catch (error) {
      console.error('💥 Error creando canción ejemplo:', error);
      alert('Error creando canción ejemplo: ' + error.message);
    }
  }

  async function cargarCanciones() {
    cargandoCanciones = true;
    errorCargaCanciones = null;
    
    try {
      console.log('🎵 Iniciando carga de canciones...');
      cancionesDisponibles = await cancionesJuegoService.obtenerCancionesDisponibles();
      
      console.log('✅ Canciones cargadas exitosamente:', cancionesDisponibles.length);
      console.log('📝 Datos de canciones:', cancionesDisponibles);
      
      if (cancionesDisponibles.length === 0) {
        console.warn('⚠️ No se encontraron canciones disponibles');
        errorCargaCanciones = 'No se encontraron canciones disponibles. Verifica que existan canciones con estado "activa" y "es_publica" = true en la base de datos.';
      }
      
    } catch (error) {
      console.error('❌ Error cargando canciones:', error);
      errorCargaCanciones = `Error cargando canciones: ${error.message}`;
    } finally {
      cargandoCanciones = false;
    }
  }
  
  async function seleccionarCancion(cancion) {
    try {
      cancionSeleccionada = cancion;
      
      // Obtener secuencia principal
      secuenciaActual = await cancionesJuegoService.obtenerSecuenciaPrincipal(cancion.id);
      
      if (secuenciaActual) {
        notasCancion = cancionesJuegoService.parseNotasSecuencia(secuenciaActual);
        estadisticasCancion = cancionesJuegoService.calcularEstadisticas(notasCancion);
        
        console.log('Canción seleccionada:', cancion.titulo);
        console.log('Notas cargadas:', notasCancion.length);
        console.log('Estadísticas:', estadisticasCancion);
      }
      
          // Reiniciar estado
    reproduciendo = false;
    pausado = false;
    tiempoActual = 0;
    botonesGuiaActivos = {};
    botonesJugadorActivos = {};
    notaActual = null;
    notasProximas = [];
    
    // Reconfigurar callbacks después de seleccionar canción
    setTimeout(() => {
      configurarCallbacksJugador();
      
      // Sincronizar direcciones del fuelle de ambos acordeones
      if (acordeonGuiaRef && acordeonJugadorRef) {
        acordeonGuiaRef.direccion = acordeonJugadorRef.direccion;
        console.log('🔄 Direcciones sincronizadas:', acordeonJugadorRef.direccion);
      }
    }, 100);
    
  } catch (error) {
    console.error('Error seleccionando canción:', error);
    alert('Error cargando la canción seleccionada');
  }
  }
  
  // ===========================================
  // 🚀 INICIALIZACIÓN
  // ===========================================
  
  onMount(async () => {
    await cargarCanciones();
    
    // Configurar callbacks después de que se monten los componentes
    setTimeout(() => {
      configurarCallbacksJugador();
      
      // Sincronizar direcciones del fuelle de ambos acordeones
      if (acordeonGuiaRef && acordeonJugadorRef) {
        acordeonGuiaRef.direccion = acordeonJugadorRef.direccion;
        console.log('🔄 Direcciones iniciales sincronizadas:', acordeonJugadorRef.direccion);
      }
    }, 100);
  });
  
  // Formatear tiempo para display
  function formatearTiempo(ms) {
    const segundos = Math.floor(ms / 1000);
    const minutos = Math.floor(segundos / 60);
    const segundosRestantes = segundos % 60;
    return `${minutos}:${segundosRestantes.toString().padStart(2, '0')}`;
  }
</script>

<svelte:head>
  <title>🎮 Prueba Juego Acordeón | Academia Vallenata</title>
</svelte:head>

<FondoEspacial />

<div class="contenedor-juego">
  
  <!-- ===========================================
       📱 PANEL DE CONTROL
       =========================================== -->
  
  <div class="panel-control">
    <h1>🎮 Prueba de Juego - Acordeón Guía</h1>
    
    <!-- Selección de canción -->
    <div class="seleccion-cancion">
      <h3>🎵 Seleccionar Canción</h3>
      
      {#if cargandoCanciones}
        <div class="estado-carga">
          <p>⏳ Cargando canciones...</p>
        </div>
      {:else if errorCargaCanciones}
        <div class="error-carga">
          <p>❌ <strong>Error:</strong> {errorCargaCanciones}</p>
          <button class="boton-reintentar" on:click={cargarCanciones}>
            🔄 Intentar de nuevo
          </button>
        </div>
      {:else if cancionesDisponibles.length === 0}
        <div class="sin-canciones">
          <p>📭 No hay canciones disponibles</p>
          <button class="boton-reintentar" on:click={cargarCanciones}>
            🔄 Recargar
          </button>
        </div>
      {:else}
        <div class="lista-canciones">
          {#each cancionesDisponibles as cancion}
            <button 
              class="boton-cancion"
              class:activa={cancionSeleccionada?.id === cancion.id}
              on:click={() => seleccionarCancion(cancion)}
            >
              <div class="info-cancion">
                <strong>{cancion.titulo}</strong>
                <span>{cancion.artista}</span>
                <small>{cancion.dificultad_tecnica} • {cancion.duracion_segundos}s</small>
              </div>
            </button>
          {/each}
        </div>
      {/if}
    </div>
    
    <!-- Controles de reproducción -->
    <div class="controles-reproduccion">
      <h3>🎧 Controles</h3>
      <div class="botones-control">
        <button 
          class="boton-control iniciar" 
          on:click={iniciarReproduccion}
          disabled={!cancionSeleccionada || reproduciendo}
        >
          ▶️ Iniciar
        </button>
        
        <button 
          class="boton-control pausar"
          on:click={pausarReproduccion}
          disabled={!reproduciendo}
        >
          ⏸️ Pausar
        </button>
        
        <button 
          class="boton-control reiniciar"
          on:click={reiniciarReproduccion}
          disabled={!cancionSeleccionada}
        >
          🔄 Reiniciar
        </button>
      </div>
    </div>
    
    <!-- Información de reproducción -->
    <div class="info-reproduccion">
      <div class="tiempo-actual">
        <strong>Tiempo:</strong> {formatearTiempo(tiempoActual)}
      </div>
      
      {#if cancionSeleccionada}
        <div class="info-cancion-actual">
          <strong>Canción:</strong> {cancionSeleccionada.titulo}
          <br>
          <strong>BPM:</strong> {cancionSeleccionada.bpm}
          <br>
          <strong>Afinación:</strong> {cancionSeleccionada.afinacion}
        </div>
      {/if}
    </div>
    
    <!-- Panel de debug -->
    {#if mostrarDebug}
      <div class="panel-debug">
        <h3>🔧 Debug</h3>
        
        <div class="debug-controles">
          <label>
            <input type="checkbox" bind:checked={mostrarDebug} />
            Mostrar información de debug
          </label>
          
          <label>
            <input type="checkbox" bind:checked={mostrarAnimaciones} />
            Mostrar animaciones de notas
          </label>
          
          <label>
            🎯 Sincronización (ms): 
            <input 
              type="range" 
              min="0" 
              max="300" 
              step="10" 
              bind:value={offsetSincronizacion}
              style="width: 150px;"
            />
            <span>{offsetSincronizacion}ms</span>
          </label>
          
          <label>
            ⚡ Anticipación Acordeón Guía (ms): 
            <input 
              type="range" 
              min="500" 
              max="5000" 
              step="100" 
              bind:value={anticipacionAcordeonGuia}
              style="width: 150px;"
            />
            <span>{anticipacionAcordeonGuia}ms</span>
          </label>
          
          <button class="boton-debug" on:click={cargarCanciones}>
            🔄 Recargar canciones
          </button>
          
          <button class="boton-debug" on:click={diagnosticoBaseDatos}>
            🔍 Diagnóstico BD
          </button>
          
          <button class="boton-debug" on:click={crearCancionEjemplo}>
            ➕ Crear canción ejemplo
          </button>
          
          <button class="boton-debug" on:click={limpiarNotasPegadas}>
            🧹 Limpiar notas pegadas
          </button>
          
          <button class="boton-debug" on:click={limpiarTodasLasNotasJugador}>
            🔥 Limpiar todas las notas
          </button>
          
          <button class="boton-debug" on:click={diagnosticarEstadoNotas}>
            📊 Diagnóstico completo
          </button>
        </div>
        
        <div class="debug-estado">
          <p><strong>Estado de carga:</strong> {cargandoCanciones ? 'Cargando...' : 'Listo'}</p>
          <p><strong>Canciones disponibles:</strong> {cancionesDisponibles.length}</p>
          <p><strong>Offset sincronización:</strong> {offsetSincronizacion}ms</p>
          <p><strong>⚡ Anticipación acordeón guía:</strong> {anticipacionAcordeonGuia}ms</p>
          <p><strong>🎯 Tiempo vuelo de notas:</strong> {anticipacionAcordeonGuia - offsetSincronizacion}ms</p>
          <p><strong>🔄 Timing correcto:</strong> Guía se adelanta {anticipacionAcordeonGuia}ms, jugador suena en tiempo real</p>
          <p><strong>🎮 Notas activas en jugador:</strong> {Object.keys(botonesJugadorActivos).length}</p>
          <p><strong>⏱️ Timeouts activos:</strong> {timeoutsDesactivacion.size}</p>
          {#if Object.keys(botonesJugadorActivos).length > 2}
            <p style="color: #ff6b6b;"><strong>⚠️ DEMASIADAS NOTAS ACTIVAS</strong></p>
          {/if}
          {#if errorCargaCanciones}
            <p><strong>Error:</strong> {errorCargaCanciones}</p>
          {/if}
        </div>
        
        {#if estadisticasCancion}
          <div class="estadisticas">
            <strong>Estadísticas:</strong>
            <ul>
              <li>Total notas: {estadisticasCancion.totalNotas}</li>
              <li>Notas melodía: {estadisticasCancion.notasMelodia}</li>
              <li>Notas bajo: {estadisticasCancion.notasBajo}</li>
              <li>Cambios fuelle: {estadisticasCancion.cambiosFuelle}</li>
            </ul>
          </div>
        {/if}
        
        {#if notaActual}
          <div class="nota-actual">
            <strong>Nota actual:</strong>
            <ul>
              <li>ID: {notaActual.nota_id}</li>
              <li>Nombre: {notaActual.nota_nombre}</li>
              <li>Fuelle: {notaActual.fuelle_direccion}</li>
              <li>Tipo: {notaActual.tipo_nota}</li>
              <li>Timestamp: {notaActual.timestamp_ms}ms</li>
            </ul>
          </div>
        {/if}
        
                 <div class="botones-activos">
           <strong>🎯 Botones activos (Acordeón Guía):</strong>
           <ul>
             {#each Object.entries(botonesGuiaActivos) as [botonId, info]}
               <li class="boton-info">
                 <span class="boton-id">{botonId}</span>
                 <span class="boton-fuelle color-{info.colorFuelle || 'default'}">{info.direccionFuelle}</span>
                 <span class="boton-tiempo">{info.diferenciaTiempo || 0}ms</span>
                 <span class="boton-tipo">{info.tipo_nota || 'melodia'}</span>
               </li>
             {/each}
           </ul>
         </div>
         
         <div class="botones-activos">
           <strong>🎮 Botones activos (Acordeón Jugador):</strong>
           <ul>
             {#each Object.entries(botonesJugadorActivos) as [botonId, info]}
               <li class="boton-info">
                 <span class="boton-id">{botonId}</span>
                 <span class="boton-fuelle color-{info.colorFuelle || 'default'}">{info.direccionFuelle}</span>
                 <span class="boton-tiempo">{info.tiempoActivacion ? Date.now() - info.tiempoActivacion : 0}ms</span>
                 <span class="boton-tipo">{info.activacionAutomatica ? 'AUTO' : 'MANUAL'}</span>
                 <span class="boton-duracion">⏱️{info.duracionMs || 'N/A'}ms</span>
                 {#if info.tiempoActivacion && (Date.now() - info.tiempoActivacion) > (info.duracionMs || 600) + 200}
                   <span class="boton-pegada">⚠️ PEGADA</span>
                 {/if}
               </li>
             {/each}
           </ul>
         </div>
         
         <div class="notas-proximas">
           <strong>Notas próximas:</strong>
           <ul>
             {#each notasProximas as notaProxima}
               <li>{notaProxima.nota_id} - {Math.round(notaProxima.tiempoRestante)}ms</li>
             {/each}
           </ul>
         </div>
      </div>
    {/if}
  </div>
  
  <!-- ===========================================
       🪗 ACORDEONES DEL JUEGO
       =========================================== -->
  
  <div class="contenedor-acordeones">
    
    <!-- Acordeón Guía (Izquierda) -->
    <div class="acordeon-guia">
      <h2>🎯 Acordeón Guía</h2>
      <p>Notas que están sonando</p>
      
      <AcordeonSimulador
        bind:this={acordeonGuiaRef}
        modoEditor={false}
        deshabilitarInteraccion={true}
        bind:botonesActivos={botonesGuiaActivos}
        afinacion={cancionSeleccionada?.afinacion || 'FBE'}
        prefijoIdBoton="guia"
        imagenFondo="/Acordeon PRO MAX.png"
        anticipacionAcordeonGuia={anticipacionAcordeonGuia}
      />
    </div>
    
    <!-- Acordeón del Jugador (Derecha) -->
    <div class="acordeon-jugador">
      <h2>🎮 Tu Acordeón</h2>
      <p>Presiona las teclas que llegan aquí</p>
      
      <AcordeonSimulador
        bind:this={acordeonJugadorRef}
        modoEditor={false}
        deshabilitarInteraccion={false}
        bind:botonesActivos={botonesJugadorActivos}
        afinacion={cancionSeleccionada?.afinacion || 'FBE'}
        prefijoIdBoton="jugador"
        imagenFondo="/Acordeon Jugador.png"
      />
    </div>
    
  </div>
   
   <!-- Sincronizador de Audio -->
   <SincronizadorAudio
     bind:this={sincronizadorRef}
     cancionCompleta={cancionSeleccionada}
     {secuenciaActual}
     {notasCancion}
     {reproduciendo}
     {pausado}
     bind:tiempoActual
     {offsetSincronizacion}
     {anticipacionAcordeonGuia}
     on:notaActivada={manejarNotaActivada}
     on:notaDesactivada={manejarNotaDesactivada}
     on:notaProxima={manejarNotaProxima}
     on:audioTerminado={manejarAudioTerminado}
     on:errorAudio={manejarErrorAudio}
   />
   
   <!-- Animaciones de notas -->
   <AnimacionesNotas
     {notasProximas}
     {mostrarAnimaciones}
     velocidadAnimacion={2000}
   />
   
 </div>

<style>
  .contenedor-juego {
    display: flex;
    gap: 2rem;
    padding: 2rem;
    min-height: 100vh;
    color: white;
  }
  
  .panel-control {
    flex: 0 0 400px;
    background: rgba(0, 0, 0, 0.8);
    padding: 1.5rem;
    border-radius: 15px;
    backdrop-filter: blur(10px);
    border: 2px solid rgba(255, 255, 255, 0.1);
    height: fit-content;
    max-height: 90vh;
    overflow-y: auto;
  }
  
  .contenedor-acordeones {
    flex: 1;
    display: flex;
    gap: 1rem;
    align-items: flex-start;
    justify-content: space-evenly;
    padding: 0.5rem;
    width: 100%;
    min-height: 100vh;
  }
  
  .acordeon-guia, .acordeon-jugador {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-start;
    text-align: center;
    min-height: 900px;
    max-width: 50%;
    position: relative;
  }
  
  .acordeon-guia {
    border: 2px solid rgba(0, 255, 100, 0.3);
    border-radius: 12px;
    padding: 1.5rem;
    background: rgba(0, 255, 100, 0.05);
    position: relative;
    overflow: hidden;
  }
  
  .acordeon-jugador {
    border: 2px solid rgba(255, 100, 0, 0.3);
    border-radius: 12px;
    padding: 1.5rem;
    background: rgba(255, 100, 0, 0.05);
    position: relative;
    overflow: hidden;
  }
  
  /* 🎵 Estilos para reducir el tamaño de los acordeones */
  .contenedor-acordeones :global(.disposicion-acordeon) {
    transform: translate(-50%, -50%) scale(0.7) !important;
    transform-origin: center center !important;
    position: absolute !important;
    left: 50% !important;
    top: 50% !important;
    width: 95vh !important;
    height: 95vh !important;
  }
  
  .acordeon-guia h2, .acordeon-jugador h2 {
    font-size: 1.5rem;
    margin-bottom: 0.5rem;
    position: relative;
    z-index: 10;
  }
  
  .acordeon-guia p, .acordeon-jugador p {
    font-size: 0.9rem;
    margin-bottom: 1rem;
    color: #ccc;
    position: relative;
    z-index: 10;
  }
  
  .seleccion-cancion {
    margin-bottom: 2rem;
  }
  
  .lista-canciones {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    max-height: 200px;
    overflow-y: auto;
  }
  
  .boton-cancion {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    padding: 1rem;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.3s ease;
    text-align: left;
  }
  
  .boton-cancion:hover {
    background: rgba(255, 255, 255, 0.2);
    border-color: rgba(255, 255, 255, 0.4);
  }
  
  .boton-cancion.activa {
    background: rgba(0, 255, 100, 0.3);
    border-color: rgba(0, 255, 100, 0.5);
  }
  
  .info-cancion {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
  }
  
  .info-cancion strong {
    color: #fff;
    font-size: 0.9rem;
  }
  
  .info-cancion span {
    color: #ccc;
    font-size: 0.8rem;
  }
  
  .info-cancion small {
    color: #aaa;
    font-size: 0.7rem;
  }
  
  .controles-reproduccion {
    margin-bottom: 2rem;
  }
  
  .botones-control {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
  }
  
  .boton-control {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border: none;
    color: white;
    padding: 0.8rem 1.5rem;
    border-radius: 25px;
    cursor: pointer;
    font-weight: 600;
    transition: all 0.3s ease;
    font-size: 0.9rem;
  }
  
  .boton-control:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }
  
  .boton-control:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  .boton-control.iniciar {
    background: linear-gradient(135deg, #00ff88 0%, #00cc6a 100%);
  }
  
  .boton-control.pausar {
    background: linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%);
  }
  
  .boton-control.reiniciar {
    background: linear-gradient(135deg, #4ecdc4 0%, #44a08d 100%);
  }
  
  .info-reproduccion {
    background: rgba(255, 255, 255, 0.05);
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 2rem;
  }
  
  .tiempo-actual {
    font-size: 1.2rem;
    margin-bottom: 1rem;
  }
  
  .panel-debug {
    background: rgba(255, 255, 255, 0.05);
    padding: 1rem;
    border-radius: 8px;
    font-size: 0.8rem;
  }
  
  .panel-debug h3 {
    margin-top: 0;
  }
  
  .debug-controles {
    margin-bottom: 1rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  }
  
  .debug-controles label {
    display: block;
    margin-bottom: 0.5rem;
    align-items: center;
  }
  
  .debug-controles label input[type="range"] {
    vertical-align: middle;
    margin: 0 0.5rem;
  }
  
  .debug-controles label span {
    font-weight: bold;
    color: #4ecdc4;
    min-width: 50px;
    display: inline-block;
  }
  
  .debug-estado {
    margin-bottom: 1rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  }
  
  .boton-debug {
    background-color: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.3);
    color: white;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.7rem;
    margin-top: 0.5rem;
    transition: all 0.3s ease;
  }
  
  .boton-debug:hover {
    background-color: rgba(255, 255, 255, 0.2);
  }

  /* 🎨 Estilos para debug de botones activos */
  .boton-info {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.3rem;
    padding: 0.3rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 4px;
    font-size: 0.7rem;
  }

  .boton-id {
    font-weight: bold;
    color: #4ecdc4;
    min-width: 120px;
  }

  .boton-fuelle {
    padding: 2px 6px;
    border-radius: 3px;
    font-size: 0.6rem;
    font-weight: bold;
  }

  .boton-fuelle.color-verde {
    background-color: rgba(34, 139, 34, 0.3);
    color: #22ff22;
  }

  .boton-fuelle.color-rojo {
    background-color: rgba(220, 20, 60, 0.3);
    color: #ff6b6b;
  }

  .boton-tiempo {
    color: #ffeb3b;
    font-weight: bold;
  }

  .boton-tipo {
    padding: 2px 6px;
    border-radius: 3px;
    font-size: 0.6rem;
    font-weight: bold;
  }

  .boton-duracion {
    color: #ff9800;
    font-weight: bold;
  }

  .boton-pegada {
    background-color: rgba(255, 0, 0, 0.3);
    color: #ff6b6b;
    padding: 2px 6px;
    border-radius: 3px;
    font-size: 0.6rem;
    font-weight: bold;
    animation: parpadear 1s infinite;
  }

  .boton-id-unico {
    color: #9c27b0;
    font-size: 0.6rem;
    opacity: 0.7;
  }

  @keyframes parpadear {
    0%, 50% { opacity: 1; }
    51%, 100% { opacity: 0.3; }
  }
  
  .panel-debug ul {
    list-style: none;
    padding: 0;
  }
  
  .panel-debug li {
    padding: 0.2rem 0;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  }
  
  .contenedor-acordeon h2 {
    margin-bottom: 1rem;
    font-size: 2rem;
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
  }
  
    .contenedor-acordeon p {
    margin-bottom: 2rem;
    font-size: 1.1rem;
    color: #ccc;
  }

  /* Estados de carga */
  .estado-carga, .error-carga, .sin-canciones {
    text-align: center;
    padding: 20px;
    margin: 10px 0;
    border-radius: 8px;
  }

  .estado-carga {
    background-color: rgba(0, 123, 255, 0.1);
    border: 1px solid rgba(0, 123, 255, 0.3);
    color: #007bff;
  }

  .error-carga {
    background-color: rgba(255, 0, 0, 0.1);
    border: 1px solid rgba(255, 0, 0, 0.3);
    color: #ff6b6b;
  }

  .sin-canciones {
    background-color: rgba(255, 193, 7, 0.1);
    border: 1px solid rgba(255, 193, 7, 0.3);
    color: #ffc107;
  }

  .boton-reintentar {
    background-color: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.3);
    color: white;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
    margin-top: 10px;
    transition: all 0.3s ease;
  }

  .boton-reintentar:hover {
    background-color: rgba(255, 255, 255, 0.2);
    transform: translateY(-1px);
  }

  /* Responsive */
  @media (max-width: 1200px) {
    .contenedor-juego {
      flex-direction: column;
    }
    
    .panel-control {
      flex: none;
      max-height: none;
    }
    
    .contenedor-acordeones {
      flex-direction: column;
      align-items: center;
    }
    
    .acordeon-guia, .acordeon-jugador {
      max-width: 80%;
    }
    
    .contenedor-acordeones :global(.disposicion-acordeon) {
      transform: scale(0.8);
    }
  }
</style> 