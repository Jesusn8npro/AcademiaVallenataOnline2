<script lang="ts">
  import PorcentajePerfil from '$lib/components/Banners/PorcentajePerfil.svelte';
  import UltimosArticulosBlog from '$lib/components/Banners/UltimosArticulosBlog.svelte';
  import RankingComunidad from '$lib/components/Banners/RankingComunidad.svelte';
  import SliderCursos from '$lib/components/Banners/SliderCursos.svelte';
  import ComunidadPublicar from '$lib/components/Comunidad/ComunidadPublicar.svelte';
  import FeedPublicaciones from '$lib/components/Comunidad/FeedPublicaciones.svelte';
  import { onMount, afterUpdate } from 'svelte';
  import { obtenerSesion, obtenerPerfil } from '$lib/supabase/autenticacionSupabase';
  import { supabase } from '$lib/supabase/clienteSupabase';

  // Estado reactivo para el perfil del usuario
  let perfil: any = {};
  let usuario: any = null;

  // Feed de publicaciones
  let publicaciones: any[] = [];
  let cargandoPublicaciones = false;
  let errorPublicaciones = '';
  let pagina = 0;
  const LIMITE = 4;
  let fin = false;
  let centinela: HTMLElement;
  let observador: IntersectionObserver;

  // Cargar publicaciones con paginación
  async function cargarMasPublicaciones() {
    if (cargandoPublicaciones || fin) return;
    cargandoPublicaciones = true;
    errorPublicaciones = '';
    const desde = pagina * LIMITE;
    const hasta = desde + LIMITE - 1;
    const { data, error } = await supabase
      .from('comunidad_publicaciones')
      .select('*')
      .order('fecha_creacion', { ascending: false })
      .range(desde, hasta);
    if (error) {
      errorPublicaciones = 'Error al cargar publicaciones: ' + error.message;
    } else {
      if (!data || data.length < LIMITE) fin = true;
      publicaciones = [...publicaciones, ...(data || []).map((pub: any) => ({
        ...pub,
        usuario_id: pub.usuario_id,
        usuario_nombre: pub.usuario_nombre || 'Usuario',
        usuario_avatar: pub.usuario_avatar || '',
        contenido: pub.descripcion || '',
        fecha: pub.fecha_creacion ? new Date(pub.fecha_creacion).toLocaleString() : '',
        url_imagen: pub.url_imagen || '',
        url_video: pub.url_video || '',
        url_gif: pub.url_gif || '',
        tipo: pub.tipo || 'texto',
        encuesta: pub.encuesta || null,
        me_gusta: pub.me_gusta || [],
        total_comentarios: pub.total_comentarios || 0,
        total_compartidos: pub.total_compartidos || 0
      }))];
      pagina += 1;
    }
    cargandoPublicaciones = false;
  }

  // Intersection Observer para scroll infinito
  function manejarInterseccion(entradas: IntersectionObserverEntry[]) {
    if (entradas[0].isIntersecting) {
      cargarMasPublicaciones();
    }
  }

  onMount(async () => {
    const sesion = await obtenerSesion();
    if (!sesion?.user) return;
    const resultado = await obtenerPerfil(sesion.user.id);
    if (!resultado?.perfil) return;
    perfil = resultado.perfil;

    // Usuario para publicaciones
    usuario = {
      id: sesion.user.id,
      nombre: perfil.nombre || perfil.nombre_usuario || 'Usuario',
      avatar_url: perfil.url_foto_perfil || ''
    };

    // Cargar primeras publicaciones
    await cargarMasPublicaciones();

    // Observer para scroll infinito
    observador = new IntersectionObserver(manejarInterseccion);
    if (centinela) observador.observe(centinela);
  });

  afterUpdate(() => {
    if (observador && centinela && !fin) {
      observador.disconnect();
      observador.observe(centinela);
    }
  });

  const manejarPublicar = async () => {
    // Recargar el feed desde el principio
    publicaciones = [];
    pagina = 0;
    fin = false;
    await cargarMasPublicaciones();
  };
