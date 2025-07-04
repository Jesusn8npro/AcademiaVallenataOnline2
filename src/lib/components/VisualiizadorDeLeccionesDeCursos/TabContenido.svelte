<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';
  import { page } from '$app/stores';
  import { get } from 'svelte/store';

  // Props
  export let modoSPA: boolean = false;
  export let clases: any[] = [];
  export let leccionActiva: string = '';
  export let progreso: Record<string, any> = {};
  export let curso: any = {};
  export let moduloActivo: any = null;

  const dispatch = createEventDispatcher();

  // Funciones para miniaturas de YouTube
  function obtenerYoutubeId(url: string): string | null {
    if (!url) return null;
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
      /youtube\.com\/watch\?.*v=([a-zA-Z0-9_-]{11})/,
      /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/
    ];
    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match && match[1]) return match[1];
    }
    return null;
  }

  function obtenerMiniatura(videoUrl: string, calidad: 'default' | 'mqdefault' | 'hqdefault' = 'mqdefault'): string {
    const videoId = obtenerYoutubeId(videoUrl);
    if (videoId) {
      return `https://img.youtube.com/vi/${videoId}/${calidad}.jpg`;
    }
    return 'https://academiavallenataonline.com/wp-content/uploads/2023/06/placeholder-video.jpg';
  }

  // Obtener ID de lección desde URL
  $: idLeccionURL = '';
  $: {
    const params = get(page).params;
    idLeccionURL = params.claseSlug || leccionActiva;
    if (idLeccionURL && typeof idLeccionURL === 'number') {
      idLeccionURL = String(idLeccionURL);
    }
  }

  // Verificar si lección está activa
  function coincideLeccionActiva(leccion: any) {
    if (!leccion || !idLeccionURL) return false;

    const idURL = String(idLeccionURL).toLowerCase();
    const idLeccion = String(leccion.id).toLowerCase();
    const slugLeccion = (leccion.slug || '').toLowerCase();
    const slugGenerado = leccion.titulo ? generateSlug(leccion.titulo).toLowerCase() : '';

    return idLeccion === idURL || 
           slugLeccion === idURL || 
           slugGenerado === idURL || 
           (slugGenerado && idURL.startsWith(slugGenerado + '-'));
  }

  // Navegar a lección
  function irALeccion(modulo: any, leccion: any) {
    let cursoSlug = curso?.slug || (curso?.titulo ? generateSlug(curso.titulo) : '');
    let moduloSlug = modulo?.slug || (modulo?.titulo ? generateSlug(modulo.titulo) : '');
    let leccionSlug = leccion?.slug || (leccion?.titulo ? generateSlug(leccion.titulo) : '');

    // Navegación para cursos
    if (curso && Array.isArray(curso.modulos) && modulo && leccion && cursoSlug && moduloSlug && leccionSlug) {
      const url = `/cursos/${cursoSlug}/${moduloSlug}/${leccionSlug}`;
      window.location.href = url;
      return;
    }
    
    // Navegación para tutoriales
    if (cursoSlug && leccionSlug) {
      const url = `/tutoriales/${cursoSlug}/clase/${leccionSlug}`;
      window.location.href = url;
      return;
    }
    
    dispatch('cambiar-leccion', { modulo, leccion });
  }

  // Formatear duración
  function formatearDuracion(segundos: number): string {
    if (!segundos) return '0:00';
    const horas = Math.floor(segundos / 3600);
    const minutos = Math.floor((segundos % 3600) / 60);
    const segs = Math.floor(segundos % 60);
    
    if (horas > 0) {
      return `${horas}:${minutos < 10 ? '0' : ''}${minutos}:${segs < 10 ? '0' : ''}${segs}`;
    }
    return `${minutos}:${segs < 10 ? '0' : ''}${segs}`;
  }

  // Verificar si lección está completada
  function esLeccionCompletada(leccionId: string): boolean {
    return progreso[leccionId] && progreso[leccionId] >= 90;
  }

  // Buscar módulo de una lección
  function buscarModuloDeleccion(leccion: any) {
    if (curso && Array.isArray(curso.modulos)) {
      for (const modulo of curso.modulos) {
        if (modulo.lecciones && modulo.lecciones.find((l: any) => l.id === leccion.id)) {
          return modulo;
        }
      }
    }
    return null;
  }
