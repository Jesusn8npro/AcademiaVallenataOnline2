<script lang="ts">
  import { page } from '$app/stores';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { onMount } from 'svelte';

  export let data: any;
  
  $: usuarioPublico = data?.usuarioPublico;
  $: slugUsuario = $page.params.slug;
  $: actividades = usuarioPublico?.actividades || [];

  let grabaciones: any[] = [];
  let cargando = true;
  let error: string | null = null;

  async function cargarActividadUsuario() {
    if (!usuarioPublico) return;
    
    try {
      cargando = true;
      error = null;

      // Buscar actividades musicales, grabaciones, contribuciones, etc.
      const [publicacionesResult, cursosResult] = await Promise.allSettled([
        // Publicaciones relacionadas con música
        supabase
          .from('comunidad_publicaciones')
          .select(`
            *,
            perfiles_usuarios!inner(
              nombre_completo,
              imagen_perfil,
              slug_usuario
            )
          `)
          .eq('usuario_id', usuarioPublico.usuarios.id)
          .in('tipo', ['video', 'audio', 'grabacion'])
          .order('fecha_publicacion', { ascending: false }),
        
        // Cursos creados por el usuario
        supabase
          .from('cursos')
          .select(`
            *,
            perfiles_usuarios!inner(
              nombre_completo,
              imagen_perfil
            )
          `)
          .eq('instructor_id', usuarioPublico.usuarios.id)
          .order('created_at', { ascending: false })
      ]);

      const publicacionesMusicales = publicacionesResult.status === 'fulfilled' 
        ? publicacionesResult.value.data || []
        : [];
      
      const cursosCreados = cursosResult.status === 'fulfilled'
        ? cursosResult.value.data || []
        : [];

             // Combinar y ordenar por fecha
       const todasActividades = [
         ...publicacionesMusicales.map((p: any) => ({
           ...p,
           tipo_actividad: 'publicacion_musical',
           fecha: p.fecha_publicacion
         })),
         ...cursosCreados.map((c: any) => ({
           ...c,
           tipo_actividad: 'curso_creado',
           fecha: c.created_at
         }))
       ].sort((a: any, b: any) => new Date(b.fecha).getTime() - new Date(a.fecha).getTime());

      actividades = todasActividades;
      
      // Filtrar solo grabaciones/videos/audios
      grabaciones = publicacionesMusicales;

    } catch (err) {
      console.error('Error cargando actividad:', err);
      error = 'Error inesperado al cargar la actividad del usuario';
    } finally {
      cargando = false;
    }
  }

  function formatearTiempoRelativo(fecha: string): string {
    if (!fecha) return 'Fecha no disponible';
    
    try {
      const fechaObjeto = new Date(fecha);
      const ahora = new Date();
      const diferencia = ahora.getTime() - fechaObjeto.getTime();
      
      const minutos = Math.floor(diferencia / (1000 * 60));
      const horas = Math.floor(diferencia / (1000 * 60 * 60));
      const dias = Math.floor(diferencia / (1000 * 60 * 60 * 24));
      const semanas = Math.floor(dias / 7);
      const meses = Math.floor(dias / 30);
      
      if (minutos < 1) return 'Ahora mismo';
      if (minutos < 60) return `Hace ${minutos} min`;
      if (horas < 24) return `Hace ${horas}h`;
      if (dias < 7) return `Hace ${dias} día${dias !== 1 ? 's' : ''}`;
      if (semanas < 4) return `Hace ${semanas} semana${semanas !== 1 ? 's' : ''}`;
      if (meses < 12) return `Hace ${meses} mes${meses !== 1 ? 'es' : ''}`;
      
      return fechaObjeto.toLocaleDateString('es-ES', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      });
    } catch {
      return 'Fecha inválida';
    }
  }

  function obtenerIconoActividad(tipo: string): string {
    const iconos: { [key: string]: string } = {
      'publicacion': '📝',
      'comentario': '💬',
      'like': '❤️',
      'inscripcion_curso': '📚',
      'completar_leccion': '✅',
      'crear_curso': '🎓',
      'perfil_actualizado': '👤',
      'foto_perfil': '📸',
      'foto_portada': '🖼️',
      'seguimiento': '👥',
      'mensaje': '✉️',
      'default': '🔸'
    };
    
    return iconos[tipo] || iconos.default;
  }

  function obtenerColorActividad(tipo: string): string {
    const colores: { [key: string]: string } = {
      'publicacion': 'azul',
      'comentario': 'verde',
      'like': 'rojo',
      'inscripcion_curso': 'purpura',
      'completar_leccion': 'naranja',
      'crear_curso': 'dorado',
      'perfil_actualizado': 'gris',
      'foto_perfil': 'rosa',
      'foto_portada': 'cyan',
      'seguimiento': 'indigo',
      'mensaje': 'teal'
    };
    
    return colores[tipo] || 'gris';
  }

  onMount(() => {
    cargarActividadUsuario();
  });

  // Recargar cuando cambie el usuario
  $: if (usuarioPublico) {
    cargarActividadUsuario();
  }
</script>

