<script lang="ts">
  import { onMount } from 'svelte';
  import { createClient } from '@supabase/supabase-js';

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  const supabase = createClient(supabaseUrl, supabaseKey);

  // Estados principales
  let cargando = true;
  let stats = {
    totalCursos: 0,
    totalTutoriales: 0,
    cursosPublicados: 0,
    tutorialesPublicados: 0,
    cursosRecientes: [] as any[],
    tutorialesRecientes: [] as any[]
  };

  onMount(() => {
    cargarEstadisticas();
    // Auto-refresh cada 5 minutos
    const interval = setInterval(cargarEstadisticas, 5 * 60 * 1000);
    return () => clearInterval(interval);
  });

  async function cargarEstadisticas() {
    try {
      const [cursosRes, tutorialesRes] = await Promise.all([
        supabase.from('cursos').select('*').order('created_at', { ascending: false }),
        supabase.from('tutoriales').select('*').order('created_at', { ascending: false })
      ]);

      const cursos = cursosRes.data || [];
      const tutoriales = tutorialesRes.data || [];

      stats = {
        totalCursos: cursos.length,
        totalTutoriales: tutoriales.length,
        cursosPublicados: cursos.filter(c => c.estado === 'publicado').length,
        tutorialesPublicados: tutoriales.filter(t => t.estado === 'publicado').length,
        cursosRecientes: cursos.slice(0, 3),
        tutorialesRecientes: tutoriales.slice(0, 3)
      };
    } catch (error) {
      console.error('Error cargando estadísticas:', error);
    } finally {
      cargando = false;
    }
  }

  function formatearFecha(fecha: string) {
    const ahora = new Date();
    const fechaItem = new Date(fecha);
    const diffTiempo = ahora.getTime() - fechaItem.getTime();
    const diffDias = Math.ceil(diffTiempo / (1000 * 3600 * 24));

    if (diffDias === 1) return 'Ayer';
    if (diffDias < 7) return `Hace ${diffDias} días`;
    return fechaItem.toLocaleDateString('es-ES', { 
      month: 'short', 
      day: 'numeric' 
    });
  }
</script>

