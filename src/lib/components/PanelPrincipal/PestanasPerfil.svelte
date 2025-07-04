<script lang="ts">
  // Iconos SVG inline para máxima personalización y rendimiento
  import { goto } from '$app/navigation';

  const pestañas = [
    { label: 'Perfil', icon: `<svg width='24' height='24' viewBox='0 0 24 24'><circle cx='12' cy='8' r='3.5' stroke='currentColor' stroke-width='1.5'/><path d='M4 20c0-3.5 8-3.5 8-3.5s8 0 8 3.5' stroke='currentColor' stroke-width='1.5'/></svg>`, route: '/mi-perfil' },
    { label: 'Mis Cursos', icon: `<svg width='24' height='24' viewBox='0 0 24 24'><rect x='4' y='4' width='16' height='16' rx='2' stroke='currentColor' stroke-width='1.5'/><path d='M8 9h8M8 14h5' stroke='currentColor' stroke-width='1.5'/></svg>`, route: '/mis-cursos' },
    { label: 'Comunidad', icon: `<svg width='24' height='24' viewBox='0 0 24 24'><circle cx='8' cy='8' r='3.5' stroke='currentColor' stroke-width='1.5'/><circle cx='16' cy='8' r='3.5' stroke='currentColor' stroke-width='1.5'/><path d='M2 20c0-3.5 6-3.5 6-3.5s6 0 6 3.5M10 20c0-3.5 6-3.5 6-3.5s6 0 6 3.5' stroke='currentColor' stroke-width='1.5'/></svg>`, route: '/comunidad' },
    { label: 'Publicaciones', icon: `<svg width='24' height='24' viewBox='0 0 24 24'><rect x='6' y='4' width='12' height='16' rx='2' stroke='currentColor' stroke-width='1.5'/><path d='M9 9h6M9 13h6' stroke='currentColor' stroke-width='1.5'/></svg>`, route: '/publicaciones' },
    { label: 'Blog', icon: `<svg width='24' height='24' viewBox='0 0 24 24'><path d='M4 19.5A2.5 2.5 0 0 1 6.5 17H20v2.5a2.5 2.5 0 0 1-2.5 2.5h-15A2.5 2.5 0 0 1 4 19.5zM4 5.5A2.5 2.5 0 0 1 6.5 3H20v14H6.5A2.5 2.5 0 0 1 4 14.5v-9z' stroke='currentColor' stroke-width='1.5'/></svg>`, route: '/blog' },
    { label: 'Configuración', icon: `<svg width='24' height='24' viewBox='0 0 24 24'><circle cx='12' cy='12' r='2.5' stroke='currentColor' stroke-width='1.5'/><path d='M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33h.09a1.65 1.65 0 0 0 1 1.51V5a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51h.09a1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82v.09a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z' stroke='currentColor' stroke-width='1.5'/></svg>`, route: '/configuracion' },
    { label: 'Salir', icon: `<svg width='24' height='24' viewBox='0 0 24 24'><path d='M16 17l5-5-5-5M21 12H9' stroke='currentColor' stroke-width='1.5'/><path d='M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4' stroke='currentColor' stroke-width='1.5'/></svg>`, route: '/sesion_cerrada' }
  ];

  import { page } from '$app/stores';
  import { get } from 'svelte/store';
  import { onMount } from 'svelte';

  let indiceActivo = 0;
  let contenedorNav: HTMLElement;
  let puedeScrollIzquierda = false;
  let puedeScrollDerecha = false;

  $: {
    const rutaActual = get(page).url.pathname;
    // Encuentra la coincidencia más específica
    const mejorCoincidencia = pestañas.reduce((mejor, pestaña, indice) => {
      if (rutaActual.startsWith(pestaña.route) && pestaña.route.length > (mejor.longitud || 0)) {
        return { indice, longitud: pestaña.route.length };
      }
      return mejor;
    }, { indice: -1, longitud: 0 });
    
    indiceActivo = mejorCoincidencia.indice !== -1 ? mejorCoincidencia.indice : 0;
  }

  function actualizarEstadoScroll() {
    if (!contenedorNav) return;
    const { scrollLeft, scrollWidth, clientWidth } = contenedorNav;
    puedeScrollIzquierda = scrollLeft > 0;
    puedeScrollDerecha = scrollLeft < scrollWidth - clientWidth - 1; // -1 for precision
  }

  function scrollHorizontal(direccion: 'izquierda' | 'derecha') {
    if (!contenedorNav) return;
    const cantidadScroll = contenedorNav.clientWidth * 0.7; // Scroll del 70% del ancho visible
    const nuevoScrollLeft =
      direccion === 'izquierda'
        ? contenedorNav.scrollLeft - cantidadScroll
        : contenedorNav.scrollLeft + cantidadScroll;
    
    contenedorNav.scrollTo({
      left: nuevoScrollLeft,
      behavior: 'smooth'
    });
  }

  onMount(() => {
    // Timeout para asegurar que el DOM está renderizado y las dimensiones son correctas
    setTimeout(actualizarEstadoScroll, 100);
    window.addEventListener('resize', actualizarEstadoScroll);
    return () => window.removeEventListener('resize', actualizarEstadoScroll);
  });
</script>

