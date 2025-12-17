<!-- Página principal con efectos exactos de Rhythm Plus -->
<script lang="ts">
  import { goto } from '$app/navigation';
  import BotonInicio from '$lib/components/SimuladorDefinitivo/components/ui/BotonInicio.svelte';
  // FondoEspacial ya está en +layout.svelte - no duplicar import
  import { audioManager, TipoEfectoUI } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
  import { onMount } from 'svelte';
  
  let mostrarContenido = false;
  let logoEscala = 0;

  onMount(() => {
    // Animación de entrada progresiva
    setTimeout(() => {
      mostrarContenido = true;
      logoEscala = 1;
    }, 300);
  });

  function irAlSeleccionCanciones() {
    goto('/simulador-gaming/seleccion-canciones');
  }
  
  function irAAuth() {
    goto('/auth'); // Ruta para login/registro
  }

  function irAPruebaSonidos() {
    audioManager.transicion();
    goto('/simulador-gaming/prueba-sonidos');
    }

	// Función para hover en tarjetas (exacto de Rhythm Plus)
	function hoverTarjeta() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.HOVER_NAVEGACION);
    }
	
	// Función para click en tarjetas (exacto de Rhythm Plus)
	function clickTarjeta() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_GENERAL);
    }
	
	// Función para hover en botones (exacto de Rhythm Plus)
	function hoverBoton() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.HOVER_SUTIL);
      }
	
	// Función para click en botones (exacto de Rhythm Plus)
	function clickBoton() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
      }
	
	// Función para navegar con sonido
	function navegarConSonido(url: string) {
		audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
		setTimeout(() => {
			goto(url);
		}, 100);
    }
</script>

<svelte:head>
  <title>Simulador de Acordeón Pro</title>
  <meta name="description" content="Simulador profesional de acordeón con efectos gaming" />
</svelte:head>

<!-- Fondo espacial idéntico al de Rhythm Plus -->
<!-- FondoEspacial renderizado desde +layout.svelte -->

