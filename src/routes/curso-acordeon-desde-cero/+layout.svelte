<script lang="ts">
  import { onMount } from 'svelte';
  import '../../app.css';

  onMount(() => {
    // Ocultar completamente el banner de notificaciones
    const bannerNotificaciones = document.querySelector('.banner-notificaciones') as HTMLElement;
    if (bannerNotificaciones) {
      bannerNotificaciones.style.display = 'none';
    }

    // Ocultar cualquier menú superior
    const menuSuperior = document.querySelector('.menu-superior') as HTMLElement;
    if (menuSuperior) {
      menuSuperior.style.display = 'none';
    }

    // Ocultar todos los menús públicos
    const barraSuperiorNegra = document.querySelector('.barra-superior-negra') as HTMLElement;
    if (barraSuperiorNegra) {
      barraSuperiorNegra.style.display = 'none';
    }

    const barraPrincipal = document.querySelector('.barra-principal-navegacion') as HTMLElement;
    if (barraPrincipal) {
      barraPrincipal.style.display = 'none';
    }

    // Ocultar banner de permisos de notificaciones
    const bannerPermisos = document.querySelector('.banner-permisos-notificacion') as HTMLElement;
    if (bannerPermisos) {
      bannerPermisos.style.display = 'none';
    }

    // Ocultar sidebar
    const sidebar = document.querySelector('.sidebar-moderno') as HTMLElement;
    if (sidebar) {
      sidebar.style.display = 'none';
    }

    // Asegurar que el body no tenga padding-top
    document.body.style.paddingTop = '0';
    document.body.style.margin = '0';
  });
</script>

<svelte:head>
  <title>Aprende a Tocar Acordeón Desde Cero - Curso Completo | Academia Vallenata</title>
  <meta name="description" content="¡Deja de soñar y empieza a tocar! El único curso paso a paso que te lleva de CERO a tocar acordeón como un profesional en tiempo récord. Con Jesús González, el maestro más reconocido de Colombia." />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</svelte:head>

<main class="landing-container">
  <slot />
</main>

<style>
  :global(body) {
    margin: 0 !important;
    padding: 0 !important;
    overflow-x: hidden;
  }

  :global(.banner-notificaciones),
  :global(.menu-superior),
  :global(.sidebar-moderno),
  :global(.menu-publico),
  :global(.barra-superior-negra),
  :global(.barra-principal-navegacion),
  :global(.banner-permisos-notificacion) {
    display: none !important;
  }

  .landing-container {
    width: 100%;
    min-height: 100vh;
    background: #fff;
    position: relative;
    z-index: 1;
  }
</style> 