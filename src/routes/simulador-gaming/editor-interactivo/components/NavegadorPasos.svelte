<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { editorStore } from '../stores/editorStore.js';
  import type { TipoContenido, PasoEditor } from '../types/tiposEditor.js';
  
  export let tipoContenido: TipoContenido;
  export let pasoActual: PasoEditor;

  const dispatch = createEventDispatcher<{
    cambioPaso: PasoEditor;
  }>();

  // Reactivo al store para obtener la configuración
  $: configuracion = $editorStore.configuracion;
  $: progreso = $editorStore.progreso;

  const manejarCambioPaso = (paso: PasoEditor) => {
    dispatch('cambioPaso', paso);
  };

  const obtenerEstadoPaso = (numeroPaso: PasoEditor) => {
    if (!configuracion) return 'pendiente';
    
    const paso = configuracion.pasos.find(p => p.numero === numeroPaso);
    if (!paso) return 'pendiente';
    
    if (paso.completado) return 'completado';
    if (numeroPaso === pasoActual) return 'actual';
    if (numeroPaso < pasoActual) return 'disponible';
    return 'pendiente';
  };

  const obtenerIconoPaso = (numeroPaso: PasoEditor) => {
    const estado = obtenerEstadoPaso(numeroPaso);
    
    switch (estado) {
      case 'completado':
        return '✓';
      case 'actual':
        return '▶';
      case 'disponible':
        return '○';
      default:
        return '○';
    }
  };

  const puedeNavegar = (numeroPaso: PasoEditor) => {
    const estado = obtenerEstadoPaso(numeroPaso);
    return estado === 'actual' || estado === 'disponible' || estado === 'completado';
  };
</script>

<div class="navegador-pasos">
  <div class="header">
    <h3>📋 Progreso del Editor</h3>
    <span class="progreso-texto">Progreso: {progreso}%</span>
  </div>

  {#if configuracion}
    <div class="pasos-container">
      <!-- Línea de progreso -->
      <div class="linea-progreso">
        <div class="linea-completada" style="width: {progreso}%"></div>
      </div>

      <!-- Pasos -->
      <div class="pasos">
        {#each configuracion.pasos as paso}
          {@const estado = obtenerEstadoPaso(paso.numero)}
          {@const navegable = puedeNavegar(paso.numero)}
          
          <div 
            class="paso"
            class:completado={estado === 'completado'}
            class:actual={estado === 'actual'}
            class:navegable={navegable}
            on:click={() => navegable && manejarCambioPaso(paso.numero)}
            role="button"
            tabindex={navegable ? 0 : -1}
          >
            <div class="circulo">
              {#if estado === 'completado'}
                ✓
              {:else}
                {paso.numero}
              {/if}
            </div>
            <div class="info">
              <h4>{paso.titulo}</h4>
              <p>{paso.descripcion}</p>
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>

<style>
  .navegador-pasos {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 15px;
    padding: 1.5rem;
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
  }

  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
  }

  .header h3 {
    color: #4ecdc4;
    margin: 0;
    font-size: 1.2rem;
  }

  .progreso-texto {
    color: white;
    font-weight: 500;
    font-size: 0.9rem;
  }

  .pasos-container {
    position: relative;
  }

  .linea-progreso {
    position: absolute;
    top: 25px;
    left: 0;
    right: 0;
    height: 2px;
    background: rgba(255, 255, 255, 0.2);
    z-index: 1;
  }

  .linea-completada {
    height: 100%;
    background: linear-gradient(90deg, #4ecdc4, #44a08d);
    transition: width 0.5s ease;
  }

  .pasos {
    display: flex;
    justify-content: space-between;
    position: relative;
    z-index: 2;
    gap: 1rem;
  }

  .paso {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    padding: 1rem;
    border-radius: 10px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.1);
    transition: all 0.3s ease;
    cursor: pointer;
  }

  .paso:hover {
    background: rgba(255, 255, 255, 0.1);
    transform: translateY(-2px);
  }

  .paso.actual {
    border-color: #4ecdc4;
    background: rgba(78, 205, 196, 0.1);
    box-shadow: 0 0 15px rgba(78, 205, 196, 0.3);
  }

  .paso.completado {
    border-color: #44a08d;
    background: rgba(68, 160, 141, 0.1);
  }

  .paso:not(.navegable) {
    cursor: default;
    opacity: 0.6;
  }

  .paso:not(.navegable):hover {
    transform: none;
    background: rgba(255, 255, 255, 0.05);
  }

  .circulo {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 1.2rem;
    color: white;
    background: rgba(255, 255, 255, 0.1);
    border: 2px solid rgba(255, 255, 255, 0.2);
    margin-bottom: 1rem;
    transition: all 0.3s ease;
  }

  .paso.actual .circulo {
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    border-color: #4ecdc4;
    animation: pulse 2s infinite;
  }

  .paso.completado .circulo {
    background: linear-gradient(45deg, #44a08d, #2d7d32);
    border-color: #44a08d;
  }

  .info h4 {
    margin: 0 0 0.5rem 0;
    color: white;
    font-size: 1rem;
  }

  .info p {
    margin: 0;
    color: #b8b8d4;
    font-size: 0.8rem;
    line-height: 1.3;
  }

  @keyframes pulse {
    0%, 100% {
      box-shadow: 0 0 0 0 rgba(78, 205, 196, 0.7);
    }
    50% {
      box-shadow: 0 0 0 10px rgba(78, 205, 196, 0);
    }
  }

  @media (max-width: 768px) {
    .header {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.5rem;
    }
    
    .pasos {
      flex-direction: column;
      gap: 0.5rem;
    }
    
    .paso {
      flex-direction: row;
      text-align: left;
    }
    
    .circulo {
      width: 40px;
      height: 40px;
      font-size: 1rem;
      margin-bottom: 0;
      margin-right: 1rem;
    }
    
    .linea-progreso {
      display: none;
    }
  }
</style> 