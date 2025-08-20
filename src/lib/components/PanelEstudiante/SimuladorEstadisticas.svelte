<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { GamificacionService } from '$lib/services/gamificacionService';

  // 🚀 Características del simulador próximo
  const caracteristicas = [
    {
      icono: '🏆',
      titulo: 'Desafíos Semanales',
      descripcion: 'Nuevos retos cada semana para mejorar tu técnica',
      color: 'linear-gradient(45deg, #ffd700, #ffa500)'
    },
    {
      icono: '🎯',
      titulo: 'Retos Progresivos',
      descripcion: 'Niveles adaptativos según tu progreso personal',
      color: 'linear-gradient(45deg, #00ff88, #00cc6a)'
    },
    {
      icono: '📚',
      titulo: 'Teoría Musical',
      descripcion: 'Aprende mientras practicas con ejercicios teóricos',
      color: 'linear-gradient(45deg, #667eea, #764ba2)'
    },
    {
      icono: '🎹',
      titulo: 'Práctica Libre',
      descripcion: 'Toca libremente y recibe feedback en tiempo real',
      color: 'linear-gradient(45deg, #f093fb, #f5576c)'
    },
    {
      icono: '📊',
      titulo: 'Métricas Avanzadas',
      descripcion: 'Análisis detallado de tu progreso y técnica',
      color: 'linear-gradient(45deg, #4facfe, #00f2fe)'
    },
    {
      icono: '🎵',
      titulo: 'Biblioteca Musical',
      descripcion: 'Más de 100 canciones para practicar',
      color: 'linear-gradient(45deg, #fa709a, #fee140)'
    }
  ];

  // 🎯 Estados del componente
  let caracteristicaActiva = 0;
  
  // ⚡ ESTADOS DE CARGA VISUALES
  let cargandoEstadisticas = true;
  let estadisticasReales: any[] = [];
  
  // 🎯 DATOS POR DEFECTO PARA MOSTRAR INMEDIATAMENTE
  const estadisticasPorDefecto = [
    { icono: '📚', valor: '0', label: 'Lecciones' },
    { icono: '⏱️', valor: '0m', label: 'Estudiando' },
    { icono: '🔥', valor: '0', label: 'Racha' },
    { icono: '💎', valor: '0', label: 'Puntos' }
  ];

  // 🕒 FUNCIÓN PARA FORMATEAR TIEMPO DE MANERA LEGIBLE
  function formatearTiempo(minutos: number): string {
    if (minutos < 1) return '0m';
    if (minutos < 60) return `${Math.round(minutos)}m`;
    if (minutos < 1440) {
      const horas = Math.floor(minutos / 60);
      const minRestantes = Math.round(minutos % 60);
      return `${horas}h ${minRestantes}m`;
    }
    const dias = Math.floor(minutos / 1440);
    const horas = Math.floor((minutos % 1440) / 60);
    return `${dias}d ${horas}h`;
  }

  // 📊 CARGAR ESTADÍSTICAS REALES DEL USUARIO
  async function cargarEstadisticasReales() {
    if (!$usuario?.id) {
      cargandoEstadisticas = false;
      return;
    }

    try {
      console.log('🚀 [SIMULADOR] Cargando estadísticas reales para:', $usuario.id);
      
      // 🚀 CARGAR DATOS EN PARALELO
      const [ranking, tiempoHistorico] = await Promise.all([
        // 💎 1. RANKING DEL USUARIO
        GamificacionService.obtenerRanking('general', 50).catch(() => []),
        
        // ⏱️ 2. TIEMPO HISTÓRICO TOTAL
        calcularTiempoHistoricoRapido($usuario.id)
      ]);

      // 💎 PROCESAR RANKING
      let puntosFinales = 0;
      const miRanking = ranking.find((r: any) => r.usuario_id === $usuario.id);
      if (miRanking) {
        puntosFinales = miRanking.puntuacion || 0;
        console.log('💎 [SIMULADOR] Puntos del ranking:', puntosFinales);
      }

      // 📊 CALCULAR ESTADÍSTICAS REALES
      const leccionesCompletadas = 0; // Por ahora en 0, se puede expandir después
      const tiempoEstudio = tiempoHistorico;
      const rachaActual = 0; // Por ahora en 0, se puede expandir después

      // ✅ ASIGNAR ESTADÍSTICAS REALES
      estadisticasReales = [
        { icono: '📚', valor: leccionesCompletadas.toString(), label: 'Lecciones' },
        { icono: '⏱️', valor: formatearTiempo(tiempoEstudio), label: 'Estudiando' },
        { icono: '🔥', valor: rachaActual.toString(), label: 'Racha' },
        { icono: '💎', valor: puntosFinales.toString(), label: 'Puntos' }
      ];

      console.log('✅ [SIMULADOR] Estadísticas reales cargadas:', estadisticasReales);
      cargandoEstadisticas = false;

    } catch (error) {
      console.error('❌ [SIMULADOR] Error cargando estadísticas:', error);
      cargandoEstadisticas = false;
    }
  }

  // 🕒 Función RÁPIDA para calcular tiempo histórico total (EN PARALELO)
  async function calcularTiempoHistoricoRapido(usuarioId: string): Promise<number> {
    try {
      // 🚀 TODAS LAS CONSULTAS EN PARALELO
      const [leccionesResult, tutorialesResult, simuladorResult, sesionesResult] = await Promise.all([
        // 1. TODO el tiempo en lecciones 
        supabase
          .from('progreso_lecciones')
          .select('tiempo_total')
          .eq('usuario_id', usuarioId),
          
        // 2. TODO el tiempo en tutoriales
        supabase
          .from('progreso_tutorial')
          .select('tiempo_visto')
          .eq('usuario_id', usuarioId),
          
        // 3. TODO el tiempo en simulador
        supabase
          .from('sesiones_simulador_acordeon')
          .select('duracion_minutos')
          .eq('usuario_id', usuarioId),
          
        // 4. TODO el tiempo en plataforma
        supabase
          .from('sesiones_usuario')
          .select('tiempo_total_minutos')
          .eq('usuario_id', usuarioId)
      ]);

      // ✅ MANEJAR RESULTADOS CON VERIFICACIÓN DE ERRORES
      const todasLecciones = leccionesResult.data || [];
      const todosTutoriales = tutorialesResult.data || [];
      const todasSesiones = simuladorResult.data || [];
      const todasSesionesUsuario = sesionesResult.data || [];

      // 🔍 VERIFICAR SI HAY ERRORES EN LAS CONSULTAS
      if (leccionesResult.error) {
        console.warn('⚠️ [SIMULADOR] Error en consulta de lecciones:', leccionesResult.error);
      }
      if (tutorialesResult.error) {
        console.warn('⚠️ [SIMULADOR] Error en consulta de tutoriales:', tutorialesResult.error);
      }
      if (simuladorResult.error) {
        console.warn('⚠️ [SIMULADOR] Error en consulta de simulador:', simuladorResult.error);
      }
      if (sesionesResult.error) {
        console.warn('⚠️ [SIMULADOR] Error en consulta de sesiones:', sesionesResult.error);
      }

      // 🔍 DIAGNÓSTICO: Ver valores exactos en la base de datos
      console.log('🔍 [SIMULADOR] Valores RAW en la base de datos:', {
        lecciones: todasLecciones.length > 0 ? todasLecciones[0].tiempo_total : 'Sin datos',
        tutoriales: todosTutoriales.length > 0 ? todosTutoriales[0].tiempo_visto : 'Sin datos',
        simulador: todasSesiones.length > 0 ? todasSesiones[0].duracion_minutos : 'Sin datos',
        sesiones: todasSesionesUsuario.length > 0 ? todasSesionesUsuario[0].tiempo_total_minutos : 'Sin datos'
      });

      // 🎯 DETERMINAR UNIDADES CORRECTAS
      let totalLecciones = 0;
      let totalTutoriales = 0;
      
      if (todasLecciones.length > 0) {
        const primerValor = todasLecciones[0].tiempo_total;
        if (primerValor > 1000000) {
          // Si es muy grande, probablemente en milisegundos
          totalLecciones = todasLecciones.reduce((sum: number, item: any) => 
            sum + ((item.tiempo_total || 0) / 60000), 0);
          console.log('🔍 [SIMULADOR] Lecciones: Valores en MILISEGUNDOS, convirtiendo a minutos');
        } else if (primerValor > 1000) {
          // Si es mediano, probablemente en segundos
          totalLecciones = todasLecciones.reduce((sum: number, item: any) => 
            sum + ((item.tiempo_total || 0) / 60), 0);
          console.log('🔍 [SIMULADOR] Lecciones: Valores en SEGUNDOS, convirtiendo a minutos');
        } else {
          // Si es pequeño, probablemente ya en minutos
          totalLecciones = todasLecciones.reduce((sum: number, item: any) => 
            sum + (item.tiempo_total || 0), 0);
          console.log('🔍 [SIMULADOR] Lecciones: Valores ya en MINUTOS');
        }
      }
      
      if (todosTutoriales.length > 0) {
        const primerValor = todosTutoriales[0].tiempo_visto;
        if (primerValor > 1000000) {
          // Si es muy grande, probablemente en milisegundos
          totalTutoriales = todosTutoriales.reduce((sum: number, item: any) => 
            sum + ((item.tiempo_visto || 0) / 60000), 0);
          console.log('🔍 [SIMULADOR] Tutoriales: Valores en MILISEGUNDOS, convirtiendo a minutos');
        } else if (primerValor > 1000) {
          // Si es mediano, probablemente en segundos
          totalTutoriales = todosTutoriales.reduce((sum: number, item: any) => 
            sum + ((item.tiempo_visto || 0) / 60), 0);
          console.log('🔍 [SIMULADOR] Tutoriales: Valores en SEGUNDOS, convirtiendo a minutos');
        } else {
          // Si es pequeño, probablemente ya en minutos
          totalTutoriales = todosTutoriales.reduce((sum: number, item: any) => 
            sum + (item.tiempo_visto || 0), 0);
          console.log('🔍 [SIMULADOR] Tutoriales: Valores ya en MINUTOS');
        }
      }
      
      const totalSimulador = todasSesiones.reduce((sum: number, item: any) => 
        sum + (item.duracion_minutos || 0), 0); // Ya está en minutos ✅
      
      // ✅ USAR tiempo_total_minutos PERO LIMITADO a valores realistas
      let totalSesiones = 0;
      if (todasSesionesUsuario.length > 0) {
        // 🎯 LIMITAR a máximo 8 horas por día (480 minutos)
        totalSesiones = todasSesionesUsuario.reduce((sum: number, item: any) => {
          const tiempo = item.tiempo_total_minutos || 0;
          // ✅ Solo usar valores realistas (< 480 minutos = 8 horas)
          return sum + (tiempo < 480 ? tiempo : 0);
        }, 0);
        
        if (totalSesiones > 0) {
          console.log('🔍 [SIMULADOR] Sesiones: Usando tiempo limitado a valores realistas');
        }
      }
      
      // ✅ CALCULAR TIEMPO REAL BASADO EN ACTIVIDAD REAL
      const tiempoReal = totalLecciones + totalTutoriales + totalSimulador;
      
      // 🎯 COMBINAR tiempo real + sesiones limitadas
      const tiempoCombinado = Math.max(tiempoReal, totalSesiones);
      
      // 🎯 Si no hay tiempo registrado, calcular basado en actividad reciente
      if (tiempoCombinado === 0) {
        // Buscar actividad reciente para estimar tiempo
        const { data: actividadReciente } = await supabase
          .from('eventos_actividad')
          .select('created_at, tipo_evento')
          .eq('usuario_id', usuarioId)
          .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()) // Últimos 7 días
          .order('created_at', { ascending: false });
        
        if (actividadReciente && actividadReciente.length > 0) {
          // Estimar tiempo basado en actividad: 5 minutos por evento
          const tiempoEstimado = Math.min(actividadReciente.length * 5, 120); // Máximo 2 horas
          console.log('🎯 [SIMULADOR] Estimando tiempo basado en actividad reciente:', tiempoEstimado, 'min');
          return tiempoEstimado;
        }
      }

      // 🎯 PRIORIDAD: Usar tiempo combinado (real + sesiones limitadas)
      console.log('⏱️ [SIMULADOR] Tiempo combinado inteligente:', {
        lecciones: totalLecciones.toFixed(2) + ' min',
        tutoriales: totalTutoriales.toFixed(2) + ' min', 
        simulador: totalSimulador + ' min',
        sesionesLimitadas: totalSesiones + ' min',
        tiempoReal: tiempoReal.toFixed(2) + ' min',
        tiempoCombinado: tiempoCombinado.toFixed(2) + ' min',
        nota: 'Combinando tiempo real + sesiones limitadas a valores realistas'
      });

      return Math.round(tiempoCombinado); // Redondear a minutos enteros

    } catch (error) {
      console.error('❌ [SIMULADOR] Error calculando tiempo histórico:', error);
      return 0;
    }
  }

  // 🔄 Rotar características automáticamente
  setInterval(() => {
    caracteristicaActiva = (caracteristicaActiva + 1) % caracteristicas.length;
  }, 3000);

  // 🚀 CARGAR ESTADÍSTICAS AL MONTAR
  onMount(() => {
    cargarEstadisticasReales();
  });

  // 🎮 Ir al simulador actual
  function explorarSimulador() {
    console.log('🎮 [NAVEGACIÓN] Explorando simulador actual...');
    goto('/simulador-gaming/simulador');
  }
