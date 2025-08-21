<script lang="ts">
  // 🎮 Panel Estudiante - Estructura Gaming
  // Solo estructura base - funcionalidad después
  
  import { onMount } from 'svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import SidebarDerecho from '$lib/components/PanelEstudiante/SidebarDerecho.svelte';
  import ContinuarAprendiendo from '$lib/components/PanelEstudiante/ContinuarAprendiendo.svelte';
  import SimuladorEstadisticas from '$lib/components/PanelEstudiante/SimuladorEstadisticas.svelte';
  import RecomendacionesCursos from '$lib/components/PanelEstudiante/RecomendacionesCursos.svelte';
  import LogrosDesafios from '$lib/components/PanelEstudiante/LogrosDesafios.svelte';
  
  // ⚡ ESTADOS PARA CARGA EN SEGUNDO PLANO
  let datosCargados = false;
  let cargandoDatos = false;
  
  // 🚀 CARGA INMEDIATA DE INTERFAZ
  onMount(() => {
    console.log('🚀 [PANEL] Panel estudiante cargado INMEDIATAMENTE');
    
    // ⚡ CARGAR DATOS EN SEGUNDO PLANO
    setTimeout(async () => {
      try {
        console.log('📊 [PANEL] Cargando datos en segundo plano...');
        cargandoDatos = true;
        
        // Aquí puedes agregar la carga de datos específicos del panel
        // Por ahora solo simulamos un delay
        await new Promise(resolve => setTimeout(resolve, 500));
        
        datosCargados = true;
        cargandoDatos = false;
        console.log('✅ [PANEL] Datos cargados en segundo plano');
        
      } catch (error) {
        console.warn('⚠️ [PANEL] Error cargando datos en segundo plano:', error);
        cargandoDatos = false;
      }
    }, 100); // 100ms después de cargar la interfaz
  });
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

    <!-- 🎮 RECOMENDACIONES + SIMULADOR PREVIEW -->
    <section class="simulador-stats">
      <div class="simulador-card">
        <RecomendacionesCursos />
      </div>
      
      <div class="estadisticas-card">
        <SimuladorEstadisticas />
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
    grid-template-columns: 1fr; /* 🚀 Cambiar a una sola columna ya que el sidebar es fixed */
    grid-template-areas: "main"; /* 🚀 Solo el contenido principal */
    min-height: 100vh; /* 🚀 Cambiar a min-height para permitir crecimiento */
    background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #334155 100%);
    color: white;
    gap: 20px;
    padding: 20px;
    padding-right: 340px; /* 🚀 Agregar padding derecho para el sidebar fijo */
    overflow: visible; /* 🚀 Permitir overflow natural */
    max-width: 100vw; /* Evitar que se extienda más allá del viewport */
    box-sizing: border-box; /* Incluir padding en el width total */
  }



  /* 📊 CONTENIDO PRINCIPAL */
  .contenido-principal {
    grid-area: main;
    display: flex;
    flex-direction: column;
    gap: 24px;
    overflow: visible; /* 🚀 Eliminar scroll del contenido central */
    height: auto; /* 🚀 Altura automática en lugar de 100% */
    padding-right: 0; /* 🚀 Eliminar padding para scrollbar */
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
    height: 480px; /* 🚀 Altura fija ajustada para consistencia */
    position: relative;
  }





  @media (max-width: 1300px) {
    .panel-gaming-container {
      height: auto; /* Permitir altura automática en móvil */
      min-height: 100vh;
      overflow: visible;
      grid-template-columns: 1fr;
      grid-template-areas: 
        "main";
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

    /* 🚀 NUEVO: Ajustar altura de las tarjetas en móvil */
    .simulador-card, .estadisticas-card {
      height: auto; /* Altura automática en móvil */
      min-height: 480px; /* 🚀 Mantener altura mínima igual para consistencia */
    }

    /* 🚀 NUEVO: Asegurar que las recomendaciones se muestren completas */
    .simulador-card {
      height: auto !important; /* Forzar altura automática */
      min-height: 480px; /* 🚀 Mantener altura mínima igual */
    }

    /* 🚀 OCULTAR SIDEBAR DERECHO EN MÓVIL */
    :global(.sidebar-derecho) {
      display: none !important;
    }
  }

  /* 🚀 MEDIA QUERY PARA PANTALLAS MEDIANAS */
  @media (max-width: 1400px) and (min-width: 1301px) {
    .panel-gaming-container {
      padding-right: 320px; /* 🚀 Reducir padding para pantallas medianas */
    }
  }

  /* 🚫 PREVENIR SCROLL HORIZONTAL GLOBAL EN ESTA PÁGINA */
  :global(html, body) {
    max-width: 100vw;
    overflow-x: hidden;
    background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #334155 100%) !important; /* 🚀 Sobrescribir fondo blanco */
  }

  /* 🚀 SOBRESCRIBIR FONDO BLANCO DEL CSS GLOBAL */
  :global(#svelte) {
    background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #334155 100%) !important;
  }

  /* Asegurar que todos los elementos dentro del panel no causen overflow */
  .panel-gaming-container * {
    max-width: 100%;
    box-sizing: border-box;
  }
</style> 