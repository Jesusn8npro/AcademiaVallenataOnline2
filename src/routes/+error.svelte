<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import ModalBusqueda from '$lib/components/Busqueda/ModalBusqueda.svelte';
  import { onMount } from 'svelte';

  // Estado del modal de búsqueda
  let modalBusquedaAbierto = false;

  // Obtener información del error
  $: errorStatus = $page.status || 404;
  $: errorMessage = $page.error?.message || 'Página no encontrada';

  // Enlaces rápidos útiles
  const enlacesRapidos = [
    {
      titulo: 'Cursos de Acordeón',
      descripcion: 'Explora nuestros cursos completos',
      icono: '📚',
      url: '/cursos',
      color: 'from-blue-500 to-blue-700'
    },
    {
      titulo: 'Tutoriales Gratis',
      descripcion: 'Aprende canciones paso a paso',
      icono: '🎵',
      url: '/tutoriales',
      color: 'from-green-500 to-green-700'
    },
    {
      titulo: 'Simulador Virtual',
      descripcion: 'Practica sin instrumento físico',
      icono: '🎮',
      url: '/simulador-de-acordeon',
      color: 'from-purple-500 to-purple-700'
    },
    {
      titulo: 'Comunidad',
      descripcion: 'Conecta con otros estudiantes',
      icono: '👥',
      url: '/comunidad',
      color: 'from-teal-500 to-teal-700'
    }
  ];

  // Sugerencias inteligentes según el tipo de error
  $: sugerenciasInteligentes = getSugerenciasInteligentes(errorStatus);

  function getSugerenciasInteligentes(status: number) {
    switch (status) {
      case 404:
        return [
          '🔍 La página que buscas podría haber cambiado de ubicación',
          '📱 Verifica que la URL esté escrita correctamente',
          '🏠 Puedes regresar al inicio y explorar desde allí',
          '🔎 Usa nuestro buscador para encontrar contenido específico'
        ];
      case 500:
        return [
          '⚙️ Estamos experimentando problemas técnicos temporales',
          '🔄 Intenta recargar la página en unos momentos',
          '📞 Si el problema persiste, contáctanos',
          '🏠 Mientras tanto, puedes explorar otras secciones'
        ];
      default:
        return [
          '🤔 Algo inesperado ha ocurrido',
          '🔄 Intenta recargar la página',
          '🏠 Regresa al inicio para continuar navegando',
          '💬 Contáctanos si necesitas ayuda'
        ];
    }
  }

  function abrirModalBusqueda() {
    modalBusquedaAbierto = true;
  }

  function cerrarModalBusqueda() {
    modalBusquedaAbierto = false;
  }

  function irAInicio() {
    goto('/');
  }

  function irAContacto() {
    goto('/contacto');
  }

  // Efecto de partículas flotantes
  onMount(() => {
    crearParticulasFlotantes();
  });

  function crearParticulasFlotantes() {
    const container = document.querySelector('.particulas-container');
    if (!container) return;

    const particulas = ['🎵', '🎶', '🎼', '🎤', '🎸', '🥁'];
    
    for (let i = 0; i < 15; i++) {
      const particula = document.createElement('div');
      particula.className = 'particula-flotante';
      particula.textContent = particulas[Math.floor(Math.random() * particulas.length)];
      particula.style.left = Math.random() * 100 + '%';
      particula.style.animationDelay = Math.random() * 10 + 's';
      particula.style.animationDuration = (Math.random() * 10 + 10) + 's';
      container.appendChild(particula);
    }
  }
</script>

<svelte:head>
  <title>{errorStatus === 404 ? 'Página No Encontrada' : 'Error'} - Academia Vallenata Online</title>
  <meta name="description" content="La página que buscas no está disponible. Explora nuestros cursos y tutoriales de acordeón vallenato." />
</svelte:head>

<!-- Partículas flotantes de fondo -->
<div class="particulas-container"></div>