<div class="contenedor-principal">
  {#if mostrarContenido}
    <div class="centro-logo" style="transform: scale({logoEscala});">
      <!-- Logo con efectos -->
      <div class="logo-contenedor">
        <img 
          src="/Acordeon PRO MAX.png" 
          alt="Acordeón Pro Max" 
          class="logo-principal"
        />
        <div class="resplandor-logo"></div>
      </div>
      
      <!-- Botón principal de START GAME -->
      <div class="contenedor-boton-principal">
        <BotonInicio 
          text="START GAME" 
          variant="colored" 
          on:click={() => navegarConSonido('/simulador-gaming/seleccion-canciones')}
        />
      </div>
      <!-- Editor Max removido - funcionalidad no necesaria -->

      <!-- Botones secundarios -->
      <div class="botones-secundarios">
        <!-- Botón de demo de sonidos -->
        <button 
          class="boton-demo"
          on:mouseenter={hoverBoton}
          on:click={() => navegarConSonido('/simulador-gaming/prueba-sonidos')}
        >
          🎵 Probar Efectos de Sonido
        </button>
        
        <!-- Botón del editor clásico -->
        <button 
          class="boton-demo"
          on:mouseenter={hoverBoton}
          on:click={() => navegarConSonido('/simulador-gaming/editor-max')}
        >
          🎼 Editor Clásico
        </button>

        <!-- Botón de simulador -->
        <button 
          class="boton-demo"
          on:mouseenter={hoverBoton}
          on:click={() => navegarConSonido('/simulador-gaming/simulador')}
        >
          🪗 Simulador de Acordeón
        </button>


        
        <!-- Botón de autenticación (igual que Rhythm Plus) -->
        <div class="boton-texto" on:click={irAAuth} role="button" tabindex="0">
          Iniciar Sesión o Registrarse
        </div>
      </div>
    </div>
  {/if}
  
  <!-- Información de versión (igual que Rhythm Plus) -->
  <div class="info-version">
    Simulador v2.0 - Alpha
</div>
</div>

<style>
  .contenedor-principal {
    min-height: 100vh;
     display: flex;
     align-items: center;
    justify-content: center;
    position: relative;
   }
   
  .centro-logo {
     display: flex;
    flex-direction: column;
     align-items: center;
    gap: 2rem;
    transition: transform 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  }
  
  .logo-contenedor {
    position: relative;
     display: flex;
     justify-content: center;
     align-items: center;
    margin-bottom: 1rem;
  }
  
  .logo-principal {
    width: 400px;
    height: auto;
    filter: drop-shadow(0 10px 30px rgba(0, 0, 0, 0.3));
    transition: all 0.3s ease;
    z-index: 2;
    position: relative;
  }
  
  .logo-principal:hover {
    filter: drop-shadow(0 15px 40px rgba(0, 0, 0, 0.4));
    transform: scale(1.05);
   }
   
  .resplandor-logo {
     position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 450px;
    height: 250px;
    background: radial-gradient(
      ellipse at center,
      rgba(255, 165, 0, 0.3) 0%,
      rgba(255, 165, 0, 0.1) 50%,
      transparent 100%
    );
    border-radius: 50%;
    z-index: 1;
    animation: resplandor-pulso 3s ease-in-out infinite;
   }
   
  @keyframes resplandor-pulso {
    0%, 100% { opacity: 0.3; transform: translate(-50%, -50%) scale(1); }
    50% { opacity: 0.6; transform: translate(-50%, -50%) scale(1.1); }
  }
  
  .botones-secundarios {
     display: flex;
     flex-direction: column;
     align-items: center;
    gap: 1rem;
   }
   
  .boton-demo {
    background: linear-gradient(135deg, #667eea, #764ba2);
    border: none;
    border-radius: 25px;
    padding: 12px 24px;
    font-size: 14px;
     font-weight: 600;
    color: white;
     cursor: pointer;
    transition: all 0.3s ease;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
   }
   
  .boton-demo:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(102, 126, 234, 0.5);
    background: linear-gradient(135deg, #764ba2, #667eea);
  }
  
  .boton-texto {
    color: rgba(255, 255, 255, 0.8);
    font-size: 14px;
    cursor: pointer;
    transition: all 0.3s ease;
    text-decoration: none;
    font-weight: 500;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    border-bottom: 2px solid transparent;
    padding-bottom: 2px;
   }
   
  .boton-texto:hover {
    color: rgba(255, 255, 255, 1);
    border-bottom-color: rgba(255, 165, 0, 0.8);
    transform: translateY(-2px);
   }

  /* Estilos para Editor Max destacado */
  .editor-max-destacado {
    margin: 1rem 0;
    z-index: 5;
  }

  .boton-editor-max {
    position: relative;
    background: linear-gradient(45deg, 
      rgba(6, 182, 212, 0.9) 0%, 
      rgba(139, 92, 246, 0.9) 50%, 
      rgba(236, 72, 153, 0.9) 100%
    );
    border: 2px solid rgba(6, 182, 212, 0.8);
    border-radius: 20px;
    padding: 20px 40px;
    cursor: pointer;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 10px 40px rgba(6, 182, 212, 0.4);
    display: flex;
    align-items: center;
    gap: 15px;
    overflow: hidden;
    animation: editor-max-pulse 4s ease-in-out infinite;
    min-width: 280px;
  }

  .boton-editor-max:hover {
    transform: translateY(-5px) scale(1.05);
    box-shadow: 0 20px 60px rgba(6, 182, 212, 0.6);
    border-color: rgba(139, 92, 246, 1);
  }

  .icono-rayo {
    font-size: 2.5rem;
    animation: rayo-glow 2s ease-in-out infinite;
    z-index: 2;
  }

  .texto-editor-max {
    display: flex;
    flex-direction: column;
    text-align: left;
    z-index: 2;
  }

  .titulo-max {
    font-size: 1.5rem;
    font-weight: 900;
    color: white;
    text-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
    letter-spacing: 2px;
  }

  .subtitulo-max {
    font-size: 0.9rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.9);
    text-transform: uppercase;
    letter-spacing: 1px;
  }

  .brillo-max {
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: linear-gradient(45deg, 
      transparent 30%, 
      rgba(255, 255, 255, 0.3) 50%, 
      transparent 70%
    );
    animation: brillo-sweep 3s ease-in-out infinite;
    z-index: 1;
  }

  @keyframes editor-max-pulse {
    0%, 100% {
      box-shadow: 0 10px 40px rgba(6, 182, 212, 0.4);
    }
    50% {
      box-shadow: 0 15px 50px rgba(139, 92, 246, 0.6);
    }
  }

  @keyframes rayo-glow {
    0%, 100% {
      text-shadow: 0 0 10px rgba(255, 255, 255, 0.8);
    }
    50% {
      text-shadow: 0 0 20px rgba(255, 255, 255, 1), 0 0 30px rgba(6, 182, 212, 0.8);
    }
  }

  @keyframes brillo-sweep {
    0% {
      transform: translateX(-100%) translateY(-100%) rotate(45deg);
    }
    50% {
      transform: translateX(0%) translateY(0%) rotate(45deg);
    }
    100% {
      transform: translateX(100%) translateY(100%) rotate(45deg);
    }
  }
   
  .info-version {
    position: fixed;
    left: 15px;
    bottom: 15px;
    color: rgba(255, 255, 255, 0.3);
    font-size: 12px;
    font-weight: 300;
    z-index: 10;
   }
   
  /* Responsive */
  @media (max-width: 768px) {
    .logo-principal {
      width: 300px;
     }
   
    .resplandor-logo {
      width: 350px;
      height: 200px;
     }
   
    .centro-logo {
      gap: 1.5rem;
    }

    .boton-editor-max {
      min-width: 240px;
      padding: 15px 30px;
    }

    .titulo-max {
      font-size: 1.3rem;
    }

    .subtitulo-max {
      font-size: 0.8rem;
    }

    .icono-rayo {
      font-size: 2rem;
    }
    
    .info-version {
      display: none;
     }
   }
   
  @media (max-width: 480px) {
    .logo-principal {
      width: 250px;
     }
    
    .resplandor-logo {
      width: 300px;
      height: 150px;
     }
     
    .centro-logo {
      gap: 1rem;
    }
    
    .boton-demo {
      font-size: 12px;
      padding: 10px 20px;
     }

    .boton-editor-max {
      min-width: 200px;
      padding: 12px 25px;
      gap: 10px;
    }

    .titulo-max {
      font-size: 1.1rem;
      letter-spacing: 1px;
    }

    .subtitulo-max {
      font-size: 0.7rem;
    }

    .icono-rayo {
      font-size: 1.8rem;
    }
   }
</style> 

