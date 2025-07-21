<script>
  // @ts-nocheck
  import { onMount } from 'svelte';
  
  // ===========================================
  // 🎯 PROPS DEL COMPONENTE
  // ===========================================
  
  export let notasProximas = [];
  export let coordenadasAcordeonGuia = { x: 0, y: 0 };
  export let coordenadasAcordeonJugador = { x: 0, y: 0 };
  export let mostrarAnimaciones = true;
  export let velocidadAnimacion = 2000; // ms para el viaje
  
  // ===========================================
  // 🎨 ESTADO DE ANIMACIONES
  // ===========================================
  
  let animacionesActivas = [];
  let contenedorRef = null;
  let ultimaActualizacion = 0;
  
  // ===========================================
  // 📍 CÁLCULO DE COORDENADAS
  // ===========================================
  
  function obtenerCoordenadasBoton(botonId) {
    const elemento = document.getElementById(botonId);
    if (!elemento) return null;
    
    const rect = elemento.getBoundingClientRect();
    const contenedorRect = contenedorRef?.getBoundingClientRect();
    
    if (!contenedorRect) return null;
    
    return {
      x: rect.left + rect.width / 2 - contenedorRect.left,
      y: rect.top + rect.height / 2 - contenedorRect.top
    };
  }
  
  // ===========================================
  // 🎮 GESTIÓN DE ANIMACIONES
  // ===========================================
  
  function crearAnimacion(nota) {
    const coordenadasOrigen = obtenerCoordenadasBoton(nota.nota_id);
    if (!coordenadasOrigen) return null;
    
    // Coordenadas destino (por ahora, centro de la pantalla)
    const coordenadasDestino = {
      x: coordenadasOrigen.x + 200, // Temporal: mover hacia la derecha
      y: coordenadasOrigen.y
    };
    
    return {
      id: `animacion-${nota.nota_id}-${Date.now()}`,
      notaId: nota.nota_id,
      inicio: coordenadasOrigen,
      destino: coordenadasDestino,
      progreso: 0,
      tiempoInicio: Date.now(),
      duracion: velocidadAnimacion,
      color: obtenerColorNota(nota),
      activa: true
    };
  }
  
  function obtenerColorNota(nota) {
    // Colores por tipo de nota
    const colores = {
      'melodia': '#00ff88',
      'bajo': '#ff6b6b',
      'default': '#4ecdc4'
    };
    
    return colores[nota.tipo_nota] || colores.default;
  }
  
  function actualizarAnimaciones() {
    if (!mostrarAnimaciones) return;
    
    const ahora = Date.now();
    
    // Actualizar animaciones existentes
    animacionesActivas = animacionesActivas.map(animacion => {
      const tiempoTranscurrido = ahora - animacion.tiempoInicio;
      const progreso = Math.min(tiempoTranscurrido / animacion.duracion, 1);
      
      return {
        ...animacion,
        progreso,
        activa: progreso < 1
      };
    }).filter(animacion => animacion.activa);
    
    // Crear nuevas animaciones para notas próximas
    for (const nota of notasProximas) {
      const yaExiste = animacionesActivas.some(a => a.notaId === nota.nota_id);
      
      if (!yaExiste && nota.tiempoRestante <= velocidadAnimacion) {
        const nuevaAnimacion = crearAnimacion(nota);
        if (nuevaAnimacion) {
          animacionesActivas = [...animacionesActivas, nuevaAnimacion];
        }
      }
    }
    
    ultimaActualizacion = ahora;
  }
  
  // ===========================================
  // 🎨 CÁLCULOS VISUALES
  // ===========================================
  
  function calcularPosicionAnimacion(animacion) {
    const { inicio, destino, progreso } = animacion;
    
    // Interpolación lineal suavizada
    const easeOutQuad = 1 - Math.pow(1 - progreso, 2);
    
    return {
      x: inicio.x + (destino.x - inicio.x) * easeOutQuad,
      y: inicio.y + (destino.y - inicio.y) * easeOutQuad
    };
  }
  
  function calcularOpacidad(animacion) {
    const { progreso } = animacion;
    
    // Fade in rápido, fade out suave
    if (progreso < 0.1) {
      return progreso * 10;
    } else if (progreso > 0.8) {
      return (1 - progreso) * 5;
    }
    
    return 1;
  }
  
  function calcularTamano(animacion) {
    const { progreso } = animacion;
    
    // Empieza pequeño y crece
    return 8 + (progreso * 4);
  }
  
  // ===========================================
  // 🔄 REACTIVOS Y LIFECYCLE
  // ===========================================
  
  let intervaloAnimacion;
  
  onMount(() => {
    // Iniciar loop de animación
    intervaloAnimacion = setInterval(actualizarAnimaciones, 16); // ~60fps
    
    return () => {
      if (intervaloAnimacion) {
        clearInterval(intervaloAnimacion);
      }
    };
  });
  
  // Reactivar cuando cambien las notas próximas
  $: if (notasProximas.length > 0) {
    actualizarAnimaciones();
  }
