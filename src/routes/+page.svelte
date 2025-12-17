<script lang="ts">
  import { onMount } from 'svelte';
  import HeroHome from '$lib/components/Inicio/HeroHome.svelte';
  import SeccionOpciones from '$lib/components/Inicio/SeccionOpciones.svelte';
  import SeccionInstructor from '$lib/components/Inicio/SeccionInstructor.svelte';
  import SeccionStats from '$lib/components/Inicio/SeccionStats.svelte';
  import SeccionCTAFinal from '$lib/components/Inicio/SeccionCTAFinal.svelte';
  
  let paginaCargada = false;
  let mostrarModal = false;

  onMount(() => {
    paginaCargada = true;
    console.log('Página cargada correctamente');
  });

  function scrollToSection(sectionId: string) {
    console.log('Scroll to:', sectionId);
    const element = document.getElementById(sectionId);
    if (element) {
      const offset = 80;
      const elementPosition = element.offsetTop - offset;
      window.scrollTo({
        top: elementPosition,
        behavior: 'smooth'
      });
    }
  }
</script>

<svelte:head>
  <title>Academia Vallenata Online - Aprende Acordeón desde Cero | Simulador Gaming</title>
  <meta name="description" content="🎵 La Academia #1 de Acordeón Vallenato online. Simulador gaming único, comunidad de 5,000+ estudiantes. Primera canción en 7 días garantizado." />
</svelte:head>

{#if paginaCargada}
  <main class="home-principal">
    <!-- Hero Principal -->
    <HeroHome {mostrarModal} {scrollToSection} />
    
    <!-- Sección de Opciones de Aprendizaje -->
    <SeccionOpciones />
    
    <!-- Sección del Instructor - Jesús González -->
    <SeccionInstructor />
    
    <!-- Sección de Estadísticas y Social Proof -->
    <SeccionStats />
    
    <!-- Sección CTA Final - Conversión -->
    <SeccionCTAFinal />
  </main>
{:else}
  <div class="loading">
    <p>Cargando...</p>
  </div>
{/if}

<style>
  .home-principal {
    width: 100%;
    min-height: 100vh;
    overflow-x: hidden;
  }

  .loading {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    font-size: 1.5rem;
  }

  /* Smooth scroll */
  :global(html) {
    scroll-behavior: smooth;
  }
</style>
