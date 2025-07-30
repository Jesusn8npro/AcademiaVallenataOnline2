<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';

  // 🎮 Estados del componente
  let cargando = true;
  let estadisticas = {
    puntajeTotal: 0,
    cancionesDominadas: 0,
    totalCanciones: 50,
    rachaActual: 0,
    nivelActual: 'Principiante',
    porcentajeNivel: 0,
    desafioSemanal: 'Porro Sabanero',
    ultimaCancion: 'Ninguna',
    fechaUltimaPractica: null as Date | null,
    proximoLogro: 'Primera Canción Perfecta'
  };

  // 🎯 Cargar estadísticas del simulador
  async function cargarEstadisticasSimulador() {
    try {
      cargando = true;
      
      if (!$usuario?.id) {
        console.log('❌ [SIMULADOR] Usuario no autenticado');
        return;
      }

      console.log('📊 [SIMULADOR] Cargando estadísticas para:', $usuario.id);

      // 🎮 Buscar progreso del simulador en experiencia_usuario
      const { data: experienciaData, error: experienciaError } = await supabase
        .from('experiencia_usuario')
        .select('*')
        .eq('usuario_id', $usuario.id)
        .single();

      if (experienciaError && experienciaError.code !== 'PGRST116') {
        console.error('❌ [SIMULADOR] Error al cargar experiencia:', experienciaError);
      }

      // 🎵 Calcular estadísticas (simuladas por ahora)
      const puntajeBase = experienciaData?.puntos_totales || 0;
      const nivelUsuario = experienciaData?.nivel_actual || 1;
      
      estadisticas = {
        puntajeTotal: puntajeBase + Math.floor(Math.random() * 1000) + 1500,
        cancionesDominadas: Math.min(Math.floor(puntajeBase / 200) + 5, 48),
        totalCanciones: 50,
        rachaActual: Math.floor(Math.random() * 15) + 1,
        nivelActual: obtenerNombreNivel(nivelUsuario),
        porcentajeNivel: Math.min((puntajeBase % 1000) / 10, 95),
        desafioSemanal: obtenerDesafioSemanal(),
        ultimaCancion: 'La Gota Fría',
        fechaUltimaPractica: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000),
        proximoLogro: obtenerProximoLogro(puntajeBase)
      };

      console.log('✅ [SIMULADOR] Estadísticas cargadas:', estadisticas);

    } catch (error) {
      console.error('❌ [SIMULADOR] Error general:', error);
    } finally {
      cargando = false;
    }
  }

  // 🏆 Obtener nombre del nivel
  function obtenerNombreNivel(nivel: number): string {
    if (nivel <= 3) return 'Principiante';
    if (nivel <= 6) return 'Intermedio';
    if (nivel <= 9) return 'Avanzado';
    return 'Profesional';
  }

  // 🎯 Obtener desafío semanal
  function obtenerDesafioSemanal(): string {
    const desafios = [
      'Porro Sabanero',
      'La Gota Fría', 
      'Alicia Adorada',
      'El Binomio de Oro',
      'La Piragua'
    ];
    const semana = Math.floor(Date.now() / (7 * 24 * 60 * 60 * 1000));
    return desafios[semana % desafios.length];
  }

  // 🏅 Obtener próximo logro
  function obtenerProximoLogro(puntaje: number): string {
    if (puntaje < 500) return 'Primera Canción Perfecta';
    if (puntaje < 1000) return 'Racha de 10 días';
    if (puntaje < 2000) return 'Maestro del Vallenato';
    return 'Leyenda del Acordeón';
  }

  // 🎮 Ir al simulador
  function irAlSimulador() {
    console.log('🎮 [NAVEGACIÓN] Yendo al simulador...');
    goto('/simulador-de-acordeon');
  }

  // 🎵 Formatear fecha de última práctica
  function formatearUltimaPractica(fecha: Date): string {
    const ahora = new Date();
    const diferencia = ahora.getTime() - fecha.getTime();
    const horas = Math.floor(diferencia / (1000 * 60 * 60));
    const dias = Math.floor(horas / 24);
    
    if (horas < 1) return 'Hace menos de una hora';
    if (horas < 24) return `Hace ${horas} hora${horas > 1 ? 's' : ''}`;
    return `Hace ${dias} día${dias > 1 ? 's' : ''}`;
  }

  onMount(() => {
    cargarEstadisticasSimulador();
  });
</script>