<svelte:head>
  {#if usuarioPublico}
    <title>Actividad de {usuarioPublico.nombre_completo || usuarioPublico.nombre || 'Usuario'} - Academia Vallenata</title>
    <meta name="description" content="Actividad reciente de {usuarioPublico.nombre_completo || usuarioPublico.nombre || 'Usuario'} en Academia Vallenata" />
  {/if}
</svelte:head>

<div class="actividad-contenido">
  
  {#if actividades.length > 0}
    <!-- 📊 Resumen de actividad -->
    <div class="seccion resumen-actividad">
      <h2>📊 Resumen de actividad</h2>
      <div class="resumen-stats">
        <div class="stat-item">
          <span class="stat-numero">{actividades.length}</span>
          <span class="stat-label">Actividades totales</span>
        </div>
                 <div class="stat-item">
           <span class="stat-numero">{actividades.filter((a: any) => a.tipo === 'publicacion').length}</span>
           <span class="stat-label">Publicaciones</span>
         </div>
         <div class="stat-item">
           <span class="stat-numero">{actividades.filter((a: any) => a.tipo === 'comentario').length}</span>
           <span class="stat-label">Comentarios</span>
         </div>
         <div class="stat-item">
           <span class="stat-numero">{actividades.filter((a: any) => a.tipo === 'like').length}</span>
           <span class="stat-label">Me gusta</span>
         </div>
      </div>
    </div>

    <!-- ⏰ Timeline de actividades -->
    <div class="seccion timeline-actividades">
      <h2>⏰ Actividad reciente</h2>
      
      <div class="timeline">
        {#each actividades as actividad, index}
          <div class="timeline-item" class:ultima={index === actividades.length - 1}>
            <div class="timeline-marker actividad-{obtenerColorActividad(actividad.tipo)}">
              <span class="timeline-icono">{obtenerIconoActividad(actividad.tipo)}</span>
            </div>
            
            <div class="timeline-contenido">
              <div class="actividad-card">
                <div class="actividad-header">
                  <div class="actividad-tipo">
                    <span class="tipo-badge actividad-{obtenerColorActividad(actividad.tipo)}">
                      {obtenerIconoActividad(actividad.tipo)} {actividad.tipo_display || actividad.tipo}
                    </span>
                  </div>
                  <div class="actividad-tiempo">
                    {formatearTiempoRelativo(actividad.fecha_creacion)}
                  </div>
                </div>
                
                <div class="actividad-descripcion">
                  <p>{actividad.descripcion || actividad.titulo || 'Actividad sin descripción'}</p>
                  
                  {#if actividad.detalles}
                    <div class="actividad-detalles">
                      {actividad.detalles}
                    </div>
                  {/if}
                </div>
                
                {#if actividad.metadata}
                  <div class="actividad-metadata">
                    {#if actividad.metadata.curso_titulo}
                      <span class="metadata-item">📚 {actividad.metadata.curso_titulo}</span>
                    {/if}
                    {#if actividad.metadata.publicacion_titulo}
                      <span class="metadata-item">📝 {actividad.metadata.publicacion_titulo}</span>
                    {/if}
                  </div>
                {/if}
              </div>
            </div>
          </div>
        {/each}
      </div>
    </div>
    
  {:else}
    <!-- 🚫 Estado vacío -->
    <div class="estado-vacio">
      <div class="vacio-icono">📊</div>
      <h3>Sin actividad reciente</h3>
      <p>Este usuario aún no tiene actividad registrada en la plataforma.</p>
      <div class="vacio-decoracion">
        <span>🎵</span>
        <span>🎶</span>
        <span>🎼</span>
      </div>
    </div>
  {/if}
  
</div>

<style>
  .actividad-contenido {
    padding: 2rem;
    max-width: 800px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .seccion {
    background: #ffffff;
    border-radius: 16px;
    padding: 1.5rem;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.04);
    border: 1px solid #f1f5f9;
  }

  .seccion h2 {
    margin: 0 0 1.5rem 0;
    font-size: 1.5rem;
    font-weight: 700;
    color: #1f2937;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  /* Resumen de actividad */
  .resumen-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 1rem;
  }

  .stat-item {
    text-align: center;
    padding: 1rem;
    background: #f8fafc;
    border-radius: 12px;
    border: 1px solid #e2e8f0;
  }

  .stat-numero {
    display: block;
    font-size: 2rem;
    font-weight: 800;
    color: #3b82f6;
    margin-bottom: 0.25rem;
  }

  .stat-label {
    font-size: 0.875rem;
    color: #64748b;
    font-weight: 600;
  }

  /* Timeline */
  .timeline {
    position: relative;
    padding-left: 2rem;
  }

  .timeline::before {
    content: '';
    position: absolute;
    left: 1rem;
    top: 0;
    bottom: 0;
    width: 2px;
    background: linear-gradient(to bottom, #e2e8f0, #f1f5f9);
  }

  .timeline-item {
    position: relative;
    margin-bottom: 2rem;
  }

  .timeline-item.ultima {
    margin-bottom: 0;
  }

  .timeline-marker {
    position: absolute;
    left: -2rem;
    top: 0.5rem;
    width: 2rem;
    height: 2rem;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 3px solid white;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    z-index: 2;
  }

  .timeline-icono {
    font-size: 0.875rem;
  }

  .timeline-contenido {
    margin-left: 1rem;
  }

  .actividad-card {
    background: #f8fafc;
    border-radius: 12px;
    padding: 1.25rem;
    border: 1px solid #e2e8f0;
    transition: all 0.2s ease;
  }

  .actividad-card:hover {
    background: #f1f5f9;
    border-color: #cbd5e1;
    transform: translateX(4px);
  }

  .actividad-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.75rem;
    gap: 1rem;
  }

  .tipo-badge {
    display: inline-block;
    padding: 0.375rem 0.75rem;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: capitalize;
  }

  .actividad-tiempo {
    font-size: 0.875rem;
    color: #6b7280;
    font-weight: 500;
    white-space: nowrap;
  }

  .actividad-descripcion p {
    margin: 0 0 0.5rem 0;
    color: #374151;
    line-height: 1.5;
  }

  .actividad-detalles {
    font-size: 0.875rem;
    color: #6b7280;
    background: white;
    padding: 0.75rem;
    border-radius: 8px;
    border: 1px solid #e2e8f0;
    margin-top: 0.5rem;
  }

  .actividad-metadata {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-top: 0.75rem;
  }

  .metadata-item {
    font-size: 0.75rem;
    color: #6b7280;
    background: white;
    padding: 0.25rem 0.5rem;
    border-radius: 6px;
    border: 1px solid #e2e8f0;
  }

  /* Colores para diferentes tipos de actividad */
  .actividad-azul, .timeline-marker.actividad-azul { background: linear-gradient(135deg, #3b82f6, #1d4ed8); color: white; }
  .actividad-verde, .timeline-marker.actividad-verde { background: linear-gradient(135deg, #10b981, #059669); color: white; }
  .actividad-rojo, .timeline-marker.actividad-rojo { background: linear-gradient(135deg, #ef4444, #dc2626); color: white; }
  .actividad-purpura, .timeline-marker.actividad-purpura { background: linear-gradient(135deg, #8b5cf6, #7c3aed); color: white; }
  .actividad-naranja, .timeline-marker.actividad-naranja { background: linear-gradient(135deg, #f97316, #ea580c); color: white; }
  .actividad-dorado, .timeline-marker.actividad-dorado { background: linear-gradient(135deg, #f59e0b, #d97706); color: white; }
  .actividad-gris, .timeline-marker.actividad-gris { background: linear-gradient(135deg, #6b7280, #4b5563); color: white; }
  .actividad-rosa, .timeline-marker.actividad-rosa { background: linear-gradient(135deg, #ec4899, #db2777); color: white; }
  .actividad-cyan, .timeline-marker.actividad-cyan { background: linear-gradient(135deg, #06b6d4, #0891b2); color: white; }
  .actividad-indigo, .timeline-marker.actividad-indigo { background: linear-gradient(135deg, #6366f1, #4f46e5); color: white; }
  .actividad-teal, .timeline-marker.actividad-teal { background: linear-gradient(135deg, #14b8a6, #0d9488); color: white; }

  /* Estado vacío */
  .estado-vacio {
    text-align: center;
    padding: 4rem 2rem;
    color: #6b7280;
  }

  .vacio-icono {
    font-size: 4rem;
    margin-bottom: 1rem;
    opacity: 0.5;
  }

  .estado-vacio h3 {
    font-size: 1.5rem;
    color: #374151;
    margin-bottom: 0.5rem;
    font-weight: 600;
  }

  .estado-vacio p {
    font-size: 1rem;
    margin-bottom: 2rem;
    max-width: 400px;
    margin-left: auto;
    margin-right: auto;
    line-height: 1.6;
  }

  .vacio-decoracion {
    display: flex;
    justify-content: center;
    gap: 1rem;
    font-size: 2rem;
    opacity: 0.3;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .actividad-contenido {
      padding: 1rem;
      gap: 1.5rem;
    }

    .seccion {
      padding: 1rem;
    }

    .seccion h2 {
      font-size: 1.25rem;
    }

    .resumen-stats {
      grid-template-columns: repeat(2, 1fr);
    }

    .stat-numero {
      font-size: 1.5rem;
    }

    .timeline {
      padding-left: 1.5rem;
    }

    .timeline-marker {
      left: -1.5rem;
      width: 1.5rem;
      height: 1.5rem;
    }

    .timeline-icono {
      font-size: 0.75rem;
    }

    .actividad-header {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.5rem;
    }

    .actividad-tiempo {
      align-self: flex-end;
    }
  }

  @media (max-width: 480px) {
    .actividad-contenido {
      padding: 0.5rem;
    }

    .seccion {
      padding: 0.75rem;
    }

    .resumen-stats {
      grid-template-columns: 1fr;
    }

    .estado-vacio {
      padding: 3rem 1rem;
    }

    .vacio-icono {
      font-size: 3rem;
    }
  }
</style> 