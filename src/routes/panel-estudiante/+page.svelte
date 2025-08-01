<script lang="ts">
  // 🎮 Panel Estudiante - Estructura Gaming
  // Solo estructura base - funcionalidad después
  
  import SidebarDerecho from '$lib/components/PanelEstudiante/SidebarDerecho.svelte';
  import ContinuarAprendiendo from '$lib/components/PanelEstudiante/ContinuarAprendiendo.svelte';
  import SimuladorEstadisticas from '$lib/components/PanelEstudiante/SimuladorEstadisticas.svelte';
  import RecomendacionesCursos from '$lib/components/PanelEstudiante/RecomendacionesCursos.svelte';
  import LogrosDesafios from '$lib/components/PanelEstudiante/LogrosDesafios.svelte';
</script>

<svelte:head>
  <title>Panel Estudiante - Academia Vallenata</title>
  <meta name="description" content="Dashboard gaming para estudiantes de acordeón" />
</svelte:head>

<!-- 🎮 LAYOUT GAMING PRINCIPAL -->
<div class="panel-gaming-container">

  <!-- 📊 CONTENIDO PRINCIPAL -->
  <main class="contenido-principal">
    
    <!-- 🎵 CONTINUAR APRENDIENDO - Hero Principal -->
    <ContinuarAprendiendo />

    <!-- 🏆 LOGROS Y DESAFÍOS -->
    <LogrosDesafios />

    <!-- 🎮 SIMULADOR + RECOMENDACIONES -->
    <section class="simulador-stats">
      <div class="simulador-card">
        <SimuladorEstadisticas />
      </div>
      
      <div class="estadisticas-card">
        <RecomendacionesCursos />
      </div>
    </section>

  </main>

  <!-- 📚 SIDEBAR DERECHO - Componente Unificado -->
  <SidebarDerecho />

</div>

<style>
  /* 🎮 LAYOUT GAMING PRINCIPAL */
  .panel-gaming-container {
    display: grid;
    grid-template-columns: 1fr 300px;
    grid-template-areas: "main widgets";
    height: 100vh; /* Altura fija para fijar sidebars */
    background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #334155 100%);
    color: white;
    gap: 20px;
    padding: 20px;
    overflow: hidden; /* Evitar scroll en el contenedor principal */
    max-width: 100vw; /* Evitar que se extienda más allá del viewport */
    box-sizing: border-box; /* Incluir padding en el width total */
  }



  /* 📊 CONTENIDO PRINCIPAL */
  .contenido-principal {
    grid-area: main;
    display: flex;
    flex-direction: column;
    gap: 24px;
    overflow-y: auto; /* Solo el contenido central tiene scroll */
    overflow-x: hidden;
    height: 100%; /* Tomar toda la altura disponible */
    padding-right: 8px; /* Espacio para el scrollbar */
  }

  /* 🎨 Estilizar scrollbar del contenido principal */
  .contenido-principal::-webkit-scrollbar {
    width: 6px;
  }

  .contenido-principal::-webkit-scrollbar-track {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 3px;
  }

  .contenido-principal::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.3);
    border-radius: 3px;
  }

  .contenido-principal::-webkit-scrollbar-thumb:hover {
    background: rgba(255, 255, 255, 0.5);
  }



  /* 🏆 LOGROS Y DESAFÍOS - Estilos manejados en el componente */

  /* 🎮 SIMULADOR + RECOMENDACIONES */
  .simulador-stats {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
  }

  .simulador-card, .estadisticas-card {
    /* Contenedores para los componentes - sin padding ni background */
    height: 450px; /* Altura fija para consistencia */
    position: relative;
  }



  /* 📱 RESPONSIVE */
  @media (max-width: 1200px) {
    .panel-gaming-container {
      grid-template-columns: 1fr 250px;
    }
  }

  @media (max-width: 900px) {
    .panel-gaming-container {
      height: auto; /* Permitir altura automática en móvil */
      min-height: 100vh;
      overflow: visible;
      grid-template-columns: 1fr;
      grid-template-areas: 
        "main"
        "widgets";
      gap: 16px;
      padding: 16px;
    }

    .contenido-principal {
      overflow: visible; /* Sin scroll en móvil */
      height: auto;
      padding-right: 0;
    }

    .simulador-stats {
      grid-template-columns: 1fr;
    }
  }

  /* 🚫 PREVENIR SCROLL HORIZONTAL GLOBAL EN ESTA PÁGINA */
  :global(html, body) {
    max-width: 100vw;
    overflow-x: hidden;
  }

  /* Asegurar que todos los elementos dentro del panel no causen overflow */
  .panel-gaming-container * {
    max-width: 100%;
    box-sizing: border-box;
  }
</style> 