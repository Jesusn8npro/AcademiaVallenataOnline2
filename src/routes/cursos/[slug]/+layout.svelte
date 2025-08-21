<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { page } from '$app/stores';
  import { fly } from 'svelte/transition';
  
  // 🚫 ESTE LAYOUT ELIMINA COMPLETAMENTE TODA LA NAVEGACIÓN
  // Solo se aplica a /cursos/[slug] (NO a /cursos/[slug]/clase/* o /cursos/[slug]/leccion/*)
  
  let esClaseOLeccion = false;
  
  $: esClaseOLeccion = $page.url.pathname.includes('/clase/') || $page.url.pathname.includes('/leccion/');

  onMount(() => {
    // ✅ TEMPORALMENTE DESHABILITADO PARA DEBUGGING DEL MENÚ
    console.log('🚫 [DEBUG] Layout de cursos DESHABILITADO temporalmente');
    /*
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
    */
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

<!-- 🚫 LAYOUT TEMPORALMENTE DESHABILITADO PARA DEBUGGING DEL MENÚ -->
<!-- 
<div class="curso-pantalla-completa" transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
  <slot />
</div>
-->

<!-- ✅ LAYOUT SIMPLE TEMPORAL -->
<div class="curso-layout-simple">
  <slot />
</div>

<style>
  /* ✅ LAYOUT SIMPLE TEMPORAL */
  .curso-layout-simple {
    min-height: 100vh;
    background: #000;
  }
  
  /* ✅ IMPORTANTE: Permitir que el menú funcione normalmente */
  :global(.menu-inferior-responsivo) {
    /* NO INTERFERIR con el menú */
  }
</style> 