<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { page } from '$app/stores';
  import { fly } from 'svelte/transition';
  
  // 🚫 ESTE LAYOUT ELIMINA COMPLETAMENTE TODA LA NAVEGACIÓN
  // Solo se aplica a /tutoriales/[slug] (NO a /tutoriales/[slug]/clase/*)
  
  let esClase = false;
  
  $: esClase = $page.url.pathname.includes('/clase/') || $page.url.pathname.includes('/contenido/');

  onMount(() => {
    // ✅ TEMPORALMENTE DESHABILITADO PARA DEBUGGING DEL MENÚ
    console.log('🚫 [DEBUG] Layout de tutoriales DESHABILITADO temporalmente');
    /*
    if (typeof document !== 'undefined') {
      // Ocultar SOLO elementos de navegación principal, NO el encabezado de lecciones
      const elementosNavegacion = document.querySelectorAll('.menu-superior, .menu-superior-autenticado, .admin-sidebar, .sidebar-moderno, .footer-politicas, nav, footer');
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

      // ✅ IMPORTANTE: NO ocultar el encabezado de lecciones ni el menú inferior
      // Estos deben permanecer visibles para la funcionalidad de las clases
      
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
    */
  });

  onDestroy(() => {
    // 🔄 RESTAURAR ESTILOS AL SALIR
    if (typeof document !== 'undefined') {
      const elementosNavegacion = document.querySelectorAll('.menu-superior, .menu-superior-autenticado, .admin-sidebar, .sidebar-moderno, .footer-politicas, nav, footer');
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
      
      // ✅ IMPORTANTE: NO restaurar el encabezado de lecciones ni el menú inferior
      // Estos deben mantenerse con sus propios estilos
      
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

<!-- ✅ LAYOUT SIMPLE TEMPORAL -->
<div class="tutorial-layout-simple">
  <slot />
</div>

<style>
  /* ✅ LAYOUT SIMPLE TEMPORAL */
  .tutorial-layout-simple {
    min-height: 100vh;
    background: #000;
  }
  
  /* ✅ IMPORTANTE: Permitir que el menú funcione normalmente */
  :global(.menu-inferior-responsivo) {
    /* NO INTERFERIR con el menú */
  }
</style> 