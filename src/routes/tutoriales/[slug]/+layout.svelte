<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { page } from '$app/stores';
  import { fly } from 'svelte/transition';
  
  // 🚫 ESTE LAYOUT ELIMINA COMPLETAMENTE TODA LA NAVEGACIÓN
  // Solo se aplica a /tutoriales/[slug] (NO a /tutoriales/[slug]/clase/*)
  
  let esClase = false;
  
  $: esClase = $page.url.pathname.includes('/clase/') || $page.url.pathname.includes('/contenido/');
  
  onMount(() => {
    // 🚫 FORZAR ESTILOS PARA ELIMINAR NAVEGACIÓN
    if (typeof document !== 'undefined') {
      // Ocultar elementos de navegación que puedan estar presentes
      const elementosNavegacion = document.querySelectorAll('.menu-superior, .menu-superior-autenticado, .admin-sidebar, .sidebar-moderno, .menu-inferior-responsivo, .footer-politicas, nav, header, footer');
      elementosNavegacion.forEach(el => {
        if (el instanceof HTMLElement) {
          el.style.display = 'none';
          el.style.visibility = 'hidden';
          el.style.opacity = '0';
          el.style.height = '0';
          el.style.width = '0';
          el.style.margin = '0';
          el.style.padding = '0';
          el.style.overflow = 'hidden';
        }
      });
      
      // Aplicar estilos al body para eliminar espacios
      document.body.style.margin = '0';
      document.body.style.padding = '0';
      document.body.style.overflowX = 'hidden';
      document.body.style.width = '100%';
      document.body.style.maxWidth = '100%';
      
      // Aplicar estilos al html
      document.documentElement.style.margin = '0';
      document.documentElement.style.padding = '0';
      document.documentElement.style.overflowX = 'hidden';
      document.documentElement.style.width = '100%';
      document.documentElement.style.maxWidth = '100%';
    }
  });
  
  onDestroy(() => {
    // 🔄 RESTAURAR ESTILOS AL SALIR
    if (typeof document !== 'undefined') {
      const elementosNavegacion = document.querySelectorAll('.menu-superior, .menu-superior-autenticado, .admin-sidebar, .sidebar-moderno, .menu-inferior-responsivo, .footer-politicas, nav, header, footer');
      elementosNavegacion.forEach(el => {
        if (el instanceof HTMLElement) {
          el.style.display = '';
          el.style.visibility = '';
          el.style.opacity = '';
          el.style.height = '';
          el.style.width = '';
          el.style.margin = '';
          el.style.padding = '';
          el.style.overflow = '';
        }
      });
      
      // Restaurar body
      document.body.style.margin = '';
      document.body.style.padding = '';
      document.body.style.overflowX = '';
      document.body.style.width = '';
      document.body.style.maxWidth = '';
      
      // Restaurar html
      document.documentElement.style.margin = '';
      document.documentElement.style.padding = '';
      document.documentElement.style.overflowX = '';
      document.documentElement.style.width = '';
      document.documentElement.style.maxWidth = '';
    }
  });
</script>

<!-- 🚫 LAYOUT COMPLETAMENTE LIMPIO - SIN NADA DE NAVEGACIÓN -->
{#if !esClase}
  <!-- Solo para páginas de detalle de tutorial, NO para clases -->
  <div class="tutorial-pantalla-completa" transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
    <slot />
  </div>
{:else}
  <!-- Para clases y contenido, usar layout normal -->
  <slot />
{/if}

<style>
  /* 🚫 PANTALLA COMPLETA TOTAL - ABSOLUTAMENTE SIN NADA */
  .tutorial-pantalla-completa {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    margin: 0 !important;
    padding: 0 !important;
    background: transparent;
    z-index: 9999;
    overflow: auto;
    box-sizing: border-box;
  }
  
  /* 🚫 FORZAR QUE TODOS LOS ELEMENTOS HIJOS NO DESBORDEN */
  .tutorial-pantalla-completa * {
    max-width: 100% !important;
    box-sizing: border-box !important;
  }
  
  /* 🚫 OCULTAR SCROLL HORIZONTAL GLOBALMENTE */
  .tutorial-pantalla-completa ::-webkit-scrollbar:horizontal {
    display: none !important;
  }
  
  /* 🚫 OCULTAR SCROLL VERTICAL GLOBALMENTE */
  .tutorial-pantalla-completa ::-webkit-scrollbar {
    display: none !important;
    width: 0 !important;
    background: transparent !important;
  }
  
  .tutorial-pantalla-completa ::-webkit-scrollbar-track {
    display: none !important;
  }
  
  .tutorial-pantalla-completa ::-webkit-scrollbar-thumb {
    display: none !important;
  }
  
  .tutorial-pantalla-completa ::-webkit-scrollbar-corner {
    display: none !important;
  }
  
  /* 🚫 REGLAS ESPECÍFICAS PARA PLANTILLAS DE TUTORIALES */
  .tutorial-pantalla-completa .container,
  .tutorial-pantalla-completa .contenedor,
  .tutorial-pantalla-completa .layout-container,
  .tutorial-pantalla-completa .main-container,
  .tutorial-pantalla-completa .curso-container,
  .tutorial-pantalla-completa .tutorial-container {
    max-width: 100% !important;
    width: 100% !important;
    margin: 0 !important;
    padding-left: 0 !important;
    padding-right: 0 !important;
    overflow-x: hidden !important;
  }
  
  /* 🚫 ASEGURAR QUE NO HAYA ESPACIOS EXTRA */
  .tutorial-pantalla-completa > *:first-child {
    margin-top: 0 !important;
    padding-top: 0 !important;
  }
  
  .tutorial-pantalla-completa > *:last-child {
    margin-bottom: 0 !important;
    padding-bottom: 0 !important;
  }
</style> 