<!-- Layout principal de la aplicación -->
<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import '../../app.css';
  import FondoPagina from '$lib/components/SimuladorDefinitivo/components/comunes/FondoPagina.svelte';
  import BarraNavegacion from '$lib/components/SimuladorDefinitivo/components/comunes/BarraNavegacion.svelte';
  import { audioManager } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
  import FondoEspacial from '$lib/components/SimuladorDefinitivo/components/efectos/FondoEspacial.svelte';
  import PaginaProximamente from '$lib/components/SimuladorDefinitivo/components/ui/PaginaProximamente.svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  
  // Determinar si estamos en una página de juego
  $: esJuego = $page.route.id?.includes('/juego');
  
  // Determinar si estamos en la página de preview (sin navegación)
  $: esPreview = $page.route.id?.includes('/preview');
  
  // 🔒 CONTROL DE ACCESO: Solo admins pueden acceder al simulador
  $: esAdmin = $usuario?.rol === 'admin';
  $: simuladorDisponible = esAdmin;
  
  let cargandoAuth = true;
  
  onMount(() => {
    // Configurar el título de la página
    document.title = 'Acordeón Plus - Simulador Musical';
    
    // Prevenir selección de texto en toda la aplicación
    document.body.classList.add('no-seleccionable');
    
    // Verificar autenticación
    const unsubscribe = usuario.subscribe((u) => {
      cargandoAuth = false;
    });
    
    // Inicializar música de fondo (exacto como Rhythm Plus) solo para admins
    if (simuladorDisponible) {
      setTimeout(() => {
        audioManager.playBgm();
      }, 1000);
    }

    return unsubscribe;
  });
</script>

<!-- Verificar si debe mostrar el simulador o la página de "proximamente" -->
{#if cargandoAuth}
  <!-- Estado de carga -->
  <div class="verificando-acceso">
    <FondoEspacial />
    <div class="loader-container">
      <div class="spinner"></div>
      <h2>Verificando acceso...</h2>
      <p>Comprobando permisos del simulador</p>
    </div>
  </div>

{:else if !simuladorDisponible}
  <!-- Mostrar página "Coming Soon" para no-admins -->
  <PaginaProximamente />

{:else}
  <!-- Simulador completo para admins -->
  <FondoEspacial />

  <!-- Barra de navegación (oculta en preview) -->
  {#if !esPreview}
    <BarraNavegacion navegacionJuego={esJuego} />
  {/if}

  <!-- Contenido de la página -->
  <main class="contenido-principal">
    <slot />
  </main>
{/if}

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
    background: #0f0f23;
    color: white;
    overflow-x: hidden;
  }
  
  :global(.no-seleccionable) {
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }
  
  :global(*) {
    box-sizing: border-box;
  }
  
  :global(:focus) {
    outline: 2px solid #4ecdc4;
    outline-offset: 2px;
  }
  
  :global(a) {
    color: #4ecdc4;
    text-decoration: none;
    transition: color 0.3s ease;
  }
  
  :global(a:hover) {
    color: #ff6b6b;
  }
  
  :global(button) {
    font-family: inherit;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  :global(button:hover) {
    transform: translateY(-1px);
  }
  
  :global(button:active) {
    transform: translateY(0);
  }
  
  :global(input, textarea, select) {
    font-family: inherit;
    font-size: 1rem;
    padding: 10px;
    border: 2px solid rgba(255, 255, 255, 0.2);
    border-radius: 10px;
    background: rgba(255, 255, 255, 0.1);
    color: white;
    transition: all 0.3s ease;
  }
  
  :global(input:focus, textarea:focus, select:focus) {
    border-color: #4ecdc4;
    background: rgba(255, 255, 255, 0.2);
  }
  
  :global(input::placeholder, textarea::placeholder) {
    color: rgba(255, 255, 255, 0.6);
  }
  
  :global(.btn-primario) {
    background: linear-gradient(135deg, #ff6b6b, #4ecdc4);
    border: none;
    border-radius: 25px;
    padding: 12px 24px;
    color: white;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  :global(.btn-primario:hover) {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(255, 107, 107, 0.4);
  }
  
  :global(.btn-secundario) {
    background: rgba(255, 255, 255, 0.2);
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-radius: 25px;
    padding: 12px 24px;
    color: white;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  :global(.btn-secundario:hover) {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-2px);
  }
  
  :global(.tarjeta) {
    background: rgba(255, 255, 255, 0.1);
    border: 2px solid rgba(255, 255, 255, 0.2);
    border-radius: 15px;
    padding: 20px;
    backdrop-filter: blur(10px);
    transition: all 0.3s ease;
  }
  
  :global(.tarjeta:hover) {
    background: rgba(255, 255, 255, 0.2);
    border-color: #4ecdc4;
    transform: translateY(-2px);
  }
  
  :global(.texto-sombra) {
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8);
  }
  
  :global(.contenedor-centrado) {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    padding: 20px;
  }
  
  :global(.fade-in) {
    animation: fadeIn 0.5s ease-in-out;
  }
  
  :global(.slide-up) {
    animation: slideUp 0.5s ease-out;
  }
  
  :global(.bounce-in) {
    animation: bounceIn 0.6s ease-out;
  }
  
  @keyframes fadeIn {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }
  
  @keyframes slideUp {
    from {
      transform: translateY(30px);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }
  
  @keyframes bounceIn {
    0% {
      transform: scale(0.3);
      opacity: 0;
    }
    50% {
      transform: scale(1.05);
    }
    70% {
      transform: scale(0.9);
    }
    100% {
      transform: scale(1);
      opacity: 1;
    }
  }
  
  :global(.scroll-personalizado) {
    scrollbar-width: thin;
    scrollbar-color: #4ecdc4 rgba(255, 255, 255, 0.1);
  }
  
  :global(.scroll-personalizado::-webkit-scrollbar) {
    width: 8px;
  }
  
  :global(.scroll-personalizado::-webkit-scrollbar-track) {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 10px;
  }
  
  :global(.scroll-personalizado::-webkit-scrollbar-thumb) {
    background: #4ecdc4;
    border-radius: 10px;
  }
  
  :global(.scroll-personalizado::-webkit-scrollbar-thumb:hover) {
    background: #ff6b6b;
  }
  
  .contenido-principal {
    position: relative;
    z-index: 1;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    :global(.contenedor-centrado) {
      padding: 10px;
    }
    
    :global(.tarjeta) {
      padding: 15px;
    }
    
    :global(.btn-primario, .btn-secundario) {
      padding: 10px 20px;
      font-size: 0.9rem;
    }
  }

  /* Estilos para verificación de acceso */
  .verificando-acceso {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
  }

  .loader-container {
    text-align: center;
    z-index: 10;
    padding: 2rem;
    background: rgba(0, 0, 0, 0.7);
    border-radius: 20px;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid rgba(230, 168, 0, 0.3);
    border-top: 4px solid #e6a800;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 1.5rem auto;
  }

  .loader-container h2 {
    color: #f1f5f9;
    font-size: 1.5rem;
    margin-bottom: 0.5rem;
  }

  .loader-container p {
    color: #94a3b8;
    font-size: 1rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
</style>
