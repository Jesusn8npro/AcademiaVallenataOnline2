<script lang="ts">
  import { createEventDispatcher, onMount } from 'svelte';

  export let tipo: 'info' | 'success' | 'warning' | 'error' = 'info';
  export let mensaje: string = '';
  export let autoCerrar: boolean = false;
  export let duracion: number = 5000;
  export let cerrable: boolean = true;

  const dispatch = createEventDispatcher<{
    cerrar: void;
  }>();

  let visible = false;
  let timeoutId: NodeJS.Timeout;

  onMount(() => {
    visible = true;
    
    if (autoCerrar) {
      timeoutId = setTimeout(() => {
        cerrar();
      }, duracion);
    }
    
    return () => {
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
    };
  });

  const cerrar = () => {
    visible = false;
    setTimeout(() => {
      dispatch('cerrar');
    }, 300);
  };

  const obtenerIcono = (tipo: string) => {
    switch (tipo) {
      case 'success':
        return '✅';
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      default:
        return 'ℹ️';
    }
  };

  const obtenerConfiguracion = (tipo: string) => {
    switch (tipo) {
      case 'success':
        return {
          color: '#4caf50',
          backgroundColor: 'rgba(76, 175, 80, 0.1)',
          borderColor: 'rgba(76, 175, 80, 0.3)'
        };
      case 'warning':
        return {
          color: '#ff9800',
          backgroundColor: 'rgba(255, 152, 0, 0.1)',
          borderColor: 'rgba(255, 152, 0, 0.3)'
        };
      case 'error':
        return {
          color: '#f44336',
          backgroundColor: 'rgba(244, 67, 54, 0.1)',
          borderColor: 'rgba(244, 67, 54, 0.3)'
        };
      default:
        return {
          color: '#2196f3',
          backgroundColor: 'rgba(33, 150, 243, 0.1)',
          borderColor: 'rgba(33, 150, 243, 0.3)'
        };
    }
  };

  $: configuracion = obtenerConfiguracion(tipo);
  $: icono = obtenerIcono(tipo);
</script>

<div 
  class="alerta-mensaje"
  class:visible
  class:info={tipo === 'info'}
  class:success={tipo === 'success'}
  class:warning={tipo === 'warning'}
  class:error={tipo === 'error'}
  style="
    --color-principal: {configuracion.color};
    --background-color: {configuracion.backgroundColor};
    --border-color: {configuracion.borderColor};
  "
  role="alert"
  aria-live="polite"
