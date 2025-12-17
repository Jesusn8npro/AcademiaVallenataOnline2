<script lang="ts">
  import FeedPublicaciones from '$lib/components/Comunidad/FeedPublicaciones.svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  
  export let data: any;
  
  $: usuarioPublico = data?.usuarioPublico;
  
  // Estados de carga
  let publicaciones: any[] = [];
  let cargando = true;
  let error = '';
  
  // Función para cargar publicaciones del usuario
  async function cargarPublicaciones() {
    
    try {
      cargando = true;
      error = '';
      
      // Cargar publicaciones reales del usuario desde Supabase
      const { data, error: errorSupabase } = await supabase
        .from('comunidad_publicaciones')
        .select(`
          *,
          perfiles(nombre_usuario, nombre, apellido, url_foto_perfil)
        `)
        .eq('usuario_id', usuarioPublico.id)
        .not('tipo', 'in', '("foto_perfil","foto_portada")')
        .order('fecha_creacion', { ascending: false })
        .limit(20);
      
      if (errorSupabase) {
        console.error('Error cargando publicaciones:', errorSupabase);
        error = 'Error al cargar las publicaciones';
        return;
      }
      
      publicaciones = data || [];
      
    } catch (err: any) {
      console.error('Error cargando publicaciones del usuario:', err);
      error = 'Error al cargar las publicaciones. Inténtalo de nuevo.';
    } finally {
      cargando = false;
    }
  }
  
  // Cargar publicaciones cuando el componente se monte o cambien los datos
  $: if (usuarioPublico?.id) {
    cargarPublicaciones();
  }
</script>

<svelte:head>
  {#if usuarioPublico}
    <title>Publicaciones de {usuarioPublico.nombre_completo || usuarioPublico.nombre || 'Usuario'} - Academia Vallenata</title>
    <meta name="description" content="Publicaciones y contenido compartido por {usuarioPublico.nombre_completo || usuarioPublico.nombre || 'Usuario'} en Academia Vallenata" />
  {/if}
</svelte:head>

<div class="publicaciones-contenido">
  
  {#if cargando}
    <!-- 🔄 Estado de carga -->
    <div class="estado-carga">
      <div class="spinner"></div>
      <h3>Cargando publicaciones...</h3>
      <p>Obteniendo el contenido compartido por {usuarioPublico?.nombre_completo || usuarioPublico?.nombre || 'este usuario'}</p>
    </div>
    
  {:else if error}
    <!-- ❌ Estado de error -->
    <div class="estado-error">
      <div class="error-icono">⚠️</div>
      <h3>Error al cargar publicaciones</h3>
      <p>{error}</p>
      <button on:click={cargarPublicaciones} class="btn-reintentar">
        🔄 Reintentar
      </button>
    </div>
    
  {:else if publicaciones.length === 0}
    <!-- 📭 Estado vacío -->
    <div class="estado-vacio">
      <div class="vacio-icono">📝</div>
      <h3>Sin publicaciones aún</h3>
      <p>
        {usuarioPublico?.nombre_completo || usuarioPublico?.nombre || 'Este usuario'} no ha compartido publicaciones todavía.
      </p>
      <div class="vacio-acciones">
        <a href="/comunidad" class="btn-comunidad">
          🌍 Explorar la Comunidad
        </a>
      </div>
      <div class="vacio-decoracion">
        <span>🎵</span>
        <span>📚</span>
        <span>🎶</span>
      </div>
    </div>
    
  {:else}
    <!-- 📝 Publicaciones del usuario -->
    <div class="seccion">
      <div class="seccion-header">
        <h2>
          📝 Publicaciones de {usuarioPublico?.nombre_completo || usuarioPublico?.nombre || 'Usuario'}
        </h2>
        <div class="estadisticas-publicaciones">
          <span class="contador-publicaciones">
            {publicaciones.length} publicación{publicaciones.length !== 1 ? 'es' : ''}
          </span>
        </div>
      </div>
      
             <div class="feed-container">
         {#each publicaciones as publicacion}
           <!-- TODO: Integrar FeedPublicaciones cuando esté implementado -->
           <div class="publicacion-placeholder">
             <p>Publicación: {publicacion.titulo || publicacion.contenido}</p>
           </div>
         {/each}
       </div>
    </div>
  {/if}
  
</div>

<style>
  .publicaciones-contenido {
    padding: 2rem;
    max-width: 800px;
    margin: 0 auto;
    min-height: 60vh;
  }

  .seccion {
    background: #ffffff;
    border-radius: 16px;
    padding: 1.5rem;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
    border: 1px solid #f1f5f9;
  }

  .seccion-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
    gap: 1rem;
  }

  .seccion-header h2 {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 700;
    color: #1f2937;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .estadisticas-publicaciones {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .contador-publicaciones {
    font-size: 0.875rem;
    color: #6b7280;
    font-weight: 600;
    background: #f8fafc;
    padding: 0.5rem 1rem;
    border-radius: 20px;
    border: 1px solid #e2e8f0;
  }

  .feed-container {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  /* Estados */
  .estado-carga,
  .estado-error,
  .estado-vacio {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    padding: 4rem 2rem;
    min-height: 50vh;
    gap: 1rem;
  }

  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .error-icono,
  .vacio-icono {
    font-size: 4rem;
    margin-bottom: 1rem;
    opacity: 0.6;
  }

  .estado-carga h3,
  .estado-error h3,
  .estado-vacio h3 {
    font-size: 1.5rem;
    color: #1f2937;
    margin: 0 0 0.5rem 0;
    font-weight: 700;
  }

  .estado-carga p,
  .estado-error p,
  .estado-vacio p {
    color: #6b7280;
    font-size: 1rem;
    line-height: 1.6;
    max-width: 400px;
    margin: 0 0 1.5rem 0;
  }

  .btn-reintentar,
  .btn-comunidad {
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    color: white;
    padding: 12px 24px;
    border-radius: 12px;
    text-decoration: none;
    font-weight: 600;
    font-size: 1rem;
    border: none;
    cursor: pointer;
    transition: all 0.2s ease;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
  }

  .btn-reintentar:hover,
  .btn-comunidad:hover {
    background: linear-gradient(135deg, #2563eb, #1e40af);
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(59, 130, 246, 0.4);
  }

  .vacio-acciones {
    margin: 1rem 0 2rem 0;
  }

  .vacio-decoracion {
    display: flex;
    justify-content: center;
    gap: 1.5rem;
    font-size: 2rem;
    opacity: 0.3;
    margin-top: 1rem;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .publicaciones-contenido {
      padding: 1rem;
    }

    .seccion {
      padding: 1rem;
    }

    .seccion-header {
      flex-direction: column;
      align-items: flex-start;
      gap: 1rem;
    }

    .seccion-header h2 {
      font-size: 1.25rem;
    }

    .estado-carga,
    .estado-error,
    .estado-vacio {
      padding: 3rem 1rem;
    }

    .estado-carga h3,
    .estado-error h3,
    .estado-vacio h3 {
      font-size: 1.25rem;
    }

    .error-icono,
    .vacio-icono {
      font-size: 3rem;
    }
  }

  @media (max-width: 480px) {
    .publicaciones-contenido {
      padding: 0.5rem;
    }

    .seccion {
      padding: 0.75rem;
    }

    .btn-reintentar,
    .btn-comunidad {
      padding: 10px 20px;
      font-size: 0.9rem;
    }

    .vacio-decoracion {
      gap: 1rem;
      font-size: 1.5rem;
    }
  }
</style> 