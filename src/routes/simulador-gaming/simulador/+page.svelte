<script>
// @ts-nocheck
import AcordeonSimulador from '$lib/components/SimuladorDefinitivo/components/simulador/AcordeonSimulador.svelte';
// FondoEspacial ya está en +layout.svelte - no duplicar import

// Variables de estado del simulador
let direccion = 'halar';
let afinacion = 'FBE';
let botonesActivos = {};
let acordeonRef = null;

// Variables para grabación local
let grabando = false;
let reproduciendo = false;
let notasGrabadas = [];
let tiempoInicioGrabacion = 0;
let tiempoInicioReproduccion = 0;
let audioContext = null;
let frameId = null;
let mensaje = '';

// Inicializar AudioContext
const inicializarAudioContext = async () => {
  try {
    audioContext = new (window.AudioContext || window.webkitAudioContext)();
    if (audioContext.state === 'suspended') {
      await audioContext.resume();
    }
  } catch (error) {
    console.error('Error al inicializar AudioContext:', error);
  }
};

// Inicializar cuando se monta el componente
import { onMount, onDestroy } from 'svelte';

onMount(() => {
  inicializarAudioContext();
});

onDestroy(() => {
  if (frameId) {
    cancelAnimationFrame(frameId);
  }
  if (audioContext) {
    audioContext.close();
  }
});

// Función para iniciar grabación
const iniciarGrabacion = async () => {
  if (!audioContext) {
    await inicializarAudioContext();
  }
  
  grabando = true;
  notasGrabadas = [];
  tiempoInicioGrabacion = audioContext.currentTime;
  mensaje = '🎵 Grabando... Toca el acordeón';
  
  // console.log('🎵 Grabación iniciada');
};

// Función para detener grabación
const detenerGrabacion = () => {
  grabando = false;
  
  // Finalizar notas activas
  finalizarNotasActivas();
  
  mensaje = `✅ Grabación completada: ${notasGrabadas.length} notas`;
  
  // console.log('🏁 Grabación terminada con', notasGrabadas.length, 'notas');
};

// Función para finalizar notas activas
const finalizarNotasActivas = () => {
  if (!audioContext) return;
  
  const tiempoActual = audioContext.currentTime - tiempoInicioGrabacion;
  
  notasGrabadas.forEach(nota => {
    if (nota.activa) {
      nota.duracion = Math.max(0.1, tiempoActual - nota.tiempo);
      nota.activa = false;
    }
  });
  
  notasGrabadas = [...notasGrabadas];
};

// Manejar nota presionada
const manejarNotaPresionada = (event) => {
  if (!grabando || !audioContext) return;
  
  const { idBoton, nombre } = event.detail;
  const tiempoRelativo = audioContext.currentTime - tiempoInicioGrabacion;
  
  // Evitar duplicados
  const notaExistente = notasGrabadas.find(n => n.idBoton === idBoton && n.activa);
  if (notaExistente) return;
  
  // Crear nueva nota
  const nota = {
    id: `${idBoton}_${Date.now()}`,
    idBoton,
    nombre,
    tiempo: tiempoRelativo,
    duracion: 0,
    direccion,
    activa: true
  };
  
  notasGrabadas.push(nota);
  
  // console.log(`✅ Nota grabada: ${nombre} en ${tiempoRelativo.toFixed(2)}s`);
};

// Manejar nota liberada
const manejarNotaLiberada = (event) => {
  if (!grabando || !audioContext) return;
  
  const { idBoton } = event.detail;
  const tiempoRelativo = audioContext.currentTime - tiempoInicioGrabacion;
  
  // Buscar la última nota activa de este botón
  const ultimaNota = notasGrabadas.reverse().find(n => n.idBoton === idBoton && n.activa);
  notasGrabadas.reverse();
  
  if (ultimaNota) {
    ultimaNota.duracion = Math.max(0.1, tiempoRelativo - ultimaNota.tiempo);
    ultimaNota.activa = false;
    
    // console.log(`✅ Nota finalizada: ${ultimaNota.nombre} - Duración: ${ultimaNota.duracion.toFixed(2)}s`);
  }
  
  notasGrabadas = [...notasGrabadas];
};

