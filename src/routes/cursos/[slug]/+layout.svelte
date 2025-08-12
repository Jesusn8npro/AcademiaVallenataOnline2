<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { page } from '$app/stores';
  import { fly } from 'svelte/transition';
  
  // 🚫 ESTE LAYOUT ELIMINA COMPLETAMENTE TODA LA NAVEGACIÓN
  // Solo se aplica a /cursos/[slug] (NO a /cursos/[slug]/clase/* o /cursos/[slug]/leccion/*)
  
  let esClaseOLeccion = false;
  
  $: esClaseOLeccion = $page.url.pathname.includes('/clase/') || $page.url.pathname.includes('/leccion/');

  onMount(() => {
    // 🚫 FORZAR ESTILOS PARA ELIMINAR NAVEGACIÓN - VERSIÓN LIMPIA
    if (typeof document !== 'undefined') {
      // 🚨 SOLO OCULTAR ELEMENTOS DE NAVEGACIÓN GENERAL - NO TOCAR HEADERS NI MENUS
      const elementosNavegacion = document.querySelectorAll('.menu-superior, .menu-superior-autenticado, .admin-sidebar, .sidebar-moderno, .footer-politicas, .footer-general');
      
      elementosNavegacion.forEach(el => {
        if (el instanceof HTMLElement) {
          // 🚨 NO TOCAR NUNCA HEADERS NI MENUS INFERIORES
          if (!el.classList.contains('lesson-header') && 
              !el.classList.contains('menu-inferior-responsivo') &&
              !el.matches('header[class*="lesson"]') &&
              !el.matches('header[class*="leccion"]')) {
            
            el.style.display = 'none';
            el.style.visibility = 'hidden';
            el.style.opacity = '0';
            el.style.height = '0';
            el.style.width = '0';
            el.style.margin = '0';
            el.style.padding = '0';
            el.style.overflow = 'hidden';
          }
        }
      });
      
      // 🚨 PROTEGER EL HEADER DE LECCIONES - NO TOCARLO NUNCA
      const headerLeccion = document.querySelector('.lesson-header, header[class*="lesson"], header[class*="leccion"]') as HTMLElement;
      if (headerLeccion) {
        console.log('✅ [LAYOUT] Header de lección encontrado, NO TOCARLO NUNCA');
        headerLeccion.setAttribute('data-protected', 'true');
        // 🚨 NO TOCAR ESTILOS - SOLO MARCAR COMO PROTEGIDO
      }
      
      // 🚨 PROTEGER EL MENU INFERIOR RESPONSIVO - NO TOCARLO NUNCA
      const menuInferior = document.querySelector('.menu-inferior-responsivo') as HTMLElement;
      if (menuInferior) {
        console.log('✅ [LAYOUT] Menu inferior encontrado, NO TOCARLO NUNCA');
        menuInferior.setAttribute('data-protected', 'true');
        // 🚨 NO TOCAR NADA - SOLO MARCAR COMO PROTEGIDO
      }
      
      // 🚨 NO HAY PROTECCIÓN CONTINUA - DEJAR QUE LOS COMPONENTES MANEJEN SU VISIBILIDAD
      // El layout NO debe interferir con headers ni menus
      
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
        // 🚨 EXCLUIR MENU INFERIOR - NO RESTAURARLO
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
      
      // 🚨 RESTAURAR HEADER DE LECCIONES - SOLO SI ES NECESARIO
      const headerLeccion = document.querySelector('.lesson-header, header[class*="lesson"], header[class*="leccion"]') as HTMLElement;
      if (headerLeccion && headerLeccion.getAttribute('data-protected') === 'true') {
        console.log('✅ [LAYOUT] Restaurando header de lección protegido');
        // SOLO RESTAURAR SI ESTÁ OCULTO
        const computedStyle = window.getComputedStyle(headerLeccion);
        if (computedStyle.display === 'none' || computedStyle.visibility === 'hidden') {
          headerLeccion.style.display = '';
          headerLeccion.style.visibility = '';
        }
      }
      
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
{#if !esClaseOLeccion}
  <!-- Solo para páginas de detalle de curso, NO para clases o lecciones -->
  <div class="curso-pantalla-completa" transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
    <slot />
  </div>
{:else}
  <!-- Para clases y lecciones, usar layout normal -->
  <slot />
{/if}

<style>
  /* 🚫 PANTALLA COMPLETA TOTAL - ABSOLUTAMENTE SIN NADA */
  .curso-pantalla-completa {
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
  
  /* 🚨 PROTECCIÓN CSS PARA HEADERS DE LECCIONES - VERSIÓN AGRESIVA */
  .curso-pantalla-completa .lesson-header,
  .curso-pantalla-completa header[class*="lesson"],
  .curso-pantalla-completa header[class*="leccion"],
  .lesson-header,
  header[class*="lesson"],
  header[class*="leccion"] {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    height: auto !important;
    width: auto !important;
    /* PRESERVAR ESTILOS ORIGINALES */
    background-color: inherit !important;
    color: inherit !important;
    border: inherit !important;
    padding: inherit !important;
    margin: inherit !important;
    font-size: inherit !important;
    font-weight: inherit !important;
    text-align: inherit !important;
    box-shadow: inherit !important;
    border-radius: inherit !important;
    transition: inherit !important;
    transform: inherit !important;
    z-index: inherit !important;
  }
  
  /* 🚨 PROTECCIÓN EXTREMA PARA HEADERS - SOBRESCRIBIR CUALQUIER ESTILO */
  .lesson-header[style*="display: none"],
  .lesson-header[style*="visibility: hidden"],
  header[class*="lesson"][style*="display: none"],
  header[class*="lesson"][style*="visibility: hidden"],
  header[class*="leccion"][style*="display: none"],
  header[class*="leccion"][style*="visibility: hidden"] {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
  }
  
  /* 🚨 PROTECCIÓN CSS PARA MENU INFERIOR RESPONSIVO - VERSIÓN AGRESIVA */
  .curso-pantalla-completa .menu-inferior-responsivo,
  .curso-pantalla-completa nav[class*="menu-inferior"],
  .curso-pantalla-completa .menu-inferior-responsivo[data-protected="true"],
  .menu-inferior-responsivo,
  nav[class*="menu-inferior"],
  .menu-inferior-responsivo[data-protected="true"] {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    position: fixed !important;
    bottom: 0 !important;
    left: 0 !important;
    right: 0 !important;
    z-index: 999999 !important;
    transform: translateY(0) !important;
    height: auto !important;
    width: auto !important;
    margin: 0 !important;
    padding: 0 !important;
    overflow: visible !important;
    /* 🚨 SOBRESCRIBIR CUALQUIER ESTILO INLINE */
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    transform: translateY(0) !important;
  }
  
  /* 🚨 PROTECCIÓN GLOBAL PARA MENU INFERIOR - VERSIÓN AGRESIVA */
  .menu-inferior-responsivo,
  nav[class*="menu-inferior"],
  .menu-inferior-responsivo[data-protected="true"] {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    transform: translateY(0) !important;
    /* 🚨 SOBRESCRIBIR CUALQUIER ESTILO INLINE */
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    transform: translateY(0) !important;
  }
  
  /* 🚨 PROTECCIÓN EXTREMA - SOBRESCRIBIR CUALQUIER ESTILO */
  .menu-inferior-responsivo[style*="display: none"],
  .menu-inferior-responsivo[style*="visibility: hidden"],
  .menu-inferior-responsivo[style*="opacity: 0"],
  .menu-inferior-responsivo[style*="transform: translateY(100%)"] {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    transform: translateY(0) !important;
  }
  
  /* 🚨 CSS DE EMERGENCIA GLOBAL - FORZAR VISIBILIDAD SIEMPRE */
  .menu-inferior-responsivo,
  .lesson-header,
  header[class*="lesson"],
  header[class*="leccion"] {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    transform: translateY(0) !important;
  }
  
  /* 🚨 SOBRESCRIBIR CUALQUIER ESTILO DEL LAYOUT */
  .menu-inferior-responsivo[data-protected="true"],
  .lesson-header[data-protected="true"],
  header[data-protected="true"] {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    transform: translateY(0) !important;
  }

  /* 🚫 FORZAR QUE TODOS LOS ELEMENTOS HIJOS NO DESBORDEN */
  .curso-pantalla-completa * {
    max-width: 100% !important;
    box-sizing: border-box !important;
  }
  
  /* 🚫 OCULTAR SCROLL HORIZONTAL GLOBALMENTE */
  .curso-pantalla-completa ::-webkit-scrollbar:horizontal {
    display: none !important;
  }
  
  /* 🚫 OCULTAR SCROLL VERTICAL GLOBALMENTE */
  .curso-pantalla-completa ::-webkit-scrollbar {
    display: none !important;
    width: 0 !important;
    background: transparent !important;
  }
  
  .curso-pantalla-completa ::-webkit-scrollbar-track {
    display: none !important;
  }
  
  .curso-pantalla-completa ::-webkit-scrollbar-thumb {
    display: none !important;
  }
  
  .curso-pantalla-completa ::-webkit-scrollbar-corner {
    display: none !important;
  }
  
  /* 🚫 REGLAS ESPECÍFICAS PARA PLANTILLAS DE CURSOS */
  .curso-pantalla-completa .container,
  .curso-pantalla-completa .contenedor,
  .curso-pantalla-completa .layout-container,
  .curso-pantalla-completa .main-container,
  .curso-pantalla-completa .curso-container,
  .curso-pantalla-completa .tutorial-container {
    max-width: 100% !important;
    width: 100% !important;
    margin: 0 !important;
    padding-left: 0 !important;
    padding-right: 0 !important;
    overflow-x: hidden !important;
  }

  /* 🚫 ASEGURAR QUE NO HAYA ESPACIOS EXTRA */
  .curso-pantalla-completa > *:first-child {
    margin-top: 0 !important;
    padding-top: 0 !important;
  }
  
  .curso-pantalla-completa > *:last-child {
    margin-bottom: 0 !important;
    padding-bottom: 0 !important;
  }
</style> 