<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { page } from '$app/stores';
  import { browser } from '$app/environment';
  
  // ✅ NUEVO: Layout seguro que respeta hidratación
  let esClase = false;
  
  $: esClase = $page.url.pathname.includes('/clase/') || $page.url.pathname.includes('/contenido/');

  onMount(() => {
    // ✅ SOLUCIÓN: Solo ejecutar DESPUÉS de hidratación completa
    if (browser) {
      console.log('✅ [LAYOUT] Tutorial layout montado en cliente');
      
      // ✅ DELAY para asegurar que SvelteKit esté completamente hidratado
      setTimeout(() => {
        aplicarEstilosSeguros();
      }, 100);
    }
  });

  onDestroy(() => {
    // ✅ SOLUCIÓN: Restaurar solo si estamos en cliente
    if (browser) {
      console.log('✅ [LAYOUT] Tutorial layout destruido, restaurando estilos');
      restaurarEstilos();
    }
  });

  // ✅ NUEVA FUNCIÓN: Aplicar estilos de manera segura
  function aplicarEstilosSeguros() {
    if (!browser) return;
    
    try {
      // ✅ SOLUCIÓN: Solo ocultar elementos NO críticos para routing
      const elementosNoCriticos = document.querySelectorAll(
        '.footer-politicas, .sidebar-moderno, .menu-superior-autenticado'
      );
      
      elementosNoCriticos.forEach(el => {
        if (el instanceof HTMLElement) {
          // ✅ SOLUCIÓN: Usar clases CSS en lugar de manipular estilos directamente
          el.classList.add('tutorial-oculto');
        }
      });
      
      // ✅ SOLUCIÓN: Aplicar clase al body en lugar de manipular estilos
      document.body.classList.add('tutorial-pantalla-completa');
      
      console.log('✅ [LAYOUT] Estilos aplicados de manera segura');
    } catch (error) {
      console.warn('⚠️ [LAYOUT] Error aplicando estilos:', error);
    }
  }

  // ✅ NUEVA FUNCIÓN: Restaurar estilos de manera segura
  function restaurarEstilos() {
    if (!browser) return;
    
    try {
      // ✅ SOLUCIÓN: Remover clases CSS en lugar de manipular estilos
      const elementosOcultos = document.querySelectorAll('.tutorial-oculto');
      elementosOcultos.forEach(el => {
        el.classList.remove('tutorial-oculto');
      });
      
      // ✅ SOLUCIÓN: Remover clase del body
      document.body.classList.remove('tutorial-pantalla-completa');
      
      console.log('✅ [LAYOUT] Estilos restaurados de manera segura');
    } catch (error) {
      console.warn('⚠️ [LAYOUT] Error restaurando estilos:', error);
    }
  }
</script>

<!-- ✅ NUEVO: Layout simple y seguro -->
<div class="tutorial-layout-seguro">
  <slot />
</div>

<style>
  /* ✅ NUEVO: Layout seguro usando CSS puro */
  .tutorial-layout-seguro {
    min-height: 100vh;
    background: #000;
    width: 100%;
    overflow-x: hidden;
  }
  
  /* ✅ NUEVO: Clases CSS para ocultar elementos de manera segura */
  :global(.tutorial-oculto) {
    display: none !important;
  }
  
  /* ✅ NUEVO: Clase para body en pantalla completa */
  :global(body.tutorial-pantalla-completa) {
    margin: 0 !important;
    padding: 0 !important;
    overflow-x: hidden !important;
    width: 100% !important;
    max-width: 100% !important;
  }
  
  /* ✅ NUEVO: Asegurar que el menú funcione correctamente */
  :global(.menu-inferior-responsivo) {
    /* NO INTERFERIR con el menú - dejar que SvelteKit maneje su estado */
  }
</style> 