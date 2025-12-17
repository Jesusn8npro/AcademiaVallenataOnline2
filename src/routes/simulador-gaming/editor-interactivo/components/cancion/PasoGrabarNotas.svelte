<script lang="ts">
  import { createEventDispatcher, onMount, onDestroy } from 'svelte';
  import { browser } from '$app/environment';
  import AcordeonSimulador from '$lib/components/SimuladorDefinitivo/components/simulador/AcordeonSimulador.svelte';
  
  export let contenido: any = {};
  
  const dispatch = createEventDispatcher<{
    avanzar: any;
    actualizar: any;
    regresar: void;
  }>();
  
  let reproductor: HTMLAudioElement | null = null;
  let acordeonRef: any = null;
  let grabandoAcordeon = false;
  let reproduciendo = false;
  let pausado = false;
  let tiempoActual = 0;
  let duracionTotal = 0;
  let volumen = 0.8;
  let velocidad = 1.0;
  let mensaje = '';
  let tipoMensaje = 'info';
  
  // Grabación
  let notasGrabadas: any[] = [];
  let tiempoInicioGrabacion = 0;
  let botonesActivos: Record<string, any> = {};
  let direccion = 'halar';
  let afinacion = contenido.afinacion || 'FBE';
  
  // Intervalos
  let intervaloActualizacionTiempo: any;
  
  onMount(() => {
    inicializarReproductor();
  });
  
  onDestroy(() => {
    limpiarRecursos();
  });
  
  const inicializarReproductor = () => {
    if (!contenido.audio) return;
    
    reproductor = new Audio();
    reproductor.src = URL.createObjectURL(contenido.audio);
    reproductor.volume = volumen;
    reproductor.playbackRate = velocidad;
    
    reproductor.addEventListener('loadedmetadata', () => {
      duracionTotal = reproductor?.duration || 0;
    });
    
    reproductor.addEventListener('timeupdate', () => {
      tiempoActual = reproductor?.currentTime || 0;
    });
    
    reproductor.addEventListener('ended', () => {
      finalizarReproduccion();
    });
  };
  
  const limpiarRecursos = () => {
    if (reproductor) {
      reproductor.pause();
      reproductor.src = '';
    }
    
    if (intervaloActualizacionTiempo) {
      clearInterval(intervaloActualizacionTiempo);
    }
    
    detenerGrabacion();
  };
  
  const toggleReproduccion = () => {
    if (!reproductor) return;
    
    if (reproduciendo) {
      reproductor.pause();
      reproduciendo = false;
      pausado = true;
    } else {
      reproductor.play();
      reproduciendo = true;
      pausado = false;
    }
  };
  
  const detenerReproduccion = () => {
    if (!reproductor) return;
    
    reproductor.pause();
    reproductor.currentTime = 0;
    reproduciendo = false;
    pausado = false;
    tiempoActual = 0;
    
    if (grabandoAcordeon) {
      detenerGrabacion();
    }
  };
  
  const finalizarReproduccion = () => {
    reproduciendo = false;
    pausado = false;
    
    if (grabandoAcordeon) {
      detenerGrabacion();
    }
  };
  
  const cambiarTiempo = (e: Event) => {
    const input = e.target as HTMLInputElement;
    const nuevoTiempo = parseFloat(input.value);
    if (reproductor) {
      reproductor.currentTime = nuevoTiempo;
      tiempoActual = nuevoTiempo;
    }
  };
  
  const cambiarVolumen = (e: Event) => {
    const input = e.target as HTMLInputElement;
    volumen = parseFloat(input.value);
    if (reproductor) {
      reproductor.volume = volumen;
    }
  };
  
  const cambiarVelocidad = (e: Event) => {
    const input = e.target as HTMLInputElement;
    velocidad = parseFloat(input.value);
    if (reproductor) {
      reproductor.playbackRate = velocidad;
    }
  };
  
  const iniciarGrabacion = () => {
    if (!reproductor) {
      mensaje = 'No hay audio cargado';
      tipoMensaje = 'error';
      return;
    }
    
    // Limpiar estado
    grabandoAcordeon = true;
    tiempoInicioGrabacion = tiempoActual;
    notasGrabadas = [];
    
    mensaje = '🎵 Grabando... Toca el acordeón mientras reproduces el audio';
    tipoMensaje = 'info';
    
    // Iniciar reproducción automáticamente
    if (!reproduciendo) {
      toggleReproduccion();
    }
    
    console.log('🎵 Grabación iniciada - Estado limpio');
  };
  
  const detenerGrabacion = () => {
    if (!grabandoAcordeon) return;
    
    grabandoAcordeon = false;
    
    // Finalizar notas activas
    finalizarNotasActivas();
    
    mensaje = `✅ Grabación completada: ${notasGrabadas.length} notas grabadas`;
    tipoMensaje = 'success';
    
    // Actualizar contenido
    actualizarContenido();
    
    console.log('🏁 Grabación detenida - Estado limpio');
  };
  
  // Manejar cuando se presiona una nota
  const manejarNotaPresionada = (event: CustomEvent) => {
    if (!grabandoAcordeon) return;
    
    const { idBoton, nombre } = event.detail;
    const tiempoGrabacion = tiempoActual - tiempoInicioGrabacion;
    
    // PREVENIR DUPLICADOS: Solo crear nota si no hay una activa para este botón
    const notaExistente = notasGrabadas.find(n => n.idBoton === idBoton && n.activa);
    if (notaExistente) {
      console.log(`🚫 DUPLICADO IGNORADO: ${nombre} (${idBoton}) - Ya existe nota activa`);
      return;
    }
    
    // Crear nueva nota simple
    const nota = {
      id: `${idBoton}_${Date.now()}`,
      idBoton,
      nombre,
      tiempo: tiempoGrabacion,
      duracion: 0,
      direccion,
      direccionFuelle: direccion,
      activa: true,
      tiempoInicio: Date.now(),
      tiempoInicioGrabacion: tiempoGrabacion
    };
    
    // Agregar a la lista
    notasGrabadas.push(nota);
    
    console.log(`✅ NOTA GRABADA: ${nombre} (${idBoton}) - Tiempo: ${tiempoGrabacion.toFixed(2)}s - Dirección: ${direccion}`);
  };
  
  // Manejar cuando se libera una nota
  const manejarNotaLiberada = (event: CustomEvent) => {
    if (!grabandoAcordeon) return;
    
    const { idBoton, nombre } = event.detail;
    const tiempoGrabacion = tiempoActual - tiempoInicioGrabacion;
    
    // Buscar la última nota activa de este botón
    const ultimaNota = notasGrabadas.reverse().find(n => n.idBoton === idBoton && n.activa);
    notasGrabadas.reverse(); // Volver al orden original
    
    if (ultimaNota) {
      const duracionCalculada = tiempoGrabacion - ultimaNota.tiempoInicioGrabacion;
      
      // Finalizar la nota
      ultimaNota.duracion = Math.max(0.1, duracionCalculada);
      ultimaNota.activa = false;
      
      console.log(`✅ NOTA FINALIZADA: ${nombre} (${idBoton}) - Duración: ${ultimaNota.duracion.toFixed(2)}s`);
    }
    
    // Forzar actualización reactiva
    notasGrabadas = [...notasGrabadas];
  };
  
  // Manejar cambio de fuelle
  const manejarCambioFuelle = (event: CustomEvent) => {
    if (!grabandoAcordeon) return;
    
    const { direccion: nuevaDireccion } = event.detail;
    
    // Solo proceder si realmente cambió la dirección
    if (direccion === nuevaDireccion) return;
    
    console.log(`🌬️ CAMBIO DE FUELLE: ${direccion} → ${nuevaDireccion}`);
    
    // Finalizar todas las notas activas
    const notasActivas = notasGrabadas.filter(n => n.activa);
    const tiempoGrabacion = tiempoActual - tiempoInicioGrabacion;
    
    notasActivas.forEach(nota => {
      nota.duracion = Math.max(0.1, tiempoGrabacion - nota.tiempoInicioGrabacion);
      nota.activa = false;
    });
    
    // Cambiar dirección
    direccion = nuevaDireccion;
    
    console.log(`✅ Cambio de fuelle completado: ${nuevaDireccion}`);
  };
  
  const finalizarNotasActivas = () => {
    const tiempoGrabacion = tiempoActual - tiempoInicioGrabacion;
    
    // Finalizar todas las notas activas
    const notasActivas = notasGrabadas.filter(n => n.activa);
    
    notasActivas.forEach(nota => {
      nota.duracion = Math.max(0.1, tiempoGrabacion - nota.tiempoInicioGrabacion);
      nota.activa = false;
    });
    
    // Forzar actualización reactiva
    notasGrabadas = [...notasGrabadas];
  };


  
  const obtenerNombreNota = (idBoton: string): string => {
    // Mapear ID de botón a nombre de nota
    const mapaNombres = {
      'do': 'Do',
      're': 'Re',
      'mi': 'Mi',
      'fa': 'Fa',
      'sol': 'Sol',
      'la': 'La',
      'si': 'Si',
      // Agregar más según la configuración del acordeón
    };
    
    return mapaNombres[idBoton as keyof typeof mapaNombres] || idBoton;
  };
  

  
  const cambiarDireccion = (nuevaDireccion: string) => {
    // Usar la función mejorada del acordeón que maneja todo automáticamente
    if (acordeonRef?.cambiarDireccion) {
      acordeonRef.cambiarDireccion(nuevaDireccion);
    }
    
    // Actualizar dirección local
    direccion = nuevaDireccion;
  };
  
  const limpiarGrabacion = () => {
    detenerGrabacion();
    
    notasGrabadas = [];
    
    mensaje = 'Grabación limpiada';
    tipoMensaje = 'info';
    actualizarContenido();
  };
  
  const resetearEstadoAcordeon = () => {
    // El acordeón ya no necesita reseteo manual porque funciona como el simulador normal
    mensaje = 'Acordeón funcionando correctamente';
    tipoMensaje = 'info';
  };

  const resetearTodoEmergencia = () => {
    console.log('🚨 RESETEO DE EMERGENCIA ACTIVADO');
    
    // Detener grabación si está activa
    if (grabandoAcordeon) {
      grabandoAcordeon = false;
    }
    
    // Detener reproducción
    if (reproductor) {
      reproductor.pause();
      reproductor.currentTime = 0;
    }
    reproduciendo = false;
    
    // Limpiar notas
    notasGrabadas = [];
    
    mensaje = '🚨 Reseteo de emergencia completado - Todo limpio';
    tipoMensaje = 'warning';
    
    console.log('✅ Reseteo de emergencia completado');
  };
  
  const actualizarContenido = () => {
    const contenidoActualizado = {
      ...contenido,
      notas: notasGrabadas,
      velocidad_grabacion: velocidad,
      direccion_inicial: direccion,
      total_notas: notasGrabadas.length
    };
    
    dispatch('actualizar', contenidoActualizado);
  };
  
  const validarYAvanzar = () => {
    if (notasGrabadas.length === 0) {
      mensaje = 'Debe grabar al menos una nota';
      tipoMensaje = 'error';
      return;
    }
    
    actualizarContenido();
    dispatch('avanzar', {
      ...contenido,
      notas: notasGrabadas,
      velocidad_grabacion: velocidad,
      direccion_inicial: direccion,
      total_notas: notasGrabadas.length
    });
  };
  
  const formatearTiempo = (segundos: number): string => {
    const minutos = Math.floor(segundos / 60);
    const segs = Math.floor(segundos % 60);
    return `${minutos}:${segs.toString().padStart(2, '0')}`;
  };
