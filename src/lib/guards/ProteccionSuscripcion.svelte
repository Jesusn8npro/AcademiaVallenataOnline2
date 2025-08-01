<script lang="ts">
  import { onMount } from 'svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  
  // Props para personalizar el contenido
  export let nombreContenido: string = "contenido premium";
  export let tipoContenido: string = "curso"; // curso o tutorial
  export let mostrarPrevisualizacion: boolean = false;
  
  let usuarioActual: any = null;
  let cargandoAuth = true;
  let accesoDenegado = false;
  let tieneAcceso = false;

  // Verificar autenticación y suscripción
  onMount(() => {
    const unsubscribe = usuario.subscribe((u) => {
      usuarioActual = u;
      cargandoAuth = false;

      if (!u) {
        // No está logueado
        accesoDenegado = true;
        setTimeout(() => {
          goto('/');
        }, 4000);
      } else {
        // Aquí verificaríamos la suscripción - por ahora solo verificamos login
        // TODO: Agregar verificación de suscripción cuando esté implementada
        tieneAcceso = true;
        accesoDenegado = false;
      }
    });

    return unsubscribe;
  });

  function irAMembresias() {
    goto('/membresias');
  }

  function irAInicio() {
    goto('/');
  }

  function irALogin() {
    const urlActual = $page.url.pathname;
    goto(`/?redirigir=${encodeURIComponent(urlActual)}`);
  }
</script>

<svelte:head>
  <title>Contenido Premium - Academia Vallenata Online</title>
</svelte:head>