// Manejar cambio de fuelle
const manejarCambioFuelle = (event) => {
  if (!grabando) return;
  
  const { direccion: nuevaDireccion } = event.detail;
  
  if (direccion === nuevaDireccion) return;
  
  // Finalizar notas activas antes del cambio
  finalizarNotasActivas();
  
  // Cambiar dirección
  direccion = nuevaDireccion;
  
  // console.log(`🌬️ Cambio de fuelle: ${nuevaDireccion}`);
};

// Función para reproducir secuencia
const reproducirSecuencia = () => {
  if (notasGrabadas.length === 0) {
    mensaje = '❌ No hay notas grabadas para reproducir';
    return;
  }
  
  if (reproduciendo) {
    detenerReproduccion();
    return;
  }
  
  if (!audioContext) {
    mensaje = '❌ Error: AudioContext no disponible';
    return;
  }
  
  reproduciendo = true;
  tiempoInicioReproduccion = audioContext.currentTime;
  mensaje = `🎵 Reproduciendo ${notasGrabadas.length} notas`;
  
  // Filtrar solo notas completas
  const notasCompletas = notasGrabadas.filter(n => !n.activa);
  
  // Programar cada nota con precisión de AudioContext
  notasCompletas.forEach(nota => {
    // Calcular tiempo absoluto para empezar la nota
    const tiempoAbsolutoInicio = tiempoInicioReproduccion + nota.tiempo;
    const tiempoAbsolutoFin = tiempoAbsolutoInicio + nota.duracion;
    
    // Programar inicio de nota con precisión
    const tiempoRelativoInicio = Math.max(0, tiempoAbsolutoInicio - audioContext.currentTime);
    setTimeout(() => {
      if (!reproduciendo) return;
      
      // Reproducir sonido
      if (acordeonRef?.reproducirTono) {
        acordeonRef.reproducirTono(nota.idBoton);
      }
      
      // Cambiar dirección si es necesario
      if (nota.direccion !== direccion) {
        direccion = nota.direccion;
      }
      
      // console.log(`🎵 Reproduciendo nota ${nota.nombre} a los ${nota.tiempo}s`);
      
    }, tiempoRelativoInicio * 1000);
    
    // Programar fin de nota con precisión
    const tiempoRelativoFin = Math.max(0, tiempoAbsolutoFin - audioContext.currentTime);
    setTimeout(() => {
      if (!reproduciendo) return;
      
      if (acordeonRef?.detenerTono) {
        acordeonRef.detenerTono(nota.idBoton);
      }
      
      // console.log(`🎵 Deteniendo nota ${nota.nombre} después de ${nota.duracion}s`);
      
    }, tiempoRelativoFin * 1000);
  });
  
  // Iniciar visualización en tiempo real
  actualizarVisualizacion();
  
  // Finalizar reproducción automáticamente
  const duracionTotal = Math.max(...notasCompletas.map(n => n.tiempo + n.duracion));
  setTimeout(() => {
    finalizarReproduccion();
  }, (duracionTotal * 1000) + 500);
  
  // console.log('🎵 Reproducción iniciada - Tiempo:', tiempoInicioReproduccion);
  // console.log('🎵 Notas a reproducir:', notasCompletas.map(n => `${n.nombre} (${n.tiempo}s-${n.tiempo+n.duracion}s)`));
};

// Función para actualizar visualización durante reproducción
const actualizarVisualizacion = () => {
  if (!reproduciendo || !audioContext) return;
  
  // Calcular tiempo transcurrido desde inicio de reproducción
  const tiempoTranscurrido = audioContext.currentTime - tiempoInicioReproduccion;
  
  // Limpiar visualización anterior
  if (acordeonRef?.limpiarTodasLasNotas) {
    acordeonRef.limpiarTodasLasNotas();
  }
  
  // Encontrar notas que deberían estar activas AHORA
  const notasActivas = notasGrabadas.filter(nota => {
    if (nota.activa) return false; // Ignorar notas no finalizadas
    const tiempoInicio = nota.tiempo;
    const tiempoFin = nota.tiempo + nota.duracion;
    return tiempoTranscurrido >= tiempoInicio && tiempoTranscurrido <= tiempoFin;
  });
  
  // Actualizar dirección del fuelle si es necesario
  if (notasActivas.length > 0) {
    const notaActiva = notasActivas[0];
    if (notaActiva.direccion !== direccion) {
      direccion = notaActiva.direccion;
    }
  }
  
  // Presionar botones visualmente para mostrar notas activas
  notasActivas.forEach(nota => {
    if (acordeonRef?.presionarBoton) {
      acordeonRef.presionarBoton(nota.idBoton);
    }
  });
  
  // Debug: mostrar qué notas están activas
  if (notasActivas.length > 0) {
    // console.log(`🎵 Tiempo ${tiempoTranscurrido.toFixed(2)}s: ${notasActivas.map(n => n.nombre).join(', ')}`);
  }
  
  // Continuar visualización a 60fps
  if (reproduciendo) {
    frameId = requestAnimationFrame(actualizarVisualizacion);
  }
};