</script>

<div class="paso-grabar-notas">
  <div class="header-paso">
    <h3>🎹 Paso 2: Grabar Notas</h3>
    <p>Graba las notas del acordeón mientras reproduces el audio</p>
  </div>
  
  <!-- Controles de reproducción -->
  <div class="controles-reproduccion">
    <div class="controles-principales">
      <button 
        class="btn-play"
        on:click={toggleReproduccion}
        disabled={!reproductor}
      >
        {reproduciendo ? '⏸️' : '▶️'}
      </button>
      
      <button 
        class="btn-stop"
        on:click={detenerReproduccion}
        disabled={!reproductor}
      >
        ⏹️
      </button>
      
      <div class="timeline">
        <input 
          type="range"
          min="0"
          max={duracionTotal}
          value={tiempoActual}
          on:input={cambiarTiempo}
          class="slider-tiempo"
        />
        <div class="tiempo-info">
          <span>{formatearTiempo(tiempoActual)}</span>
          <span>{formatearTiempo(duracionTotal)}</span>
        </div>
      </div>
    </div>
    
    <div class="controles-avanzados">
      <div class="control-volumen">
        <label>🔊 Volumen:</label>
        <input 
          type="range"
          min="0"
          max="1"
          step="0.1"
          value={volumen}
          on:input={cambiarVolumen}
          class="slider-volumen"
        />
      </div>
      
      <div class="control-velocidad">
        <label>⏩ Velocidad:</label>
        <input 
          type="range"
          min="0.5"
          max="2"
          step="0.1"
          value={velocidad}
          on:input={cambiarVelocidad}
          class="slider-velocidad"
        />
        <span>{velocidad}x</span>
      </div>
    </div>
  </div>
  
  <!-- Controles de grabación -->
  <div class="controles-grabacion">
    <div class="estado-grabacion">
      <div class="indicador-grabacion" class:activo={grabandoAcordeon}>
        <div class="pulso"></div>
        <span>{grabandoAcordeon ? 'GRABANDO' : 'LISTO'}</span>
      </div>
      
      <div class="contador-notas">
        <span>Notas grabadas: {notasGrabadas.length}</span>
      </div>
    </div>
    
    <div class="botones-grabacion">
      <button 
        class="btn-grabar"
        class:activo={grabandoAcordeon}
        on:click={grabandoAcordeon ? detenerGrabacion : iniciarGrabacion}
        disabled={!reproductor}
      >
        {grabandoAcordeon ? '⏹️ Detener' : '🔴 Grabar'}
      </button>
      
      <button 
        class="btn-limpiar"
        on:click={limpiarGrabacion}
        disabled={grabandoAcordeon || notasGrabadas.length === 0}
      >
        🗑️ Limpiar
      </button>
      
      <button 
        class="btn-resetear"
        on:click={resetearEstadoAcordeon}
        disabled={grabandoAcordeon}
        title="Resetear estado del acordeón si las notas se quedan pegadas"
      >
        🔄 Resetear
      </button>
      
      <button 
        class="btn-emergencia"
        on:click={resetearTodoEmergencia}
        title="🚨 Reseteo de emergencia - Limpia todo si algo se queda pegado"
      >
        🚨 Emergencia
      </button>
      
      <button 
        class="btn-ayuda"
        on:click={() => {
          // Ya no se necesita esta función porque el acordeón funciona como el simulador normal
          mensaje = 'El acordeón funciona correctamente, no se pegan las teclas';
          tipoMensaje = 'info';
        }}
        disabled={!grabandoAcordeon}
        title="🔓 Información sobre el funcionamiento"
      >
        ℹ️ Información
      </button>
    </div>
  </div>
  
  <!-- Control de dirección del fuelle -->
  <div class="control-direccion">
    <h4>🎵 Dirección del Fuelle</h4>
    <div class="botones-direccion">
      <button 
        class="btn-direccion"
        class:activo={direccion === 'halar'}
        on:click={() => cambiarDireccion('halar')}
      >
        ← Halar
      </button>
      <button 
        class="btn-direccion"
        class:activo={direccion === 'empujar'}
        on:click={() => cambiarDireccion('empujar')}
      >
        Empujar →
      </button>
    </div>
  </div>
  
  <!-- Simulador de acordeón -->
  <div class="simulador-acordeon">
    <h4>🪗 Simulador de Acordeón</h4>
    <div class="editor-max-acordeon">
      <AcordeonSimulador 
        bind:this={acordeonRef}
        {afinacion}
        {direccion}
        bind:botonesActivos
        on:notaPresionada={manejarNotaPresionada}
        on:notaLiberada={manejarNotaLiberada}
        on:cambioFuelle={manejarCambioFuelle}
      />
    </div>
  </div>
  
  <!-- Lista de notas grabadas -->
  {#if notasGrabadas.length > 0}
    <div class="lista-notas">
      <h4>📝 Notas Grabadas</h4>
      <div class="notas-container">
        {#each notasGrabadas.slice(0, 20) as nota, index}
          <div class="nota-item">
            <span class="nota-nombre">{nota.nombre}</span>
            <span class="nota-tiempo">{nota.tiempo.toFixed(2)}s</span>
            <span class="nota-duracion">{nota.duracion.toFixed(2)}s</span>
            <span class="nota-direccion">{nota.direccion}</span>
          </div>
        {/each}
        
        {#if notasGrabadas.length > 20}
          <div class="nota-item nota-mas">
            <span>... y {notasGrabadas.length - 20} notas más</span>
          </div>
        {/if}
      </div>
    </div>
  {/if}
  
  <!-- Mensaje de estado -->
  {#if mensaje}
    <div class="mensaje-estado" class:error={tipoMensaje === 'error'} class:success={tipoMensaje === 'success'}>
      {mensaje}
    </div>
  {/if}
  
  <!-- Acciones -->
  <div class="acciones">
    <button 
      class="btn-regresar"
      on:click={() => dispatch('regresar')}
    >
      ← Regresar
    </button>
    
    <button 
      class="btn-avanzar"
      on:click={validarYAvanzar}
      disabled={notasGrabadas.length === 0}
    >
      Continuar a Preview →
    </button>
  </div>
</div>

<style>
  .paso-grabar-notas {
    padding: 1.5rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 15px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.5rem;
  }

  .header-paso {
    grid-column: 1 / -1;
  }

  .simulador-acordeon {
    grid-column: 1 / -1;
  }
  
  .header-paso {
    text-align: center;
  }
  
  .header-paso h3 {
    font-size: 1.5rem;
    color: #4ecdc4;
    margin-bottom: 0.5rem;
  }
  
  .header-paso p {
    color: #b8b8d4;
  }
  
  .controles-reproduccion {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  
  .controles-principales {
    display: flex;
    align-items: center;
    gap: 1rem;
  }
  
  .btn-play,
  .btn-stop {
    width: 50px;
    height: 50px;
    border: none;
    border-radius: 50%;
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
    font-size: 1.2rem;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-play:hover,
  .btn-stop:hover {
    transform: scale(1.1);
  }
  
  .timeline {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .slider-tiempo {
    width: 100%;
    height: 6px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 3px;
    outline: none;
    appearance: none;
  }
  
  .slider-tiempo::-webkit-slider-thumb {
    appearance: none;
    width: 16px;
    height: 16px;
    background: #4ecdc4;
    border-radius: 50%;
    cursor: pointer;
  }
  
  .tiempo-info {
    display: flex;
    justify-content: space-between;
    font-size: 0.9rem;
    color: #b8b8d4;
  }
  
  .controles-avanzados {
    display: flex;
    gap: 2rem;
    align-items: center;
  }
  
  .control-volumen,
  .control-velocidad {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  
  .control-volumen label,
  .control-velocidad label {
    font-size: 0.9rem;
    color: #b8b8d4;
  }
  
  .slider-volumen,
  .slider-velocidad {
    width: 100px;
    height: 4px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 2px;
    outline: none;
    appearance: none;
  }
  
  .slider-volumen::-webkit-slider-thumb,
  .slider-velocidad::-webkit-slider-thumb {
    appearance: none;
    width: 12px;
    height: 12px;
    background: #4ecdc4;
    border-radius: 50%;
    cursor: pointer;
  }
  
  .controles-grabacion {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .estado-grabacion {
    display: flex;
    align-items: center;
    gap: 1rem;
  }
  
  .indicador-grabacion {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  
  .pulso {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    background: #666;
    transition: background 0.3s ease;
  }
  
  .indicador-grabacion.activo .pulso {
    background: #ff4444;
    animation: pulso 1s infinite;
  }
  
  @keyframes pulso {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }
  
  .contador-notas {
    color: #b8b8d4;
    font-size: 0.9rem;
  }
  
  .botones-grabacion {
    display: flex;
    gap: 1rem;
  }
  
  .btn-grabar {
    padding: 0.8rem 1.5rem;
    border: none;
    border-radius: 25px;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    background: linear-gradient(45deg, #ff4444, #cc3333);
    color: white;
  }
  
  .btn-grabar.activo {
    background: linear-gradient(45deg, #ffaa00, #ff8800);
  }
  
  .btn-limpiar {
    padding: 0.8rem 1.5rem;
    background: linear-gradient(45deg, #666, #555);
    color: white;
    border: none;
    border-radius: 25px;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-resetear {
    padding: 0.8rem 1.5rem;
    background: linear-gradient(45deg, #ffa726, #ff9800);
    color: white;
    border: none;
    border-radius: 25px;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .btn-emergencia {
    padding: 0.8rem 1.5rem;
    background: linear-gradient(45deg, #ff6b6b, #ee5a24);
    color: white;
    border: none;
    border-radius: 25px;
    cursor: pointer;
    transition: all 0.3s ease;
    font-weight: 600;
    box-shadow: 0 2px 8px rgba(255, 107, 107, 0.3);
    border: 2px solid rgba(255, 107, 107, 0.2);
  }
  
  .btn-emergencia:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(255, 107, 107, 0.4);
    background: linear-gradient(45deg, #ff5252, #d32f2f);
  }
  
  .btn-ayuda {
    padding: 0.8rem 1.5rem;
    background: linear-gradient(45deg, #2196f3, #1976d2);
    color: white;
    border: none;
    border-radius: 25px;
    cursor: pointer;
    transition: all 0.3s ease;
    font-weight: 600;
    box-shadow: 0 2px 8px rgba(33, 150, 243, 0.3);
  }
  
  .btn-ayuda:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(33, 150, 243, 0.4);
    background: linear-gradient(45deg, #1e88e5, #1565c0);
  }
  
  .btn-ayuda:disabled {
    opacity: 0.6;
    cursor: not-allowed;
    transform: none;
  }
  
  .btn-grabar:hover,
  .btn-limpiar:hover,
  .btn-resetear:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }
  
  .control-direccion {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
    text-align: center;
  }
  
  .control-direccion h4 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }
  
  .botones-direccion {
    display: flex;
    gap: 1rem;
    justify-content: center;
  }
  
  .btn-direccion {
    padding: 0.8rem 1.5rem;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-radius: 25px;
    background: rgba(255, 255, 255, 0.05);
    color: white;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-direccion.activo {
    border-color: #4ecdc4;
    background: rgba(78, 205, 196, 0.2);
  }
  
  .simulador-acordeon {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1rem;
    text-align: center;
  }

  .simulador-acordeon h4 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }

  /* Estilos específicos para el acordeón (copiados del Editor Max) */
  .editor-max-acordeon :global(.disposicion-acordeon) {
    width: 50vh !important;
    height: 50vh !important;
    position: relative !important;
    left: auto !important;
    top: auto !important;
    transform: none !important;
    margin: 0 auto;
  }

  .editor-max-acordeon :global(.boton) {
    height: 2.5vh !important;
    width: 2.5vh !important;
    font-size: 0.9vh !important;
    margin-bottom: 0.5vh !important;
  }

  .editor-max-acordeon :global(.fila h4) {
    font-size: 0.6vh !important;
  }

  .editor-max-acordeon :global(.lado-teclas) {
    width: 1.7% !important;
  }

  .editor-max-acordeon :global(.lado-bajos) {
    width: 1.7% !important;
  }

  @media (max-width: 1200px) {
    .editor-max-acordeon :global(.disposicion-acordeon) {
      width: 45vh !important;
      height: 45vh !important;
    }
  }

  @media (max-width: 992px) {
    .editor-max-acordeon :global(.disposicion-acordeon) {
      width: 40vh !important;
      height: 40vh !important;
    }
  }

  @media (max-width: 768px) {
    .paso-grabar-notas {
      grid-template-columns: 1fr;
    }

    .editor-max-acordeon :global(.disposicion-acordeon) {
      width: 35vh !important;
      height: 35vh !important;
    }
  }
  
  .lista-notas {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
  }
  
  .lista-notas h4 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }
  
  .notas-container {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 0.5rem;
    max-height: 200px;
    overflow-y: auto;
  }
  
  .nota-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.5rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 5px;
    font-size: 0.9rem;
  }
  
  .nota-nombre {
    font-weight: bold;
    color: #4ecdc4;
  }
  
  .nota-tiempo,
  .nota-duracion,
  .nota-direccion {
    color: #b8b8d4;
    font-size: 0.8rem;
  }
  
  .nota-mas {
    text-align: center;
    font-style: italic;
    color: #888;
  }
  
  .mensaje-estado {
    padding: 1rem;
    border-radius: 8px;
    text-align: center;
  }
  
  .mensaje-estado.success {
    background: rgba(76, 175, 80, 0.1);
    border: 1px solid rgba(76, 175, 80, 0.3);
    color: #4caf50;
  }
  
  .mensaje-estado.error {
    background: rgba(244, 67, 54, 0.1);
    border: 1px solid rgba(244, 67, 54, 0.3);
    color: #f44336;
  }
  
  .acciones {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .btn-regresar {
    padding: 0.8rem 1.5rem;
    background: rgba(255, 255, 255, 0.1);
    color: white;
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 25px;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-avanzar {
    padding: 1rem 2rem;
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
    border: none;
    border-radius: 25px;
    font-size: 1.1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-regresar:hover,
  .btn-avanzar:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }
  
  .btn-avanzar:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .controles-principales {
      flex-direction: column;
      align-items: stretch;
    }
    
    .controles-avanzados {
      flex-direction: column;
      gap: 1rem;
    }
    
    .controles-grabacion {
      flex-direction: column;
      gap: 1rem;
    }
    
    .botones-direccion {
      flex-direction: column;
    }
    
    .acciones {
      flex-direction: column;
      gap: 1rem;
    }
  }
</style> 