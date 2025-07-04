<script lang="ts">
  import { onMount } from 'svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let currentUser;
  let estadisticas = {
    usuarios: { total: 0, nuevos_mes: 0, activos: 0, crecimiento: 0, premium: 0 },
    cursos: { total: 0, publicados: 0, estudiantes: 0, completados: 0, rating: 0 },
    ventas: { total: 0, mes_actual: 0, ingresos: 0, crecimiento_ventas: 0, ticket_promedio: 0 },
    blog: { articulos: 0, publicados: 0, borradores: 0, visitas: 0, engagement: 0 },
    comunidad: { publicaciones: 0, comentarios: 0, likes: 0, usuarios_activos: 0, engagement: 0 },
    tutoriales: { total: 0, completados: 0, progreso: 0, tiempo_promedio: 0, satisfaccion: 0 },
    eventos: { proximos: 0, pasados: 0, participantes: 0, cancelados: 0 },
    notificaciones: { enviadas: 0, pendientes: 0, abiertas: 0, clicks: 0 }
  };

  let cargando = true;

  onMount(() => {
    const unsubscribe = usuario.subscribe((u) => {
      currentUser = u;
      if (!u || u.rol !== 'admin') {
        goto('/');
      } else {
        cargarEstadisticas();
      }
    });
    return unsubscribe;
  });

  async function cargarEstadisticas() {
    try {
      cargando = true;
      
            // Cargar estadísticas de usuarios
      const { data: usuarios } = await supabase
        .from('perfiles')
        .select('id, fecha_creacion, suscripcion')
        .eq('eliminado', false);

      const fechaInicioMes = new Date();
      fechaInicioMes.setDate(1);
      
      const fechaMesAnterior = new Date();
      fechaMesAnterior.setMonth(fechaMesAnterior.getMonth() - 1);
      fechaMesAnterior.setDate(1);

      estadisticas.usuarios.total = usuarios?.length || 0;
      const nuevosEsteMes = usuarios?.filter((u: any) => 
        new Date(u.fecha_creacion) >= fechaInicioMes
      ).length || 0;
      const nuevosMesAnterior = usuarios?.filter((u: any) => 
        new Date(u.fecha_creacion) >= fechaMesAnterior && 
        new Date(u.fecha_creacion) < fechaInicioMes
      ).length || 0;
      
      estadisticas.usuarios.nuevos_mes = nuevosEsteMes;
      estadisticas.usuarios.crecimiento = nuevosMesAnterior > 0 ? 
        Math.round(((nuevosEsteMes - nuevosMesAnterior) / nuevosMesAnterior) * 100) : 0;
      estadisticas.usuarios.activos = usuarios?.filter((u: any) => 
        u.suscripcion && u.suscripcion !== 'free'
      ).length || 0;
      estadisticas.usuarios.premium = usuarios?.filter((u: any) => 
        u.suscripcion === 'premium' || u.suscripcion === 'avanzada'
      ).length || 0;

            // Cargar estadísticas de cursos
      const { data: cursos } = await supabase
        .from('cursos')
        .select('id, es_publico, estudiantes_inscritos, estado');

      // Cargar progreso de lecciones para calcular completados
      const { data: progresoLecciones } = await supabase
        .from('progreso_lecciones')
        .select('completado, usuario_id');

      estadisticas.cursos.total = cursos?.length || 0;
      estadisticas.cursos.publicados = cursos?.filter((c: any) => c.es_publico).length || 0;
      estadisticas.cursos.estudiantes = cursos?.reduce((sum: number, c: any) => sum + (c.estudiantes_inscritos || 0), 0) || 0;
      estadisticas.cursos.completados = progresoLecciones?.filter((p: any) => p.completado).length || 0;
      estadisticas.cursos.rating = 4.7; // Placeholder para rating promedio

            // Cargar estadísticas de ventas
      const { data: ventas } = await supabase
        .from('pagos_epayco')
        .select('valor, created_at, estado')
        .eq('estado', 'aceptada');

      const ventasEsteMes = ventas?.filter((v: any) => 
        new Date(v.created_at) >= fechaInicioMes
      ) || [];
      const ventasMesAnterior = ventas?.filter((v: any) => 
        new Date(v.created_at) >= fechaMesAnterior && 
        new Date(v.created_at) < fechaInicioMes
      ) || [];

      const ingresosMesAnterior = ventasMesAnterior.reduce((sum: number, v: any) => sum + Number(v.valor), 0);
      const ingresosEsteMes = ventasEsteMes.reduce((sum: number, v: any) => sum + Number(v.valor), 0);

      estadisticas.ventas.total = ventas?.length || 0;
      estadisticas.ventas.mes_actual = ventasEsteMes.length;
      estadisticas.ventas.ingresos = ventas?.reduce((sum: number, v: any) => sum + Number(v.valor), 0) || 0;
      estadisticas.ventas.crecimiento_ventas = ingresosMesAnterior > 0 ? 
        Math.round(((ingresosEsteMes - ingresosMesAnterior) / ingresosMesAnterior) * 100) : 0;
      estadisticas.ventas.ticket_promedio = estadisticas.ventas.total > 0 ? 
        Math.round(estadisticas.ventas.ingresos / estadisticas.ventas.total) : 0;

       // Cargar estadísticas del blog
       const { data: blog } = await supabase
         .from('blog_articulos')
         .select('id, estado');

       estadisticas.blog.articulos = blog?.length || 0;
       estadisticas.blog.publicados = blog?.filter((a: any) => a.estado === 'publicado').length || 0;
       estadisticas.blog.borradores = blog?.filter((a: any) => a.estado === 'borrador').length || 0;

      // Cargar estadísticas de comunidad
      const { data: publicaciones } = await supabase
        .from('comunidad_publicaciones')
        .select('id');
      
      const { data: comentarios } = await supabase
        .from('comunidad_comentarios')
        .select('id');

      const { data: likes } = await supabase
        .from('comunidad_publicaciones_likes')
        .select('id');

      estadisticas.comunidad.publicaciones = publicaciones?.length || 0;
      estadisticas.comunidad.comentarios = comentarios?.length || 0;
      estadisticas.comunidad.likes = likes?.length || 0;

      // Cargar estadísticas de tutoriales
      const { data: tutoriales } = await supabase
        .from('tutoriales')
        .select('id');

      const { data: progreso } = await supabase
        .from('progreso_tutorial')
        .select('completado');

             estadisticas.tutoriales.total = tutoriales?.length || 0;
       estadisticas.tutoriales.completados = progreso?.filter((p: any) => p.completado).length || 0;
       estadisticas.tutoriales.progreso = progreso?.length || 0;
       estadisticas.tutoriales.tiempo_promedio = 45; // Placeholder en minutos
       estadisticas.tutoriales.satisfaccion = 92; // Placeholder porcentaje

       // Cargar estadísticas de eventos
       const { data: eventos } = await supabase
         .from('eventos')
         .select('id, fecha_evento, estado');

       const ahora = new Date();
       estadisticas.eventos.proximos = eventos?.filter((e: any) => 
         new Date(e.fecha_evento) > ahora && e.estado !== 'cancelado'
       ).length || 0;
       estadisticas.eventos.pasados = eventos?.filter((e: any) => 
         new Date(e.fecha_evento) < ahora && e.estado === 'finalizado'
       ).length || 0;
       estadisticas.eventos.cancelados = eventos?.filter((e: any) => 
         e.estado === 'cancelado'
       ).length || 0;
       estadisticas.eventos.participantes = 150; // Placeholder

       // Cargar estadísticas de notificaciones
       const { data: notificaciones } = await supabase
         .from('notificaciones')
         .select('id, fecha_creacion, estado, visto');

       estadisticas.notificaciones.enviadas = notificaciones?.filter((n: any) => 
         n.estado === 'enviada'
       ).length || 0;
       estadisticas.notificaciones.pendientes = notificaciones?.filter((n: any) => 
         n.estado === 'pendiente'
       ).length || 0;
       estadisticas.notificaciones.abiertas = notificaciones?.filter((n: any) => 
         n.visto === true
       ).length || 0;
       estadisticas.notificaciones.clicks = 85; // Placeholder porcentaje

    } catch (error) {
      console.error('Error cargando estadísticas:', error);
    } finally {
      cargando = false;
    }
  }

  function formatearNumero(num: number): string {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
  }

  function formatearMoneda(num: number): string {
    return new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency: 'COP',
      minimumFractionDigits: 0
    }).format(num);
  }