</script>

<div class="contenedor-comunidad">
  <!-- Banner Superior -->
  <div class="contenedor-banner">
    <div class="contenido-banner">
      <div class="texto-banner">
        <h1 class="titulo-banner">🎵 Comunidad de Acordeonistas</h1>
        <p class="subtitulo-banner">Comparte tus grabaciones, conecta con otros músicos y aprende juntos</p>
        <div class="caracteristicas-banner">
          <div class="elemento-caracteristica">
            <span class="icono-caracteristica">🎥</span>
            <span class="texto-caracteristica">Videos</span>
          </div>
          <div class="elemento-caracteristica">
            <span class="icono-caracteristica">🎼</span>
            <span class="texto-caracteristica">Grabaciones</span>
          </div>
          <div class="elemento-caracteristica">
            <span class="icono-caracteristica">💬</span>
            <span class="texto-caracteristica">Preguntas</span>
          </div>
          <div class="elemento-caracteristica">
            <span class="icono-caracteristica">📊</span>
            <span class="texto-caracteristica">Encuestas</span>
          </div>
        </div>
      </div>
      <div class="visual-banner">
        <div class="onda-musical">
          <div class="barra-onda"></div>
          <div class="barra-onda"></div>
          <div class="barra-onda"></div>
          <div class="barra-onda"></div>
          <div class="barra-onda"></div>
        </div>
      </div>
    </div>
  </div>

  <!-- Contenido Principal de 3 Columnas -->
  <div class="grilla-contenido-principal">
    <!-- Columna Izquierda -->
    <div class="columna-izquierda">
      <PorcentajePerfil {perfil} />
      <UltimosArticulosBlog />
    </div>

    <!-- Columna Central -->
    <div class="columna-central">
      <div class="contenedor-publicar">
        <ComunidadPublicar {usuario} on:publicar={manejarPublicar} />
      </div>
      
      <!-- Feed de Publicaciones -->
      {#if publicaciones.length === 0 && !cargandoPublicaciones}
        <div class="cargando-feed">No hay publicaciones aún.</div>
      {/if}
      {#each publicaciones as pub (pub.id)}
        <FeedPublicaciones
          id={pub.id}
          usuario_id={pub.usuario_id}
          usuario_nombre={pub.usuario_nombre}
          usuario_avatar={pub.usuario_avatar}
          fecha={pub.fecha_creacion}
          contenido={pub.descripcion}
          url_imagen={pub.url_imagen}
          url_video={pub.url_video}
          url_gif={pub.url_gif}
          tipo={pub.tipo}
          encuesta={pub.encuesta}
          me_gusta={pub.me_gusta}
          total_comentarios={pub.total_comentarios}
          total_compartidos={pub.total_compartidos}
          usuario={usuario}
        />
      {/each}

      <!-- Estados del scroll infinito -->
      {#if cargandoPublicaciones && publicaciones.length > 0}
        <div class="cargando-feed">Cargando más publicaciones...</div>
      {/if}

      {#if !fin && !cargandoPublicaciones && publicaciones.length > 0}
        <div bind:this={centinela} style="height: 1px;"></div>
      {/if}

      {#if fin && publicaciones.length > 0}
        <div class="cargando-feed">Fin de las publicaciones</div>
      {/if}

      {#if !cargandoPublicaciones && publicaciones.length === 0}
        <div class="cargando-feed">Sé el primero en publicar algo.</div>
      {/if}
    </div>

    <!-- Columna Derecha -->
    <div class="columna-derecha">
      <RankingComunidad />
      <SliderCursos />
    </div>
  </div>
</div>

<style>
  /* --- Contenedor Principal --- */
  .contenedor-comunidad {
    padding: 1rem;
    max-width: 1700px;
    margin: 0 auto;
    font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
    margin-top: 30px;
  }

  /* --- Banner Superior --- */
  .contenedor-banner {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 2.5rem 2rem;
    border-radius: 16px;
    margin-bottom: 2rem;
    box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3);
    overflow: hidden;
    position: relative;
  }

  .contenedor-banner::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="20" cy="20" r="2" fill="rgba(255,255,255,0.1)"/><circle cx="80" cy="30" r="1.5" fill="rgba(255,255,255,0.08)"/><circle cx="40" cy="70" r="1" fill="rgba(255,255,255,0.06)"/></svg>');
    pointer-events: none;
  }

  .contenido-banner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    max-width: 1200px;
    margin: 0 auto;
    position: relative;
    z-index: 1;
  }

  .texto-banner {
    flex: 1;
    max-width: 600px;
  }

  .titulo-banner {
    font-size: 2.5rem;
    font-weight: 800;
    margin: 0 0 1rem 0;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    background: linear-gradient(45deg, #ffffff, #f0f8ff);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .subtitulo-banner {
    font-size: 1.2rem;
    margin: 0 0 1.5rem 0;
    opacity: 0.95;
    font-weight: 400;
    line-height: 1.5;
  }

  .caracteristicas-banner {
    display: flex;
    gap: 1.5rem;
    flex-wrap: wrap;
  }

  .elemento-caracteristica {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: rgba(255, 255, 255, 0.15);
    padding: 0.75rem 1rem;
    border-radius: 25px;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    transition: all 0.3s ease;
  }

  .elemento-caracteristica:hover {
    background: rgba(255, 255, 255, 0.25);
    transform: translateY(-2px);
  }

  .icono-caracteristica {
    font-size: 1.2rem;
  }

  .texto-caracteristica {
    font-size: 0.9rem;
    font-weight: 600;
  }

  .visual-banner {
    flex-shrink: 0;
    margin-left: 2rem;
  }

  .onda-musical {
    display: flex;
    align-items: center;
    gap: 4px;
    height: 60px;
  }

  .barra-onda {
    width: 6px;
    background: linear-gradient(180deg, #ffffff, #f0f8ff);
    border-radius: 3px;
    animation: onda 1.5s ease-in-out infinite;
  }

  .barra-onda:nth-child(1) { height: 20px; animation-delay: 0s; }
  .barra-onda:nth-child(2) { height: 35px; animation-delay: 0.2s; }
  .barra-onda:nth-child(3) { height: 50px; animation-delay: 0.4s; }
  .barra-onda:nth-child(4) { height: 30px; animation-delay: 0.6s; }
  .barra-onda:nth-child(5) { height: 25px; animation-delay: 0.8s; }

  @keyframes onda {
    0%, 100% { transform: scaleY(1); opacity: 0.7; }
    50% { transform: scaleY(1.5); opacity: 1; }
  }

  /* --- Grilla de 3 Columnas --- */
  .grilla-contenido-principal {
    display: grid;
    grid-template-columns: 280px 1fr 320px; /* Columna derecha más ancha */
    gap: 2rem;
  }

  /* --- Estilos de las Columnas --- */
  .columna-izquierda,
  .columna-central,
  .columna-derecha {
    border-radius: 12px;
    min-height: 600px; /* Para que se vea el esqueleto */
  }

  .columna-izquierda {
    padding: 0; /* Sin padding para que el componente se ajuste perfectamente */
    overflow: hidden; /* Para mantener el border-radius */
    display: flex;
    flex-direction: column;
    gap: 30px; /* Sin gap para que se vean integrados */
  }

  .columna-izquierda :global(.banner-articulos) {
    border-radius:12px; /* Solo esquinas inferiores redondeadas */
    margin: 0; /* Quitamos el margin del componente */
  }

  .columna-central {
    padding: 0;
    background-color: transparent;
    box-shadow: none;
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .contenedor-publicar {
    background-color: #ffffff;
    border-radius: 12px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    overflow: hidden;
    margin-bottom: 1rem;
  }

  .columna-derecha {
    padding: 1.5rem 1rem; /* Padding uniforme para ambos componentes */
    overflow-y: auto; /* Permite scroll si el contenido es muy alto */
    display: flex;
    flex-direction: column;
    align-items: center; /* Centra los componentes */
    justify-content: flex-start;
    gap: 1.5rem; /* Espaciado entre ranking y mini cursos */
  }

  .columna-derecha > :global(div) {
    background: white;
    padding: 1rem;
    border-radius: 12px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  }

  .columna-derecha > :global(div:not(:last-child)) {
    margin-bottom: 1.5rem;
  }

  .cargando-feed {
    text-align: center;
    padding: 2rem;
    color: #6b7280;
    font-weight: 500;
  }

  /* Ajustes específicos para el ranking */
  .columna-derecha :global(.ranking-gamer) {
    margin-bottom: 0; /* Quitamos el margin del componente */
    width: 100%; /* Ocupa todo el ancho disponible */
    max-width: 300px; /* Se ajusta al nuevo ancho de la columna */
  }

  /* Ajustes específicos para slider de cursos */
  .columna-derecha :global(.slider-cursos-wrapper) {
    margin: 0; /* Quitamos el margin del componente */
    width: 100%; /* Ocupa todo el ancho disponible */
    max-width: 300px; /* Se ajusta al nuevo ancho de la columna */
  }

  /* Scrollbar personalizado para la columna derecha */
  .columna-derecha::-webkit-scrollbar {
    width: 6px;
  }

  .columna-derecha::-webkit-scrollbar-track {
    background: #f1f5f9;
    border-radius: 10px;
  }

  .columna-derecha::-webkit-scrollbar-thumb {
    background: #cbd5e1;
    border-radius: 10px;
  }

  .columna-derecha::-webkit-scrollbar-thumb:hover {
    background: #94a3b8;
  }

  /* --- Diseño Responsivo --- */
  @media (max-width: 1400px) {
    .grilla-contenido-principal {
      grid-template-columns: 1fr; /* Solo columna central */
    }
    .columna-izquierda, .columna-derecha {
      display: none; /* Ocultar columnas laterales */
    }
    .columna-central {
      padding: 0;
      width: 100%; /* Ocupa el 100% del ancho disponible */
      max-width: none; /* Sin límite de ancho máximo */
    }
  }

  @media (max-width: 992px) {
    .contenedor-comunidad {
      padding: 1rem;
    }
    .grilla-contenido-principal {
      grid-template-columns: 1fr; /* Una sola columna */
    }
    .columna-izquierda, .columna-derecha {
      display: none; /* Ocultar todas las columnas laterales */
    }
    .columna-central {
      width: 100%; /* Asegurar 100% de ancho */
    }
  }

  /* --- Banner Responsivo --- */
  @media (max-width: 768px) {
    .contenedor-comunidad {
      padding: 1rem;
    }
    .contenedor-banner {
      padding: 2rem 1.5rem;
      flex-direction: column;
      align-items: flex-start;
      gap: 1rem;
    }
    .titulo-banner {
      font-size: 2rem;
    }
    .subtitulo-banner {
      font-size: 1.1rem;
    }
    .visual-banner {
      display: none;
    }
  }

  @media (max-width: 480px) {
    .contenedor-banner {
      padding: 1.5rem 1rem;
      border-radius: 12px;
    }

    .titulo-banner {
      font-size: 1.7rem;
    }

    .subtitulo-banner {
      font-size: 1rem;
    }

    .caracteristicas-banner {
      gap: 0.8rem;
    }

    .elemento-caracteristica {
      padding: 0.5rem 0.7rem;
      border-radius: 20px;
    }

    .icono-caracteristica {
      font-size: 1rem;
    }

    .texto-caracteristica {
      font-size: 0.75rem;
    }

    .onda-musical {
      height: 50px;
    }

    .barra-onda {
      width: 5px;
    }
  }
</style>