<div class="contenedor-pestañas-wrapper">
  <div class="nav-container-interno">
    <button
      class="boton-scroll izquierda"
      aria-label="Desplazar a la izquierda"
      on:click={() => scrollHorizontal('izquierda')}
      class:visible={puedeScrollIzquierda}
    >
      <svg viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" /></svg>
    </button>

    <nav
      class="navegacion-pestañas"
      bind:this={contenedorNav}
      on:scroll={actualizarEstadoScroll}
    >
      {#each pestañas as pestaña, i}
        <a
          href={pestaña.route || '#'}
          class="pestaña-item"
          class:activo={indiceActivo === i}
          aria-label={pestaña.label}
          role="tab"
          on:click={(e) => {
            if (!pestaña.route) e.preventDefault();
            else goto(pestaña.route);
          }}
        >
          <div class="contenido-pestaña">
            <div class="icono">{@html pestaña.icon}</div>
            <span class="etiqueta">{pestaña.label}</span>
          </div>
        </a>
      {/each}
    </nav>

    <button
      class="boton-scroll derecha"
      aria-label="Desplazar a la derecha"
      on:click={() => scrollHorizontal('derecha')}
      class:visible={puedeScrollDerecha}
    >
      <svg viewBox="0 0 24 24"><path d="M9 18l6-6-6-6" /></svg>
    </button>
  </div>
</div>

<style>
  .contenedor-pestañas-wrapper {
    position: relative;
    width: 100%;
    margin-top: -60px;
    z-index: 20;
  }

  .nav-container-interno {
    position: relative;
    margin-top: 50px;
  }

  .navegacion-pestañas {
    display: flex;
    justify-content: center;
    background: #ffffff;
    border-radius: 16px;
    padding: 0 12px;
    box-shadow: 0 6px 32px -4px rgba(0, 0, 0, 0.08);
  }
  .pestaña-item {
    display: flex;
    justify-content: center;
    padding: 8px 12px;
    color: #4b5563; /* Gris más oscuro para mejor lectura */
    text-decoration: none;
    position: relative;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    flex: 1; /* Distribución equitativa en escritorio */
    min-width: 80px;
    text-align: center;
  }
  .contenido-pestaña {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    padding: 8px 4px;
    border-radius: 12px;
    width: 100%;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    top: 0;
  }

  .pestaña-item.activo .contenido-pestaña {
    color: #2563eb;
    transform: translateY(-4px);
  }
  .pestaña-item:hover:not(.activo) .contenido-pestaña {
    background-color: #f3f4f6; /* Fondo sutil al pasar el mouse */
    transform: translateY(-2px);
  }

  .icono {
    width: 26px;
    height: 26px;
  }
  .etiqueta {
    font-size: 0.7rem; /* 11.2px */
    font-weight: 600;
    letter-spacing: 0.02em;
  }

  .pestaña-item::after {
    content: '';
    position: absolute;
    bottom: 4px;
    left: 20%;
    width: 60%;
    height: 4px;
    background: #2563eb;
    border-radius: 10px;
    transform: scaleX(0);
    transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    transform-origin: center;
  }
  .pestaña-item.activo::after {
    transform: scaleX(1);
  }

  /* === BOTONES DE SCROLL RESPONSIVOS === */
  .boton-scroll {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    background-color: #2563eb; /* Azul primario */
    border: none;
    border-radius: 50%;
    width: 36px;
    height: 36px;
    display: none; /* Ocultos por defecto */
    align-items: center;
    justify-content: center;
    cursor: pointer;
    z-index: 25;
    box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
    transition: all 0.2s ease;
    opacity: 0;
    pointer-events: none;
  }
  .boton-scroll.visible {
    opacity: 1;
    pointer-events: auto;
  }
  .boton-scroll:hover {
    background-color: #1d4ed8; /* Azul más oscuro */
    transform: translateY(-50%) scale(1.1);
  }
  .boton-scroll.izquierda {
    left: -18px;
  }
  .boton-scroll.derecha {
    right: -18px;
  }
  .boton-scroll svg {
    width: 20px;
    height: 20px;
    stroke: #ffffff; /* Blanco */
    stroke-width: 2.5;
    fill: none;
    stroke-linecap: round;
    stroke-linejoin: round;
  }

  /* === DISEÑO RESPONSIVO PARA MÓVILES === */
  @media (max-width: 768px) {
    .navegacion-pestañas {
      justify-content: flex-start;
      overflow-x: auto;
      scroll-snap-type: x mandatory;
      padding: 0 16px; /* Espacio para que no se peguen a los bordes */
      -ms-overflow-style: none; /* IE and Edge */
      scrollbar-width: none; /* Firefox */
    }
    .navegacion-pestañas::-webkit-scrollbar {
      display: none; /* Chrome, Safari, and Opera */
    }
    .pestaña-item {
      flex: 0 0 auto; /* No crecen, no se encogen, tamaño automático */
      width: 30%; /* Muestra ~3 pestañas */
      scroll-snap-align: center;
    }
    .boton-scroll {
      display: flex; /* Muestra los botones en móvil */
    }
  }

  @media (max-width: 480px) {
    .pestaña-item {
      width: 40%; /* Muestra ~2.5 pestañas */
    }
  }
</style>
