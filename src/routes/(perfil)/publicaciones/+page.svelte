<script lang="ts">
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import FeedPublicaciones from '$lib/components/Comunidad/FeedPublicaciones.svelte';
  import RankingComunidad from '$lib/components/Banners/RankingComunidad.svelte';
  import PorcentajePerfil from '$lib/components/Banners/PorcentajePerfil.svelte';
  import BannerSlider from '$lib/components/Banners/BannerSlider.svelte';
  import SliderCursos from '$lib/components/Banners/SliderCursos.svelte';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { onMount } from 'svelte';

  let publicaciones: any[] = [];
  let cargando = true;

  // Usar datos del store para el perfil
  $: perfil = $perfilStore.perfil;

  async function cargarPublicaciones() {
    if (!$usuario?.id) return;

    try {
      const { data, error } = await supabase
        .from('comunidad_publicaciones')
        .select(`
          *,
          perfiles!inner(nombre_usuario, nombre_completo, url_foto_perfil)
        `)
        .eq('usuario_id', $usuario.id)
        .order('fecha_creacion', { ascending: false });

      if (error) throw error;
      
      // Mapear los datos agregando el slug y avatar
      publicaciones = (data || []).map((pub: any) => ({
        ...pub,
        usuario_slug: pub.perfiles?.nombre_usuario || '',
        usuario_nombre: pub.perfiles?.nombre_completo || pub.usuario_nombre || 'Usuario',
        usuario_avatar: pub.perfiles?.url_foto_perfil || pub.usuario_avatar || ''
      }));
    } catch (error) {
      console.error('Error cargando publicaciones:', error);
    } finally {
      cargando = false;
    }
  }



  onMount(() => {
    cargarPublicaciones();
  });
</script>

<svelte:head>
  <title>Mis Publicaciones - Academia Vallenata</title>
  <meta name="description" content="Revisa todas tus publicaciones en la comunidad" />
</svelte:head>

<div class="contenido-publicaciones">
  <div class="timeline-grid">
    <div class="columna-timeline columna-izquierda">
      <div class="bloque-ranking">
        <RankingComunidad />
      </div>
      <SliderCursos />
    </div>
    
    <div class="columna-timeline columna-central">
      <div class="header-seccion">
        <h1>Mis Publicaciones</h1>
        <p>Todas tus contribuciones a la comunidad</p>
      </div>
      
      <!-- Timeline personal del usuario -->
      {#if cargando}
        <div class="estado-carga">
          <div class="spinner"></div>
          <p>Cargando tus publicaciones...</p>
        </div>
      {:else if publicaciones.length === 0}
        <div class="estado-vacio">
          <div class="icono-vacio">📝</div>
          <h3>No has publicado nada aún</h3>
          <p>¡Comparte algo con la comunidad para empezar!</p>
          <a href="/comunidad" class="boton-accion">Ir a Comunidad</a>
        </div>
      {:else}
        <div class="feed-publicaciones">
          {#each publicaciones as pub}
            <FeedPublicaciones
              id={pub.id}
              usuario_id={pub.usuario_id}
              usuario_nombre={pub.usuario_nombre}
              url_foto_perfil={pub.usuario_avatar}
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
              usuario={$usuario}
            />
          {/each}
        </div>
      {/if}
    </div>
    
    <div class="columna-timeline columna-derecha">
      <!-- Porcentaje de perfil y banner slider -->
      <PorcentajePerfil {perfil} />
      <BannerSlider />
    </div>
  </div>
</div>

<style>
  .contenido-publicaciones {
    padding: 2rem;
  }

  .header-seccion {
    margin-bottom: 2rem;
    text-align: center;
  }

  .header-seccion h1 {
    font-size: 2rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }

  .header-seccion p {
    color: #6b7280;
    font-size: 1.1rem;
  }

  .timeline-grid {
    display: flex;
    width: 100%;
    gap: 24px;
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
    padding: 0 1rem;
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

  .boton-accion {
    display: inline-block;
    background: #3b82f6;
    color: white;
    padding: 12px 24px;
    border-radius: 8px;
    text-decoration: none;
    font-weight: 600;
    transition: background-color 0.2s ease;
  }

  .boton-accion:hover {
    background: #2563eb;
  }

  /* 📱 RESPONSIVE DESIGN - OCULTAR COLUMNAS LATERALES EN 1300PX */
  @media (max-width: 1350px) {
    .columna-izquierda,
    .columna-derecha {
      display: none;
    }
    
    .timeline-grid {
      justify-content: center;
    }
    
    .columna-central {
      flex: 1;
      max-width: 800px;
      margin: 0 auto;
      padding: 0 2rem;
    }
  }

  @media (max-width: 768px) {
    
    .columna-central {
      padding: 0 1rem;
    }
    
    .header-seccion h1 {
      font-size: 1.75rem;
    }
    
    .header-seccion p {
      font-size: 1rem;
    }
  }

  @media (max-width: 640px) {
    .contenido-publicaciones {
      padding: 0.5rem;
    }
    
    .columna-central {
      padding: 0 0.5rem;
    }
    
    .header-seccion {
      margin-bottom: 1.5rem;
    }
    
    .header-seccion h1 {
      font-size: 1.5rem;
    }
    
    .estado-vacio,
    .estado-carga {
      padding: 2rem 1rem;
    }
  }
</style> 