</script>

<div class="contenedor-animaciones" bind:this={contenedorRef}>
  {#if mostrarAnimaciones}
    <svg class="overlay-animaciones" width="100%" height="100%">
      <!-- Definir efectos y gradientes -->
      <defs>
        <filter id="glow">
          <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
          <feMerge> 
            <feMergeNode in="coloredBlur"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
        
        <radialGradient id="gradienteNota">
          <stop offset="0%" style="stop-color:currentColor;stop-opacity:1" />
          <stop offset="100%" style="stop-color:currentColor;stop-opacity:0.3" />
        </radialGradient>
      </defs>
      
      <!-- Renderizar animaciones activas -->
      {#each animacionesActivas as animacion}
        {@const posicion = calcularPosicionAnimacion(animacion)}
        {@const opacidad = calcularOpacidad(animacion)}
        {@const tamano = calcularTamano(animacion)}
        
        <!-- Círculo principal de la nota -->
        <circle
          cx={posicion.x}
          cy={posicion.y}
          r={tamano}
          fill={animacion.color}
          opacity={opacidad}
          filter="url(#glow)"
          class="nota-animada"
        />
        
        <!-- Estela de la nota -->
        <circle
          cx={posicion.x - 20}
          cy={posicion.y}
          r={tamano * 0.6}
          fill={animacion.color}
          opacity={opacidad * 0.5}
          class="estela-nota"
        />
        
        <!-- Línea de trayectoria -->
        <line
          x1={animacion.inicio.x}
          y1={animacion.inicio.y}
          x2={posicion.x}
          y2={posicion.y}
          stroke={animacion.color}
          stroke-width="2"
          opacity={opacidad * 0.3}
          stroke-dasharray="5,5"
          class="trayectoria-nota"
        />
      {/each}
    </svg>
  {/if}
  
  <!-- Debug info -->
  {#if animacionesActivas.length > 0}
    <div class="debug-animaciones">
      <small>Animaciones activas: {animacionesActivas.length}</small>
    </div>
  {/if}
</div>

<style>
  .contenedor-animaciones {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    z-index: 100;
  }
  
  .overlay-animaciones {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
  }
  
  .nota-animada {
    filter: drop-shadow(0 0 10px currentColor);
  }
  
  .estela-nota {
    filter: blur(2px);
  }
  
  .trayectoria-nota {
    stroke-linecap: round;
  }
  
  .debug-animaciones {
    position: absolute;
    top: 10px;
    right: 10px;
    background: rgba(0, 0, 0, 0.7);
    color: white;
    padding: 0.5rem;
    border-radius: 4px;
    font-size: 0.7rem;
    pointer-events: auto;
  }
  
  /* Animaciones CSS adicionales */
  @keyframes pulso {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.1); }
  }
  
  .nota-animada {
    animation: pulso 0.5s ease-in-out infinite;
  }
</style> 