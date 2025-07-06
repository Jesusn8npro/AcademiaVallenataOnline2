<script lang="ts">
  import GridMisCursos from '$lib/components/MisCursos/GridMisCursos.svelte';
  import PorcentajePerfil from '$lib/components/Banners/PorcentajePerfil.svelte';
  import BannerSlider from '$lib/components/Banners/BannerSlider.svelte';
  import { perfilStore } from '$lib/stores/perfilStore';

  // Usar datos del store en lugar de cargar por separado
  $: perfilData = $perfilStore.perfil;
  $: cargandoPerfil = $perfilStore.cargando;
</script>

<svelte:head>
  <title>Mis Cursos - Academia Vallenata</title>
  <meta name="description" content="Accede a todos tus cursos de acordeón vallenato" />
</svelte:head>

<div class="contenido-mis-cursos">
  <div class="layout-mis-cursos">
    <div class="columna-principal">
      <div class="header-seccion">
        <h1>Mis Cursos</h1>
        <p>Continúa con tu aprendizaje de acordeón vallenato</p>
      </div>
      
      <!-- 🎯 USANDO EL COMPONENTE AUTOSUFICIENTE (sin props, se carga solo) -->
      <GridMisCursos />
    </div>
    
    <aside class="columna-lateral">
      <div class="widgets-contenedor">
        {#if perfilData}
          <PorcentajePerfil perfil={perfilData} />
        {/if}
        <BannerSlider />
      </div>
    </aside>
  </div>
</div>

<style>
  .contenido-mis-cursos {
    padding: 2rem;
  }

  .layout-mis-cursos {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 2.5rem;
    align-items: start;
  }

  .columna-principal {
    min-width: 0;
  }

  .header-seccion {
    margin-bottom: 2rem;
  }

  .header-seccion h1 {
    font-size: 2rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }

  .header-seccion p {
    color: #6b7280;
    font-size: 1.1rem;
  }

  .columna-lateral {
    position: sticky;
    top: 2rem;
  }

  .widgets-contenedor {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  @media (max-width: 900px) {
    .contenido-mis-cursos {
      padding: 1.5rem;
    }

    .layout-mis-cursos {
      grid-template-columns: 1fr;
      gap: 2rem;
    }

    .columna-lateral {
      order: 1;
      position: static;
    }

    .columna-principal {
      order: 0;
    }
  }

  @media (max-width: 640px) {
    .contenido-mis-cursos {
      padding: 1rem;
    }
    
    .header-seccion h1 {
      font-size: 1.75rem;
    }
  }
</style> 