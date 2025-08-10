<script lang="ts">
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { generateUniqueSlug, generateSlug } from '$lib/utilidades/utilidadesSlug';
  import { goto } from '$app/navigation';

  // Props tipadas - CAMPOS REALES DE LA BD
  export let cursos: Array<{
    id: string;
    titulo: string;
    descripcion?: string;
    descripcion_corta?: string;
    imagen_url?: string;
    estudiantes_inscritos?: number;
    conteo_lecciones?: number;
    duracion_estimada?: number;
    estado?: string;
    nivel?: string;
    categoria?: string;
    precio_normal?: number;
    precio_rebajado?: number;
    created_at: string;
    [key: string]: any;
  }> = [];

  export let tutoriales: Array<{
    id: string;
    titulo: string;
    descripcion?: string;
    descripcion_corta?: string;
    imagen_url?: string;
    duracion?: number;
    duracion_estimada?: number;
    estado?: string;
    nivel?: string;
    categoria?: string;
    artista?: string;
    acordeonista?: string;
    tonalidad?: string;
    precio_normal?: number;
    precio_rebajado?: number;
    created_at: string;
    [key: string]: any;
  }> = [];

  export let modoVista: 'cuadricula' | 'lista' = 'cuadricula';

  // Estados internos
  let procesandoAccion = false;
  let itemProcesando = '';

  // Unificar y ordenar contenido
  $: contenidoUnificado = [
    ...cursos.map(c => ({ ...c, tipo: 'curso' as const })),
    ...tutoriales.map(t => ({ ...t, tipo: 'tutorial' as const }))
  ].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
  
  // Debug temporal
  $: if (contenidoUnificado.length > 0) {
    console.log('🎨 [COMPONENTE] Primer item:', contenidoUnificado[0]);
    console.log('🎨 [COMPONENTE] Campos disponibles:', Object.keys(contenidoUnificado[0]));
  }

  function obtenerBadgeEstado(estado: string) {
    const estados: Record<string, string> = {
      'publicado': 'badge-publicado',
      'borrador': 'badge-borrador',
      'archivado': 'badge-archivado'
    };
    return estados[estado] || 'badge-default';
  }

  function obtenerBadgeNivel(nivel: string) {
    const niveles: Record<string, string> = {
      'principiante': 'badge-principiante',
      'intermedio': 'badge-intermedio',
      'avanzado': 'badge-avanzado'
    };
    return niveles[nivel] || 'badge-default';
  }

  function obtenerImagenPorDefecto(tipo: string) {
    return tipo === 'curso' 
      ? 'from-emerald-100 via-blue-50 to-purple-100' 
      : 'from-pink-100 via-purple-50 to-indigo-100';
  }

  function obtenerIconoTipo(tipo: string) {
    if (tipo === 'curso') {
      return `<svg class="h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
      </svg>`;
    } else {
      return `<svg class="h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
      </svg>`;
    }
  }

  function formatearFecha(fecha: string) {
    if (!fecha) return '';
    return new Date(fecha).toLocaleDateString('es-ES', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  }

  async function manejarEliminar(item: any) {
    if (procesandoAccion) return;

    const confirmacion = confirm(
      `¿Estás seguro que deseas eliminar este ${item.tipo}?\n\n"${item.titulo}"\n\nEsta acción no se puede deshacer.`
    );

    if (!confirmacion) return;

    try {
      procesandoAccion = true;
      itemProcesando = item.id;

      const tabla = item.tipo === 'curso' ? 'cursos' : 'tutoriales';
      const { error } = await supabase.from(tabla).delete().eq('id', item.id);

      if (error) throw error;

      // Recargar la página para refrescar los datos
      window.location.reload();
    } catch (error) {
      console.error('Error eliminando:', error);
      alert(`Error al eliminar el ${item.tipo}. Por favor, intenta de nuevo.`);
    } finally {
      procesandoAccion = false;
      itemProcesando = '';
    }
  }

  async function manejarEditar(item: any) {
    if (procesandoAccion) return;

    try {
      procesandoAccion = true;
      itemProcesando = item.id;

      // Usar ID para ambos tipos (más confiable)
        goto(`/administrador/crear-contenido?tipo=${item.tipo}&editar=${item.id}`);
    } catch (error) {
      console.error('Error al editar:', error);
      alert('Error al cargar el contenido para editar. Por favor, intenta de nuevo.');
    } finally {
      procesandoAccion = false;
      itemProcesando = '';
    }
  }

  async function manejarVer(item: any) {
    if (procesandoAccion) return;

    try {
      procesandoAccion = true;
      itemProcesando = item.id;

      if (item.tipo === 'curso') {
        const { data: curso, error } = await supabase
          .from('cursos')
          .select('slug, titulo')
          .eq('id', item.id)
          .single();

        if (error || !curso) {
          throw new Error('No se encontró el curso');
        }

        if (curso.slug) {
          goto(`/cursos/${curso.slug}`);
          return;
        }

        const nuevoSlug = generateUniqueSlug(curso.titulo);
        const { error: updateError } = await supabase
          .from('cursos')
          .update({ slug: nuevoSlug })
          .eq('id', item.id);

        if (updateError) throw updateError;
        goto(`/cursos/${nuevoSlug}`);
      } else {
        // Para tutoriales, usar el título para generar slug dinámicamente
        const { data: tutorial, error } = await supabase
          .from('tutoriales')
          .select('titulo')
          .eq('id', item.id)
          .single();

        if (error || !tutorial) {
          throw new Error('No se encontró el tutorial');
        }

        // Generar slug dinámicamente sin guardar en BD
        const slugGenerado = generateSlug(tutorial.titulo);
        goto(`/tutoriales/${slugGenerado}`);
      }
    } catch (error) {
      console.error('Error al ver:', error);
      alert('Error al cargar el contenido. Por favor, intenta de nuevo.');
    } finally {
      procesandoAccion = false;
      itemProcesando = '';
    }
  }
</script>

<div class="mostrador-contenido">
  {#if contenidoUnificado.length === 0}
    <!-- Estado vacío mejorado -->
    <div class="estado-vacio">
      <div class="contenido-vacio">
        <div class="icono-vacio">
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
        </div>
        <h3 class="titulo-vacio">No hay contenido para mostrar</h3>
        <p class="descripcion-vacio">
          Comienza creando tu primer curso o tutorial para verlo aquí.
        </p>
        <div class="acciones-vacio">
          <a href="/administrador/crear-contenido?tipo=curso" class="boton-vacio boton-curso">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
            </svg>
            Crear primer curso
          </a>
          <a href="/administrador/crear-contenido?tipo=tutorial" class="boton-vacio boton-tutorial">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
            </svg>
            Crear primer tutorial
          </a>
        </div>
      </div>
    </div>
  {:else}
    <!-- Contenido principal -->
    <div class="contenedor-items {modoVista === 'lista' ? 'modo-lista' : 'modo-cuadricula'}">
      {#each contenidoUnificado as item (item.id)}
        <div class="tarjeta-contenido {modoVista === 'lista' ? 'vista-lista' : 'vista-cuadricula'}">
          <!-- Imagen/Thumbnail -->
          <div class="contenedor-imagen">
            {#if item.imagen_url}
              <img 
                src={item.imagen_url} 
                alt={item.titulo} 
                class="imagen-contenido"
                loading="lazy"
              />
            {:else}
              <div class="imagen-placeholder bg-gradient-to-br {obtenerImagenPorDefecto(item.tipo)}">
                <div class="icono-placeholder">
                  {@html obtenerIconoTipo(item.tipo)}
                </div>
              </div>
            {/if}
            
            <!-- Badge tipo en la imagen -->
            <div class="badge-tipo {item.tipo === 'curso' ? 'badge-curso' : 'badge-tutorial'}">
              <svg class="icono-badge" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                {#if item.tipo === 'curso'}
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                {:else}
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                {/if}
              </svg>
              {item.tipo === 'curso' ? 'Curso' : 'Tutorial'}
            </div>

            <!-- Indicador de carga para este item -->
            {#if procesandoAccion && itemProcesando === item.id}
              <div class="overlay-carga">
                <div class="spinner-accion"></div>
              </div>
            {/if}
          </div>

          <!-- Información del contenido -->
          <div class="info-contenido">
            <!-- Badges de estado y nivel -->
            <div class="badges-superiores">
              {#if item.estado}
                <span class="badge {obtenerBadgeEstado(item.estado)}">
                  {item.estado}
                </span>
              {/if}
              
              {#if item.nivel}
                <span class="badge {obtenerBadgeNivel(item.nivel)}">
                  {item.nivel}
                </span>
              {/if}
            </div>

            <!-- Título y descripción -->
            <div class="texto-principal">
              <h3 class="titulo-contenido">{item.titulo}</h3>
              <p class="descripcion-contenido">
                {item.descripcion_corta || item.descripcion || 'Sin descripción disponible'}
              </p>
            </div>

            <!-- Estadísticas REALES -->
            <div class="estadisticas-contenido">
              <div class="stat-item">
                <svg class="stat-icono" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m7-7a4 4 0 11-8 0 4 4 0 018 0z"></path>
                </svg>
                <span class="stat-numero">
                  {#if item.tipo === 'curso'}
                    {(item as any).estudiantes_inscritos_real ?? (item as any).estudiantes_inscritos ?? 0}
                  {:else}
                    {(item as any).estudiantes_inscritos_real ?? 0}
                  {/if}
                </span>
                <span class="stat-label">Estudiantes</span>
              </div>

                            {#if item.tipo === 'curso'}
                <div class="stat-item">
                  <svg class="stat-icono" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
                  </svg>
                  <span class="stat-numero">{(item as any).modulos_count_real ?? (item as any).modulos_count ?? 0}</span>
                  <span class="stat-label">Módulos</span>
                </div>

                <div class="stat-item">
                  <svg class="stat-icono" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                  </svg>
                  <span class="stat-numero">{(item as any).lecciones_count_real ?? (item as any).lecciones_count ?? (item as any).conteo_lecciones ?? 0}</span>
                  <span class="stat-label">Lecciones</span>
                </div>
                
                <div class="stat-item">
                  <svg class="stat-icono" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  <span class="stat-numero">{(item as any).duracion_estimada || 0}</span>
                  <span class="stat-label">Min</span>
                </div>
                            {:else}
                <div class="stat-item">
                  <svg class="stat-icono" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16"></path>
                  </svg>
                  <span class="stat-numero">{(item as any).partes_count_real ?? (item as any).partes_count ?? 0}</span>
                  <span class="stat-label">Partes</span>
                </div>

                <div class="stat-item">
                  <svg class="stat-icono" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  <span class="stat-numero">{(item as any).duracion || (item as any).duracion_estimada || 0}</span>
                  <span class="stat-label">Minutos</span>
                </div>

                                 {#if (item as any).artista}
                  <div class="stat-item">
                    <svg class="stat-icono" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                    </svg>
                                         <span class="stat-numero">{(item as any).artista}</span>
                    <span class="stat-label">Artista</span>
                  </div>
                {/if}

                                 {#if (item as any).tonalidad}
                  <div class="stat-item">
                    <svg class="stat-icono" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3"></path>
                    </svg>
                                         <span class="stat-numero">{(item as any).tonalidad}</span>
                    <span class="stat-label">Tono</span>
                  </div>
                {/if}
              {/if}
            </div>

            <!-- Fecha de creación -->
            <div class="fecha-creacion">
              <svg class="icono-fecha" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
              </svg>
              <span>Creado: {formatearFecha(item.created_at)}</span>
            </div>

            <!-- Acciones -->
            <div class="acciones-contenido">
              <button 
                class="boton-accion boton-editar"
                on:click={() => manejarEditar(item)}
                disabled={procesandoAccion}
                title="Editar contenido"
              >
                <svg class="icono-accion" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                </svg>
                <span>Editar</span>
              </button>

              <button 
                class="boton-accion boton-ver"
                on:click={() => manejarVer(item)}
                disabled={procesandoAccion}
                title="Ver contenido"
              >
                <svg class="icono-accion" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
                </svg>
                <span>Ver</span>
              </button>

              <button 
                class="boton-accion boton-eliminar"
                on:click={() => manejarEliminar(item)}
                disabled={procesandoAccion}
                title="Eliminar contenido"
              >
                <svg class="icono-accion" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                </svg>
                <span>Eliminar</span>
              </button>
            </div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .mostrador-contenido {
    font-family: 'Inter', system-ui, -apple-system, sans-serif;
  }

  /* === ESTADO VACÍO === */
  .estado-vacio {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
    padding: 3rem;
  }

  .contenido-vacio {
    text-align: center;
    max-width: 500px;
  }

  .icono-vacio {
    width: 80px;
    height: 80px;
    margin: 0 auto 2rem;
    color: #9ca3af;
  }

  .titulo-vacio {
    font-size: 1.5rem;
    font-weight: 600;
    color: #374151;
    margin: 0 0 1rem 0;
  }

  .descripcion-vacio {
    color: #6b7280;
    margin: 0 0 2rem 0;
    line-height: 1.6;
  }

  .acciones-vacio {
    display: flex;
    gap: 1rem;
    justify-content: center;
  }

  .boton-vacio {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 1rem 1.5rem;
    border-radius: 12px;
    font-weight: 500;
    text-decoration: none;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }

  .boton-vacio svg {
    width: 1.25rem;
    height: 1.25rem;
  }

  .boton-curso {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: white;
  }

  .boton-curso:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(16, 185, 129, 0.3);
  }

  .boton-tutorial {
    background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
    color: white;
  }

  .boton-tutorial:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(59, 130, 246, 0.3);
  }

  /* === CONTENEDOR PRINCIPAL === */
  .contenedor-items {
    transition: all 0.3s ease;
  }

  .modo-cuadricula {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 2rem;
  }

  .modo-lista {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  /* === TARJETAS === */
  .tarjeta-contenido {
    background: white;
    border-radius: 20px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.06);
    overflow: hidden;
    transition: all 0.3s ease;
    border: 1px solid #f1f5f9;
    position: relative;
  }

  .tarjeta-contenido:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.12);
    border-color: #e2e8f0;
  }

  .vista-cuadricula {
    display: flex;
    flex-direction: column;
  }

  .vista-lista {
    display: grid;
    grid-template-columns: 200px 1fr;
    gap: 0;
  }

  /* === IMAGEN === */
  .contenedor-imagen {
    position: relative;
    overflow: hidden;
  }

  .vista-cuadricula .contenedor-imagen {
    height: 220px;
  }

  .vista-lista .contenedor-imagen {
    height: 180px;
  }

  .imagen-contenido {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.5s ease;
  }

  .tarjeta-contenido:hover .imagen-contenido {
    transform: scale(1.05);
  }

  .imagen-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #6b7280;
  }

  .icono-placeholder {
    opacity: 0.7;
  }

  .badge-tipo {
    position: absolute;
    top: 1rem;
    left: 1rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    border-radius: 12px;
    font-weight: 600;
    font-size: 0.85rem;
    backdrop-filter: blur(10px);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
    border: 1px solid rgba(255, 255, 255, 0.2);
  }

  .badge-curso {
    background: rgba(16, 185, 129, 0.9);
    color: white;
  }

  .badge-tutorial {
    background: rgba(59, 130, 246, 0.9);
    color: white;
  }

  .icono-badge {
    width: 1rem;
    height: 1rem;
  }

  .overlay-carga {
    position: absolute;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    backdrop-filter: blur(2px);
  }

  .spinner-accion {
    width: 2rem;
    height: 2rem;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-top: 2px solid white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  /* === INFORMACIÓN === */
  .info-contenido {
    padding: 1.5rem;
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .badges-superiores {
    display: flex;
    gap: 0.75rem;
    flex-wrap: wrap;
  }

  .badge {
    padding: 0.375rem 0.875rem;
    border-radius: 8px;
    font-size: 0.8rem;
    font-weight: 600;
    border: 1px solid;
    display: flex;
    align-items: center;
    gap: 0.25rem;
  }

  .texto-principal {
    flex: 1;
  }

  .titulo-contenido {
    font-size: 1.125rem;
    font-weight: 700;
    color: #1f2937;
    margin: 0 0 0.75rem 0;
    line-height: 1.3;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .descripcion-contenido {
    color: #6b7280;
    font-size: 0.9rem;
    line-height: 1.5;
    margin: 0;
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .estadisticas-contenido {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
  }

  .stat-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: #f8fafc;
    padding: 0.5rem 0.875rem;
    border-radius: 8px;
    border: 1px solid #e2e8f0;
  }

  .stat-icono {
    width: 1rem;
    height: 1rem;
    color: #6b7280;
  }

  .stat-numero {
    font-weight: 600;
    color: #374151;
    font-size: 0.9rem;
  }

  .stat-label {
    font-size: 0.8rem;
    color: #6b7280;
  }

  .fecha-creacion {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #6b7280;
    font-size: 0.85rem;
  }

  .icono-fecha {
    width: 1rem;
    height: 1rem;
  }

  /* === ACCIONES === */
  .acciones-contenido {
    display: flex;
    gap: 0.75rem;
    margin-top: auto;
    padding-top: 1rem;
    border-top: 1px solid #f1f5f9;
  }

  .boton-accion {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    border: none;
    border-radius: 10px;
    font-weight: 500;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
  }

  .boton-accion:disabled {
    opacity: 0.6;
    cursor: not-allowed;
    transform: none !important;
  }

  .boton-accion::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
    transition: left 0.5s;
  }

  .boton-accion:hover:not(:disabled)::before {
    left: 100%;
  }

  .icono-accion {
    width: 1.125rem;
    height: 1.125rem;
  }

  .boton-editar {
    background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
    color: white;
  }

  .boton-editar:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);
  }

  .boton-ver {
    background: linear-gradient(135deg, #64748b 0%, #475569 100%);
    color: white;
  }

  .boton-ver:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(100, 116, 139, 0.3);
  }

  .boton-eliminar {
    background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
    color: white;
  }

  .boton-eliminar:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
  }

  /* === RESPONSIVE === */
  @media (max-width: 1200px) {
    .modo-cuadricula {
      grid-template-columns: repeat(2, 1fr);
      gap: 1.5rem;
    }
  }

  @media (max-width: 1024px) {
    .vista-lista {
      grid-template-columns: 150px 1fr;
    }

    .vista-lista .contenedor-imagen {
      height: 140px;
    }
  }

  @media (max-width: 768px) {
    .modo-cuadricula {
      grid-template-columns: 1fr;
      gap: 1rem;
    }

    .vista-lista {
      grid-template-columns: 1fr;
    }

    .vista-lista .contenedor-imagen {
      height: 200px;
    }

    .info-contenido {
      padding: 1.25rem;
    }

    .acciones-contenido {
      flex-direction: column;
      gap: 0.5rem;
    }

    .boton-accion {
      padding: 0.875rem;
    }

    .estadisticas-contenido {
      gap: 0.5rem;
    }

    .stat-item {
      flex: 1;
      min-width: 0;
      justify-content: center;
    }

    .acciones-vacio {
      flex-direction: column;
      align-items: center;
    }
  }

  @media (max-width: 480px) {
    .estado-vacio {
      padding: 2rem 1rem;
    }

    .modo-cuadricula {
      grid-template-columns: 1fr;
      gap: 1rem;
    }

    .badges-superiores {
      gap: 0.5rem;
    }

    .badge {
      padding: 0.25rem 0.75rem;
      font-size: 0.75rem;
    }

    .titulo-contenido {
      font-size: 1rem;
    }

    .descripcion-contenido {
      font-size: 0.85rem;
    }
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
</style>
