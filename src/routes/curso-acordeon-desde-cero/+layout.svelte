<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import '../../app.css';
  
  let observer: MutationObserver;

  onMount(() => {
    console.log('🎯 [CURSO LAYOUT] Configurando página de landing');
    
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
        '.navbar'
      ];

      selectoresAOcultar.forEach(selector => {
        const elementos = document.querySelectorAll(selector);
        elementos.forEach(elemento => {
          if (elemento instanceof HTMLElement) {
            elemento.style.display = 'none';
    }
        });
      });

      // Configurar body
      document.body.style.paddingTop = '0';
      document.body.style.margin = '0';
      
      console.log('✅ [CURSO LAYOUT] Elementos de navegación ocultados');
    }

    // Ejecutar inmediatamente
    ocultarElementosNavegacion();
    
    // 🔧 TAMBIÉN EJECUTAR DESPUÉS DE 100ms POR SI HAY RENDERIZADO TARDÍO
    setTimeout(ocultarElementosNavegacion, 100);
    
    // 🔧 DETECTAR BFCACHE Y RESTAURACIÓN
    window.addEventListener('pageshow', (event) => {
      if (event.persisted) {
        console.log('🔄 [CURSO BFCACHE] Página restaurada desde cache');
        // Re-aplicar ocultación después de restauración
        setTimeout(ocultarElementosNavegacion, 0);
        setTimeout(ocultarElementosNavegacion, 100);
        setTimeout(ocultarElementosNavegacion, 500);
    }
    });

    // 🔧 DETECTAR CUANDO LA PÁGINA SE VUELVE VISIBLE
    document.addEventListener('visibilitychange', () => {
      if (!document.hidden) {
        console.log('👁️ [CURSO VISIBILITY] Página visible - re-aplicando estilos');
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
      console.log('🧹 [CURSO LAYOUT] Observer desconectado');
    }
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