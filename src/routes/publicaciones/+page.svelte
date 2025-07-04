<script lang="ts">
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';
import { supabase } from '$lib/supabase/clienteSupabase';
import { usuario } from '$lib/UsuarioActivo/usuario';
import FeedPublicaciones from '$lib/components/Comunidad/FeedPublicaciones.svelte';
import RankingComunidad from '$lib/components/Banners/RankingComunidad.svelte';
import PorcentajePerfil from '$lib/components/Banners/PorcentajePerfil.svelte';
import BannerSlider from '$lib/components/Banners/BannerSlider.svelte';
import { onMount } from 'svelte';

  let publicaciones = [];
let cargando = true;

// Props simuladas para MiniCursosComunidad (ajusta si tienes datos reales)
let inscripciones = [];
let isLoading = false;
let error = null;

// Perfil del usuario para PorcentajePerfil
let perfil = {};

onMount(async () => {
  cargando = true;
  // Cargar publicaciones
  const { data: publicacionesData } = await supabase
    .from('comunidad_publicaciones')
    .select('*')
    .eq('usuario_id', $usuario.id)
    .order('fecha_creacion', { ascending: false });
  publicaciones = publicacionesData || [];

  // Cargar perfil del usuario
  const { data: perfilData } = await supabase
    .from('perfiles')
    .select('*')
    .eq('id', $usuario.id)
    .single();
  if (perfilData) {
    perfil = perfilData;
  }
  cargando = false;
});
</script>

<div class="contenedor-pagina">
    <div class="espacio-encabezado-perfil">
      <EncabezadoPerfil />
    </div>
    <div class="zona-pestañas">
      <PestanasPerfil />
    </div>
    <div class="contenido-pestaña">
      <div class="timeline-grid">
        <div class="columna-timeline columna-izquierda">
          <div class="bloque-ranking">
  <RankingComunidad />
</div>
          <MiniCursosComunidad />
        </div>
        <div class="columna-timeline columna-central">
          <!-- Timeline personal del usuario -->
          {#if cargando}
            <p>Cargando tus publicaciones...</p>
          {:else if publicaciones.length === 0}
            <p>No has publicado nada aún.</p>
          {:else}
            <div style="width: 100%;">
              {#each publicaciones as pub}
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
                  usuario={$usuario}
                />
              {/each}
            </div>
          {/if}
        </div>
        <div class="columna-timeline columna-derecha">
  <!-- Widget de sugerencias de amigos -->

  <!-- Porcentaje de perfil y banner slider -->
  <PorcentajePerfil {perfil} />
  <BannerSlider />
</div>
      </div>
    </div>
  </div>
  
  <style>
  .contenedor-pagina {
    max-width: 1500px;
    margin: 0 auto;
    padding: 0 0px;
    background-color: #ffffff;  
  }
  .espacio-encabezado-perfil {
    width: 100%;
    height: 100%;
    border-radius: 16px 16px;
    margin-bottom: 1rem;
    margin-top: 2rem;
  }
  .contenedor-pagina .contenido-pestaña {
    width: 1500px;
    height: 100%;
    margin: 0 auto;
    margin-top: 20px;
    display: flex;
    box-shadow: 0 4px 24px 0 rgba(0,0,0,0.04);
    padding: 28px 32px 18px 32px;
    position: relative;
    z-index: 1;
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
.columna-derecha > :global(.widget-progreso),
.columna-derecha > :global(.progreso-circular),
.columna-derecha > :global(.titulo-progreso) {
  margin-left: auto !important;
  margin-right: auto !important;
}
/* Elimina widgets viejos de la columna izquierda */
.widget-perfil,
.widget-estadisticas,
.widget-acceso {
  display: none !important;
}
/* Ajuste para que los componentes hijos no sobresalgan */
.columna-izquierda > :global(*) {
  margin-bottom: 0;
  border-radius: 12px;
  box-shadow: none;
  background: transparent;
}
.columna-central {
  flex: 5;
  min-width: 0;
  max-width: 100%;
}
  .mini-avatar {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  object-fit: cover;
  margin-right: 10px;
  border: 1.5px solid #e0e7ef;
}
/* Elimina estilos viejos de widgets que ya no existen en la columna izquierda */

.mini-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.mini-email {
  font-size: 0.98em;
  color: #888;
}
.mini-pais {
  font-size: 0.96em;
  color: #1877f2;
}
.widget-estadisticas ul, .widget-sugerencias ul, .widget-eventos ul {
  list-style: none;
  padding: 0;
  margin: 0;
}
.widget-estadisticas li, .widget-sugerencias li, .widget-eventos li {
  margin-bottom: 7px;
  display: flex;
  align-items: center;
  gap: 8px;
}
.widget-sugerencias button, .widget-acceso button {
  margin-left: auto;
  background: #1877f2;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 4px 12px;
  font-size: 0.98em;
  cursor: pointer;
  transition: background 0.15s;
}
.widget-sugerencias button:hover, .widget-acceso button:hover {
  background: #1558b0;
}
.widget-banner {
  margin: 18px 0 0 0;
  text-align: center;
}
.widget-banner p {
  font-size: 0.97em;
  color: #333;
  margin: 6px 0 0 0;
}
.widget-acceso {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
</style>