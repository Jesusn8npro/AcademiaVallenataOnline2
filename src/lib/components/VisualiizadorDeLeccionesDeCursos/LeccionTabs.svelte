<script lang="ts">
  import ComentariosLeccion from '$lib/components/VisualiizadorDeLeccionesDeCursos/ComentariosLeccion.svelte';
  import NotasLeccion from '$lib/components/VisualiizadorDeLeccionesDeCursos/NotasLeccion.svelte';
  import TabContenido from '$lib/components/VisualiizadorDeLeccionesDeCursos/TabContenido.svelte';
  import TarjetaInformacionCurso from '$lib/components/VisualiizadorDeLeccionesDeCursos/TarjetaInformacionCurso.svelte';
  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
  export let contenido: string = '';
  export let recursos: string = '';
  export let comentarios: any[] = [];
  export let cursoId: string = '';
  export let usuarioActual: any = null; // { id, rol, nombre, avatar_url }
  export let leccionId: string = '';
  export let tipo: 'leccion' | 'clase' = 'leccion'; // Nuevo prop para distinguir tipo
  export let curso: any = {}; // Objeto completo del curso/tutorial desde Supabase
  export let clases: any[] = [];
  export let progreso: Record<string, any> = {};
  export let mostrarSidebar: boolean = true;

  let activeTab = 0;
  $: tabLabels = mostrarSidebar
    ? ['Información', 'Comentarios', 'Notas']
    : ['Contenido', 'Información', 'Comentarios', 'Notas']; // Contenido primero si sidebar oculta

  // Mantener la pestaña activa en localStorage si es "Contenido"
  import { onMount } from 'svelte';
  const TAB_KEY = 'leccionTabs-activeTab';

  onMount(() => {
    if (!mostrarSidebar) {
      // Si la sidebar está oculta, mostrar Contenido por defecto
      const savedTab = localStorage.getItem(TAB_KEY);
      if (savedTab !== null) {
        activeTab = +savedTab;
      } else {
        activeTab = 0; // Contenido ahora es la primera pestaña
        localStorage.setItem(TAB_KEY, '0');
      }
    } else {
      activeTab = 0;
      localStorage.removeItem(TAB_KEY);
    }
  });

  $: if (!mostrarSidebar && activeTab === 0) {
    localStorage.setItem(TAB_KEY, '0');
  }

  function setActiveTab(i: number) {
    activeTab = i;
    if (!mostrarSidebar && i === 1) {
      localStorage.setItem(TAB_KEY, '1');
    } else {
      localStorage.removeItem(TAB_KEY);
    }
  }


</script>