<!-- 🎹 SIMULADOR DE ACORDEÓN - ESTADÍSTICAS -->
<div class="simulador-estadisticas">
  
  {#if cargando}
    <!-- Estado de carga -->
    <div class="cargando-simulador">
      <div class="skeleton-simulador"></div>
    </div>
    
  {:else}
    <!-- 🎮 Tarjeta principal del simulador -->
    <div class="tarjeta-simulador">
      
      <!-- 🎵 Header con icono y título -->
      <div class="simulador-header">
        <div class="icono-simulador">🎹</div>
        <div class="titulo-simulador">
          <h3>Simulador de Acordeón</h3>
          <p class="subtitulo">¡Practica y mejora tu técnica!</p>
        </div>
      </div>

      <!-- 📊 Estadísticas principales -->
      <div class="estadisticas-grid">
        
        <!-- Puntaje total -->
        <div class="stat-item puntaje">
          <div class="stat-icono">🏆</div>
          <div class="stat-info">
            <span class="stat-valor">{estadisticas.puntajeTotal.toLocaleString()}</span>
            <span class="stat-label">Puntos</span>
          </div>
        </div>

        <!-- Canciones dominadas -->
        <div class="stat-item canciones">
          <div class="stat-icono">🎵</div>
          <div class="stat-info">
            <span class="stat-valor">{estadisticas.cancionesDominadas}/{estadisticas.totalCanciones}</span>
            <span class="stat-label">Canciones</span>
          </div>
        </div>

        <!-- Racha actual -->
        <div class="stat-item racha">
          <div class="stat-icono">🔥</div>
          <div class="stat-info">
            <span class="stat-valor">{estadisticas.rachaActual} días</span>
            <span class="stat-label">Racha</span>
          </div>
        </div>

        <!-- Nivel actual -->
        <div class="stat-item nivel">
          <div class="stat-icono">📈</div>
          <div class="stat-info">
            <span class="stat-valor">{estadisticas.nivelActual}</span>
            <span class="stat-label">{estadisticas.porcentajeNivel}%</span>
          </div>
        </div>

      </div>

      <!-- 🎯 Desafío semanal -->
      <div class="desafio-semanal">
        <div class="desafio-header">
          <span class="desafio-icono">🎯</span>
          <span class="desafio-titulo">Desafío Semanal</span>
        </div>
        <div class="desafio-cancion">"{estadisticas.desafioSemanal}"</div>
        <div class="desafio-progreso">
          <div class="progreso-bar">
            <div class="progreso-fill" style="width: {Math.random() * 70 + 10}%"></div>
          </div>
        </div>
      </div>

      <!-- 🎵 Última actividad -->
      <div class="ultima-actividad">
        <div class="actividad-info">
          <span class="actividad-icono">🎶</span>
          <div class="actividad-texto">
            <span class="actividad-cancion">Última: "{estadisticas.ultimaCancion}"</span>
            <span class="actividad-fecha">
              {estadisticas.fechaUltimaPractica ? formatearUltimaPractica(estadisticas.fechaUltimaPractica) : 'Nunca'}
            </span>
          </div>
        </div>
      </div>

      <!-- 🏅 Próximo logro -->
      <div class="proximo-logro">
        <span class="logro-icono">🏅</span>
        <span class="logro-texto">Próximo: {estadisticas.proximoLogro}</span>
      </div>

      <!-- 🎮 Botón de acción principal -->
      <button class="boton-practicar" on:click={irAlSimulador}>
        <span class="boton-icono">🎮</span>
        <span class="boton-texto">PRACTICAR AHORA</span>
        <svg class="boton-flecha" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M5 12h14M12 5l7 7-7 7"/>
        </svg>
      </button>

    </div>
  {/if}
  
</div>

<style>
  /* 🎹 CONTENEDOR PRINCIPAL */
  .simulador-estadisticas {
    width: 100%;
    height: 100%;
  }

  /* 🎮 TARJETA DEL SIMULADOR */
  .tarjeta-simulador {
    background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 50%, #60a5fa 100%);
    border-radius: 20px;
    padding: 20px;
    color: white;
    position: relative;
    overflow: hidden;
    box-shadow: 0 8px 32px rgba(59, 130, 246, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    height: 100%;
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .tarjeta-simulador::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: radial-gradient(circle at 20% 20%, rgba(255, 255, 255, 0.1) 0%, transparent 50%);
    pointer-events: none;
  }

  /* 🎵 HEADER */
  .simulador-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 8px;
  }

  .icono-simulador {
    font-size: 2.5rem;
    filter: drop-shadow(0 2px 8px rgba(0, 0, 0, 0.3));
  }

  .titulo-simulador h3 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 700;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  }

  .subtitulo {
    margin: 0;
    font-size: 0.85rem;
    opacity: 0.8;
    margin-top: 2px;
  }

  /* 📊 GRID DE ESTADÍSTICAS */
  .estadisticas-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    margin-bottom: 8px;
  }

  .stat-item {
    background: rgba(255, 255, 255, 0.15);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 12px;
    display: flex;
    align-items: center;
    gap: 10px;
    border: 1px solid rgba(255, 255, 255, 0.2);
    transition: all 0.3s ease;
  }

  .stat-item:hover {
    background: rgba(255, 255, 255, 0.2);
    transform: translateY(-2px);
  }

  .stat-icono {
    font-size: 1.5rem;
    opacity: 0.9;
  }

  .stat-info {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .stat-valor {
    font-size: 1rem;
    font-weight: 700;
    line-height: 1;
  }

  .stat-label {
    font-size: 0.75rem;
    opacity: 0.8;
    line-height: 1;
  }

  /* 🎯 DESAFÍO SEMANAL */
  .desafio-semanal {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 14px;
    border: 1px solid rgba(255, 255, 255, 0.15);
  }

  .desafio-header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 8px;
  }

  .desafio-icono {
    font-size: 1.1rem;
  }

  .desafio-titulo {
    font-size: 0.9rem;
    font-weight: 600;
    opacity: 0.9;
  }

  .desafio-cancion {
    font-size: 1rem;
    font-weight: 700;
    margin-bottom: 8px;
    color: #fbbf24;
  }

  .progreso-bar {
    background: rgba(255, 255, 255, 0.2);
    border-radius: 6px;
    height: 6px;
    overflow: hidden;
  }

  .progreso-fill {
    background: linear-gradient(90deg, #10b981, #34d399);
    height: 100%;
    border-radius: 6px;
    transition: width 0.5s ease;
  }

  /* 🎵 ÚLTIMA ACTIVIDAD */
  .ultima-actividad {
    background: rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    padding: 12px;
  }

  .actividad-info {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .actividad-icono {
    font-size: 1.2rem;
    opacity: 0.8;
  }

  .actividad-texto {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .actividad-cancion {
    font-size: 0.9rem;
    font-weight: 600;
  }

  .actividad-fecha {
    font-size: 0.75rem;
    opacity: 0.7;
  }

  /* 🏅 PRÓXIMO LOGRO */
  .proximo-logro {
    display: flex;
    align-items: center;
    gap: 8px;
    background: rgba(251, 191, 36, 0.15);
    border-radius: 8px;
    padding: 10px;
    border: 1px solid rgba(251, 191, 36, 0.3);
  }

  .logro-icono {
    font-size: 1.1rem;
  }

  .logro-texto {
    font-size: 0.85rem;
    font-weight: 600;
    color: #fbbf24;
  }

  /* 🎮 BOTÓN PRINCIPAL */
  .boton-practicar {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    border: none;
    border-radius: 12px;
    padding: 14px 20px;
    color: white;
    font-weight: 700;
    font-size: 0.95rem;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 4px 16px rgba(16, 185, 129, 0.3);
    margin-top: auto;
  }

  .boton-practicar:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 24px rgba(16, 185, 129, 0.4);
    background: linear-gradient(135deg, #059669 0%, #047857 100%);
  }

  .boton-icono {
    font-size: 1.1rem;
  }

  .boton-flecha {
    width: 20px;
    height: 20px;
    transition: transform 0.3s ease;
  }

  .boton-practicar:hover .boton-flecha {
    transform: translateX(4px);
  }

  /* 🔄 LOADING */
  .cargando-simulador {
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 40px 20px;
  }

  .skeleton-simulador {
    background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 50%, #60a5fa 100%);
    border-radius: 20px;
    width: 100%;
    height: 100%;
    position: relative;
    overflow: hidden;
  }

  .skeleton-simulador::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, 
      transparent 0%, 
      rgba(255, 255, 255, 0.1) 50%, 
      transparent 100%
    );
    animation: shimmer 2s infinite;
  }

  @keyframes shimmer {
    0% { left: -100%; }
    100% { left: 100%; }
  }

  /* 📱 RESPONSIVE */
  @media (max-width: 900px) {
    .tarjeta-simulador {
      padding: 16px;
      gap: 12px;
    }

    .simulador-header {
      gap: 10px;
    }

    .icono-simulador {
      font-size: 2rem;
    }

    .titulo-simulador h3 {
      font-size: 1.1rem;
    }

    .estadisticas-grid {
      gap: 10px;
    }

    .stat-item {
      padding: 10px;
      gap: 8px;
    }

    .stat-icono {
      font-size: 1.3rem;
    }

    .stat-valor {
      font-size: 0.9rem;
    }

    .stat-label {
      font-size: 0.7rem;
    }

    .boton-practicar {
      padding: 12px 16px;
      font-size: 0.9rem;
    }
  }
</style>
