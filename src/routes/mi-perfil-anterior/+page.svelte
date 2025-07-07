<script lang="ts">
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
  import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';
  import InfoPestañaPerfil from '$lib/components/PanelPrincipal/InfoPestañaPerfil.svelte';
  import PorcentajePerfil from '$lib/components/Banners/PorcentajePerfil.svelte';
  import UltimosArticulosBlog from '$lib/components/Banners/UltimosArticulosBlog.svelte';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';

  let perfilData: any = {};
  let statsData = { publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 };
  let cargandoPerfil = true;

  async function cargarEstadisticasComunidad(userId: string) {
    try {
      const { count: conteoPublicaciones } = await supabase.from('comunidad_publicaciones').select('*', { count: 'exact', head: true }).eq('usuario_id', userId);
      const { count: conteoCursos } = await supabase.from('inscripciones').select('*', { count: 'exact', head: true }).eq('usuario_id', userId);
      const { count: conteoTutoriales } = await supabase.from('progreso_tutorial').select('*', { count: 'exact', head: true }).eq('usuario_id', userId).eq('completado', true);
      const { data: rankingData } = await supabase.from('perfiles').select('id').order('puntos_comunidad', { ascending: false });
      const posicionRanking = rankingData ? rankingData.findIndex((p: any) => p.id === userId) + 1 : 0;
      return {
        publicaciones: conteoPublicaciones || 0,
        cursos: conteoCursos || 0,
        tutoriales: conteoTutoriales || 0,
        ranking: posicionRanking || 0
      };
    } catch (error) {
      console.error('Error cargando estadísticas:', error);
      return { publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 };
    }
  }

  onMount(async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const [perfilResult, statsResult] = await Promise.all([
        supabase.from('perfiles').select('*').eq('id', user.id).single(),
        cargarEstadisticasComunidad(user.id)
      ]);
      
      perfilData = perfilResult.data || { nombre_completo: user.email, id: user.id };
      statsData = statsResult;
    }
    cargandoPerfil = false;
  });

  async function handleUpdate(event: any) {
    const perfilActualizado = event.detail;
    
    if (perfilActualizado.nivel_habilidad) {
      perfilActualizado.nivel_habilidad = perfilActualizado.nivel_habilidad.toLowerCase();
    }
    
    perfilData = { ...perfilData, ...perfilActualizado };

    const { id, ...datosParaActualizar } = perfilData;

    const { error } = await supabase
      .from('perfiles')
      .update(datosParaActualizar)
      .eq('id', id);
      
    if (error) {
      console.error('Error actualizando perfil:', error.message);
      alert(`Hubo un error al actualizar tu perfil: ${error.message}`);
    } else {
      console.log('¡Perfil actualizado correctamente!');
    }
  }
</script>

<div class="contenedor-perfil">
  <EncabezadoPerfil 
    bind:nombreCompleto={perfilData.nombre_completo} 
    bind:correoElectronico={perfilData.correo_electronico} 
    bind:urlAvatar={perfilData.url_foto_perfil} 
    bind:urlPortada={perfilData.portada_url} 
    bind:posicionPortadaY={perfilData.posicion_img_portada}
    userId={perfilData.id}
    stats={statsData}
  />
  
  <PestanasPerfil />
  
  <div class="contenido-principal-perfil">
    {#if cargandoPerfil}
      <div class="estado-carga">
        <div class="spinner-carga"></div>
        <p>Cargando información del perfil...</p>
      </div>
    {:else}
      <div class="layout-info-perfil">
        <div class="columna-formulario-principal">
          <InfoPestañaPerfil bind:perfil={perfilData} on:actualizar={handleUpdate} />
        </div>
        <aside class="columna-widget-lateral">
          <div class="widgets-contenedor">
            <PorcentajePerfil perfil={perfilData} />
            <UltimosArticulosBlog />
          </div>
        </aside>
      </div>
    {/if}
  </div>
</div>

<style>
  .contenedor-perfil {
    max-width: 1500px;
    margin: 2rem auto;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .contenido-principal-perfil {
    background: #fff;
    border-radius: 16px;
    box-shadow: 0 4px 24px 0 rgba(0,0,0,0.04);
  }

  .estado-carga {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 2rem;
    gap: 1.5rem;
  }

  .spinner-carga {
    width: 50px;
    height: 50px;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .estado-carga p {
    color: #64748b;
    font-weight: 500;
  }

  .layout-info-perfil {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 2.5rem;
    align-items: start;
  }

  .columna-formulario-principal {
    min-width: 0;
  }

  .columna-widget-lateral {
    position: sticky;
    top: 2rem;
  }

  .widgets-contenedor {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }
  
  @media (max-width: 900px) {
    .contenido-principal-perfil {
      padding: 1.5rem;
    }

    .layout-info-perfil {
      grid-template-columns: 1fr;
      gap: 2rem;
    }

    .columna-widget-lateral {
      order: 1;
      position: static;
    }

    .columna-formulario-principal {
      order: 0;
    }
  }

  @media (max-width: 640px) {
    .contenedor-perfil {
      margin: 1rem auto;
      padding: 0;
    }
    
    .contenido-principal-perfil {
      padding: 1rem;
      border-radius: 12px;
    }

  }
</style>