<div class="leccion-contenido">

  <div class="tabs">
    <div class="tab-headers">
      {#each tabLabels as label, i}
        <button
          class="tab-btn {activeTab === i ? 'active' : ''}"
          on:click={() => setActiveTab(i)}
        >{label}</button>
      {/each}
    </div>
    <div class="tab-content">
      {#if !mostrarSidebar}
        {#if activeTab === 0}
          <div class="tab-panel active">
            <TabContenido
              clases={clases}
              leccionActiva={leccionId}
              progreso={progreso}
              curso={curso}
              modoSPA={true}
              on:cambiar-leccion={(e) => {
                // Emitir evento hacia el padre para navegar
                const leccion = e.detail.leccion;
                if (leccion) {
                  const customEvent = new CustomEvent('cambiar-leccion', { detail: { leccion } });
                  dispatchEvent(customEvent);
                }
              }}
            />
          </div>
        {:else if activeTab === 1}
          <div class="tab-panel active">
            <TarjetaInformacionCurso
              titulo={curso?.titulo || ''}
              imagen_url={curso?.imagen_url || ''}
              categoria={curso?.categoria || ''}
              nivel={curso?.nivel || ''}
              duracion_estimada={curso?.duracion_estimada || curso?.duracion || 0}
              descripcion={curso?.descripcion || ''}
              descripcion_corta={curso?.descripcion_corta || ''}
              objetivos={curso?.objetivos || []}
              requisitos={curso?.requisitos || []}
              artista={curso?.artista || ''}
              acordeonista={curso?.acordeonista || ''}
              tonalidad={curso?.tonalidad || ''}
              conteo_lecciones={curso?.conteo_lecciones || 0}
              estudiantes_inscritos={curso?.estudiantes_inscritos || 0}
              tipo={tipo === 'leccion' ? 'curso' : 'tutorial'}
            />
          </div>
        {:else if activeTab === 2}
          <div class="tab-panel active">
            <ComentariosLeccion leccionId={leccionId} usuarioActual={usuarioActual} tipo={tipo} />
          </div>
        {:else if activeTab === 3}
          <div class="tab-panel active">
            <NotasLeccion leccionId={leccionId} usuarioActual={usuarioActual} tipo={tipo} />
          </div>
        {/if}
      {:else}
        <div class="tab-panel {activeTab === 0 ? 'active' : ''}">
          <TarjetaInformacionCurso
            titulo={curso?.titulo || ''}
            imagen_url={curso?.imagen_url || ''}
            categoria={curso?.categoria || ''}
            nivel={curso?.nivel || ''}
            duracion_estimada={curso?.duracion_estimada || curso?.duracion || 0}
            descripcion={curso?.descripcion || ''}
            descripcion_corta={curso?.descripcion_corta || ''}
            objetivos={curso?.objetivos || []}
            requisitos={curso?.requisitos || []}
            artista={curso?.artista || ''}
            acordeonista={curso?.acordeonista || ''}
            tonalidad={curso?.tonalidad || ''}
            conteo_lecciones={curso?.conteo_lecciones || 0}
            estudiantes_inscritos={curso?.estudiantes_inscritos || 0}
            tipo={tipo === 'leccion' ? 'curso' : 'tutorial'}
          />
        </div>
        <div class="tab-panel {activeTab === 1 ? 'active' : ''}">
          <ComentariosLeccion leccionId={leccionId} usuarioActual={usuarioActual} tipo={tipo} />
        </div>
        <div class="tab-panel {activeTab === 2 ? 'active' : ''}">
          <NotasLeccion leccionId={leccionId} usuarioActual={usuarioActual} tipo={tipo} />
        </div>
      {/if}
        </div>
  </div>
</div>

<style>
.leccion-contenido {
  padding: 16px 24px 0 24px !important;
  margin: 0 !important;
  background-color: #fff !important;
  color: #222;
  border-radius: 0;
  box-shadow: none;
  min-height: calc(100vh - 370px); /* Ajusta 370px si el video/header tiene otra altura */
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
}
.tabs {
  display: flex;
  flex-direction: column;
}
.tab-headers {
  display: flex;
  border-bottom: 1px solid #e5e7eb;
  margin-bottom: 20px;
}
.tab-btn {
  padding: 10px 20px;
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  font-size: 14px;
  font-weight: 500;
  color: #6b7280;
  cursor: pointer;
  transition: color 0.2s, border-color 0.2s;
}
.tab-btn.active {
  color: #e63946;
  border-bottom-color: #e63946;
}
.tab-content {
  flex: 1;
}
.tab-panel {
  display: none;
}
.tab-panel.active {
  display: block;
}
.contenido-html {
  line-height: 1.6;
  font-size: 16px;
  color: #333;
}
.contenido-html h1, .contenido-html h2, .contenido-html h3 {
  margin-top: 1.5em;
  margin-bottom: 0.75em;
}
.contenido-html p {
  margin-bottom: 1em;
}
.contenido-html ul, .contenido-html ol {
  margin-left: 1.5em;
  margin-bottom: 1em;
}
.info-img {
  width: 140px;
  height: 140px;
  object-fit: cover;
  border-radius: 10px;
  background: #eee;
}
.info-img.small {
  width: 78px;
  height: 78px;
  min-width: 78px;
  min-height: 78px;
  border-radius: 12px;
}
.tab-panel.info-detalles {
  display: flex;
  gap: 18px;
  margin-bottom: 6px;
  font-size: 1.08rem;
  color: #444;
  align-items: center;
}
.info-detalle-item {
  display: flex;
  align-items: center;
  gap: 5px;
  background: #fffbe7;
  padding: 3px 10px;
  border-radius: 8px;
  box-shadow: 0 1px 3px 0 rgba(255,215,64,0.12);
  font-weight: 500;
}
.emoji {
  font-size: 1.1em;
  margin-right: 2px;
}


.info-chip.categoria {
  background: linear-gradient(90deg, #ff8a65 0%, #e63946 100%);
  color: #fff;
  font-weight: bold;
}
.info-chip.nivel {
  background: linear-gradient(90deg, #43cea2 0%, #185a9d 100%);
  color: #fff;
  font-weight: bold;
}
.info-chip.duracion {
  background: linear-gradient(90deg, #f7971e 0%, #ffd200 100%);
  color: #fff;
  font-weight: bold;
}


@media (max-width: 1024px) {
  .leccion-contenido {
    padding: 1rem 1.5rem 0 1.5rem !important;
  }
  .tab-headers {
    gap: 0.5rem;
    overflow-x: auto;
    padding-bottom: 0.25rem;
  }
  .tab-btn {
    padding: 0.75rem 1.25rem;
    font-size: 0.875rem;
    white-space: nowrap;
    min-width: fit-content;
  }
}

@media (max-width: 768px) {
  .leccion-contenido {
    padding: 0.75rem 1rem 0 1rem !important;
  }
  .tab-headers {
    margin-bottom: 1rem;
    -webkit-overflow-scrolling: touch;
  }
  .tab-btn {
    padding: 0.625rem 1rem;
    font-size: 0.8rem;
    font-weight: 600;
  }
}

@media (max-width: 480px) {
  .leccion-contenido {
    padding: 0.5rem 0.75rem 0 0.75rem !important;
    min-height: calc(100vh - 320px);
  }
  .tab-headers {
    margin-bottom: 0.75rem;
    gap: 0.25rem;
  }
  .tab-btn {
    padding: 0.5rem 0.75rem;
    font-size: 0.75rem;
    border-radius: 0.5rem;
  }
  .tab-btn.active {
    background: rgba(230, 57, 70, 0.1);
  }
}

/* Fondo para el layout principal de la página de lección */
:global(.contenido-principal) {
  background-color: #1a1a1a !important;
  color: #fff;
}
</style>
