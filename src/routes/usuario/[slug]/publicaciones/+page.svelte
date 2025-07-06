<script lang="ts">
  import FeedPublicaciones from '$lib/components/Comunidad/FeedPublicaciones.svelte';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';

  export let data;
  
  // Extraer datos del servidor
  $: perfil = data.perfil;
  $: slug = data.slug;
  
  let publicaciones: any[] = [];
  let cargando = true;
  let error = '';

  async function cargarPublicaciones() {
    try {
      cargando = true;
      error = '';
      
      const { data: publicacionesData, error: errorPublicaciones } = await supabase
        .from('comunidad_publicaciones')
        .select(`
          *,
          perfiles:usuario_id (
            nombre,
            apellido,
            url_avatar,
            nombre_usuario
          )
        `)
        .eq('usuario_id', perfil.id)
        .order('fecha_creacion', { ascending: false });
        
      if (errorPublicaciones) {
        error = 'Error al cargar las publicaciones';
        console.error('Error:', errorPublicaciones);
        return;
      }
      
      publicaciones = publicacionesData || [];
    } catch (err) {
      error = 'Error inesperado al cargar las publicaciones';
      console.error('Error:', err);
    } finally {
      cargando = false;
    }
  }

  onMount(() => {
    cargarPublicaciones();
  });
</script>

<svelte:head>
  <title>Publicaciones de {perfil.nombre} {perfil.apellido} - Academia Vallenata Online</title>
  <meta name="description" content="Descubre las publicaciones de {perfil.nombre} {perfil.apellido} en nuestra comunidad de acordeón vallenato" />
</svelte:head>

<div class="contenedor-publicaciones">
  <div class="encabezado-seccion">
    <h1 class="titulo-seccion">
      <span class="icono-publicaciones">📝</span>
      Publicaciones de {perfil.nombre}
    </h1>
    <p class="descripcion-seccion">
      Todas las publicaciones compartidas por {perfil.nombre} {perfil.apellido} en la comunidad
    </p>
  </div>

  <div class="feed-container">
    {#if cargando}
      <div class="estado-carga">
        <div class="spinner"></div>
        <p>Cargando publicaciones...</p>
      </div>
    {:else if error}
      <div class="estado-error">
        <span class="icono-error">⚠️</span>
        <p>{error}</p>
        <button class="boton-reintentar" on:click={cargarPublicaciones}>
          Intentar de nuevo
        </button>
      </div>
    {:else if publicaciones.length === 0}
      <div class="estado-vacio">
        <span class="icono-vacio">📭</span>
        <h3>Sin publicaciones</h3>
        <p>{perfil.nombre} aún no ha compartido ninguna publicación en la comunidad</p>
      </div>
    {:else}
      <div class="lista-publicaciones">
        {#each publicaciones as publicacion (publicacion.id)}
          {@const nombreCompleto = `${publicacion.perfiles?.nombre || ''} ${publicacion.perfiles?.apellido || ''}`.trim()}
          <FeedPublicaciones
            id={publicacion.id}
            usuario_id={publicacion.usuario_id}
            usuario_nombre={nombreCompleto}
            usuario_slug={publicacion.perfiles?.nombre_usuario || ''}
            usuario_avatar={publicacion.perfiles?.url_avatar || ''}
            fecha={new Date(publicacion.fecha_creacion).toLocaleDateString('es-ES', {
              day: 'numeric',
              month: 'long',
              hour: '2-digit',
              minute: '2-digit'
            })}
            contenido={publicacion.contenido || ''}
            url_imagen={publicacion.url_imagen || ''}
            url_video={publicacion.url_video || ''}
            url_gif={publicacion.url_gif || ''}
            tipo={publicacion.tipo || 'texto'}
            encuesta={publicacion.encuesta}
            me_gusta={[]}
            total_comentarios={0}
            total_compartidos={0}
            usuario={null}
          />
        {/each}
      </div>
    {/if}
  </div>
</div>

<style>
  .contenedor-publicaciones {
    max-width: 800px;
    margin: 0 auto;
    padding: 2rem 1rem;
  }

  .encabezado-seccion {
    text-align: center;
    margin-bottom: 2rem;
    padding: 2rem;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    border-radius: 20px;
    border: 1px solid rgba(148, 163, 184, 0.1);
  }

  .titulo-seccion {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.75rem;
    font-size: 2rem;
    font-weight: 700;
    color: #1e293b;
    margin: 0 0 0.5rem 0;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .icono-publicaciones {
    font-size: 2.25rem;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));
  }

  .descripcion-seccion {
    font-size: 1.1rem;
    color: #64748b;
    margin: 0;
    max-width: 500px;
    margin: 0 auto;
  }

  .feed-container {
    min-height: 400px;
  }

  .lista-publicaciones {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  /* Estados de carga, error y vacío */
  .estado-carga,
  .estado-error,
  .estado-vacio {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 3rem 1.5rem;
    text-align: center;
    background: white;
    border-radius: 20px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
    border: 1px solid rgba(148, 163, 184, 0.1);
  }

  .spinner {
    width: 48px;
    height: 48px;
    border: 4px solid #e2e8f0;
    border-top: 4px solid #667eea;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .estado-carga p,
  .estado-error p,
  .estado-vacio p {
    color: #64748b;
    font-size: 1.1rem;
    margin: 0.5rem 0;
  }

  .estado-vacio h3 {
    color: #374151;
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0.5rem 0;
  }

  .icono-error,
  .icono-vacio {
    font-size: 3rem;
    margin-bottom: 0.5rem;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));
  }

  .boton-reintentar {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    margin-top: 1rem;
  }

  .boton-reintentar:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(102, 126, 234, 0.3);
  }

  /* Responsive */
  @media (max-width: 768px) {
    .contenedor-publicaciones {
      padding: 1rem 0.5rem;
    }
    
    .titulo-seccion {
      font-size: 1.5rem;
    }
    
    .encabezado-seccion {
      padding: 1.5rem 1rem;
    }
  }
</style> 