</script>

<!-- 🚀 SIMULADOR PREVIEW - PRÓXIMAMENTE -->
<div class="simulador-preview">
  
  <!-- 🎮 Header del preview -->
  <div class="preview-header">
    <div class="header-icon">
      <div class="acordeon-icon">🎹</div>
      <div class="coming-soon-badge">PRÓXIMAMENTE</div>
    </div>
    <div class="header-info">
      <h3>🚀 Simulador Avanzado</h3>
      <p class="subtitulo">Aquí encontrarás todos tus desafíos del simulador de acordeón</p>
    </div>
  </div>

  <!-- ✨ Característica destacada (rotativa) -->
  <div class="caracteristica-destacada">
    <div 
      class="caracteristica-card"
      style="background: {caracteristicas[caracteristicaActiva].color}"
    >
      <div class="caracteristica-icon">
        {caracteristicas[caracteristicaActiva].icono}
      </div>
      <div class="caracteristica-info">
        <h4>{caracteristicas[caracteristicaActiva].titulo}</h4>
        <p>{caracteristicas[caracteristicaActiva].descripcion}</p>
      </div>
    </div>
  </div>

  <!-- 🎯 Lista de características -->
  <div class="caracteristicas-lista">
    <h4 class="lista-titulo">Lo que incluirá:</h4>
    <div class="caracteristicas-grid">
      {#each caracteristicas as caracteristica, index}
        <div 
          class="caracteristica-mini"
          class:activa={index === caracteristicaActiva}
        >
          <span class="mini-icon">{caracteristica.icono}</span>
          <span class="mini-titulo">{caracteristica.titulo}</span>
        </div>
      {/each}
    </div>
  </div>

  <!-- 📊 ESTADÍSTICAS GAMING - CON SKELETON LOADER -->
  <div class="estadisticas-gaming">
    <h4 class="estadisticas-titulo">📊 Estadísticas Gaming</h4>
    
    {#if cargandoEstadisticas}
      <!-- ⚡ SKELETON LOADER PARA ESTADÍSTICAS -->
      <div class="estadisticas-skeleton">
        {#each estadisticasPorDefecto as stat}
          <div class="stat-skeleton">
            <div class="stat-icon-skeleton"></div>
            <div class="stat-content-skeleton">
              <div class="stat-valor-skeleton"></div>
              <div class="stat-label-skeleton"></div>
            </div>
          </div>
        {/each}
      </div>
    {:else}
      <!-- ✅ ESTADÍSTICAS REALES -->
      <div class="estadisticas-grid">
        {#each (estadisticasReales.length > 0 ? estadisticasReales : estadisticasPorDefecto) as stat}
          <div class="stat-item">
            <span class="stat-icon">{stat.icono}</span>
            <div class="stat-info">
              <span class="stat-valor">{stat.valor}</span>
              <span class="stat-label">{stat.label}</span>
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </div>

  <!-- 📋 Resumen de beneficios -->
  <div class="beneficios-resumen">
    <div class="beneficio">
      <span class="beneficio-icon">🎯</span>
      <span class="beneficio-texto">Retos personalizados</span>
    </div>
    <div class="beneficio">
      <span class="beneficio-icon">📚</span>
      <span class="beneficio-texto">Clases pendientes</span>
    </div>
    <div class="beneficio">
      <span class="beneficio-icon">🏋️</span>
      <span class="beneficio-texto">Ejercicios prácticos</span>
    </div>
  </div>

  <!-- 🎮 Botón de exploración -->
  <button class="btn-explorar" on:click={explorarSimulador}>
    <span class="btn-icon">🔍</span>
    <span class="btn-texto">Explorar Simulador Actual</span>
    <svg class="btn-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor">
      <path d="M5 12h14M12 5l7 7-7 7"/>
    </svg>
  </button>

</div>

<style>
  /* 🚀 CONTENEDOR PRINCIPAL */
  .simulador-preview {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 20px;
    padding: 16px;
    color: white;
    position: relative;
    overflow: hidden;
    box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    height: 100%;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .simulador-preview::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: radial-gradient(circle at 20% 80%, rgba(255, 255, 255, 0.1) 0%, transparent 50%);
    pointer-events: none;
  }

  /* 🎮 HEADER DEL PREVIEW */
  .preview-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 8px;
  }

  .header-icon {
    position: relative;
  }

  .acordeon-icon {
    font-size: 1.8rem;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
    animation: float 3s ease-in-out infinite;
  }

  .coming-soon-badge {
    position: absolute;
    top: -8px;
    right: -16px;
    background: linear-gradient(45deg, #ff6b6b, #ee5a24);
    color: white;
    font-size: 0.5rem;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 8px;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
    animation: pulse 2s infinite;
  }

  @keyframes float {
    0%, 100% { transform: translateY(0px); }
    50% { transform: translateY(-3px); }
  }

  @keyframes pulse {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.05); }
  }

  .header-info h3 {
    margin: 0;
    font-size: 1.1rem;
    font-weight: 700;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  }

  .subtitulo {
    margin: 0;
    font-size: 0.75rem;
    opacity: 0.8;
    margin-top: 2px;
    line-height: 1.3;
  }

  /* ✨ CARACTERÍSTICA DESTACADA */
  .caracteristica-destacada {
    margin-bottom: 8px;
  }

  .caracteristica-card {
    border-radius: 12px;
    padding: 12px;
    display: flex;
    align-items: center;
    gap: 10px;
    border: 1px solid rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(10px);
    transition: all 0.5s ease;
    animation: fadeIn 0.5s ease;
  }

  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
  }

  .caracteristica-icon {
    font-size: 1.5rem;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
  }

  .caracteristica-info h4 {
    margin: 0 0 4px 0;
    font-size: 0.9rem;
    font-weight: 700;
    color: white;
  }

  .caracteristica-info p {
    margin: 0;
    font-size: 0.7rem;
    opacity: 0.9;
    line-height: 1.3;
  }

  /* 🎯 LISTA DE CARACTERÍSTICAS */
  .caracteristicas-lista {
    margin-bottom: 8px;
  }

  .lista-titulo {
    margin: 0 0 8px 0;
    font-size: 0.8rem;
    font-weight: 600;
    opacity: 0.9;
  }

  .caracteristicas-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 6px;
  }

  .caracteristica-mini {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 6px 8px;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: all 0.3s ease;
    border: 1px solid transparent;
  }

  .caracteristica-mini.activa {
    background: rgba(255, 255, 255, 0.2);
    border-color: rgba(255, 215, 0, 0.3);
    transform: scale(1.02);
  }

  .mini-icon {
    font-size: 0.8rem;
  }

  .mini-titulo {
    font-size: 0.65rem;
    font-weight: 600;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  /* 📊 ESTADÍSTICAS GAMING */
  .estadisticas-gaming {
    margin-bottom: 8px;
  }

  .estadisticas-titulo {
    margin: 0 0 8px 0;
    font-size: 0.8rem;
    font-weight: 600;
    opacity: 0.9;
  }

  /* 📋 BENEFICIOS RESUMEN */
  .beneficios-resumen {
    display: flex;
    justify-content: space-between;
    gap: 8px;
    margin-bottom: 8px;
    padding: 8px;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 8px;
  }

  .beneficio {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    flex: 1;
    text-align: center;
  }

  .beneficio-icon {
    font-size: 1rem;
  }

  .beneficio-texto {
    font-size: 0.6rem;
    font-weight: 600;
    opacity: 0.8;
  }

  /* 📊 SKELETON LOADER */
  .estadisticas-skeleton {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
    padding: 10px;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .stat-skeleton {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .stat-icon-skeleton {
    width: 20px;
    height: 20px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 50%;
  }

  .stat-content-skeleton {
    flex: 1;
  }

  .stat-valor-skeleton {
    width: 40%;
    height: 16px;
    background: rgba(255, 255, 255, 0.3);
    border-radius: 4px;
    margin-bottom: 4px;
  }

  .stat-label-skeleton {
    width: 60%;
    height: 14px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 4px;
  }

  /* ✅ ESTADÍSTICAS REALES */
  .estadisticas-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
    padding: 10px;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .stat-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .stat-icon {
    font-size: 1.2rem;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
  }

  .stat-info {
    display: flex;
    flex-direction: column;
  }

  .stat-valor {
    font-size: 1rem;
    font-weight: 700;
    color: white;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
  }

  .stat-label {
    font-size: 0.6rem;
    opacity: 0.8;
    color: white;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
  }

  /* 🎮 BOTÓN DE EXPLORACIÓN */
  .btn-explorar {
    background: linear-gradient(45deg, #ffd700, #ffa500);
    color: #1a1a1a;
    border: none;
    border-radius: 10px;
    padding: 10px 16px;
    font-size: 0.8rem;
    font-weight: 700;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 4px 16px rgba(255, 215, 0, 0.3);
    margin-top: auto;
  }

  .btn-explorar:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(255, 215, 0, 0.4);
  }

  .btn-icon {
    font-size: 0.9rem;
  }

  .btn-arrow {
    width: 14px;
    height: 14px;
    transition: transform 0.3s ease;
  }

  .btn-explorar:hover .btn-arrow {
    transform: translateX(3px);
  }

  /* 📱 RESPONSIVE */
  @media (max-width: 900px) {
    .simulador-preview {
      padding: 12px;
      gap: 10px;
    }
    
    .preview-header {
      gap: 8px;
    }
    
    .acordeon-icon {
      font-size: 1.6rem;
    }
    
    .header-info h3 {
      font-size: 1rem;
    }
    
    .subtitulo {
      font-size: 0.7rem;
    }
    
    .caracteristica-card {
      padding: 10px;
      gap: 8px;
    }
    
    .caracteristica-icon {
      font-size: 1.3rem;
    }
    
    .caracteristicas-grid {
      grid-template-columns: 1fr;
      gap: 4px;
    }
    
    .btn-explorar {
      padding: 8px 12px;
      font-size: 0.75rem;
    }
  }
</style>