>
  <div class="contenido-alerta">
    <div class="icono-alerta">
      {icono}
    </div>
    
    <div class="mensaje-alerta">
      <p>{mensaje}</p>
    </div>
    
    {#if cerrable}
      <button 
        class="boton-cerrar"
        on:click={cerrar}
        aria-label="Cerrar alerta"
      >
        ×
      </button>
    {/if}
  </div>
  
  {#if autoCerrar}
    <div class="barra-progreso">
      <div 
        class="progreso-auto" 
        style="animation-duration: {duracion}ms"
      ></div>
    </div>
  {/if}
</div>

<style>
  .alerta-mensaje {
    position: fixed;
    top: 20px;
    right: 20px;
    z-index: 1000;
    min-width: 300px;
    max-width: 500px;
    background: var(--background-color);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    backdrop-filter: blur(10px);
    transform: translateX(100%);
    opacity: 0;
    transition: all 0.3s ease;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
  }

  .alerta-mensaje.visible {
    transform: translateX(0);
    opacity: 1;
  }

  .contenido-alerta {
    display: flex;
    align-items: flex-start;
    gap: 1rem;
    padding: 1rem;
  }

  .icono-alerta {
    font-size: 1.5rem;
    flex-shrink: 0;
    margin-top: 0.1rem;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
  }

  .mensaje-alerta {
    flex-grow: 1;
  }

  .mensaje-alerta p {
    margin: 0;
    color: white;
    font-size: 0.95rem;
    line-height: 1.4;
    word-wrap: break-word;
  }

  .boton-cerrar {
    background: none;
    border: none;
    color: var(--color-principal);
    font-size: 1.5rem;
    cursor: pointer;
    padding: 0;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: all 0.2s ease;
    flex-shrink: 0;
  }

  .boton-cerrar:hover {
    background: rgba(255, 255, 255, 0.1);
    transform: scale(1.1);
  }

  .boton-cerrar:active {
    transform: scale(0.9);
  }

  .barra-progreso {
    height: 3px;
    background: rgba(255, 255, 255, 0.2);
    width: 100%;
    overflow: hidden;
  }

  .progreso-auto {
    height: 100%;
    background: var(--color-principal);
    width: 100%;
    transform: translateX(-100%);
    animation: progressAnimation linear;
  }

  @keyframes progressAnimation {
    from {
      transform: translateX(-100%);
    }
    to {
      transform: translateX(0%);
    }
  }

  /* Variaciones por tipo */
  .alerta-mensaje.success {
    animation: successPulse 0.5s ease-in-out;
  }

  .alerta-mensaje.error {
    animation: errorShake 0.5s ease-in-out;
  }

  .alerta-mensaje.warning {
    animation: warningBounce 0.5s ease-in-out;
  }

  @keyframes successPulse {
    0%, 100% {
      transform: translateX(0) scale(1);
    }
    50% {
      transform: translateX(0) scale(1.02);
    }
  }

  @keyframes errorShake {
    0%, 100% {
      transform: translateX(0);
    }
    25% {
      transform: translateX(-5px);
    }
    75% {
      transform: translateX(5px);
    }
  }

  @keyframes warningBounce {
    0%, 100% {
      transform: translateX(0) translateY(0);
    }
    50% {
      transform: translateX(0) translateY(-3px);
    }
  }

  /* Responsive */
  @media (max-width: 768px) {
    .alerta-mensaje {
      top: 10px;
      right: 10px;
      left: 10px;
      min-width: unset;
      max-width: unset;
    }
    
    .contenido-alerta {
      padding: 0.8rem;
    }
    
    .icono-alerta {
      font-size: 1.3rem;
    }
    
    .mensaje-alerta p {
      font-size: 0.9rem;
    }
  }

  /* Modo oscuro mejorado */
  .alerta-mensaje.info {
    background: rgba(33, 150, 243, 0.15);
    border-color: rgba(33, 150, 243, 0.4);
  }

  .alerta-mensaje.success {
    background: rgba(76, 175, 80, 0.15);
    border-color: rgba(76, 175, 80, 0.4);
  }

  .alerta-mensaje.warning {
    background: rgba(255, 152, 0, 0.15);
    border-color: rgba(255, 152, 0, 0.4);
  }

  .alerta-mensaje.error {
    background: rgba(244, 67, 54, 0.15);
    border-color: rgba(244, 67, 54, 0.4);
  }

  /* Efectos de hover */
  .alerta-mensaje:hover {
    transform: translateX(0) translateY(-2px);
    box-shadow: 0 6px 25px rgba(0, 0, 0, 0.4);
  }

  /* Focus para accesibilidad */
  .boton-cerrar:focus {
    outline: none;
    box-shadow: 0 0 0 2px var(--color-principal);
  }

  /* Animación de entrada desde diferentes direcciones según el tipo */
  .alerta-mensaje.info {
    animation: slideInFromRight 0.3s ease-out;
  }

  .alerta-mensaje.success {
    animation: slideInFromTop 0.3s ease-out;
  }

  .alerta-mensaje.warning {
    animation: slideInFromBottom 0.3s ease-out;
  }

  .alerta-mensaje.error {
    animation: slideInFromLeft 0.3s ease-out;
  }

  @keyframes slideInFromRight {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  @keyframes slideInFromTop {
    from {
      transform: translateY(-100%);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }

  @keyframes slideInFromBottom {
    from {
      transform: translateY(100%);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }

  @keyframes slideInFromLeft {
    from {
      transform: translateX(-100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }
</style> 