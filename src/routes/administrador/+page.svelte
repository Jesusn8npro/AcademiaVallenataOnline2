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
  <!-- Header Premium del Dashboard -->
  <div class="dashboard-header">
    <div class="header-background">
      <div class="gradient-orb orb-1"></div>
      <div class="gradient-orb orb-2"></div>
      <div class="gradient-orb orb-3"></div>
    </div>
    <div class="header-content">
      <div class="header-info">
        <div class="admin-badge">
          <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2L3 7v10c0 5.55 3.84 9.74 9 10.95 5.16-1.21 9-5.4 9-10.95V7l-9-5z"/>
          </svg>
          <span>Admin</span>
        </div>
        <h1 class="dashboard-title">Panel de Control</h1>
        <p class="dashboard-subtitle">Academia Vallenata Online - Vista General del Sistema</p>
        <div class="header-stats">
          <div class="header-stat">
            <span class="stat-number">{formatearNumero(estadisticas.usuarios.total)}</span>
            <span class="stat-label">Usuarios</span>
          </div>
          <div class="header-stat">
            <span class="stat-number">{formatearMoneda(estadisticas.ventas.ingresos)}</span>
            <span class="stat-label">Ingresos</span>
          </div>
          <div class="header-stat">
            <span class="stat-number">{estadisticas.cursos.total}</span>
            <span class="stat-label">Cursos</span>
          </div>
        </div>
      </div>
      <div class="header-actions">
        <button class="btn-refresh" on:click={cargarEstadisticas} disabled={cargando}>
          <div class="btn-inner">
            <svg width="18" height="18" fill="none" viewBox="0 0 24 24" class:spinning={cargando}>
              <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
            </svg>
            <span>{cargando ? 'Actualizando...' : 'Actualizar'}</span>
          </div>
        </button>
        <button class="btn-settings" on:click={() => goto('/administrador/configuracion')}>
          <svg width="18" height="18" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
          </svg>
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
    background: 
      radial-gradient(circle at 20% 80%, rgba(255, 102, 0, 0.05) 0%, transparent 50%),
      radial-gradient(circle at 80% 20%, rgba(255, 140, 66, 0.05) 0%, transparent 50%),
      linear-gradient(135deg, #0f0f23 0%, #1a1a3e 100%);
    padding: 1.5rem;
    position: relative;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  }

  .dashboard-header {
    background: rgba(255, 255, 255, 0.02);
    backdrop-filter: blur(20px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 24px;
    padding: 2.5rem;
    margin-bottom: 2rem;
    position: relative;
    overflow: hidden;
  }

  .header-background {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    overflow: hidden;
    border-radius: 24px;
  }

  .gradient-orb {
    position: absolute;
    border-radius: 50%;
    filter: blur(80px);
    opacity: 0.3;
    animation: float 6s ease-in-out infinite;
  }

  .orb-1 {
    width: 200px;
    height: 200px;
    background: linear-gradient(45deg, #ff6600, #ff8c42);
    top: -100px;
    right: -100px;
    animation-delay: 0s;
  }

  .orb-2 {
    width: 150px;
    height: 150px;
    background: linear-gradient(45deg, #3B82F6, #60A5FA);
    bottom: -75px;
    left: -75px;
    animation-delay: 2s;
  }

  .orb-3 {
    width: 120px;
    height: 120px;
    background: linear-gradient(45deg, #10B981, #34D399);
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    animation-delay: 4s;
  }

  @keyframes float {
    0%, 100% { transform: translate(0, 0) rotate(0deg); }
    33% { transform: translate(30px, -30px) rotate(120deg); }
    66% { transform: translate(-20px, 20px) rotate(240deg); }
  }

  .header-content {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 2rem;
    position: relative;
    z-index: 2;
  }

  .admin-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    background: linear-gradient(135deg, #ff6600, #ff8c42);
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 50px;
    font-size: 0.875rem;
    font-weight: 600;
    margin-bottom: 1rem;
    box-shadow: 0 4px 15px rgba(255, 102, 0, 0.3);
  }

  .dashboard-title {
    font-size: 3rem;
    font-weight: 900;
    color: white;
    margin: 0 0 0.5rem 0;
    background: linear-gradient(135deg, #ffffff, #f8fafc);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    line-height: 1.1;
    letter-spacing: -0.02em;
  }

  .dashboard-subtitle {
    color: rgba(255, 255, 255, 0.7);
    font-size: 1.125rem;
    margin: 0 0 2rem 0;
    font-weight: 400;
  }

  .header-stats {
    display: flex;
    gap: 2rem;
    margin-top: 1rem;
  }

  .header-stat {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
  }

  .stat-number {
    font-size: 1.5rem;
    font-weight: 700;
    color: #ff6600;
    line-height: 1;
  }

  .stat-label {
    font-size: 0.875rem;
    color: rgba(255, 255, 255, 0.6);
    margin-top: 0.25rem;
  }

  .header-actions {
    display: flex;
    gap: 1rem;
    align-items: flex-start;
  }

  .btn-refresh, .btn-settings {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 16px;
    padding: 1rem 1.25rem;
    color: white;
    cursor: pointer;
    transition: all 0.3s ease;
    font-weight: 500;
    position: relative;
    overflow: hidden;
  }

  .btn-refresh {
    min-width: 140px;
  }

  .btn-settings {
    width: 52px;
    height: 52px;
    padding: 0;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .btn-inner {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .btn-refresh:hover, .btn-settings:hover {
    background: rgba(255, 255, 255, 0.15);
    border-color: rgba(255, 102, 0, 0.5);
    transform: translateY(-2px);
    box-shadow: 0 8px 30px rgba(255, 102, 0, 0.2);
  }

  .btn-refresh:disabled {
    opacity: 0.6;
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
    grid-template-columns: repeat(auto-fit, minmax(380px, 1fr));
    gap: 1.25rem;
    margin-bottom: 3rem;
  }

  .metric-card {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(20px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 20px;
    padding: 2rem;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    overflow: hidden;
  }

  .metric-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 2px;
    background: linear-gradient(90deg, #ff6600, #ff8c42);
    opacity: 0.8;
  }

  .metric-card::after {
    content: '';
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle, rgba(255, 102, 0, 0.03) 0%, transparent 70%);
    opacity: 0;
    transition: opacity 0.4s ease;
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
    transform: translateY(-8px) scale(1.02);
    border-color: rgba(255, 102, 0, 0.3);
    box-shadow: 
      0 25px 50px -12px rgba(0, 0, 0, 0.25),
      0 0 0 1px rgba(255, 102, 0, 0.05),
      inset 0 1px 0 rgba(255, 255, 255, 0.1);
  }

  .metric-card:hover::after {
    opacity: 1;
  }

  .metric-header {
    display: flex;
    align-items: center;
    gap: 1.25rem;
    margin-bottom: 1.5rem;
    position: relative;
    z-index: 2;
  }

  .metric-icon {
    width: 56px;
    height: 56px;
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #ff6600;
    flex-shrink: 0;
    transition: all 0.3s ease;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  }

  /* Colores específicos para iconos */
  .metric-icon.usuarios-icon { color: #60A5FA; }
  .metric-icon.cursos-icon { color: #34D399; }
  .metric-icon.ventas-icon { color: #FBBF24; }
  .metric-icon.blog-icon { color: #A78BFA; }
  .metric-icon.comunidad-icon { color: #F472B6; }
  .metric-icon.tutoriales-icon { color: #ff8c42; }
  .metric-icon.eventos-icon { color: #22D3EE; }
  .metric-icon.notificaciones-icon { color: #F87171; }

  .metric-info {
    flex: 1;
  }

  .metric-info h3 {
    font-size: 1.375rem;
    font-weight: 700;
    color: rgba(255, 255, 255, 0.95);
    margin: 0 0 0.5rem 0;
    line-height: 1.2;
    letter-spacing: -0.01em;
  }

  .metric-trend {
    font-size: 0.875rem;
  }

  .trend-indicator {
    display: inline-flex;
    align-items: center;
    gap: 0.3rem;
    padding: 0.25rem 0.6rem;
    border-radius: 12px;
    font-weight: 600;
    font-size: 0.75rem;
    backdrop-filter: blur(10px);
  }

  .trend-indicator.positive {
    background: rgba(16, 185, 129, 0.15);
    border: 1px solid rgba(16, 185, 129, 0.3);
    color: #34D399;
  }

  .trend-indicator.negative {
    background: rgba(239, 68, 68, 0.15);
    border: 1px solid rgba(239, 68, 68, 0.3);
    color: #F87171;
  }

  .content-status, .engagement-level, .satisfaction-score, .events-status, .notification-rate {
    color: rgba(255, 255, 255, 0.6);
    font-weight: 500;
  }

  .main-stat {
    font-size: 2.75rem;
    font-weight: 900;
    color: rgba(255, 255, 255, 0.95);
    margin-bottom: 1.25rem;
    line-height: 1;
    letter-spacing: -0.02em;
  }

  .sub-stats {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    margin-bottom: 1.75rem;
    position: relative;
    z-index: 2;
  }

  .stat-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .stat-label {
    color: rgba(255, 255, 255, 0.6);
    font-size: 0.875rem;
    font-weight: 500;
  }

  .stat-value {
    font-weight: 700;
    color: rgba(255, 255, 255, 0.9);
  }

  .stat-value.highlight {
    color: #ff8c42;
    text-shadow: 0 0 10px rgba(255, 140, 66, 0.3);
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
    padding: 1rem 1.25rem;
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    color: rgba(255, 255, 255, 0.9);
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    position: relative;
    z-index: 2;
    overflow: hidden;
  }

  .metric-action::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.1), transparent);
    transition: left 0.5s ease;
  }

  .metric-action:hover::before {
    left: 100%;
  }

  /* Efectos hover específicos por tipo */
  .usuarios-action:hover { border-color: rgba(96, 165, 250, 0.5); color: #60A5FA; }
  .cursos-action:hover { border-color: rgba(52, 211, 153, 0.5); color: #34D399; }
  .ventas-action:hover { border-color: rgba(251, 191, 36, 0.5); color: #FBBF24; }
  .blog-action:hover { border-color: rgba(167, 139, 250, 0.5); color: #A78BFA; }
  .comunidad-action:hover { border-color: rgba(244, 114, 182, 0.5); color: #F472B6; }
  .tutoriales-action:hover { border-color: rgba(255, 140, 66, 0.5); color: #ff8c42; }
  .eventos-action:hover { border-color: rgba(34, 211, 238, 0.5); color: #22D3EE; }
  .notificaciones-action:hover { border-color: rgba(248, 113, 113, 0.5); color: #F87171; }

  .metric-action:hover {
    transform: translateY(-2px);
    background: rgba(255, 255, 255, 0.15);
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.2);
  }

  .quick-actions {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(20px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 24px;
    padding: 2.5rem;
    position: relative;
    overflow: hidden;
  }

  .quick-actions::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 2px;
    background: linear-gradient(90deg, #ff6600, #ff8c42);
    opacity: 0.8;
  }

  .section-title {
    font-size: 1.75rem;
    font-weight: 800;
    color: rgba(255, 255, 255, 0.95);
    margin-bottom: 2rem;
    position: relative;
    display: inline-block;
    letter-spacing: -0.01em;
  }

  .section-title::after {
    content: '';
    position: absolute;
    bottom: -8px;
    left: 0;
    width: 60px;
    height: 3px;
    background: linear-gradient(90deg, #ff6600, #ff8c42);
    border-radius: 2px;
  }

  .actions-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 1.25rem;
  }

  .action-card {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 16px;
    padding: 2rem;
    text-align: center;
    cursor: pointer;
    transition: all 0.4s ease;
    text-decoration: none;
    color: inherit;
    position: relative;
    overflow: hidden;
  }

  .action-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.05), transparent);
    transition: left 0.6s ease;
  }

  .action-card:hover::before {
    left: 100%;
  }

  .action-card:hover {
    border-color: rgba(255, 102, 0, 0.3);
    background: rgba(255, 255, 255, 0.08);
    transform: translateY(-4px) scale(1.02);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
  }

  .action-icon {
    width: 64px;
    height: 64px;
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 102, 0, 0.3);
    border-radius: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 1.5rem;
    color: #ff8c42;
    transition: all 0.3s ease;
  }

  .action-card:hover .action-icon {
    transform: scale(1.1);
    background: rgba(255, 102, 0, 0.1);
    border-color: rgba(255, 102, 0, 0.5);
    box-shadow: 0 8px 30px rgba(255, 102, 0, 0.2);
  }

  .action-card h3 {
    font-size: 1.25rem;
    font-weight: 700;
    color: rgba(255, 255, 255, 0.95);
    margin: 0 0 0.75rem 0;
    letter-spacing: -0.01em;
  }

  .action-card p {
    color: rgba(255, 255, 255, 0.6);
    font-size: 0.875rem;
    margin: 0;
    line-height: 1.6;
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

    .dashboard-header {
      padding: 2rem;
    }

    .header-content {
      flex-direction: column;
      align-items: flex-start;
      gap: 1.5rem;
    }

    .header-actions {
      width: 100%;
      justify-content: flex-end;
    }

    .header-stats {
      flex-direction: column;
      gap: 1rem;
    }

    .dashboard-title {
      font-size: 2.25rem;
    }

    .metrics-grid {
      grid-template-columns: 1fr;
      gap: 1rem;
    }

    .actions-grid {
      grid-template-columns: 1fr;
    }

    .main-stat {
      font-size: 2.25rem;
    }

    .stat-row {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.75rem;
    }

    .stat-item {
      width: 100%;
    }

    .mini-progress, .monthly-bar, .event-timeline, .notification-gauge {
      flex: 1;
      width: 100%;
      margin-top: 0.5rem;
    }

    .status-pills, .completion-circle, .completion-donut, .interaction-bars {
      margin-top: 0.5rem;
    }

    .metric-info h3 {
      font-size: 1.25rem;
    }

    .metric-trend {
      font-size: 0.8rem;
    }

    .metric-card {
      padding: 1.5rem;
    }

    .quick-actions {
      padding: 2rem;
    }

    .btn-refresh {
      min-width: auto;
      padding: 1rem;
    }

    .btn-inner span {
      display: none;
    }
  }

  @media (max-width: 480px) {
    .dashboard-header {
      padding: 1.5rem;
    }

    .dashboard-title {
      font-size: 1.875rem;
    }

    .dashboard-subtitle {
      font-size: 1rem;
    }

    .main-stat {
      font-size: 2rem;
    }

    .metric-card {
      padding: 1.25rem;
    }

    .quick-actions {
      padding: 1.5rem;
    }

    .section-title {
      font-size: 1.5rem;
    }

    .action-card {
      padding: 1.5rem;
    }

    .action-icon {
      width: 56px;
      height: 56px;
    }

    .admin-badge {
      font-size: 0.8rem;
      padding: 0.4rem 0.8rem;
    }

    .metric-icon {
      width: 48px;
      height: 48px;
    }

    .metric-info h3 {
      font-size: 1.125rem;
    }
  }
</style>