// Función para detener reproducción
const detenerReproduccion = () => {
  reproduciendo = false;
  
  if (frameId) {
    cancelAnimationFrame(frameId);
    frameId = null;
  }
  
  // Limpiar visualización completamente
  if (acordeonRef?.limpiarTodasLasNotas) {
    acordeonRef.limpiarTodasLasNotas();
  }
  
  // Detener todos los sonidos activos
  Object.keys(botonesActivos).forEach(idBoton => {
    if (acordeonRef?.detenerTono) {
      acordeonRef.detenerTono(idBoton);
    }
  });
  
  // Limpiar array de botones activos
  botonesActivos = {};
  
  // Restaurar dirección original
  direccion = 'halar';
  
  mensaje = '⏹️ Reproducción detenida';
  
  // console.log('🎵 Reproducción detenida - Estado limpio');
};

// Función para finalizar reproducción
const finalizarReproduccion = () => {
  detenerReproduccion();
  mensaje = '✅ Reproducción completada';
  
  // console.log('🎵 Reproducción completada');
};

// Función para limpiar grabación
const limpiarGrabacion = () => {
  // Detener grabación si está activa
  if (grabando) {
    detenerGrabacion();
  }
  
  // Detener reproducción si está activa
  if (reproduciendo) {
    detenerReproduccion();
  }
  
  // Limpiar datos
  notasGrabadas = [];
  tiempoInicioGrabacion = 0;
  tiempoInicioReproduccion = 0;
  
  // Limpiar visualización
  if (acordeonRef?.limpiarTodasLasNotas) {
    acordeonRef.limpiarTodasLasNotas();
  }
  
  // Restaurar estado inicial
  direccion = 'halar';
  botonesActivos = {};
  
  mensaje = '🧹 Grabación limpiada - Estado inicial restaurado';
  
  // console.log('🧹 Grabación limpiada - Estado inicial restaurado');
};
</script>

<svelte:head>
  <title>Simulador de Acordeón - El REY</title>
</svelte:head>

<FondoEspacial />

<main>
  <div class="contenedor-simulador">
    <!-- Controles de grabación -->
    <div class="controles-grabacion">
      <div class="botones-principales">
        <button 
          class="btn-grabar" 
          class:activo={grabando}
          on:click={grabando ? detenerGrabacion : iniciarGrabacion}
        >
          {grabando ? '⏹️ Detener' : '🎤 Grabar'}
        </button>
        
        <button 
          class="btn-reproducir" 
          class:activo={reproduciendo}
          on:click={reproducirSecuencia}
          disabled={notasGrabadas.length === 0}
        >
          {reproduciendo ? '⏸️ Pausar' : '▶️ Reproducir'}
        </button>
        
        <button 
          class="btn-limpiar" 
          on:click={limpiarGrabacion}
          disabled={notasGrabadas.length === 0}
        >
          🧹 Limpiar
        </button>
        
        <button 
          class="btn-debug" 
          on:click={() => {
            // console.log('🔍 Estado actual:');
            // console.log('- Grabando:', grabando);
            // console.log('- Reproduciendo:', reproduciendo);
            // console.log('- Notas grabadas:', notasGrabadas.length);
            // console.log('- Notas completas:', notasGrabadas.filter(n => !n.activa).length);
            // console.log('- Dirección:', direccion);
            // console.log('- Botones activos:', Object.keys(botonesActivos).length);
            mensaje = '🔍 Estado mostrado en consola';
          }}
        >
          🔍 Debug
        </button>
      </div>
      
      <div class="info-grabacion">
        <span class="contador-notas">
          📝 {notasGrabadas.filter(n => !n.activa).length} notas completas
        </span>
        <span class="estado-grabacion" class:activo={grabando}>
          {grabando ? '🔴 GRABANDO' : '⏹️ Detenido'}
        </span>
        <span class="estado-reproduccion" class:activo={reproduciendo}>
          {reproduciendo ? '🎵 REPRODUCIENDO' : '⏸️ Pausado'}
        </span>
        <span class="estado-mensaje">
          {mensaje}
        </span>
      </div>
    </div>

    <div class="solo-escritorio">
      <div class="acordeon-container">
        <AcordeonSimulador 
          bind:this={acordeonRef}
          bind:direccion={direccion}
          bind:afinacion={afinacion}
          bind:botonesActivos={botonesActivos}
          on:notaPresionada={manejarNotaPresionada}
          on:notaLiberada={manejarNotaLiberada}
          on:cambioFuelle={manejarCambioFuelle}
        />
      </div>
    </div>
  </div>