<div class="sidebar-resumen">
  {#if cargando}
    <div class="loading">
      <div class="skeleton"></div>
      <div class="skeleton"></div>
      <div class="skeleton"></div>
    </div>
  {:else}
    <!-- Panel de Control -->
    <div class="panel-control">
      <div class="panel-header">
        <h3>📊 Panel de Control</h3>
        <span class="actualizado">🔄 Actualizado ahora</span>
      </div>
    </div>

    <!-- Resumen General -->
    <div class="widget">
      <h4>📈 Resumen General</h4>
      
      <div class="stat-item">
        <div class="stat-icon">📚</div>
        <div class="stat-info">
          <span class="stat-number">{stats.totalCursos}</span>
          <span class="stat-label">Cursos Totales</span>
          <span class="stat-trend">📈 +0 esta semana</span>
        </div>
      </div>

      <div class="stat-item">
        <div class="stat-icon">🎥</div>
        <div class="stat-info">
          <span class="stat-number">{stats.totalTutoriales}</span>
          <span class="stat-label">Tutoriales Totales</span>
          <span class="stat-trend">📈 +0 esta semana</span>
        </div>
      </div>

      <div class="stat-item">
        <div class="stat-icon">👥</div>
        <div class="stat-info">
          <span class="stat-number">0</span>
          <span class="stat-label">Estudiantes Activos</span>
          <span class="stat-trend">📈 +0 esta semana</span>
        </div>
      </div>
    </div>

    <!-- Progreso de Publicación -->
    <div class="widget">
      <h4>🎯 Progreso de Publicación</h4>
      
      {#if stats}
        {@const totalContenido = stats.totalCursos + stats.totalTutoriales}
        {@const totalPublicados = stats.cursosPublicados + stats.tutorialesPublicados}
        {@const porcentaje = totalContenido > 0 ? Math.round((totalPublicados / totalContenido) * 100) : 0}
        
        <div class="progreso-principal">
          <span class="progreso-numero">{porcentaje}%</span>
          <span class="progreso-texto">Contenido publicado</span>
        </div>
        
        <div class="barra-progreso">
          <div class="progreso-fill" style="width: {porcentaje}%"></div>
        </div>
        
        <div class="progreso-detalles">
          <div class="detalle-item">
            <span class="bullet green"></span>
            <span>{stats.cursosPublicados} cursos publicados</span>
          </div>
          <div class="detalle-item">
            <span class="bullet blue"></span>
            <span>{stats.tutorialesPublicados} tutoriales publicados</span>
          </div>
        </div>
      {/if}
    </div>

    <!-- Actividad Reciente -->
    <div class="widget">
      <h4>🕐 Actividad Reciente</h4>
      
      {#if stats.tutorialesRecientes.length > 0}
        <div class="actividad-seccion">
          <h5>🎥 Tutoriales recientes</h5>
          {#each stats.tutorialesRecientes as tutorial}
            <div class="item-reciente">
              <div class="item-info">
                <span class="item-titulo">{tutorial.titulo}</span>
                <span class="item-fecha">{formatearFecha(tutorial.created_at)}</span>
              </div>
              <span class="item-estado {tutorial.estado === 'publicado' ? 'publicado' : 'borrador'}">
                {tutorial.estado === 'publicado' ? '✅' : '📝'}
              </span>
            </div>
          {/each}
        </div>
      {/if}

      {#if stats.cursosRecientes.length > 0}
        <div class="actividad-seccion">
          <h5>📚 Cursos recientes</h5>
          {#each stats.cursosRecientes as curso}
            <div class="item-reciente">
              <div class="item-info">
                <span class="item-titulo">{curso.titulo}</span>
                <span class="item-fecha">{formatearFecha(curso.created_at)}</span>
              </div>
              <span class="item-estado {curso.estado === 'publicado' ? 'publicado' : 'borrador'}">
                {curso.estado === 'publicado' ? '✅' : '📝'}
              </span>
            </div>
          {/each}
        </div>
      {/if}
      
      <div class="refresh-info">
        🔄 Datos en tiempo real
      </div>
    </div>
  {/if}
</div>

<style>
  .sidebar-resumen {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  /* Loading */
  .loading {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .skeleton {
    height: 60px;
    background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
    background-size: 200% 100%;
    animation: loading 1.5s infinite;
    border-radius: 8px;
  }

  @keyframes loading {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }

  /* Panel de Control */
  .panel-control {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1.5rem;
    border-radius: 12px;
    text-align: center;
  }

  .panel-header h3 {
    font-size: 1.1rem;
    font-weight: 600;
    margin: 0 0 0.5rem 0;
  }

  .actualizado {
    font-size: 0.8rem;
    opacity: 0.8;
  }

  /* Widgets */
  .widget {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 12px;
    padding: 1.5rem;
  }

  .widget h4 {
    font-size: 1rem;
    font-weight: 600;
    margin: 0 0 1rem 0;
    color: #374151;
  }

  .widget h5 {
    font-size: 0.9rem;
    font-weight: 500;
    margin: 0 0 0.75rem 0;
    color: #6b7280;
  }

  /* Stats */
  .stat-item {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem 0;
    border-bottom: 1px solid #f3f4f6;
  }

  .stat-item:last-child {
    border-bottom: none;
  }

  .stat-icon {
    font-size: 1.5rem;
    width: 40px;
    height: 40px;
    background: #f8fafc;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .stat-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .stat-number {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1f2937;
  }

  .stat-label {
    font-size: 0.8rem;
    color: #6b7280;
  }

  .stat-trend {
    font-size: 0.75rem;
    color: #10b981;
  }

  /* Progreso */
  .progreso-principal {
    text-align: center;
    margin-bottom: 1rem;
  }

  .progreso-numero {
    font-size: 2.5rem;
    font-weight: 700;
    color: #667eea;
    display: block;
    line-height: 1;
  }

  .progreso-texto {
    font-size: 0.9rem;
    color: #6b7280;
  }

  .barra-progreso {
    width: 100%;
    height: 8px;
    background: #e5e7eb;
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: 1rem;
  }

  .progreso-fill {
    height: 100%;
    background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
    transition: width 0.3s ease;
  }

  .progreso-detalles {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .detalle-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.85rem;
    color: #6b7280;
  }

  .bullet {
    width: 8px;
    height: 8px;
    border-radius: 50%;
  }

  .bullet.green {
    background: #10b981;
  }

  .bullet.blue {
    background: #3b82f6;
  }

  /* Actividad Reciente */
  .actividad-seccion {
    margin-bottom: 1.5rem;
  }

  .actividad-seccion:last-of-type {
    margin-bottom: 1rem;
  }

  .item-reciente {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.75rem 0;
    border-bottom: 1px solid #f3f4f6;
  }

  .item-reciente:last-child {
    border-bottom: none;
  }

  .item-info {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    flex: 1;
  }

  .item-titulo {
    font-weight: 500;
    color: #374151;
    font-size: 0.85rem;
    line-height: 1.3;
  }

  .item-fecha {
    font-size: 0.75rem;
    color: #9ca3af;
  }

  .item-estado {
    font-size: 1rem;
    margin-left: 0.5rem;
  }

  .refresh-info {
    text-align: center;
    font-size: 0.75rem;
    color: #9ca3af;
    padding-top: 1rem;
    border-top: 1px solid #f3f4f6;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .sidebar-resumen {
      gap: 1rem;
    }

    .widget {
      padding: 1rem;
    }

    .panel-control {
      padding: 1rem;
    }

    .stat-item {
      padding: 0.75rem 0;
    }

    .stat-icon {
      width: 35px;
      height: 35px;
      font-size: 1.2rem;
    }

    .stat-number {
      font-size: 1.2rem;
    }

    .progreso-numero {
      font-size: 2rem;
    }
  }
</style>