</script>

<div class="contenedor-principal">
  {#if curso && Array.isArray(curso.modulos) && curso.modulos.length > 0}
    <!-- Vista de cursos con módulos -->
    <div class="lista-modulos">
      {#each curso.modulos as modulo (modulo.id)}
        <div class="modulo-contenedor">
          <div class="modulo-encabezado">
            <h3 class="modulo-titulo">{modulo.titulo}</h3>
          </div>
          
          <div class="lecciones-scroll">
            {#each modulo.lecciones as leccion (leccion.id)}
              <div 
                class="tarjeta-leccion {coincideLeccionActiva(leccion) ? 'activa' : ''} {esLeccionCompletada(leccion.id) ? 'completada' : ''}"
                on:click={() => irALeccion(modulo, leccion)}
                tabindex="0"
                role="button"
                aria-label={`Ir a la lección ${leccion.titulo}`}
                on:keydown={(e) => { if (e.key === 'Enter' || e.key === ' ') irALeccion(modulo, leccion); }}
              >
                <div class="miniatura-contenedor">
                  {#if leccion.thumbnail_url || leccion.thumbnail || leccion.video_miniatura_url || leccion.video_url}
                    <img 
                      src={leccion.thumbnail_url || leccion.thumbnail || leccion.video_miniatura_url || obtenerMiniatura(leccion.video_url)} 
                      alt={leccion.titulo}
                      loading="lazy"
                      class="miniatura-imagen"
                      on:error={(e) => {
                        const imgElement = e.currentTarget as HTMLImageElement;
                        if (imgElement) {
                          imgElement.onerror = null;
                          imgElement.src = 'https://academiavallenataonline.com/wp-content/uploads/2023/06/placeholder-video.jpg';
                        }
                      }}
                    />
                  {:else}
                    <div class="miniatura-placeholder">
                      <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="23 7 16 12 23 17 23 7"></polygon>
                        <rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect>
                      </svg>
                    </div>
                  {/if}
                  
                  <div class="icono-reproducir">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="white" stroke="none">
                      <polygon points="5 3 19 12 5 21 5 3"></polygon>
                    </svg>
                  </div>
                  
                  {#if leccion.duracion}
                    <div class="duracion-badge">{formatearDuracion(leccion.duracion)}</div>
                  {/if}
                </div>
                
                <div class="info-leccion">
                  <div class="titulo-leccion">
                    {leccion.titulo}
                    {#if esLeccionCompletada(leccion.id)}
                      <span class="icono-completado" title="Completada">
                        <svg width="14" height="14" fill="none" stroke="#4CAF50" stroke-width="2" viewBox="0 0 24 24">
                          <polyline points="20 6 9 17 4 12"/>
                        </svg>
                      </span>
                    {/if}
                  </div>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/each}
    </div>
  {:else if clases && clases.length > 0}
    <!-- Vista de tutoriales (clases individuales) -->
    <div class="lista-clases">
      {#each clases as leccion (leccion.id)}
        <div 
          class="tarjeta-leccion {coincideLeccionActiva(leccion) ? 'activa' : ''} {esLeccionCompletada(leccion.id) ? 'completada' : ''}"
          on:click={() => irALeccion(buscarModuloDeleccion(leccion), leccion)}
          tabindex="0"
          role="button"
          aria-label={`Ir a la clase ${leccion.titulo}`}
          on:keydown={(e) => {
            if (e.key === 'Enter' || e.key === ' ') {
              irALeccion(buscarModuloDeleccion(leccion), leccion);
            }
          }}
        >
          <div class="miniatura-contenedor">
            {#if leccion.thumbnail_url || leccion.thumbnail || leccion.video_miniatura_url || leccion.video_url}
              <img 
                src={leccion.thumbnail_url || leccion.thumbnail || leccion.video_miniatura_url || obtenerMiniatura(leccion.video_url)} 
                alt={leccion.titulo}
                loading="lazy"
                class="miniatura-imagen"
                on:error={(e) => {
                  const imgElement = e.currentTarget as HTMLImageElement;
                  if (imgElement) {
                    imgElement.onerror = null;
                    imgElement.src = 'https://academiavallenataonline.com/wp-content/uploads/2023/06/placeholder-video.jpg';
                  }
                }}
              />
            {:else}
              <div class="miniatura-placeholder">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polygon points="23 7 16 12 23 17 23 7"></polygon>
                  <rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect>
                </svg>
              </div>
            {/if}
            
            <div class="icono-reproducir">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="white" stroke="none">
                <polygon points="5 3 19 12 5 21 5 3"></polygon>
              </svg>
            </div>
            
            {#if leccion.duracion}
              <div class="duracion-badge">{formatearDuracion(leccion.duracion)}</div>
            {/if}
          </div>
          
          <div class="info-leccion">
            <div class="titulo-leccion">
              {leccion.titulo}
              {#if esLeccionCompletada(leccion.id)}
                <span class="icono-completado" title="Completada">
                  <svg width="14" height="14" fill="none" stroke="#4CAF50" stroke-width="2" viewBox="0 0 24 24">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </span>
              {/if}
            </div>
          </div>
        </div>
      {/each}
    </div>
  {:else}
    <div class="sin-contenido">
      <p>No hay clases disponibles en este momento.</p>
    </div>
  {/if}
</div>

<style>
/* Contenedor principal */
.contenedor-principal {
  width: 100%;
  padding: 1rem 0;
  box-sizing: border-box;
}

/* Lista de módulos para cursos */
.lista-modulos {
  display: flex;
  flex-direction: row;
  gap: 1.5rem;
  width: 100%;
  overflow-x: auto;
  padding-bottom: 0.75rem;
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 #f1f5f9;
}

.lista-modulos::-webkit-scrollbar {
  height: 8px;
}

.lista-modulos::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 4px;
}

.lista-modulos::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

.lista-modulos::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

/* Contenedor de módulo */
.modulo-contenedor {
  min-width: 300px;
  max-width: 350px;
  flex: 0 0 auto;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border-radius: 16px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: all 0.3s ease;
}

.modulo-contenedor:hover {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  border-color: #cbd5e1;
}

/* Encabezado del módulo */
.modulo-encabezado {
  padding: 1rem;
  background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%);
  color: white;
  text-align: center;
}

.modulo-titulo {
  font-size: 1rem;
  font-weight: 700;
  margin: 0;
  color: white;
}

/* Scroll horizontal de lecciones */
.lecciones-scroll {
  display: flex;
  flex-direction: row;
  gap: 1rem;
  padding: 1rem;
  overflow-x: auto;
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 #f8fafc;
}

.lecciones-scroll::-webkit-scrollbar {
  height: 6px;
}

.lecciones-scroll::-webkit-scrollbar-track {
  background: #f8fafc;
  border-radius: 3px;
}

.lecciones-scroll::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

/* Lista de clases para tutoriales */
.lista-clases {
  display: flex;
  flex-direction: row;
  gap: 1rem;
  width: 100%;
  overflow-x: auto;
  padding-bottom: 0.75rem;
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 #f1f5f9;
}

.lista-clases::-webkit-scrollbar {
  height: 8px;
}

.lista-clases::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 4px;
}

.lista-clases::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

/* Tarjeta de lección */
.tarjeta-leccion {
  background: #1a1a1a;
  color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 160px;
  max-width: 200px;
  width: 180px;
  padding: 0.75rem;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all 0.3s ease;
  position: relative;
  flex: 0 0 auto;
}

.tarjeta-leccion:hover {
  background: #2a2a2a;
  border-color: #ff9800;
  transform: translateY(-4px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
}

.tarjeta-leccion.activa {
  border-color: #2196f3;
  background: #e3f2fd;
  color: #0d47a1;
  box-shadow: 0 6px 20px rgba(33, 150, 243, 0.3);
}

.tarjeta-leccion.completada {
  border-color: #4caf50;
}

/* Contenedor de miniatura */
.miniatura-contenedor {
  position: relative;
  width: 100%;
  height: 100px;
  border-radius: 8px;
  overflow: hidden;
  background: #111111;
  margin-bottom: 0.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.miniatura-imagen {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 8px;
}

.miniatura-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #333333;
  color: #666666;
}

/* Icono de reproducir */
.icono-reproducir {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 32px;
  height: 32px;
  background: rgba(0, 0, 0, 0.7);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  transition: all 0.3s ease;
  z-index: 2;
}

.tarjeta-leccion:hover .icono-reproducir {
  background: #ff9800;
  transform: translate(-50%, -50%) scale(1.1);
}

/* Badge de duración */
.duracion-badge {
  position: absolute;
  bottom: 6px;
  right: 6px;
  background: rgba(0, 0, 0, 0.8);
  color: #ffffff;
  font-size: 0.75rem;
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
  font-weight: 500;
  z-index: 2;
}

/* Información de la lección */
.info-leccion {
  width: 100%;
  text-align: center;
}

.titulo-leccion {
  font-size: 0.9rem;
  font-weight: 500;
  line-height: 1.3;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
  word-wrap: break-word;
  overflow-wrap: break-word;
  hyphens: auto;
}

.icono-completado {
  flex-shrink: 0;
  color: #4caf50;
  margin-left: 0.25rem;
}

/* Sin contenido */
.sin-contenido {
  color: #64748b;
  text-align: center;
  padding: 2rem 0;
  font-style: italic;
}

/* Responsive Design */
@media (max-width: 1024px) {
  .modulo-contenedor {
    min-width: 280px;
    max-width: 320px;
  }
  
  .tarjeta-leccion {
    min-width: 150px;
    width: 160px;
    max-width: 180px;
  }
}

@media (max-width: 768px) {
  .contenedor-principal {
    padding: 0.75rem 0;
  }
  
  .lista-modulos,
  .lista-clases {
    gap: 0.75rem;
    padding-left: 1rem;
    padding-right: 1rem;
  }
  
  .modulo-contenedor {
    min-width: 260px;
    max-width: 300px;
  }
  
  .tarjeta-leccion {
    min-width: 140px;
    width: 150px;
    max-width: 170px;
    padding: 0.5rem;
  }
  
  .miniatura-contenedor {
    height: 85px;
    margin-bottom: 0.5rem;
  }
  
  .modulo-titulo {
    font-size: 0.9rem;
  }
  
  .titulo-leccion {
    font-size: 0.8rem;
  }
  
  .icono-reproducir {
    width: 28px;
    height: 28px;
  }
  
  .icono-reproducir svg {
    width: 14px;
    height: 14px;
  }
}

@media (max-width: 480px) {
  .lista-modulos,
  .lista-clases {
    padding-left: 0.75rem;
    padding-right: 0.75rem;
    gap: 0.5rem;
  }
  
  .modulo-contenedor {
    min-width: 240px;
    max-width: 280px;
  }
  
  .tarjeta-leccion {
    min-width: 130px;
    width: 140px;
    max-width: 160px;
    padding: 0.5rem 0.25rem;
  }
  
  .miniatura-contenedor {
    height: 75px;
  }
  
  .modulo-encabezado {
    padding: 0.75rem;
  }
  
  .lecciones-scroll {
    padding: 0.75rem;
    gap: 0.75rem;
  }
  
  .titulo-leccion {
    font-size: 0.75rem;
    line-height: 1.2;
  }
  
  .duracion-badge {
    font-size: 0.7rem;
    padding: 0.15rem 0.3rem;
  }
}

/* Mejoras adicionales para dispositivos muy pequeños */
@media (max-width: 360px) {
  .tarjeta-leccion {
    min-width: 120px;
    width: 130px;
    max-width: 150px;
  }
  
  .modulo-contenedor {
    min-width: 220px;
    max-width: 260px;
  }
}
</style>