</main>

<style>
  .contenedor-simulador {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 100vh;
    position: relative;
    padding-top: 70px;
  }

  .controles-grabacion {
    position: fixed;
    top: 80px;
    left: 20px;
    z-index: 1000;
    background: rgba(0, 0, 0, 0.8);
    padding: 1rem;
    border-radius: 15px;
    border: 2px solid #4ecdc4;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    backdrop-filter: blur(10px);
  }

  .botones-principales {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 0.5rem;
  }

  .btn-grabar, .btn-reproducir, .btn-limpiar, .btn-debug {
    padding: 0.5rem 1rem;
    border: none;
    border-radius: 25px;
    font-size: 0.9rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
  }

  .btn-grabar {
    background: linear-gradient(45deg, #ff6b6b, #ee5a24);
    color: white;
  }

  .btn-grabar.activo {
    background: linear-gradient(45deg, #e74c3c, #c0392b);
    animation: pulso 1s infinite;
  }

  .btn-reproducir {
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
  }

  .btn-reproducir.activo {
    background: linear-gradient(45deg, #2ecc71, #27ae60);
  }

  .btn-limpiar {
    background: linear-gradient(45deg, #ffa726, #ff9800);
    color: white;
  }

  .btn-debug {
    background: linear-gradient(45deg, #9c27b0, #673ab7);
    color: white;
  }

  .btn-grabar:hover, .btn-reproducir:hover, .btn-limpiar:hover, .btn-debug:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }

  .btn-grabar:disabled, .btn-reproducir:disabled, .btn-limpiar:disabled, .btn-debug:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
  }

  @keyframes pulso {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.05); }
  }

  .info-grabacion {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    font-size: 0.8rem;
  }

  .contador-notas {
    color: #4ecdc4;
    font-weight: bold;
  }

  .estado-grabacion {
    color: #ff6b6b;
    font-weight: bold;
    font-size: 0.75rem;
  }

  .estado-grabacion.activo {
    color: #e74c3c;
    text-shadow: 0 0 5px rgba(231, 76, 60, 0.5);
    animation: parpadeo 1s infinite;
  }

  .estado-reproduccion {
    color: #4ecdc4;
    font-weight: bold;
    font-size: 0.75rem;
  }

  .estado-reproduccion.activo {
    color: #2ecc71;
    text-shadow: 0 0 5px rgba(46, 204, 113, 0.5);
  }

  .estado-mensaje {
    color: #b8b8d4;
    font-style: italic;
  }

  @keyframes parpadeo {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }

  .solo-escritorio {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 100%;
  }

  .acordeon-container {
    position: relative;
    width: 100%;
    height: 100%;
    max-width: 800px;
    max-height: 800px;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  @media screen and (min-width: 600px) {
    .solo-escritorio { 
      display: flex !important; 
    }
  }

  @media (max-width: 768px) {
    .controles-grabacion {
      position: fixed;
      top: 10px;
      left: 10px;
      right: 10px;
      width: auto;
    }
    
    .botones-principales {
      justify-content: center;
    }
    
    .acordeon-container {
      max-width: 600px;
      max-height: 600px;
    }
  }

  @media (max-width: 480px) {
    .acordeon-container {
      max-width: 400px;
      max-height: 400px;
    }
    
    .btn-grabar, .btn-reproducir, .btn-limpiar, .btn-debug {
      padding: 0.4rem 0.8rem;
      font-size: 0.8rem;
    }
  }
</style> 
  
 
