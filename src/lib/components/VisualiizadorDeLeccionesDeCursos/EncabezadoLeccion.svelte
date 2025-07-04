<script lang="ts">
  // --- FULLSCREEN LOGIC ---
  import { onMount, onDestroy } from 'svelte';
  let isFullscreen = false;
  let rootElem: HTMLElement | null = null;

  function toggleFullscreen() {
    if (!isFullscreen) {
      rootElem = document.documentElement;
      if (rootElem.requestFullscreen) {
        rootElem.requestFullscreen();
      } else if ((rootElem as any).webkitRequestFullscreen) {
        (rootElem as any).webkitRequestFullscreen();
      }
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if ((document as any).webkitExitFullscreen) {
        (document as any).webkitExitFullscreen();
      }
    }
  }

  function fullscreenChangeHandler() {
    isFullscreen = !!(document.fullscreenElement || (document as any).webkitFullscreenElement);
  }

  onMount(() => {
    document.addEventListener('fullscreenchange', fullscreenChangeHandler);
    document.addEventListener('webkitfullscreenchange', fullscreenChangeHandler);
  });
  onDestroy(() => {
    document.removeEventListener('fullscreenchange', fullscreenChangeHandler);
    document.removeEventListener('webkitfullscreenchange', fullscreenChangeHandler);
  });


  import { createEventDispatcher } from 'svelte';
  import BarraProgresoGeneral from '$lib/components/VisualiizadorDeLeccionesDeCursos/BarraProgresoGeneral.svelte';
  import BarraLateralCurso from '$lib/components/VisualiizadorDeLeccionesDeCursos/BarraLateralCurso.svelte';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';
  
  // Props
  export let cursoTitulo: string = '';
  export let leccionTitulo: string = '';
  export let cursoId: string = '';
  export let leccionId: string = '';
  export let tipo: 'leccion' | 'clase' = 'leccion'; // "leccion" para curso, "clase" para tutorial
  export let mostrarSidebar: boolean = true;
  // Props adicionales requeridas para el sidebar móvil
  export let curso: any = null; // Debe ser pasado desde el padre
  export let moduloActivo: string = '';
  export let progreso: any = {};
  
  export let onToggleSidebar: () => void = () => {};
  export let usuarioActual: any = null;
  export let leccionAnterior: any = null;
  export let leccionSiguiente: any = null;
  
  // Determinar la etiqueta apropiada según el tipo
  $: etiquetaContenido = tipo === 'leccion' ? 'Lección:' : 'Clase:';
  
  // Estado
  let isScrolled = false;

  // Event dispatcher
  const dispatch = createEventDispatcher();
  
  // Detectar scroll para cambiar el aspecto
  function handleScroll() {
    isScrolled = window.scrollY > 10;
  }
  
  let isDesktop = true;

  function handleResize() {
    isDesktop = window.innerWidth > 1024;
  }

  onMount(() => {
    // Configurar eventos de scroll y resize
    window.addEventListener('scroll', handleScroll);
    handleResize();
    window.addEventListener('resize', handleResize);
    
    // Cleanup function
    return () => {
      window.removeEventListener('resize', handleResize);
    };
  });
  
  onDestroy(() => {
    window.removeEventListener('scroll', handleScroll);
  });

  let sidebarMobileOpen = false;
  function toggleSidebarMobile() {
    sidebarMobileOpen = !sidebarMobileOpen;
  }
</script>

<header 
  class="lesson-header"
  class:scrolled={isScrolled}
  