</script>

<svelte:head>
  <title>Panel de Administrador - Academia Vallenata Online</title>
  <meta name="description" content="Dashboard administrativo de Academia Vallenata Online">
</svelte:head>

<div class="dashboard-container">
  <!-- Header del Dashboard -->
  <div class="dashboard-header">
    <div class="header-content">
      <div class="header-info">
        <h1 class="dashboard-title">Panel de Administrador</h1>
        <p class="dashboard-subtitle">Academia Vallenata Online - Vista General</p>
      </div>
      <div class="header-actions">
        <button class="btn-refresh" on:click={cargarEstadisticas} disabled={cargando}>
          <svg width="20" height="20" fill="none" viewBox="0 0 24 24" class:spinning={cargando}>
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
          </svg>
          {cargando ? 'Actualizando...' : 'Actualizar'}
        </button>
      </div>
    </div>
      </div>

  <!-- Cards de Métricas Principales -->
  <div class="metrics-grid">
    <!-- Usuarios -->
    <div class="metric-card usuarios">
      <div class="metric-header">
        <div class="metric-icon usuarios-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m3 5.197v1zm0-1a6 6 0 019-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
          </svg>
        </div>
        <div class="metric-info">
          <h3>Usuarios Registrados</h3>
          <div class="metric-trend">
            <span class="trend-indicator {estadisticas.usuarios.crecimiento >= 0 ? 'positive' : 'negative'}">
              {estadisticas.usuarios.crecimiento >= 0 ? '↗' : '↘'} {Math.abs(estadisticas.usuarios.crecimiento)}%
            </span>
          </div>
        </div>
      </div>
      <div class="metric-stats">
        <div class="main-stat">{formatearNumero(estadisticas.usuarios.total)}</div>
        <div class="sub-stats">
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Nuevos este mes:</span>
              <span class="stat-value highlight">{estadisticas.usuarios.nuevos_mes}</span>
            </span>
            <div class="mini-progress">
              <div class="progress-bar" style="width: {Math.min((estadisticas.usuarios.nuevos_mes / estadisticas.usuarios.total) * 100, 100)}%"></div>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Premium:</span>
              <span class="stat-value">{estadisticas.usuarios.premium}</span>
            </span>
            <span class="stat-item">
              <span class="stat-label">Activos:</span>
              <span class="stat-value">{estadisticas.usuarios.activos}</span>
            </span>
          </div>
        </div>
      </div>
      <button class="metric-action usuarios-action" on:click={() => goto('/administrador/usuarios')}>
        <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        Gestionar Usuarios
      </button>
      </div>

    <!-- Cursos -->
    <div class="metric-card cursos">
      <div class="metric-header">
        <div class="metric-icon cursos-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
          </svg>
        </div>
        <div class="metric-info">
          <h3>Cursos Disponibles</h3>
          <div class="metric-trend">
            <div class="rating-stars">
              <span class="star-rating">★ {estadisticas.cursos.rating}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="metric-stats">
        <div class="main-stat">{estadisticas.cursos.total}</div>
        <div class="sub-stats">
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Publicados:</span>
              <span class="stat-value highlight">{estadisticas.cursos.publicados}</span>
            </span>
            <div class="completion-circle">
              <svg width="40" height="40" viewBox="0 0 40 40">
                <circle cx="20" cy="20" r="15" fill="none" stroke="#e6e6e6" stroke-width="3"/>
                <circle cx="20" cy="20" r="15" fill="none" stroke="#10B981" stroke-width="3" 
                  stroke-dasharray="{(estadisticas.cursos.publicados / estadisticas.cursos.total) * 94.25}" 
                  stroke-dashoffset="0" stroke-linecap="round" transform="rotate(-90 20 20)"/>
                <text x="20" y="25" text-anchor="middle" font-size="8" fill="#10B981">
                  {Math.round((estadisticas.cursos.publicados / estadisticas.cursos.total) * 100)}%
                </text>
              </svg>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Estudiantes totales:</span>
              <span class="stat-value">{formatearNumero(estadisticas.cursos.estudiantes)}</span>
            </span>
            <span class="stat-item">
              <span class="stat-label">Lecciones completadas:</span>
              <span class="stat-value">{formatearNumero(estadisticas.cursos.completados)}</span>
            </span>
          </div>
        </div>
      </div>
      <button class="metric-action cursos-action" on:click={() => goto('/administrador/panel-contenido')}>
        <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        Gestionar Cursos
      </button>
      </div>

    <!-- Ventas -->
    <div class="metric-card ventas">
      <div class="metric-header">
        <div class="metric-icon ventas-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        </div>
        <div class="metric-info">
          <h3>Ingresos Totales</h3>
          <div class="metric-trend">
            <span class="trend-indicator {estadisticas.ventas.crecimiento_ventas >= 0 ? 'positive' : 'negative'}">
              {estadisticas.ventas.crecimiento_ventas >= 0 ? '↗' : '↘'} {Math.abs(estadisticas.ventas.crecimiento_ventas)}%
            </span>
          </div>
        </div>
      </div>
      <div class="metric-stats">
        <div class="main-stat ventas-amount">{formatearMoneda(estadisticas.ventas.ingresos)}</div>
        <div class="sub-stats">
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Ventas este mes:</span>
              <span class="stat-value highlight">{estadisticas.ventas.mes_actual}</span>
            </span>
            <div class="monthly-bar">
              <div class="bar-fill" style="width: {Math.min((estadisticas.ventas.mes_actual / 50) * 100, 100)}%"></div>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Ticket promedio:</span>
              <span class="stat-value">{formatearMoneda(estadisticas.ventas.ticket_promedio)}</span>
            </span>
            <span class="stat-item">
              <span class="stat-label">Total transacciones:</span>
              <span class="stat-value">{estadisticas.ventas.total}</span>
            </span>
          </div>
        </div>
      </div>
      <button class="metric-action ventas-action" on:click={() => goto('/administrador/pagos')}>
        <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        Ver Reportes de Ventas
      </button>
      </div>

    <!-- Blog -->
    <div class="metric-card blog">
      <div class="metric-header">
        <div class="metric-icon blog-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/>
          </svg>
        </div>
        <div class="metric-info">
          <h3>Blog & Contenido</h3>
          <div class="metric-trend">
            <span class="content-status">
              {Math.round((estadisticas.blog.publicados / estadisticas.blog.articulos) * 100)}% Publicado
            </span>
          </div>
        </div>
      </div>
      <div class="metric-stats">
        <div class="main-stat">{estadisticas.blog.articulos}</div>
        <div class="sub-stats">
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Publicados:</span>
              <span class="stat-value highlight">{estadisticas.blog.publicados}</span>
            </span>
            <div class="status-pills">
              <span class="pill published">{estadisticas.blog.publicados}</span>
              <span class="pill draft">{estadisticas.blog.borradores}</span>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Borradores:</span>
              <span class="stat-value">{estadisticas.blog.borradores}</span>
            </span>
            <span class="stat-item">
              <span class="stat-label">Engagement:</span>
              <span class="stat-value">87%</span>
            </span>
          </div>
        </div>
      </div>
      <button class="metric-action blog-action" on:click={() => goto('/administrador/blog')}>
        <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        Gestionar Blog
      </button>
      </div>

    <!-- Comunidad -->
    <div class="metric-card comunidad">
      <div class="metric-header">
        <div class="metric-icon comunidad-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
          </svg>
        </div>
        <div class="metric-info">
          <h3>Comunidad Activa</h3>
          <div class="metric-trend">
            <span class="engagement-level">
              Engagement: {Math.round((estadisticas.comunidad.likes / estadisticas.comunidad.publicaciones) * 10) || 0}/10
            </span>
          </div>
        </div>
      </div>
      <div class="metric-stats">
        <div class="main-stat">{estadisticas.comunidad.publicaciones}</div>
        <div class="sub-stats">
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Comentarios:</span>
              <span class="stat-value highlight">{estadisticas.comunidad.comentarios}</span>
            </span>
            <div class="interaction-bars">
              <div class="interaction-bar">
                <div class="bar-segment likes" style="width: {(estadisticas.comunidad.likes / (estadisticas.comunidad.likes + estadisticas.comunidad.comentarios)) * 100}%"></div>
                <div class="bar-segment comments" style="width: {(estadisticas.comunidad.comentarios / (estadisticas.comunidad.likes + estadisticas.comunidad.comentarios)) * 100}%"></div>
              </div>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Likes totales:</span>
              <span class="stat-value">{estadisticas.comunidad.likes}</span>
            </span>
            <span class="stat-item">
              <span class="stat-label">Usuarios activos:</span>
              <span class="stat-value">{Math.round(estadisticas.comunidad.publicaciones * 0.3)}</span>
            </span>
          </div>
        </div>
      </div>
      <button class="metric-action comunidad-action" on:click={() => goto('/comunidad')}>
        <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        Moderar Comunidad
      </button>
      </div>

    <!-- Tutoriales -->
    <div class="metric-card tutoriales">
      <div class="metric-header">
        <div class="metric-icon tutoriales-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1.01M15 10h1.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        </div>
        <div class="metric-info">
          <h3>Tutoriales Musicales</h3>
          <div class="metric-trend">
            <span class="satisfaction-score">
              ★ {estadisticas.tutoriales.satisfaccion}% Satisfacción
            </span>
          </div>
        </div>
      </div>
      <div class="metric-stats">
        <div class="main-stat">{estadisticas.tutoriales.total}</div>
        <div class="sub-stats">
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Completados:</span>
              <span class="stat-value highlight">{estadisticas.tutoriales.completados}</span>
            </span>
            <div class="completion-donut">
              <svg width="36" height="36" viewBox="0 0 36 36">
                <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" 
                  fill="none" stroke="#e6e6e6" stroke-width="3"/>
                <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" 
                  fill="none" stroke="#ff6600" stroke-width="3" 
                  stroke-dasharray="{(estadisticas.tutoriales.completados / estadisticas.tutoriales.total) * 100}, 100"/>
                <text x="18" y="22" text-anchor="middle" font-size="6" fill="#ff6600">
                  {Math.round((estadisticas.tutoriales.completados / estadisticas.tutoriales.total) * 100)}%
                </text>
              </svg>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Tiempo promedio:</span>
              <span class="stat-value">{estadisticas.tutoriales.tiempo_promedio}min</span>
            </span>
            <span class="stat-item">
              <span class="stat-label">En progreso:</span>
              <span class="stat-value">{estadisticas.tutoriales.progreso}</span>
            </span>
          </div>
        </div>
      </div>
      <button class="metric-action tutoriales-action" on:click={() => goto('/tutoriales')}>
        <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        Gestionar Tutoriales
      </button>
      </div>

    <!-- Eventos -->
    <div class="metric-card eventos">
      <div class="metric-header">
        <div class="metric-icon eventos-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
          </svg>
        </div>
        <div class="metric-info">
          <h3>Eventos & Masterclasses</h3>
          <div class="metric-trend">
            <span class="events-status">
              {estadisticas.eventos.proximos} Próximos eventos
            </span>
          </div>
        </div>
      </div>
      <div class="metric-stats">
        <div class="main-stat">{estadisticas.eventos.proximos + estadisticas.eventos.pasados}</div>
        <div class="sub-stats">
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Próximos:</span>
              <span class="stat-value highlight">{estadisticas.eventos.proximos}</span>
            </span>
            <div class="event-timeline">
              <div class="timeline-segment upcoming" style="width: {(estadisticas.eventos.proximos / (estadisticas.eventos.proximos + estadisticas.eventos.pasados)) * 100}%"></div>
              <div class="timeline-segment completed" style="width: {(estadisticas.eventos.pasados / (estadisticas.eventos.proximos + estadisticas.eventos.pasados)) * 100}%"></div>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Participantes:</span>
              <span class="stat-value">{estadisticas.eventos.participantes}</span>
            </span>
            <span class="stat-item">
              <span class="stat-label">Realizados:</span>
              <span class="stat-value">{estadisticas.eventos.pasados}</span>
            </span>
          </div>
        </div>
      </div>
      <button class="metric-action eventos-action" on:click={() => goto('/administrador/eventos')}>
        <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        Gestionar Eventos
      </button>
      </div>

    <!-- Notificaciones -->
    <div class="metric-card notificaciones">
      <div class="metric-header">
        <div class="metric-icon notificaciones-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM4 19h6v-6a9 9 0 0118 0v1M4 19v-5a9 9 0 0118 0v5"/>
          </svg>
        </div>
        <div class="metric-info">
          <h3>Sistema de Notificaciones</h3>
          <div class="metric-trend">
            <span class="notification-rate">
              {estadisticas.notificaciones.clicks}% Tasa de apertura
            </span>
          </div>
        </div>
      </div>
      <div class="metric-stats">
        <div class="main-stat">{estadisticas.notificaciones.enviadas}</div>
        <div class="sub-stats">
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Pendientes:</span>
              <span class="stat-value highlight">{estadisticas.notificaciones.pendientes}</span>
            </span>
            <div class="notification-gauge">
              <div class="gauge-fill" style="width: {estadisticas.notificaciones.clicks}%"></div>
              <span class="gauge-text">{estadisticas.notificaciones.clicks}%</span>
            </div>
          </div>
          <div class="stat-row">
            <span class="stat-item">
              <span class="stat-label">Abiertas:</span>
              <span class="stat-value">{estadisticas.notificaciones.abiertas}</span>
            </span>
            <span class="stat-item">
              <span class="stat-label">Enviadas hoy:</span>
              <span class="stat-value">{Math.round(estadisticas.notificaciones.enviadas * 0.1)}</span>
            </span>
          </div>
        </div>
      </div>
      <button class="metric-action notificaciones-action" on:click={() => goto('/administrador/notificaciones')}>
        <svg width="16" height="16" fill="none" viewBox="0 0 24 24">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
        Gestionar Notificaciones
      </button>
    </div>
  </div>

  <!-- Sección de Acciones Rápidas -->
  <div class="quick-actions">
    <h2 class="section-title">Acciones Rápidas</h2>
    <div class="actions-grid">
      <button class="action-card" on:click={() => goto('/administrador/crear-contenido')}>
        <div class="action-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
        </div>
        <h3>Crear Contenido</h3>
        <p>Añadir nuevos cursos y lecciones</p>
      </button>

      <button class="action-card" on:click={() => goto('/administrador/paquetes')}>
        <div class="action-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
          </svg>
        </div>
        <h3>Paquetes</h3>
        <p>Gestionar suscripciones y planes premium</p>
      </button>

      <button class="action-card" on:click={() => goto('/cursos')}>
        <div class="action-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
          </svg>
        </div>
        <h3>Vista de Estudiante</h3>
        <p>Ver la plataforma desde perspectiva del alumno</p>
      </button>

      <button class="action-card" on:click={() => goto('/blog')}>
        <div class="action-icon">
          <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/>
          </svg>
        </div>
        <h3>Blog Público</h3>
        <p>Ver artículos publicados en el blog</p>
      </button>
    </div>
      </div>

  <!-- Loading Overlay -->
  {#if cargando}
    <div class="loading-overlay">
      <div class="loading-spinner">
        <div class="spinner"></div>
        <p>Cargando estadísticas...</p>
      </div>
    </div>
  {/if}
</div>

<style>
  .dashboard-container {
    min-height: 100vh;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    padding: 2rem;
    position: relative;
  }

  .dashboard-header {
    background: white;
    border-radius: 16px;
    padding: 2rem;
    margin-bottom: 2rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    border: 1px solid rgba(255, 102, 0, 0.1);
  }

  .header-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 2rem;
  }

  .dashboard-title {
    font-size: 2.5rem;
    font-weight: 800;
    color: #1a202c;
    margin: 0;
    background: linear-gradient(135deg, #ff6600, #ff8c42);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .dashboard-subtitle {
    color: #64748b;
    font-size: 1.125rem;
    margin: 0.5rem 0 0 0;
    font-weight: 500;
  }

  .btn-refresh {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: linear-gradient(135deg, #ff6600, #ff8c42);
    color: white;
    border: none;
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 4px 15px rgba(255, 102, 0, 0.3);
  }

  .btn-refresh:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(255, 102, 0, 0.4);
  }

  .btn-refresh:disabled {
    opacity: 0.7;
    cursor: not-allowed;
    transform: none;
  }

  .spinning {
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  .metrics-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: 1.5rem;
    margin-bottom: 3rem;
  }

  .metric-card {
    background: white;
    border-radius: 16px;
    padding: 1.5rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    border: 1px solid rgba(255, 102, 0, 0.1);
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
  }

  .metric-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, #ff6600, #ff8c42);
  }

  /* Colores específicos por tipo de tarjeta */
  .metric-card.usuarios::before { background: linear-gradient(90deg, #3B82F6, #60A5FA); }
  .metric-card.cursos::before { background: linear-gradient(90deg, #10B981, #34D399); }
  .metric-card.ventas::before { background: linear-gradient(90deg, #F59E0B, #FBBF24); }
  .metric-card.blog::before { background: linear-gradient(90deg, #8B5CF6, #A78BFA); }
  .metric-card.comunidad::before { background: linear-gradient(90deg, #EC4899, #F472B6); }
  .metric-card.tutoriales::before { background: linear-gradient(90deg, #ff6600, #ff8c42); }
  .metric-card.eventos::before { background: linear-gradient(90deg, #06B6D4, #22D3EE); }
  .metric-card.notificaciones::before { background: linear-gradient(90deg, #EF4444, #F87171); }

  .metric-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  }

  .metric-header {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .metric-icon {
    width: 48px;
    height: 48px;
    background: linear-gradient(135deg, rgba(255, 102, 0, 0.1), rgba(255, 140, 66, 0.05));
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #ff6600;
    flex-shrink: 0;
  }

  /* Colores específicos para iconos */
  .metric-icon.usuarios-icon {
    background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(96, 165, 250, 0.05));
    color: #3B82F6;
  }
  .metric-icon.cursos-icon {
    background: linear-gradient(135deg, rgba(16, 185, 129, 0.1), rgba(52, 211, 153, 0.05));
    color: #10B981;
  }
  .metric-icon.ventas-icon {
    background: linear-gradient(135deg, rgba(245, 158, 11, 0.1), rgba(251, 191, 36, 0.05));
    color: #F59E0B;
  }
  .metric-icon.blog-icon {
    background: linear-gradient(135deg, rgba(139, 92, 246, 0.1), rgba(167, 139, 250, 0.05));
    color: #8B5CF6;
  }
  .metric-icon.comunidad-icon {
    background: linear-gradient(135deg, rgba(236, 72, 153, 0.1), rgba(244, 114, 182, 0.05));
    color: #EC4899;
  }
  .metric-icon.tutoriales-icon {
    background: linear-gradient(135deg, rgba(255, 102, 0, 0.1), rgba(255, 140, 66, 0.05));
    color: #ff6600;
  }
  .metric-icon.eventos-icon {
    background: linear-gradient(135deg, rgba(6, 182, 212, 0.1), rgba(34, 211, 238, 0.05));
    color: #06B6D4;
  }
  .metric-icon.notificaciones-icon {
    background: linear-gradient(135deg, rgba(239, 68, 68, 0.1), rgba(248, 113, 113, 0.05));
    color: #EF4444;
  }

  .metric-info {
    flex: 1;
  }

  .metric-info h3 {
    font-size: 1.25rem;
    font-weight: 700;
    color: #374151;
    margin: 0 0 0.25rem 0;
    line-height: 1.2;
  }

  .metric-trend {
    font-size: 0.8rem;
  }

  .trend-indicator {
    display: inline-flex;
    align-items: center;
    gap: 0.25rem;
    padding: 0.15rem 0.4rem;
    border-radius: 8px;
    font-weight: 600;
    font-size: 0.7rem;
  }

  .trend-indicator.positive {
    background: rgba(16, 185, 129, 0.1);
    color: #059669;
  }

  .trend-indicator.negative {
    background: rgba(239, 68, 68, 0.1);
    color: #DC2626;
  }

  .content-status, .engagement-level, .satisfaction-score, .events-status, .notification-rate {
    color: #6b7280;
    font-weight: 500;
  }

  .main-stat {
    font-size: 2.5rem;
    font-weight: 800;
    color: #1a202c;
    margin-bottom: 1rem;
  }

  .sub-stats {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
  }

  .stat-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .stat-label {
    color: #64748b;
    font-size: 0.875rem;
    font-weight: 500;
  }

  .stat-value {
    font-weight: 700;
    color: #374151;
  }

  .stat-value.highlight {
    color: #ff6600;
  }

  /* Nuevos elementos visuales */
  .stat-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    margin-bottom: 0.5rem;
  }

  .mini-progress, .monthly-bar, .event-timeline, .notification-gauge {
    height: 6px;
    background: #e5e7eb;
    border-radius: 3px;
    overflow: hidden;
    flex: 0 0 60px;
    position: relative;
  }

  .progress-bar, .bar-fill, .gauge-fill {
    height: 100%;
    border-radius: 3px;
    transition: width 0.8s ease;
  }

  .progress-bar { background: #3B82F6; }
  .bar-fill { background: #F59E0B; }
  .gauge-fill { background: #EF4444; }

  .completion-circle, .completion-donut {
    flex: 0 0 40px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .status-pills {
    display: flex;
    gap: 0.4rem;
    flex: 0 0 auto;
  }

  .pill {
    padding: 0.2rem 0.4rem;
    border-radius: 6px;
    font-size: 0.7rem;
    font-weight: 600;
  }

  .pill.published {
    background: rgba(16, 185, 129, 0.15);
    color: #059669;
  }

  .pill.draft {
    background: rgba(107, 114, 128, 0.15);
    color: #6b7280;
  }

  .interaction-bars {
    flex: 0 0 60px;
  }

  .interaction-bar {
    height: 8px;
    background: #e5e7eb;
    border-radius: 4px;
    display: flex;
    overflow: hidden;
  }

  .bar-segment.likes { background: #EC4899; }
  .bar-segment.comments { background: #8B5CF6; }

  .timeline-segment.upcoming { background: #06B6D4; }
  .timeline-segment.completed { background: #10B981; }

  .notification-gauge {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .gauge-text {
    position: absolute;
    font-size: 0.6rem;
    font-weight: 600;
    color: #EF4444;
  }

  .main-stat.ventas-amount {
    background: linear-gradient(135deg, #F59E0B, #FBBF24);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .metric-action {
    width: 100%;
    padding: 0.75rem 1rem;
    color: white;
    border: none;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.4rem;
  }

  /* Colores específicos para botones de acción */
  .usuarios-action { background: linear-gradient(135deg, #3B82F6, #60A5FA); }
  .cursos-action { background: linear-gradient(135deg, #10B981, #34D399); }
  .ventas-action { background: linear-gradient(135deg, #F59E0B, #FBBF24); }
  .blog-action { background: linear-gradient(135deg, #8B5CF6, #A78BFA); }
  .comunidad-action { background: linear-gradient(135deg, #EC4899, #F472B6); }
  .tutoriales-action { background: linear-gradient(135deg, #ff6600, #ff8c42); }
  .eventos-action { background: linear-gradient(135deg, #06B6D4, #22D3EE); }
  .notificaciones-action { background: linear-gradient(135deg, #EF4444, #F87171); }

  .metric-action:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  }

  .quick-actions {
    background: white;
    border-radius: 16px;
    padding: 2rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    border: 1px solid rgba(255, 102, 0, 0.1);
  }

  .section-title {
    font-size: 1.5rem;
    font-weight: 700;
    color: #374151;
    margin-bottom: 1.5rem;
    padding-bottom: 0.5rem;
    border-bottom: 2px solid #ff6600;
    display: inline-block;
  }

  .actions-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1rem;
  }

  .action-card {
    background: #f8fafc;
    border: 2px solid #e2e8f0;
    border-radius: 12px;
    padding: 1.5rem;
    text-align: center;
    cursor: pointer;
    transition: all 0.3s ease;
    text-decoration: none;
    color: inherit;
  }

  .action-card:hover {
    border-color: #ff6600;
    background: #fff;
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(255, 102, 0, 0.15);
  }

  .action-icon {
    width: 56px;
    height: 56px;
    background: linear-gradient(135deg, #ff6600, #ff8c42);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 1rem;
    color: white;
  }

  .action-card h3 {
    font-size: 1.125rem;
    font-weight: 700;
    color: #374151;
    margin: 0 0 0.5rem 0;
  }

  .action-card p {
    color: #64748b;
    font-size: 0.875rem;
    margin: 0;
    line-height: 1.5;
  }

  .loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .loading-spinner {
    background: white;
    padding: 2rem;
    border-radius: 16px;
    text-align: center;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid #e2e8f0;
    border-top: 3px solid #ff6600;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 1rem;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .dashboard-container {
      padding: 1rem;
    }

    .header-content {
      flex-direction: column;
      align-items: flex-start;
      gap: 1rem;
    }

    .dashboard-title {
      font-size: 2rem;
    }

    .metrics-grid {
      grid-template-columns: 1fr;
      gap: 1rem;
    }

    .actions-grid {
      grid-template-columns: 1fr;
    }

    .main-stat {
      font-size: 2rem;
    }

    .stat-row {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.5rem;
    }

    .stat-item {
      width: 100%;
    }

    .mini-progress, .monthly-bar, .event-timeline, .notification-gauge {
      flex: 1;
      width: 100%;
      margin-top: 0.25rem;
    }

    .status-pills, .completion-circle, .completion-donut, .interaction-bars {
      margin-top: 0.25rem;
    }

    .metric-info h3 {
      font-size: 1.1rem;
    }

    .metric-trend {
      font-size: 0.75rem;
    }
  }

  @media (max-width: 480px) {
    .dashboard-title {
      font-size: 1.75rem;
    }

    .dashboard-subtitle {
      font-size: 1rem;
    }

    .main-stat {
      font-size: 1.75rem;
    }

    .metric-card {
      padding: 1rem;
    }

    .quick-actions {
      padding: 1.5rem;
    }
    }
</style>

