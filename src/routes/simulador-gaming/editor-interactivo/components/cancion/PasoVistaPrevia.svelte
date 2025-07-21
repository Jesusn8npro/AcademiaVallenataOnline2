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
  let reproduciendo = false;
  let tiempoActual = 0;
  let duracionTotal = 0;
  let volumen = 0.8;
  let velocidad = contenido.velocidad_grabacion || 1.0;
  let mensaje = '';
  let tipoMensaje = 'info';
  
  // Nuevas variables para reproducción fluida
  let audioContext: AudioContext | null = null;
  let tiempoInicioReproduccion = 0;
  let tiempoOffsetAudio = 0;
  let frameId: number | null = null;
  let notasEnCola: any[] = [];
  let notasProgramadas: any[] = [];
  let lookaheadTime = 0.1; // 100ms lookahead
  let scheduleInterval = 0.025; // 25ms scheduling interval
  let nextScheduleTime = 0;
  
  // Visualización
  let notasActivas: Set<string> = new Set();
  let notaActual: any = null;
  let siguienteNota: any = null;
  let direccionActual = contenido.direccion_inicial || 'halar';
  
  // Variables para manejar oscillators activos
  let botonesActivos: Record<string, any> = {};
  
  onMount(() => {
    inicializarAudioContext();
    inicializarReproductor();
    prepararPreview();
  });
  
  onDestroy(() => {
    limpiarRecursos();
  });
  
  const inicializarAudioContext = () => {
    try {
      audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      if (audioContext.state === 'suspended') {
        audioContext.resume();
      }
    } catch (error) {
      console.error('Error al inicializar AudioContext:', error);
    }
  };
  
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
    
    if (frameId) {
      cancelAnimationFrame(frameId);
    }
    
    detenerReproduccionSincronizada();
    
    if (audioContext) {
      audioContext.close();
    }
  };
  
  const prepararPreview = () => {
    if (!contenido.notas || contenido.notas.length === 0) {
      mensaje = 'No hay notas grabadas para previsualizar';
      tipoMensaje = 'error';
      return;
    }
    
    // Ordenar notas por tiempo
    notasEnCola = [...contenido.notas]
      .filter((nota: any) => !nota.activa)
      .sort((a: any, b: any) => a.tiempo - b.tiempo);
    
    mensaje = `🎵 Preview listo. Velocidad: ${velocidad}x | ${notasEnCola.length} notas`;
    tipoMensaje = 'success';
    
    console.log('🎵 Preview preparado con', notasEnCola.length, 'notas');
  };
  
  const reproducirSecuenciaSincronizada = () => {
    if (notasEnCola.length === 0) {
      mensaje = 'No hay notas para reproducir';
      tipoMensaje = 'error';
      return;
    }
    
    if (reproduciendo) {
      detenerReproduccionSincronizada();
      return;
    }
    
    if (!audioContext) {
      mensaje = 'Error: AudioContext no disponible';
      tipoMensaje = 'error';
      return;
    }
    
    // Iniciar reproducción
    reproduciendo = true;
    notasProgramadas = [];
    notasActivas.clear();
    
    // Iniciar audio
    if (reproductor) {
      reproductor.currentTime = tiempoActual;
      reproductor.play();
    }
    
    // Capturar tiempo de inicio
    tiempoInicioReproduccion = audioContext.currentTime;
    tiempoOffsetAudio = tiempoActual;
    nextScheduleTime = tiempoInicioReproduccion;
    
    // Iniciar bucle de programación de audio
    programarNotasAudio();
    
    // Iniciar bucle de visualización
    actualizarVisualizacion();
    
    mensaje = `🎵 Reproduciendo ${notasEnCola.length} notas`;
    tipoMensaje = 'info';
    
    console.log('🎵 Reproducción iniciada - Tiempo AudioContext:', tiempoInicioReproduccion);
  };
  
  const programarNotasAudio = () => {
    if (!audioContext || !reproduciendo) return;
    
    const tiempoActualAudio = audioContext.currentTime;
    const tiempoHastaLookahead = tiempoActualAudio + lookaheadTime;
    
    // Programar todas las notas que deben sonar en el siguiente lookahead
    notasEnCola.forEach((nota: any) => {
      const tiempoNotaAbsoluto = tiempoInicioReproduccion + (nota.tiempo - tiempoOffsetAudio);
      
      // Solo programar notas que están en el rango del lookahead
      if (tiempoNotaAbsoluto >= nextScheduleTime && tiempoNotaAbsoluto < tiempoHastaLookahead) {
        programarNotaIndividual(nota, tiempoNotaAbsoluto);
      }
    });
    
    // Actualizar siguiente tiempo de programación
    nextScheduleTime = tiempoHastaLookahead;
    
    // Continuar programando si seguimos reproduciendo
    if (reproduciendo) {
      setTimeout(() => programarNotasAudio(), scheduleInterval * 1000);
    }
  };
  
  const programarNotaIndividual = (nota: any, tiempoInicio: number) => {
    if (!audioContext || !acordeonRef) return;
    
    // Evitar programar la misma nota múltiples veces
    const notaId = `${nota.id}_${tiempoInicio}`;
    if (notasProgramadas.includes(notaId)) return;
    
    notasProgramadas.push(notaId);
    
    // Programar inicio de nota
    setTimeout(() => {
      if (!reproduciendo) return;
      
      if (acordeonRef?.reproducirTono) {
        const { oscillator } = acordeonRef.reproducirTono(nota.idBoton);
        botonesActivos = {
          ...botonesActivos,
          [nota.idBoton]: { 
            oscillator, 
            direccionFuelle: nota.direccion || 'halar',
            duracionOriginal: nota.duracion,
            tiempoInicio: audioContext?.currentTime || 0
          }
        };
      }
      
      // Programar detención de nota
      setTimeout(() => {
        if (!reproduciendo) return;
        
        if (acordeonRef?.detenerTono) {
          acordeonRef.detenerTono(nota.idBoton);
        }
        
        // Quitar de botones activos
        const newMap = { ...botonesActivos };
        delete newMap[nota.idBoton];
        botonesActivos = newMap;
        
      }, nota.duracion * 1000);
      
    }, (tiempoInicio - (audioContext?.currentTime || 0)) * 1000);
    
    console.log(`🎵 Programada nota: ${nota.nombre} en ${tiempoInicio.toFixed(3)}s`);
  };
  
  const actualizarVisualizacion = () => {
    if (!reproduciendo) return;
    
    // Limpiar visualización anterior
    if (acordeonRef?.limpiarTodasLasNotas) {
      acordeonRef.limpiarTodasLasNotas();
    }
    
    // Calcular tiempo actual relativo
    const tiempoReproduccionRelativo = tiempoActual - tiempoOffsetAudio;
    
    // Encontrar notas que deberían estar visibles
    const notasVisibles = notasEnCola.filter((nota: any) => {
      const tiempoInicio = nota.tiempo;
      const tiempoFin = nota.tiempo + nota.duracion;
      return tiempoReproduccionRelativo >= tiempoInicio && tiempoReproduccionRelativo <= tiempoFin;
    });
    
    // Actualizar dirección si es necesario
    if (notasVisibles.length > 0) {
      const notaVisible = notasVisibles[0];
      if (notaVisible.direccion && notaVisible.direccion !== direccionActual) {
        direccionActual = notaVisible.direccion;
        if (acordeonRef?.cambiarDireccion) {
          acordeonRef.cambiarDireccion(direccionActual);
        }
      }
    }
    
    // Mostrar notas visibles
    notasVisibles.forEach((nota: any) => {
      if (acordeonRef?.presionarBoton) {
        acordeonRef.presionarBoton(nota.idBoton);
      }
    });
    
    // Actualizar información de estado
    notaActual = notasVisibles[0] || null;
    siguienteNota = notasEnCola
      .filter((n: any) => n.tiempo > tiempoReproduccionRelativo)
      .sort((a: any, b: any) => a.tiempo - b.tiempo)[0] || null;
    
    // Continuar actualización visual
    if (reproduciendo) {
      frameId = requestAnimationFrame(actualizarVisualizacion);
    }
  };
  
  const detenerReproduccionSincronizada = () => {
    if (!reproduciendo) return;
    
    reproduciendo = false;
    
    if (reproductor) {
      reproductor.pause();
    }
    
    if (frameId) {
      cancelAnimationFrame(frameId);
      frameId = null;
    }
    
    // Detener todos los sonidos activos
    Object.keys(botonesActivos).forEach(idBoton => {
      if (acordeonRef?.detenerTono) {
        acordeonRef.detenerTono(idBoton);
      }
    });
    
    botonesActivos = {};
    notasProgramadas = [];
    notasActivas.clear();
    
    // Limpiar visualización
    if (acordeonRef?.limpiarTodasLasNotas) {
      acordeonRef.limpiarTodasLasNotas();
    }
    
    // Restaurar dirección original
    direccionActual = contenido.direccion_inicial || 'halar';
    if (acordeonRef?.cambiarDireccion) {
      acordeonRef.cambiarDireccion(direccionActual);
    }
    
    notaActual = null;
    siguienteNota = null;
    
    mensaje = '⏹️ Reproducción detenida';
    tipoMensaje = 'info';
    
    console.log('🎵 Reproducción detenida - Estado limpio');
  };
  
  const finalizarReproduccion = () => {
    detenerReproduccionSincronizada();
    mensaje = '✅ Reproducción completada';
    tipoMensaje = 'success';
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
  
  const validarYAvanzar = () => {
    if (!contenido.notas || contenido.notas.length === 0) {
      mensaje = 'No hay notas grabadas para publicar';
      tipoMensaje = 'error';
      return;
    }
    
    dispatch('avanzar', contenido);
  };
  
  const formatearTiempo = (segundos: number): string => {
    const minutos = Math.floor(segundos / 60);
    const segs = Math.floor(segundos % 60);
    return `${minutos}:${segs.toString().padStart(2, '0')}`;
  };
</script>

<div class="paso-vista-previa">
  <div class="header-paso">
    <h3>👁️ Paso 3: Vista Previa</h3>
    <p>Previsualiza la sincronización entre el audio y las notas grabadas</p>
  </div>
  
  <!-- Información de la canción -->
  <div class="info-cancion">
    <div class="metadatos">
      <h4>📝 {contenido.titulo}</h4>
      <p>Artista: {contenido.artista} | Género: {contenido.genero}</p>
      <p>Notas grabadas: {notasEnCola.length} | Duración: {formatearTiempo(duracionTotal)}</p>
    </div>
    
    <div class="estadisticas">
      <div class="stat">
        <span class="stat-valor">{notasEnCola.length}</span>
        <span class="stat-label">Notas</span>
      </div>
      <div class="stat">
        <span class="stat-valor">{velocidad}x</span>
        <span class="stat-label">Velocidad</span>
      </div>
      <div class="stat">
        <span class="stat-valor">{direccionActual}</span>
        <span class="stat-label">Dirección</span>
      </div>
    </div>
  </div>
  
  <!-- Controles de reproducción -->
  <div class="controles-preview">
    <div class="controles-principales">
      <button 
        class="btn-play-preview"
        on:click={reproducirSecuenciaSincronizada}
        disabled={!reproductor || notasEnCola.length === 0}
      >
        {reproduciendo ? '⏸️ Pausar' : '▶️ Reproducir Preview'}
      </button>
      
      <button 
        class="btn-stop-preview"
        on:click={detenerReproduccionSincronizada}
        disabled={!reproduciendo}
      >
        ⏹️ Detener
      </button>
      
      <button 
        class="btn-limpiar-preview"
        on:click={() => {
          detenerReproduccionSincronizada();
          notaActual = null;
          siguienteNota = null;
          mensaje = '🧹 Estado del acordeón limpiado - Todas las notas detenidas';
          tipoMensaje = 'success';
        }}
      >
        🧹 Limpiar Acordeón
      </button>
      
      <button 
        class="btn-verificar-preview"
        on:click={() => {
          console.log('🔍 Estado de reproducción:');
          console.log('- Reproduciendo:', reproduciendo);
          console.log('- Tiempo actual:', tiempoActual.toFixed(2) + 's');
          console.log('- Notas grabadas:', notasEnCola.length);
          console.log('- Botones activos:', Object.keys(botonesActivos).length);
          console.log('- Timeouts programados:', notasProgramadas.length);
          console.log('- Nota actual:', notaActual?.nombre || 'Ninguna');
          console.log('- Siguiente nota:', siguienteNota?.nombre || 'Ninguna');
          
          if (Object.keys(botonesActivos).length > 0) {
            console.log('🎵 Botones activos:', Object.keys(botonesActivos).map(id => {
              const boton = botonesActivos[id];
              return `${id} (${boton.notaId})`;
            }).join(', '));
          }
          
          mensaje = `🔍 Estado verificado - ${Object.keys(botonesActivos).length} notas activas`;
          tipoMensaje = 'info';
        }}
      >
        🔍 Verificar Estado
      </button>
      
              <button 
          class="btn-prueba-rapida"
          on:click={() => {
            // Prueba rápida: reproducir una nota de prueba
            if (notasEnCola.length > 0) {
              const notaPrueba = notasEnCola[0];
              
              // Reproducir sonido real
              if (acordeonRef?.reproducirTono) {
                const { oscillator } = acordeonRef.reproducirTono(notaPrueba.idBoton);
                botonesActivos = {
                  ...botonesActivos,
                  [notaPrueba.idBoton]: { 
                    oscillator, 
                    direccionFuelle: notaPrueba.direccion || 'halar',
                    duracionOriginal: notaPrueba.duracion,
                    tiempoInicio: Date.now()
                  }
                };
                
                // Detener después de 2 segundos
                setTimeout(() => {
                  if (acordeonRef?.detenerTono) {
                    acordeonRef.detenerTono(notaPrueba.idBoton);
                  }
                  // Quitar de botones activos
                  const newMap = { ...botonesActivos };
                  delete newMap[notaPrueba.idBoton];
                  botonesActivos = newMap;
                }, 2000);
                
                mensaje = `🧪 Prueba rápida: ${notaPrueba.nombre} por 2 segundos`;
                tipoMensaje = 'info';
              }
            } else {
              mensaje = '❌ No hay notas para probar';
              tipoMensaje = 'error';
            }
          }}
        >
          🧪 Prueba Rápida
        </button>
    </div>
    
    <div class="timeline-preview">
      <input 
        type="range"
        min="0"
        max={duracionTotal}
        value={tiempoActual}
        on:input={cambiarTiempo}
        class="slider-tiempo"
        disabled={reproduciendo}
      />
      <div class="tiempo-info">
        <span>{formatearTiempo(tiempoActual)}</span>
        <span>{formatearTiempo(duracionTotal)}</span>
      </div>
    </div>
    
    <div class="controles-adicionales">
      <div class="control-volumen">
        <label>🔊</label>
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
        <label>⏩</label>
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
  
  <!-- Información de notas en tiempo real -->
  <div class="info-tiempo-real">
    <div class="nota-actual">
      <h5>🎵 Nota Actual</h5>
      {#if notaActual}
        <div class="nota-info">
          <span class="nota-nombre">{notaActual.nombre}</span>
          <span class="nota-tiempo">{notaActual.tiempo.toFixed(2)}s</span>
          <span class="nota-direccion">{notaActual.direccion}</span>
          <div class="nota-duracion">
            Duración: {notaActual.duracion.toFixed(2)}s
          </div>
        </div>
      {:else}
        <p class="sin-nota">-</p>
      {/if}
    </div>
    
    <div class="siguiente-nota">
      <h5>⏭️ Siguiente Nota</h5>
      {#if siguienteNota}
        <div class="nota-info">
          <span class="nota-nombre">{siguienteNota.nombre}</span>
          <span class="nota-tiempo">{siguienteNota.tiempo.toFixed(2)}s</span>
          <span class="nota-direccion">{siguienteNota.direccion}</span>
          <div class="tiempo-restante">
            En {(siguienteNota.tiempo - tiempoActual).toFixed(1)}s
          </div>
        </div>
      {:else}
        <p class="sin-nota">-</p>
      {/if}
    </div>
    
    <div class="direccion-actual">
      <h5>🎶 Dirección Fuelle</h5>
      <div class="direccion-indicador" class:halar={direccionActual === 'halar'} class:empujar={direccionActual === 'empujar'}>
        {direccionActual === 'halar' ? '← Halar' : 'Empujar →'}
      </div>
    </div>
    
    <div class="estado-reproduccion">
      <h5>📊 Estado</h5>
      <div class="estado-info">
        {#if reproduciendo}
          <span class="estado-activo">🔴 Reproduciendo</span>
        {:else}
          <span class="estado-pausado">⏸️ Pausado</span>
        {/if}
        <div class="progreso-tiempo">
          {formatearTiempo(tiempoActual)} / {formatearTiempo(duracionTotal)}
        </div>
      </div>
    </div>
  </div>
  
  <!-- Simulador de acordeón -->
  <div class="simulador-preview">
    <div class="preview-acordeon-container">
      <AcordeonSimulador 
        bind:this={acordeonRef}
        afinacion={contenido.afinacion || 'FBE'}
        direccion={direccionActual}
        deshabilitarInteraccion={true}
        reproduciendo={reproduciendo}
        bind:botonesActivos={botonesActivos}
      />
    </div>
  </div>
  
  <!-- Línea de tiempo visual -->
  <div class="linea-tiempo-visual">
    <h5>📊 Línea de Tiempo</h5>
    <div class="timeline-container">
      <div class="timeline-track">
        {#each notasEnCola.slice(0, 50) as nota}
          <div 
            class="nota-timeline"
            style="
              left: {(nota.tiempo / duracionTotal) * 100}%; 
              width: {Math.max((nota.duracion / duracionTotal) * 100, 1)}%;
            "
            class:activa={notaActual && notaActual.id === nota.id}
          >
            <span class="nota-nombre-timeline">{nota.nombre}</span>
          </div>
        {/each}
        
        <div 
          class="indicador-tiempo"
          style="left: {(tiempoActual / duracionTotal) * 100}%"
        ></div>
      </div>
    </div>
  </div>
  
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
      ← Regresar a Grabación
    </button>
    
    <button 
      class="btn-avanzar"
      on:click={validarYAvanzar}
      disabled={notasEnCola.length === 0}
    >
      Continuar a Publicación →
    </button>
  </div>
</div>

<style>
  .paso-vista-previa {
    padding: 1.5rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 15px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
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
  
  .info-cancion {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .metadatos h4 {
    color: #4ecdc4;
    margin-bottom: 0.5rem;
  }
  
  .metadatos p {
    color: #b8b8d4;
    margin: 0.2rem 0;
  }
  
  .estadisticas {
    display: flex;
    gap: 1rem;
  }
  
  .stat {
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
  }
  
  .stat-valor {
    font-size: 1.5rem;
    font-weight: bold;
    color: #4ecdc4;
  }
  
  .stat-label {
    font-size: 0.8rem;
    color: #b8b8d4;
  }
  
  .controles-preview {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  
  .controles-principales {
    display: flex;
    gap: 1rem;
    justify-content: center;
  }
  
  .btn-play-preview,
  .btn-stop-preview {
    padding: 1rem 2rem;
    border: none;
    border-radius: 25px;
    font-size: 1.1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-play-preview {
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
  }
  
  .btn-stop-preview {
    background: linear-gradient(45deg, #ff6b6b, #ee5a24);
    color: white;
  }
  
  .btn-limpiar-preview {
    padding: 0.8rem 1.5rem;
    border: none;
    border-radius: 25px;
    font-size: 1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    background: linear-gradient(45deg, #ffa726, #ff9800);
    color: white;
  }
  
  .btn-verificar-preview {
    padding: 0.8rem 1.5rem;
    border: none;
    border-radius: 25px;
    font-size: 1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    background: linear-gradient(45deg, #2196f3, #1976d2);
    color: white;
  }
  
  .btn-prueba-rapida {
    padding: 0.8rem 1.5rem;
    border: none;
    border-radius: 25px;
    font-size: 1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    background: linear-gradient(45deg, #9c27b0, #673ab7);
    color: white;
  }
  
  .btn-play-preview:hover,
  .btn-stop-preview:hover,
  .btn-limpiar-preview:hover,
  .btn-verificar-preview:hover,
  .btn-prueba-rapida:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }
  
  .timeline-preview {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .slider-tiempo {
    width: 100%;
    height: 8px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 4px;
    outline: none;
    appearance: none;
  }
  
  .slider-tiempo::-webkit-slider-thumb {
    appearance: none;
    width: 20px;
    height: 20px;
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
  
  .controles-adicionales {
    display: flex;
    gap: 2rem;
    justify-content: center;
    align-items: center;
  }
  
  .control-volumen,
  .control-velocidad {
    display: flex;
    align-items: center;
    gap: 0.5rem;
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
  
  .info-tiempo-real {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
  }
  
  .nota-actual,
  .siguiente-nota,
  .direccion-actual {
    text-align: center;
  }
  
  .nota-actual h5,
  .siguiente-nota h5,
  .direccion-actual h5 {
    color: #4ecdc4;
    margin-bottom: 0.5rem;
  }
  
  .nota-info {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
  }
  
  .nota-nombre {
    font-weight: bold;
    color: white;
  }
  
  .nota-tiempo,
  .nota-direccion {
    color: #b8b8d4;
    font-size: 0.9rem;
  }
  
  .nota-duracion,
  .tiempo-restante {
    color: #9ca3af;
    font-size: 0.8rem;
    font-style: italic;
    margin-top: 0.2rem;
  }
  
  .sin-nota {
    color: #666;
    font-style: italic;
  }
  
  .estado-reproduccion {
    text-align: center;
  }
  
  .estado-info {
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
  }
  
  .estado-activo {
    color: #ff6b6b;
    font-weight: bold;
    animation: pulsoRojo 1s ease-in-out infinite;
  }
  
  .estado-pausado {
    color: #ffa726;
    font-weight: bold;
  }
  
  .progreso-tiempo {
    color: #b8b8d4;
    font-size: 0.9rem;
  }
  
  @keyframes pulsoRojo {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
  }
  
  .direccion-indicador {
    padding: 0.5rem 1rem;
    border-radius: 20px;
    font-weight: bold;
    display: inline-block;
  }
  
  .direccion-indicador.halar {
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
  }
  
  .direccion-indicador.empujar {
    background: linear-gradient(45deg, #ff6b6b, #ee5a24);
    color: white;
  }
  
  .simulador-preview {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1rem;
    min-height: 200px;
  }
  
  .linea-tiempo-visual {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
  }
  
  .linea-tiempo-visual h5 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }
  
  .timeline-container {
    position: relative;
    height: 60px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 5px;
    overflow: hidden;
  }
  
  .timeline-track {
    position: relative;
    height: 100%;
    width: 100%;
  }
  
  .nota-timeline {
    position: absolute;
    top: 10px;
    height: 40px;
    background: rgba(78, 205, 196, 0.7);
    border-radius: 3px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.7rem;
    color: white;
    font-weight: bold;
    border: 1px solid rgba(78, 205, 196, 0.9);
  }
  
  .nota-timeline.activa {
    background: rgba(255, 107, 107, 0.9);
    border-color: #ff6b6b;
    animation: pulsoNota 0.5s ease-in-out;
  }
  
  @keyframes pulsoNota {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.1); }
  }
  
  .indicador-tiempo {
    position: absolute;
    top: 0;
    bottom: 0;
    width: 2px;
    background: #ff6b6b;
    z-index: 10;
  }
  
  .nota-nombre-timeline {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 100%;
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
    .info-cancion {
      flex-direction: column;
      gap: 1rem;
    }
    
    .controles-principales {
      flex-direction: column;
    }
    
    .controles-adicionales {
      flex-direction: column;
      gap: 1rem;
    }
    
    .info-tiempo-real {
      grid-template-columns: 1fr;
    }
    
    .acciones {
      flex-direction: column;
      gap: 1rem;
    }
  }
  
  /* Estilos para el preview del acordeón (copiados del editor-max) */
  .preview-acordeon-container :global(.disposicion-acordeon) {
    width: 50vh !important;
    height: 50vh !important;
    position: relative !important;
    left: auto !important;
    top: auto !important;
    transform: none !important;
    margin: 0 auto;
  }

  .preview-acordeon-container :global(.boton) {
    height: 2.5vh !important;
    width: 2.5vh !important;
    font-size: 0.9vh !important;
    margin-bottom: 0.5vh !important;
  }

  .preview-acordeon-container :global(.fila h4) {
    font-size: 0.6vh !important;
  }

  .preview-acordeon-container :global(.lado-teclas) {
    width: 1.7% !important;
  }

  .preview-acordeon-container :global(.lado-bajos) {
    width: 1.7% !important;
  }

  @media (max-width: 1200px) {
    .preview-acordeon-container :global(.disposicion-acordeon) {
      width: 45vh !important;
      height: 45vh !important;
    }
  }

  @media (max-width: 992px) {
    .preview-acordeon-container :global(.disposicion-acordeon) {
      width: 40vh !important;
      height: 40vh !important;
    }
  }

  @media (max-width: 768px) {
    .preview-acordeon-container :global(.disposicion-acordeon) {
      width: 35vh !important;
      height: 35vh !important;
    }
  }
</style> 