<div class="error-page">
  <!-- Hero Section -->
  <div class="hero-section">
    <div class="error-content">
      <!-- Número del error con efecto 3D -->
      <div class="error-number">
        <span class="numero-3d">{errorStatus}</span>
        <div class="numero-sombra">{errorStatus}</div>
      </div>

      <!-- Mensaje principal -->
      <div class="mensaje-principal">
        <h1 class="titulo-error">
          {#if errorStatus === 404}
            ¡Oops! Esta página se fue de parranda
          {:else if errorStatus === 500}
            ¡Ups! Nuestros servidores están afinando
          {:else}
            ¡Algo inesperado ocurrió!
          {/if}
        </h1>
        
        <p class="descripcion-error">
          {#if errorStatus === 404}
            La página que buscas no está aquí, pero tenemos muchísimo contenido increíble esperándote
          {:else if errorStatus === 500}
            Estamos trabajando para solucionar esto. Mientras tanto, explora nuestras otras secciones
          {:else}
            No te preocupes, esto puede pasar. Vamos a ayudarte a encontrar lo que necesitas
          {/if}
        </p>
      </div>

      <!-- Botones de acción principales -->
      <div class="botones-principales">
        <button 
          class="boton-principal boton-busqueda"
          on:click={abrirModalBusqueda}
        >
          <svg class="icono-busqueda" viewBox="0 0 24 24" fill="none">
            <circle cx="11" cy="11" r="8" stroke="currentColor" stroke-width="2"/>
            <path d="m21 21-4.35-4.35" stroke="currentColor" stroke-width="2"/>
          </svg>
          Buscar en la Academia
        </button>

        <button 
          class="boton-secundario boton-inicio"
          on:click={irAInicio}
        >
          <svg class="icono-home" viewBox="0 0 24 24" fill="none">
            <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" stroke="currentColor" stroke-width="2"/>
            <polyline points="9,22 9,12 15,12 15,22" stroke="currentColor" stroke-width="2"/>
          </svg>
          Ir al Inicio
        </button>
      </div>
    </div>
  </div>

  <!-- Sección de enlaces rápidos -->
  <div class="enlaces-rapidos-section">
    <h2 class="titulo-seccion">✨ Contenido Popular</h2>
    <div class="grid-enlaces">
      {#each enlacesRapidos as enlace}
        <a 
          href={enlace.url} 
          class="tarjeta-enlace bg-gradient-to-br {enlace.color}"
        >
          <div class="icono-enlace">{enlace.icono}</div>
          <h3 class="titulo-enlace">{enlace.titulo}</h3>
          <p class="descripcion-enlace">{enlace.descripcion}</p>
          <div class="flecha-enlace">→</div>
        </a>
      {/each}
    </div>
  </div>

  <!-- Sección de sugerencias -->
  <div class="sugerencias-section">
    <h2 class="titulo-seccion">💡 Sugerencias Útiles</h2>
    <div class="lista-sugerencias">
      {#each sugerenciasInteligentes as sugerencia}
        <div class="sugerencia-item">
          <div class="punto-sugerencia"></div>
          <span class="texto-sugerencia">{sugerencia}</span>
        </div>
      {/each}
    </div>
  </div>

  <!-- Sección de ayuda -->
  <div class="ayuda-section">
    <div class="ayuda-contenido">
      <h3 class="titulo-ayuda">¿Necesitas ayuda personalizada?</h3>
      <p class="descripcion-ayuda">
        Nuestro equipo está aquí para ayudarte. Contáctanos y resolveremos cualquier duda sobre nuestros cursos de acordeón.
      </p>
      <button 
        class="boton-contacto"
        on:click={irAContacto}
      >
        📞 Contactar Soporte
      </button>
    </div>
  </div>

  <!-- Footer minimalista -->
  <div class="footer-error">
    <p>© 2025 Academia Vallenata Online - La mejor forma de aprender acordeón</p>
  </div>
</div>

<!-- Modal de búsqueda -->
<ModalBusqueda 
  abierto={modalBusquedaAbierto} 
  onCerrar={cerrarModalBusqueda}
/>

<style>
  .error-page {
    min-height: 100vh;
    background: linear-gradient(135deg, 
      #667eea 0%, 
      #764ba2 25%, 
      #667eea 50%, 
      #f093fb 75%, 
      #f5576c 100%);
    background-size: 400% 400%;
    animation: gradientShift 15s ease infinite;
    position: relative;
    overflow-x: hidden;
    font-family: 'Inter', sans-serif;
  }

  .particulas-container {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    z-index: 1;
  }

  :global(.particula-flotante) {
    position: absolute;
    font-size: 2rem;
    opacity: 0.3;
    animation: flotar linear infinite;
    pointer-events: none;
  }

  @keyframes flotar {
    0% {
      transform: translateY(100vh) rotate(0deg);
      opacity: 0;
    }
    10% {
      opacity: 0.3;
    }
    90% {
      opacity: 0.3;
    }
    100% {
      transform: translateY(-100vh) rotate(360deg);
      opacity: 0;
    }
  }

  @keyframes gradientShift {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
  }

  .hero-section {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    padding: 2rem;
    position: relative;
    z-index: 2;
  }

  .error-content {
    text-align: center;
    max-width: 800px;
    margin: 0 auto;
  }

  .error-number {
    position: relative;
    margin-bottom: 2rem;
  }

     .numero-3d {
     font-size: clamp(8rem, 20vw, 16rem);
     font-weight: 900;
     background: linear-gradient(45deg, #fff, #ffd700, #fff);
     -webkit-background-clip: text;
     -webkit-text-fill-color: transparent;
     background-clip: text;
     text-shadow: 
       0 0 50px rgba(255,255,255,0.8),
       0 0 100px rgba(255,215,0,0.6),
       0 8px 16px rgba(0,0,0,0.3);
     position: relative;
     z-index: 2;
     display: block;
     animation: brillo 3s ease-in-out infinite alternate;
   }

   @keyframes brillo {
     0% {
       text-shadow: 
         0 0 50px rgba(255,255,255,0.8),
         0 0 100px rgba(255,215,0,0.6),
         0 8px 16px rgba(0,0,0,0.3);
     }
     100% {
       text-shadow: 
         0 0 80px rgba(255,255,255,1),
         0 0 140px rgba(255,215,0,0.8),
         0 8px 16px rgba(0,0,0,0.3);
     }
   }

  .numero-sombra {
    position: absolute;
    top: 8px;
    left: 8px;
    font-size: clamp(8rem, 20vw, 16rem);
    font-weight: 900;
    color: rgba(0,0,0,0.3);
    z-index: 1;
  }

  .mensaje-principal {
    margin-bottom: 3rem;
  }

  .titulo-error {
    font-size: clamp(2rem, 5vw, 3.5rem);
    font-weight: 800;
    color: white;
    margin-bottom: 1rem;
    text-shadow: 0 2px 10px rgba(0,0,0,0.3);
    line-height: 1.2;
  }

  .descripcion-error {
    font-size: clamp(1.1rem, 2.5vw, 1.3rem);
    color: rgba(255,255,255,0.9);
    margin-bottom: 0;
    line-height: 1.6;
    text-shadow: 0 1px 5px rgba(0,0,0,0.2);
  }

  .botones-principales {
    display: flex;
    gap: 1.5rem;
    justify-content: center;
    flex-wrap: wrap;
    margin-bottom: 4rem;
  }

     .boton-principal {
     display: flex;
     align-items: center;
     gap: 0.75rem;
     padding: 1.2rem 2.5rem;
     background: linear-gradient(45deg, #667eea, #764ba2);
     color: white;
     border: none;
     border-radius: 50px;
     font-size: 1.2rem;
     font-weight: 700;
     cursor: pointer;
     transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
     box-shadow: 
       0 15px 35px rgba(0,0,0,0.3),
       0 0 0 2px rgba(255,255,255,0.2);
     backdrop-filter: blur(10px);
   }

     .boton-principal:hover {
     transform: translateY(-5px) scale(1.05);
     box-shadow: 
       0 25px 50px rgba(0,0,0,0.4),
       0 0 0 3px rgba(255,255,255,0.3),
       0 0 30px rgba(102,126,234,0.6);
     background: linear-gradient(45deg, #5a67d8, #6b46c1);
   }

  .boton-secundario {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 1rem 2rem;
    background: rgba(255,255,255,0.1);
    color: white;
    border: 2px solid rgba(255,255,255,0.3);
    border-radius: 50px;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    backdrop-filter: blur(10px);
  }

  .boton-secundario:hover {
    background: rgba(255,255,255,0.2);
    border-color: rgba(255,255,255,0.5);
    transform: translateY(-2px);
  }

  .icono-busqueda,
  .icono-home {
    width: 20px;
    height: 20px;
  }

  .enlaces-rapidos-section,
  .sugerencias-section,
  .ayuda-section {
    padding: 3rem 2rem;
    position: relative;
    z-index: 2;
  }

  .titulo-seccion {
    text-align: center;
    font-size: 2.5rem;
    font-weight: 800;
    color: white;
    margin-bottom: 3rem;
    text-shadow: 0 2px 10px rgba(0,0,0,0.3);
  }

     .grid-enlaces {
     display: grid;
     grid-template-columns: repeat(4, 1fr);
     gap: 2rem;
     max-width: 1400px;
     margin: 0 auto;
   }

     .tarjeta-enlace {
     padding: 2rem;
     border-radius: 20px;
     text-decoration: none;
     color: white;
     transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
     position: relative;
     overflow: hidden;
     box-shadow: 0 10px 30px rgba(0,0,0,0.2);
     backdrop-filter: blur(10px);
   }

  .tarjeta-enlace:hover {
    transform: translateY(-5px) scale(1.02);
    box-shadow: 0 20px 50px rgba(0,0,0,0.3);
  }

  .icono-enlace {
    font-size: 3rem;
    margin-bottom: 1rem;
    display: block;
  }

  .titulo-enlace {
    font-size: 1.3rem;
    font-weight: 700;
    margin-bottom: 0.5rem;
    color: white;
  }

  .descripcion-enlace {
    font-size: 0.95rem;
    opacity: 0.9;
    margin-bottom: 1rem;
    line-height: 1.5;
  }

  .flecha-enlace {
    position: absolute;
    top: 1.5rem;
    right: 1.5rem;
    font-size: 1.5rem;
    opacity: 0.7;
    transition: all 0.3s ease;
  }

  .tarjeta-enlace:hover .flecha-enlace {
    transform: translateX(5px);
    opacity: 1;
  }

  .lista-sugerencias {
    max-width: 600px;
    margin: 0 auto;
    background: rgba(255,255,255,0.1);
    backdrop-filter: blur(10px);
    border-radius: 20px;
    padding: 2.5rem;
    border: 1px solid rgba(255,255,255,0.2);
  }

     .sugerencia-item {
     display: flex;
     align-items: flex-start;
     gap: 1rem;
     margin-bottom: 1.5rem;
   }

   .sugerencia-item:last-child {
     margin-bottom: 0;
   }

  .punto-sugerencia {
    width: 8px;
    height: 8px;
    background: white;
    border-radius: 50%;
    margin-top: 0.6rem;
    flex-shrink: 0;
  }

  .texto-sugerencia {
    color: white;
    font-size: 1.1rem;
    line-height: 1.6;
  }

  .ayuda-section {
    background: rgba(0,0,0,0.2);
    backdrop-filter: blur(20px);
  }

  .ayuda-contenido {
    max-width: 600px;
    margin: 0 auto;
    text-align: center;
  }

  .titulo-ayuda {
    font-size: 2rem;
    font-weight: 700;
    color: white;
    margin-bottom: 1rem;
  }

  .descripcion-ayuda {
    font-size: 1.1rem;
    color: rgba(255,255,255,0.9);
    line-height: 1.6;
    margin-bottom: 2rem;
  }

  .boton-contacto {
    padding: 1rem 2.5rem;
    background: linear-gradient(45deg, #ff6b6b, #feca57);
    color: white;
    border: none;
    border-radius: 50px;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 10px 25px rgba(0,0,0,0.2);
  }

  .boton-contacto:hover {
    transform: translateY(-3px);
    box-shadow: 0 15px 35px rgba(0,0,0,0.3);
  }

  .footer-error {
    text-align: center;
    padding: 2rem;
    background: rgba(0,0,0,0.3);
    color: rgba(255,255,255,0.7);
    font-size: 0.9rem;
  }

     /* Responsive */
   @media (max-width: 1200px) {
     .grid-enlaces {
       grid-template-columns: repeat(2, 1fr);
       gap: 1.5rem;
     }
   }

   @media (max-width: 768px) {
     .botones-principales {
       flex-direction: column;
       align-items: center;
     }

     .boton-principal,
     .boton-secundario {
       width: 100%;
       max-width: 300px;
     }

     .grid-enlaces {
       grid-template-columns: 1fr;
       gap: 1.5rem;
     }

     .lista-sugerencias {
       padding: 1.5rem;
     }
   }
</style> 