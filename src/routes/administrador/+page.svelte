<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { cargarTodasLasEstadisticas, type EstadisticasCompletas } from '$lib/services/adminService';
  
  // Redirección automática a panel-administracion
  onMount(() => {
    goto('/panel-administracion', { replaceState: true });
  });
  
  // Componentes de administrador
  import SeccionUsuarios from '$lib/components/Administrador/SeccionUsuarios.svelte';
  import SeccionVentas from '$lib/components/Administrador/SeccionVentas.svelte';
  import SeccionComunidad from '$lib/components/Administrador/SeccionComunidad.svelte';

  let estadisticas: EstadisticasCompletas | null = null;
  let cargando = true;
  let seccionActiva = 'dashboard';

  onMount(() => {
    // El layout ya se encarga de la autenticación
    cargarEstadisticas();
  });

  async function cargarEstadisticas() {
    try {
      cargando = true;
      estadisticas = await cargarTodasLasEstadisticas();
    } catch (error) {
      console.error('Error cargando estadísticas:', error);
    } finally {
      cargando = false;
    }
  }

  // Navegación entre secciones
  function cambiarSeccion(seccion: string) {
    seccionActiva = seccion;
  }
</script>

<svelte:head>
  <title>Panel de Administración - Academia Vallenata Online</title>
  <meta name="description" content="Panel de administración para gestionar usuarios, cursos, ventas y contenido de la Academia Vallenata Online." />
</svelte:head>

<main class="admin-container">
  <!-- Header del panel -->
  <header class="admin-header">
    <div class="header-content">
      <div class="header-title">
        <h1>
          <i class="fas fa-tachometer-alt"></i>
          Panel de Administración
        </h1>
        <p>Academia Vallenata Online</p>
      </div>
      
      <div class="header-actions">
        <button class="btn-refresh" on:click={cargarEstadisticas} disabled={cargando}>
          <i class="fas fa-sync-alt" class:rotating={cargando}></i>
          {cargando ? 'Cargando...' : 'Actualizar'}
        </button>
      </div>
    </div>
  </header>

  <!-- Navegación de secciones -->
  <nav class="admin-nav">
    <div class="nav-content">
      <button 
        class="nav-item" 
        class:active={seccionActiva === 'dashboard'}
        on:click={() => cambiarSeccion('dashboard')}
      >
        <i class="fas fa-chart-pie"></i>
        Dashboard
      </button>
      
      <button 
        class="nav-item" 
        on:click={() => goto('/administrador/usuarios')}
      >
        <i class="fas fa-users"></i>
        Usuarios
      </button>
      
      <button 
        class="nav-item" 
        on:click={() => goto('/administrador/panel-contenido')}
      >
        <i class="fas fa-graduation-cap"></i>
        Contenido
      </button>

      <button 
        class="nav-item" 
        on:click={() => goto('/administrador/blog')}
      >
        <i class="fas fa-blog"></i>
        Blog
      </button>

      <button 
        class="nav-item" 
        on:click={() => goto('/administrador/eventos')}
      >
        <i class="fas fa-calendar"></i>
        Eventos
      </button>

      <button 
        class="nav-item" 
        on:click={() => goto('/administrador/pagos')}
      >
        <i class="fas fa-credit-card"></i>
        Pagos
      </button>
    </div>
  </nav>

  <!-- Contenido principal -->
  <section class="admin-content">
    {#if seccionActiva === 'dashboard'}
      <div class="dashboard-sections">
        <!-- Sección de Usuarios -->
        <SeccionUsuarios 
          estadisticas={estadisticas?.usuarios || null} 
          loading={cargando} 
        />
        
        <!-- Sección de Ventas -->
        <SeccionVentas 
          estadisticas={estadisticas?.ventas || null} 
          loading={cargando} 
        />
        
        <!-- Sección de Cursos y Comunidad -->
        <SeccionComunidad 
          estadisticasComunidad={estadisticas?.comunidad || null}
          estadisticasCursos={estadisticas?.cursos || null}
          loading={cargando} 
        />
    </div>
  {/if}
  </section>
</main>

<style>
  .admin-container {
    min-height: 100vh;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    padding-bottom: 2rem;
  }

  /* Header */
  .admin-header {
    background: white;
    border-bottom: 1px solid #e2e8f0;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  }

  .header-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 1.5rem 2rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .header-title h1 {
    font-size: 1.75rem;
    font-weight: 700;
    color: #1f2937;
    margin: 0;
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .header-title h1 i {
    color: #3b82f6;
  }

  .header-title p {
    margin: 0.25rem 0 0 0;
    color: #6b7280;
    font-size: 0.875rem;
  }

  .btn-refresh {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: #3b82f6;
    color: white;
    border: none;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .btn-refresh:hover:not(:disabled) {
    background: #2563eb;
    transform: translateY(-1px);
  }

  .btn-refresh:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .rotating {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  /* Navegación */
  .admin-nav {
    background: white;
    border-bottom: 1px solid #e2e8f0;
  }

  .nav-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 2rem;
    display: flex;
    gap: 0.5rem;
    overflow-x: auto;
  }

  .nav-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 1rem 1.25rem;
    background: none;
    border: none;
    color: #6b7280;
    font-weight: 500;
    cursor: pointer;
    border-bottom: 3px solid transparent;
    transition: all 0.2s ease;
    white-space: nowrap;
  }

  .nav-item:hover, .nav-item.active {
    color: #3b82f6;
    border-bottom-color: #3b82f6;
  }

  /* Contenido principal */
  .admin-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 2rem;
  }

  .dashboard-sections {
    display: flex;
    flex-direction: column;
    gap: 2.5rem;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .admin-container {
      padding-bottom: 5rem;
    }

    .header-content {
      padding: 1rem;
      flex-direction: column;
      gap: 1rem;
      align-items: stretch;
    }

    .header-title h1 {
      font-size: 1.5rem;
    }

    .nav-content {
      padding: 0 1rem;
    }

    .nav-item {
      padding: 0.75rem 1rem;
      font-size: 0.875rem;
    }

    .admin-content {
      padding: 1rem;
    }

    .dashboard-sections {
      gap: 2rem;
    }
  }

  @media (max-width: 480px) {
    .header-content {
      padding: 0.75rem;
    }

    .header-title h1 {
      font-size: 1.25rem;
    }

    .btn-refresh {
      padding: 0.5rem 1rem;
      font-size: 0.875rem;
    }
    }
</style>

