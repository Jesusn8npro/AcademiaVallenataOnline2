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
  import { obtenerSlugUsuario } from '$lib/utilidades/utilidadesSlug';

  // Estado del usuario
  let perfil: any = {};
  let usuario: any = null;

  // Feed de publicaciones - VOLVEMOS A LA LÓGICA ORIGINAL PERO LIMPIA
  let publicaciones: any[] = [];
  let cargandoPublicaciones = false;
  let errorPublicaciones = '';
  let pagina = 0;
  const LIMITE = 4;
  let fin = false;
  let centinela: HTMLElement;
  let observador: IntersectionObserver;

  // Cargar publicaciones con paginación - LÓGICA ORIGINAL LIMPIA
  async function cargarMasPublicaciones() {
    if (cargandoPublicaciones || fin) return;
    
    cargandoPublicaciones = true;
    errorPublicaciones = '';
    const desde = pagina * LIMITE;
    const hasta = desde + LIMITE - 1;
    
    try {
      // Cargar publicaciones CON JOIN para obtener más datos del perfil
      const { data, error } = await supabase
        .from('comunidad_publicaciones')
        .select(`
          *,
          perfiles(nombre_usuario, nombre, apellido, nombre_completo, url_foto_perfil)
        `)
        .not('tipo', 'in', '("foto_perfil","foto_portada")') // 🚫 Excluir publicaciones automáticas
        .order('fecha_creacion', { ascending: false })
        .range(desde, hasta);
        
      if (error) {
        errorPublicaciones = 'Error al cargar publicaciones: ' + error.message;
        return;
      }

      if (!data || data.length < LIMITE) fin = true;
      
      // Para cada publicación, cargar sus likes
      const publicacionesConLikes = await Promise.all((data || []).map(async (pub: any) => {
        // Cargar IDs de usuarios que dieron like
        const { data: likesData, error: likesError } = await supabase
          .from('comunidad_publicaciones_likes')
          .select('usuario_id')
          .eq('publicacion_id', pub.id);
          
        const likesUsuarios = likesError ? [] : (likesData || []).map((like: any) => like.usuario_id);
        
        // Obtener slug usando función unificada
        const datosUsuario = {
          nombre_usuario: pub.perfiles?.nombre_usuario,
          nombre: pub.perfiles?.nombre || pub.usuario_nombre,
          apellido: pub.perfiles?.apellido,
          nombre_completo: pub.perfiles?.nombre_completo,
          usuario_nombre: pub.usuario_nombre
        };
        
        const usuarioSlug = obtenerSlugUsuario(datosUsuario);
        
        console.log(`✅ Usuario: ${pub.usuario_nombre}, Slug generado: ${usuarioSlug}`);
        
        // Log para debugging
        if (likesUsuarios.length > 0) {
          console.log(`📊 Publicación ${pub.id}: ${likesUsuarios.length} likes cargados`);
        }
        
        return {
          ...pub,
          usuario_id: pub.usuario_id,
          usuario_nombre: pub.usuario_nombre || 'Usuario',
          url_foto_perfil: pub.perfiles?.url_foto_perfil || '',
          usuario_slug: usuarioSlug,
          contenido: pub.descripcion || '',
          fecha: pub.fecha_creacion ? new Date(pub.fecha_creacion).toLocaleString() : '',
          url_imagen: pub.url_imagen || '',
          url_video: pub.url_video || '',
          url_gif: pub.url_gif || '',
          tipo: pub.tipo || 'texto',
          encuesta: pub.encuesta || null,
          me_gusta: likesUsuarios,
          total_comentarios: pub.total_comentarios || 0,
          total_compartidos: pub.total_compartidos || 0
        };
      }));
      
      publicaciones = [...publicaciones, ...publicacionesConLikes];
      pagina += 1;
      
    } catch (error) {
      console.error('Error cargando publicaciones:', error);
      errorPublicaciones = 'Error al cargar publicaciones';
    } finally {
      cargandoPublicaciones = false;
    }
  }

  // Intersection Observer para scroll infinito
  function manejarInterseccion(entradas: IntersectionObserverEntry[]) {
    if (entradas[0].isIntersecting) {
      cargarMasPublicaciones();
    }
  }

  // Función para hacer scroll a una publicación específica
  function scrollAPublicacion(publicacionId: string) {
    const elemento = document.getElementById(`publicacion-${publicacionId}`);
    if (elemento) {
      elemento.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'center' 
      });
      // Resaltar la publicación brevemente
      elemento.style.border = '3px solid #3b82f6';
      elemento.style.borderRadius = '12px';
      setTimeout(() => {
        elemento.style.border = '';
        elemento.style.borderRadius = '';
      }, 3000);
    } else {
      // Si no se encuentra, intentar cargar más publicaciones
      console.log('🔍 Publicación no encontrada, cargando más...');
      if (!fin && !cargandoPublicaciones) {
        cargarMasPublicaciones().then(() => {
          setTimeout(() => scrollAPublicacion(publicacionId), 500);
        });
      }
    }
  }

  // Manejar nueva publicación
  const manejarPublicar = async () => {
    // Recargar el feed desde el principio
    publicaciones = [];
    pagina = 0;
    fin = false;
    await cargarMasPublicaciones();
  };

  onMount(async () => {
    // Cargar datos del usuario
    const sesion = await obtenerSesion();
    if (!sesion?.user) return;
    const resultado = await obtenerPerfil(sesion.user.id);
    if (!resultado?.perfil) return;
    perfil = resultado.perfil;

    // Usuario para publicaciones
    usuario = {
      id: sesion.user.id,
      nombre: perfil.nombre || perfil.nombre_usuario || 'Usuario'
    };

    // Cargar primeras publicaciones
    await cargarMasPublicaciones();

    // Observer para scroll infinito
    observador = new IntersectionObserver(manejarInterseccion);
    if (centinela) observador.observe(centinela);

    // Manejar hash de URL para ir a publicación específica
    if (typeof window !== 'undefined' && window.location.hash) {
      const hash = window.location.hash;
      const match = hash.match(/#publicacion-(.+)/);
      if (match) {
        const publicacionId = match[1];
        // Esperar un poco para que se carguen las publicaciones
        setTimeout(() => {
          scrollAPublicacion(publicacionId);
        }, 1000);
      }
    }
  });

  afterUpdate(() => {
    if (observador && centinela && !fin) {
      observador.disconnect();
      observador.observe(centinela);
    }
  });
</script>

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

<!-- Contenido Principal con misma estructura que Publicaciones -->
<div class="contenido-comunidad">
  <div class="timeline-grid">
    <!-- Columna Izquierda -->
    <div class="columna-timeline columna-izquierda">
      <div class="bloque-ranking">
        <PorcentajePerfil {perfil} />
      </div>
      <UltimosArticulosBlog />
    </div>

    <!-- Columna Central -->
    <div class="columna-timeline columna-central">
      <div class="contenedor-publicar">
        <ComunidadPublicar {usuario} on:publicar={manejarPublicar} />
      </div>
      
      <!-- Feed de Publicaciones -->
      <div class="feed-publicaciones">
        {#if publicaciones.length === 0 && !cargandoPublicaciones}
          <div class="estado-vacio">
            <div class="icono-vacio">🎵</div>
            <h3>No hay publicaciones aún</h3>
            <p>¡Sé el primero en compartir algo con la comunidad!</p>
          </div>
        {/if}
        {#each publicaciones as pub (pub.id)}
          <FeedPublicaciones
            id={pub.id}
            usuario_id={pub.usuario_id}
            usuario_nombre={pub.usuario_nombre}
            url_foto_perfil={pub.url_foto_perfil}
            usuario_slug={pub.usuario_slug}
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
          <div class="estado-carga">
            <div class="spinner"></div>
            <p>Cargando más publicaciones...</p>
          </div>
        {/if}

        {#if !fin && !cargandoPublicaciones && publicaciones.length > 0}
          <div bind:this={centinela} style="height: 1px;"></div>
        {/if}

        {#if fin && publicaciones.length > 0}
          <div class="estado-carga">
            <p>Fin de las publicaciones</p>
          </div>
        {/if}

        {#if !cargandoPublicaciones && publicaciones.length === 0}
          <div class="estado-vacio">
            <div class="icono-vacio">📝</div>
            <h3>Sé el primero en publicar</h3>
            <p>¡Comparte algo increíble con la comunidad!</p>
          </div>
        {/if}
      </div>
    </div>

    <!-- Columna Derecha -->
    <div class="columna-timeline columna-derecha">
      <RankingComunidad />
      <SliderCursos />
    </div>
  </div>
</div>

<style>
  /* --- BANNER SUPERIOR --- */
  .contenedor-banner {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 2.5rem 2rem;
    border-radius: 16px;
    margin: 2rem;
    margin-bottom: 0;
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

  /* --- LAYOUT PRINCIPAL (IGUAL QUE PUBLICACIONES) --- */
  .contenido-comunidad {
    padding: 0;
  }

  .timeline-grid {
    display: flex;
    width: 100%;
    gap: 24px;
    padding: 2rem;
  }

  .columna-timeline {
    background: #fff;
    border-radius: 12px;
    min-height: 300px;
    box-shadow: 0 4px 24px 0 rgba(0,0,0,0.04);
    padding: 18px 10px;
  }

  .columna-izquierda {
    flex: 1.5;
    max-width: 350px;
    background: #fff;
    box-shadow: 0 2px 8px rgba(0,0,0,0.05);
    border-radius: 12px;
    border: 1.5px solid #f3f3f3;
    padding: 14px 10px 18px 10px;
    display: flex;
    flex-direction: column;
    gap: 18px;
    align-items: stretch;
  }

  .bloque-ranking {
    background: none !important;
    box-shadow: none !important;
    border: none !important;
    padding: 0 !important;
    margin-bottom: 18px;
  }

  .bloque-ranking > :global(.ranking-gamer) {
    margin-bottom: 0;
    border-radius: 22px;
    box-shadow: 0 6px 24px 0 rgba(0,0,0,0.45);
    background: linear-gradient(135deg, #1a1a2e 60%, #16213e 100%);
  }

  .columna-derecha {
    flex: 1.5;
    min-width: 220px;
    max-width: 350px;
    background: #fff;
    box-shadow: 0 2px 8px rgba(0,0,0,0.05);
    border-radius: 12px;
    border: 1.5px solid #f3f3f3;
    padding: 18px 14px;
    display: flex;
    flex-direction: column;
    gap: 24px;
    align-items: center;
    justify-content: flex-start;
  }

  .columna-central {
    flex: 5;
    padding: 0;
  }

  .contenedor-publicar {
    background-color: #ffffff;
    border-radius: 12px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    overflow: hidden;
    margin-bottom: 1rem;
  }

  .feed-publicaciones {
    width: 100%;
  }

  .estado-carga {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 3rem 1rem;
    gap: 1rem;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .estado-vacio {
    text-align: center;
    padding: 4rem 2rem;
  }

  .icono-vacio {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .estado-vacio h3 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }

  .estado-vacio p {
    color: #6b7280;
    margin-bottom: 2rem;
  }

  /* --- RESPONSIVE (IGUAL QUE PUBLICACIONES) --- */
  @media (max-width: 1350px) {
    .columna-izquierda,
    .columna-derecha {
      display: none;
    }
    
    .timeline-grid {
      justify-content: center;
      padding: 2rem;
    }
    
    .columna-central {
      flex: 1;
      max-width: 800px;
      margin: 0 auto;
      padding: 0;
    }
  }

  @media (max-width: 768px) {
    .timeline-grid {
      padding: 1rem;
    }
    
    .columna-central {
      padding: 0;
    }
  }

  @media (max-width: 640px) {
    .timeline-grid {
      padding: 0.5rem;
    }
    
    .columna-central {
      padding: 0;
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