<!-- Mostrar loading mientras se verifica acceso -->
{#if cargandoAuth}
  <div class="auth-verificacion">
    <div class="spinner"></div>
    <h2>Verificando acceso...</h2>
    <p>Comprobando tu suscripción</p>
  </div>

<!-- Si acceso denegado, mostrar mensaje -->
{:else if accesoDenegado}
  <div class="acceso-denegado">
    <div class="error-icono">
      <svg width="80" height="80" viewBox="0 0 24 24" fill="none">
        <path d="M12 2C13.1 2 14 2.9 14 4V6C15.1 6 16 6.9 16 8V20C16 21.1 15.1 22 14 22H10C8.9 22 8 21.1 8 20V8C8 6.9 8.9 6 10 6V4C10 2.9 10.9 2 12 2ZM12 4V6H12V4ZM10 8V20H14V8H10Z" fill="#8b5cf6"/>
      </svg>
    </div>
    <h1>🎵 CONTENIDO PREMIUM</h1>
    <p class="mensaje-principal">Este {tipoContenido} "{nombreContenido}" requiere acceso premium</p>
    
    <div class="info-simple">
      {#if !usuarioActual}
        <p><strong>🚪 Inicia sesión para continuar</strong></p>
        <p>Necesitas una cuenta en la Academia Vallenata Online para acceder a este contenido</p>
      {:else}
        <p><strong>⭐ Contenido exclusivo para miembros</strong></p>
        <p>Únete a nuestros planes premium y obtén acceso completo a todos los cursos y tutoriales</p>
      {/if}
    </div>

    <div class="beneficios-premium">
      <h3>🎯 Con tu suscripción premium obtienes:</h3>
      <div class="beneficios-grid">
        <div class="beneficio-item">
          <span class="beneficio-icono">🎵</span>
          <p>Acceso a todos los cursos de acordeón</p>
        </div>
        <div class="beneficio-item">
          <span class="beneficio-icono">🎥</span>
          <p>Tutoriales paso a paso en HD</p>
        </div>
        <div class="beneficio-item">
          <span class="beneficio-icono">📱</span>
          <p>Simulador interactivo premium</p>
        </div>
        <div class="beneficio-item">
          <span class="beneficio-icono">📊</span>
          <p>Seguimiento de progreso detallado</p>
        </div>
        <div class="beneficio-item">
          <span class="beneficio-icono">🏆</span>
          <p>Certificados de completación</p>
        </div>
        <div class="beneficio-item">
          <span class="beneficio-icono">👨‍🏫</span>
          <p>Soporte directo del instructor</p>
        </div>
      </div>
    </div>

    <div class="acciones">
      {#if !usuarioActual}
        <button class="btn-login" on:click={irALogin}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M11 7L9.6 8.4l2.6 2.6H2v2h10.2l-2.6 2.6L11 17l5-5-5-5zm9 12h-8v2h8c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2h-8v2h8v12z" fill="currentColor"/>
          </svg>
          Iniciar Sesión
        </button>
      {:else}
        <button class="btn-premium" on:click={irAMembresias}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M12 2L3.09 8.26L4.5 9.67L12 4.33L19.5 9.67L20.91 8.26L12 2ZM12 22L3.09 15.74L4.5 14.33L12 19.67L19.5 14.33L20.91 15.74L12 22Z" fill="currentColor"/>
          </svg>
          Ver Planes Premium
        </button>
      {/if}
      <button class="btn-inicio" on:click={irAInicio}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" fill="currentColor"/>
        </svg>
        Explorar Contenido Gratis
      </button>
    </div>
    
    <div class="countdown">
      <p>Redirigiendo automáticamente...</p>
    </div>
  </div>

<!-- Si tiene acceso, mostrar contenido -->
{:else}
  <slot />
{/if}

<style>
  .auth-verificacion {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
    color: white;
    text-align: center;
    gap: 1rem;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid rgba(255, 255, 255, 0.3);
    border-top: 4px solid white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .acceso-denegado {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
    color: white;
    text-align: center;
    padding: 2rem;
    gap: 1.5rem;
  }

  .error-icono {
    animation: float 3s ease-in-out infinite;
  }

  @keyframes float {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-15px); }
  }

  .acceso-denegado h1 {
    font-size: 2.8rem;
    font-weight: 900;
    margin: 0;
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
    letter-spacing: 2px;
  }

  .mensaje-principal {
    font-size: 1.3rem;
    font-weight: 600;
    margin: 1rem 0;
    opacity: 0.95;
  }

  .info-simple {
    background: rgba(0, 0, 0, 0.3);
    border-radius: 12px;
    padding: 1.5rem;
    border: 1px solid rgba(255, 255, 255, 0.2);
    margin: 1rem 0;
    max-width: 500px;
  }

  .info-simple p {
    margin: 0.8rem 0;
    font-size: 1rem;
    line-height: 1.4;
  }

  .beneficios-premium {
    background: rgba(0, 0, 0, 0.2);
    border-radius: 16px;
    padding: 2rem;
    border: 2px solid rgba(255, 255, 255, 0.3);
    margin: 1.5rem 0;
    max-width: 700px;
  }

  .beneficios-premium h3 {
    margin: 0 0 1.5rem 0;
    font-size: 1.2rem;
    font-weight: 700;
  }

  .beneficios-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1rem;
  }

  .beneficio-item {
    display: flex;
    align-items: center;
    gap: 0.8rem;
    padding: 0.8rem;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    text-align: left;
  }

  .beneficio-icono {
    font-size: 1.5rem;
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 50%;
    flex-shrink: 0;
  }

  .beneficio-item p {
    margin: 0;
    font-size: 0.9rem;
    font-weight: 500;
  }

  .acciones {
    display: flex;
    gap: 1rem;
    margin-top: 1.5rem;
  }

  .btn-inicio, .btn-login, .btn-premium {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 1rem 2rem;
    border: none;
    border-radius: 12px;
    font-weight: 700;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.3s ease;
    text-decoration: none;
    text-transform: uppercase;
    letter-spacing: 1px;
  }

  .btn-premium {
    background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
    color: white;
    box-shadow: 0 4px 15px rgba(245, 158, 11, 0.3);
  }

  .btn-premium:hover {
    transform: translateY(-3px);
    box-shadow: 0 6px 20px rgba(245, 158, 11, 0.4);
  }

  .btn-login {
    background: #10b981;
    color: white;
    box-shadow: 0 4px 15px rgba(16, 185, 129, 0.3);
  }

  .btn-login:hover {
    background: #059669;
    transform: translateY(-3px);
    box-shadow: 0 6px 20px rgba(16, 185, 129, 0.4);
  }

  .btn-inicio {
    background: rgba(255, 255, 255, 0.2);
    color: white;
    border: 2px solid rgba(255, 255, 255, 0.4);
  }

  .btn-inicio:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-2px);
  }

  .countdown {
    margin-top: 1.5rem;
    opacity: 0.8;
  }

  .countdown p {
    font-size: 0.9rem;
    animation: pulse 2s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 0.8; }
    50% { opacity: 1; }
  }

  /* Responsive */
  @media (max-width: 768px) {
    .acceso-denegado {
      padding: 1rem;
      gap: 1rem;
    }

    .acceso-denegado h1 {
      font-size: 2rem;
    }

    .acciones {
      flex-direction: column;
      width: 100%;
      max-width: 300px;
    }

    .btn-inicio, .btn-login, .btn-premium {
      justify-content: center;
      width: 100%;
      padding: 1rem;
    }

    .beneficios-grid {
      grid-template-columns: 1fr;
    }

    .beneficios-premium {
      padding: 1.5rem;
      max-width: 100%;
    }

    .mensaje-principal {
      font-size: 1.1rem;
    }
  }
</style> 