>
  <div class="header-left">
    {#if !isDesktop}
      <button class="sidebar-mobile-btn" on:click={toggleSidebarMobile} aria-label="Mostrar menú del curso">
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
      </button>
    {/if}
    <a href="/" class="logo-link">
      <img 
        src="https://academiavallenataonline.com/wp-content/uploads/2020/04/cropped-cropped-Academia-Vallenata-LOGO-4.png" 
        alt="Academia Vallenata" 
        class="logo"
      />
    </a>
    <!-- Versión responsiva: mostrar título y clase al lado del logo (ajustada) -->
    <div class="curso-info-mobile">
      <a href={tipo === 'leccion' ? `/cursos/${curso?.slug || cursoId}` : `/tutoriales/${curso?.slug || cursoId}`} class="curso-titulo" title="Ver información del curso">
        {cursoTitulo}
      </a>
      <span class="separador">|</span>
      <span class="leccion-titulo"><span class="clase-label">{etiquetaContenido}</span> {leccionTitulo}</span>
    </div>
    <div class="curso-info">
      <a href={tipo === 'leccion' ? `/cursos/${curso?.slug || cursoId}` : `/tutoriales/${curso?.slug || cursoId}`} class="curso-titulo" title="Ver información del curso">
        {cursoTitulo}
      </a>
      <span class="separador">|</span>
      <h1 class="leccion-titulo"><span class="clase-label">{etiquetaContenido}</span> {leccionTitulo}</h1>
    </div>
  </div>

  {#if sidebarMobileOpen && !isDesktop}
    <div class="sidebar-mobile-overlay" on:click={toggleSidebarMobile}>
      <div class="sidebar-mobile-panel" on:click|stopPropagation>
        <BarraLateralCurso
          curso={curso}
          moduloActivo={moduloActivo}
          leccionActiva={leccionId}
          progreso={progreso}
        />
      </div>
    </div>
  {/if} 
  
  <div class="header-right">
    <!-- Mini navegación entre lecciones/clases -->
    <div class="mini-nav">
      <button class="mini-nav-btn prev" on:click={() => {
  if (leccionAnterior) {
    if (tipo === 'leccion') {
      dispatch('anterior-leccion', { leccion: leccionAnterior });
    } else {
      const slug = leccionAnterior.slug || (leccionAnterior.titulo ? generateSlug(leccionAnterior.titulo) : leccionAnterior.id);
      const cursoSlug = curso?.slug || (curso?.titulo ? generateSlug(curso.titulo) : curso?.id);
      if (cursoSlug && slug) {
        window.location.href = `/tutoriales/${cursoSlug}/clase/${slug}`;
      }
    }
  }
}} disabled={!leccionAnterior} aria-label="Anterior">
  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"></polyline></svg>
</button>
<button class="mini-nav-btn next" on:click={() => {
  if (leccionSiguiente) {
    if (tipo === 'leccion') {
      dispatch('siguiente-leccion', { leccion: leccionSiguiente });
    } else {
      const slug = leccionSiguiente.slug || (leccionSiguiente.titulo ? generateSlug(leccionSiguiente.titulo) : leccionSiguiente.id);
      const cursoSlug = curso?.slug || (curso?.titulo ? generateSlug(curso.titulo) : curso?.id);
      if (cursoSlug && slug) {
        window.location.href = `/tutoriales/${cursoSlug}/clase/${slug}`;
      }
    }
  }
}} disabled={!leccionSiguiente} aria-label="Siguiente">
  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 6 15 12 9 18"></polyline></svg>
</button>
    </div>
    
    
    <div class="progress-wrapper">
      <BarraProgresoGeneral 
        tipo={tipo === 'leccion' ? 'curso' : 'tutorial'} 
        contenidoId={cursoId} 
      />

    </div>
    
    {#if isDesktop}
    <button class="header-btn fullscreen-btn" aria-label={isFullscreen ? 'Salir de pantalla completa' : 'Pantalla completa'} on:click={toggleFullscreen}>
      {#if isFullscreen}
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 9L5 5m0 4V5h4"/><path d="M15 9l4-4m0 4V5h-4"/><path d="M15 15l4 4m0-4v4h-4"/><path d="M9 15l-4 4m0-4v4h4"/></svg>
      {:else}
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 3v3a2 2 0 0 1-2 2H3m18 0h-3a2 2 0 0 1-2-2V3m0 18v-3a2 2 0 0 1 2-2h3M3 16h3a2 2 0 0 1 2 2v3"/></svg>
      {/if}
    </button>
{/if}    
    
    <button 
      class="toggle-sidebar-btn" 
      on:click={onToggleSidebar}
      aria-label={mostrarSidebar ? 'Ocultar contenido del curso' : 'Mostrar contenido del curso'}
    >
      <div class="icon-container">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
          <line x1="9" y1="3" x2="9" y2="21"></line>
        </svg>
      </div>
      <span class="toggle-text">{mostrarSidebar ? 'Ocultar contenido' : 'Ver contenido'}</span>
    </button>
  </div>
</header>

<style>
  .lesson-header {
    position: relative;
    top: 0;
    left: 0;
    right: 0;
    width: 100%;
    min-height: 60px;
    height: auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    padding: 10px 20px;
    background-color: #1c1d1f;
    color: white;
    z-index: 1000;
    transition: all 0.3s ease;
    margin: 0;
    box-sizing: border-box;
    border-color: #fff;
    border-bottom: 0.5px solid #fff;
  }
  

  
  .scrolled {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.25);
  }
  
  .header-left {
    display: flex;
    align-items: center;
    gap: 15px;
    flex-wrap: wrap;
    flex: 1;
    min-width: 0;
  }
  
  .toggle-sidebar-btn {
    display: flex;
    align-items: center;
    gap: 6px;
    background-color: #3e4143;
    border: none;
    color: white;
    cursor: pointer;
    padding: 8px 12px;
    border-radius: 4px;
    font-size: 0.85rem;
    transition: all 0.2s ease;
    margin-left: 10px;
  }

  .sidebar-mobile-btn {
    display: none;
    background: none;
    border: none;
    padding: 6px 10px 6px 0;
    color: #fff;
    cursor: pointer;
    align-items: center;
    justify-content: center;
  }
  @media (max-width: 1024px) {
    .sidebar-mobile-btn {
      display: flex;
      margin-right: 2px;
      z-index: 1020;
      background: none;
    }
  }

  .sidebar-mobile-overlay {
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0,0,0,0.45);
    z-index: 2000;
    display: flex;
    justify-content: flex-start;
    align-items: stretch;
  }
  .sidebar-mobile-panel {
    width: 80vw;
    max-width: 320px;
    height: 100vh;
    background: #232323;
    box-shadow: 2px 0 16px rgba(0,0,0,0.18);
    overflow-y: auto;
    position: relative;
    z-index: 2001;
    animation: sidebarIn 0.2s;
  }
  @keyframes sidebarIn {
    from { transform: translateX(-100%); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
  }

  @media (max-width: 800px) {
    .toggle-sidebar-btn {
      display: none !important;
    }
  }

  .toggle-sidebar-btn:hover {
    background-color: #505356;
  }
  
  .icon-container {
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .toggle-text {
    font-weight: 500;
  }
  
  .logo-link {
    display: flex;
    align-items: center;
  }
  
  .logo {
    height: 35px;
    width: auto;
    margin-right: 15px;
  }
  
  .curso-info {
    display: flex;
    align-items: center;
    font-size: 0.9rem;
    flex-wrap: wrap;
    min-width: 0;
    flex: 1;
  }
  
  .curso-info-mobile {
    display: none;
    flex-direction: column;
    align-items: flex-start;
    width: 100%;
    max-width: 100vw;
    box-sizing: border-box;
    padding: 4px 10px 4px 0;
    font-size: 0.96rem;
    color: #fff;
    font-weight: 500;
    overflow: hidden;
    word-break: break-word;
    white-space: normal;
  }
  .curso-info-mobile .curso-titulo {
    color: #fff;
    font-weight: 700;
    text-decoration: none;
    font-size: 1rem;
    display: block;
    width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: normal;
    margin-bottom: 2px;
    transition: color 0.2s ease;
    cursor: pointer;
  }
  
  .curso-info-mobile .curso-titulo:hover {
    color: #a435f0;
    text-decoration: underline;
  }
  .curso-info-mobile .leccion-titulo {
    color: #a1a1a1;
    font-size: 0.95rem;
    font-weight: 400;
    display: block;
    width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: normal;
  }
  .curso-info-mobile .clase-label {
    color: #a435f0;
    margin-right: 4px;
  }

  .curso-info-mobile .separador {
    display: none;
  }

  @media (max-width: 1024px) {
    .header-left {
      display: flex;
      align-items: center;
      flex-direction: row;
      width: 100%;
      gap: 8px;
      min-width: 0;
    }

    .logo-link {
      flex-shrink: 0;
      margin-right: 8px;
    }

    .logo {
      max-width: 36px;
      height: auto;
      display: block;
    }

    .curso-info {
      display: none;
    }

    .curso-info-mobile {
      display: flex;
      flex-direction: row;
      align-items: center;
      flex: 1;
      min-width: 0;
      width: 100%;
      padding: 0;
      background: none;
      gap: 6px;
      overflow: hidden;
      font-size: 0.96rem;
    }

    .curso-info-mobile .curso-titulo, .curso-info-mobile .leccion-titulo {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 45vw;
      display: inline-block;
    }

    .curso-info-mobile .curso-titulo {
      margin-bottom: 0;
    }

    .curso-info-mobile .separador {
      display: inline;
    }
  }

  .curso-titulo {
    color: #a1a1a1;
    text-decoration: none;
    white-space: normal;
    overflow: visible;
    text-overflow: initial;
    max-width: none;
    flex: 1;
    min-width: 0;
    transition: color 0.2s ease;
    cursor: pointer;
  }
  
  .curso-titulo:hover {
    color: #a435f0;
    text-decoration: underline;
  }
  
  .clase-label {
    color: #a435f0;
    margin-right: 4px;
  }
  
  .separador {
    margin: 0 10px;
    color: #666;
  }
  
  .leccion-titulo {
    font-size: 0.9rem;
    font-weight: 500;
    white-space: normal;
    overflow: visible;
    text-overflow: initial;
    margin: 0;
    max-width: none;
    flex: 2;
    min-width: 0;
  }
  
  .header-right {
    display: flex;
    align-items: center;
    gap: 15px;
    flex-wrap: wrap;
    justify-content: flex-end;
  }
  
  .progress-wrapper {
    display: flex;
    flex-direction: column;
    gap: 3px;
  }
  
  .header-btn {
    display: flex;
    align-items: center;
    gap: 5px;
    background: none;
    border: 1px solid #555;
    color: white;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.9rem;
    transition: all 0.2s ease;
  }
  
  .header-btn:hover {
    background-color: rgba(255, 255, 255, 0.1);
  }
  

  
  @media (max-width: 768px) {
    .curso-info {
      display: none;
    }
    
    .progress-wrapper {
      display: none;
    }
    
    .header-btn span {
      display: none;
    }
    
    .toggle-text {
      display: none;
    }
    
    .toggle-sidebar-btn {
      padding: 8px;
    }
    
    .header-btn {
      padding: 8px;
    }
  }
.mini-nav {
  display: flex;
  gap: 6px;
  align-items: center;
}
.mini-nav-btn {
  background: #222;
  border: 1px solid #444;
  border-radius: 4px;
  color: #fff;
  padding: 4px 8px;
  cursor: pointer;
  transition: background 0.2s;
  font-size: 1rem;
}
.mini-nav-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

</style> 