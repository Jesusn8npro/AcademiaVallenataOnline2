<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import '../../../app.css';
  
  let observer: MutationObserver;

  onMount(() => {
    console.log('🎯 [TUTORIAL DETALLE] Configurando página sin menús');
    
    // 🔧 FUNCIÓN PARA OCULTAR ELEMENTOS DE NAVEGACIÓN
    function ocultarElementosNavegacion() {
      // Lista de selectores a ocultar
      const selectoresAOcultar = [
        '.banner-notificaciones',
        '.menu-superior',
        '.barra-superior-negra', 
        '.barra-principal-navegacion',
        '.banner-permisos-notificacion',
        '.sidebar-moderno',
        '.menu-publico',
        '.navbar',
        '.menu-superior-autenticado',
        '.admin-sidebar',
        '.menu-inferior-responsivo',
        '.footer-politicas',
        '.chat-widget',
        'nav',
        'header',
        'footer'
      ];

      selectoresAOcultar.forEach(selector => {
        const elementos = document.querySelectorAll(selector);
        elementos.forEach(elemento => {
          if (elemento instanceof HTMLElement) {
            elemento.style.display = 'none';
            elemento.style.visibility = 'hidden';
            elemento.style.opacity = '0';
            elemento.style.height = '0';
            elemento.style.overflow = 'hidden';
          }
        });
      });

      // Configurar body
      document.body.style.paddingTop = '0';
      document.body.style.margin = '0';
      document.body.style.overflow = 'auto';
      
      console.log('✅ [TUTORIAL DETALLE] Elementos de navegación ocultados');
    }

    // Ejecutar inmediatamente
    ocultarElementosNavegacion();
    
    // 🔧 TAMBIÉN EJECUTAR DESPUÉS DE 100ms POR SI HAY RENDERIZADO TARDÍO
    setTimeout(ocultarElementosNavegacion, 100);
    setTimeout(ocultarElementosNavegacion, 500);
    
    // 🔧 DETECTAR BFCACHE Y RESTAURACIÓN
    window.addEventListener('pageshow', (event) => {
      if (event.persisted) {
        console.log('🔄 [TUTORIAL BFCACHE] Página restaurada desde cache');
        // Re-aplicar ocultación después de restauración
        setTimeout(ocultarElementosNavegacion, 0);
        setTimeout(ocultarElementosNavegacion, 100);
        setTimeout(ocultarElementosNavegacion, 500);
      }
    });

    // 🔧 DETECTAR CUANDO LA PÁGINA SE VUELVE VISIBLE
    document.addEventListener('visibilitychange', () => {
      if (!document.hidden) {
        console.log('👁️ [TUTORIAL VISIBILITY] Página visible - re-aplicando estilos');
        setTimeout(ocultarElementosNavegacion, 50);
      }
    });
    
    // 🔧 OBSERVER PARA DETECTAR NUEVOS ELEMENTOS QUE SE AGREGUEN
    observer = new MutationObserver(() => {
      ocultarElementosNavegacion();
    });
    
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  });

  onDestroy(() => {
    if (observer) {
      observer.disconnect();
      console.log('🧹 [TUTORIAL DETALLE] Observer desconectado');
    }
  });
</script>

<svelte:head>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</svelte:head>

<main class="tutorial-detalle-container">
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
  :global(.banner-permisos-notificacion),
  :global(.menu-superior-autenticado),
  :global(.admin-sidebar),
  :global(.menu-inferior-responsivo),
  :global(.footer-politicas),
  :global(.chat-widget),
  :global(nav),
  :global(header),
  :global(footer) {
    display: none !important;
    visibility: hidden !important;
    opacity: 0 !important;
    height: 0 !important;
    overflow: hidden !important;
  }

  .tutorial-detalle-container {
    width: 100%;
    min-height: 100vh;
    background: #fff;
    position: relative;
    z-index: 1;
  }
</style> 