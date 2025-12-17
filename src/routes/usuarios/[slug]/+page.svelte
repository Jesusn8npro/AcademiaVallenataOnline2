<script lang="ts">
  export let data: any;
  
  $: usuarioPublico = data?.usuarioPublico;
  
  // 📊 Datos del usuario organizados
  $: informacionBasica = usuarioPublico ? {
    nombre_completo: usuarioPublico.nombre_completo || `${usuarioPublico.nombre || ''} ${usuarioPublico.apellido || ''}`.trim() || 'Usuario',
    biografia: usuarioPublico.biografia,
    ciudad: usuarioPublico.ciudad,
    pais: usuarioPublico.pais,
    whatsapp: usuarioPublico.whatsapp,
    correo_electronico: usuarioPublico.correo_electronico,
    fecha_creacion: usuarioPublico.fecha_creacion,
    rol: usuarioPublico.rol,
    suscripcion: usuarioPublico.suscripcion,
    nivel_habilidad: usuarioPublico.nivel_habilidad,
    instrumento: usuarioPublico.instrumento
  } : null;

  $: estadisticas = usuarioPublico?.estadisticas || {
    publicaciones: 0,
    cursos_creados: 0,
    cursos_inscritos: 0
  };

  // 🕒 Función para formatear fechas
  function formatearFecha(fecha: string): string {
    if (!fecha) return 'No disponible';
    
    try {
      const date = new Date(fecha);
      return date.toLocaleDateString('es-ES', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
    } catch {
      return 'Fecha inválida';
    }
  }

  function formatearFechaRelativa(fecha: string): string {
    if (!fecha) return 'No disponible';
    
    try {
      const date = new Date(fecha);
      const ahora = new Date();
      const diferencia = ahora.getTime() - date.getTime();
      const dias = Math.floor(diferencia / (1000 * 60 * 60 * 24));
      
      if (dias === 0) return 'Hoy';
      if (dias === 1) return 'Ayer';
      if (dias < 30) return `Hace ${dias} días`;
      if (dias < 365) return `Hace ${Math.floor(dias / 30)} meses`;
      return `Hace ${Math.floor(dias / 365)} años`;
    } catch {
      return 'No disponible';
    }
  }
</script>

<svelte:head>
  {#if informacionBasica}
    <title>{informacionBasica.nombre_completo} - Academia Vallenata</title>
    <meta name="description" content="Conoce a {informacionBasica.nombre_completo} en Academia Vallenata" />
  {/if}
</svelte:head>

{#if informacionBasica}
  <div class="perfil-contenido">
    
    <!-- 📊 Estadísticas rápidas -->
    <div class="seccion estadisticas-rapidas">
      <h2>📊 Estadísticas</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-numero">{estadisticas.publicaciones}</div>
          <div class="stat-label">Publicaciones</div>
        </div>
        <div class="stat-card">
          <div class="stat-numero">{usuarioPublico?.ranking || '#--'}</div>
          <div class="stat-label">Ranking</div>
        </div>
        <div class="stat-card">
          <div class="stat-numero">{usuarioPublico?.nivel_usuario || 1}</div>
          <div class="stat-label">Nivel</div>
        </div>
      </div>
    </div>

    <!-- 📝 Información personal -->
    <div class="seccion informacion-personal">
      <h2>👤 Información personal</h2>
      <div class="info-grid">
        
        {#if informacionBasica.biografia}
          <div class="info-item full-width">
            <div class="info-icon">📖</div>
            <div class="info-content">
              <div class="info-label">Biografía</div>
              <div class="info-valor biografia">{informacionBasica.biografia}</div>
            </div>
          </div>
        {/if}

        <div class="info-item">
          <div class="info-icon">👤</div>
          <div class="info-content">
            <div class="info-label">Rol</div>
            <div class="info-valor">
              <span class="badge badge-{informacionBasica.rol}">
                {informacionBasica.rol === 'estudiante' ? '🎓 Estudiante' : 
                 informacionBasica.rol === 'instructor' ? '👨‍🏫 Instructor' : 
                 informacionBasica.rol === 'administrador' ? '👑 Administrador' : 
                 '🙋‍♂️ ' + informacionBasica.rol}
              </span>
            </div>
          </div>
        </div>

        <div class="info-item">
          <div class="info-icon">⭐</div>
          <div class="info-content">
            <div class="info-label">Suscripción</div>
            <div class="info-valor">
              <span class="badge badge-{informacionBasica.suscripcion}">
                {informacionBasica.suscripcion === 'free' ? '🆓 Gratuita' : 
                 informacionBasica.suscripcion === 'premium' ? '💎 Premium' : 
                 informacionBasica.suscripcion === 'pro' ? '🚀 Pro' : 
                 '📦 ' + informacionBasica.suscripcion}
              </span>
            </div>
          </div>
        </div>

        {#if informacionBasica.ciudad || informacionBasica.pais}
          <div class="info-item">
            <div class="info-icon">📍</div>
            <div class="info-content">
              <div class="info-label">Ubicación</div>
              <div class="info-valor">{`${informacionBasica.ciudad || ''} ${informacionBasica.pais || ''}`.trim()}</div>
            </div>
          </div>
        {/if}

        <div class="info-item">
          <div class="info-icon">📅</div>
          <div class="info-content">
            <div class="info-label">Miembro desde</div>
            <div class="info-valor">{formatearFecha(informacionBasica.fecha_creacion)}</div>
          </div>
        </div>

        {#if informacionBasica.nivel_habilidad}
          <div class="info-item">
            <div class="info-icon">🎵</div>
            <div class="info-content">
              <div class="info-label">Nivel de habilidad</div>
              <div class="info-valor">
                <span class="badge badge-habilidad">
                  {informacionBasica.nivel_habilidad === 'principiante' ? '🌱 Principiante' : 
                   informacionBasica.nivel_habilidad === 'intermedio' ? '🌿 Intermedio' : 
                   informacionBasica.nivel_habilidad === 'avanzado' ? '🌳 Avanzado' : 
                   '🎯 ' + informacionBasica.nivel_habilidad}
                </span>
              </div>
            </div>
          </div>
        {/if}

        {#if informacionBasica.instrumento}
          <div class="info-item">
            <div class="info-icon">🪗</div>
            <div class="info-content">
              <div class="info-label">Instrumento principal</div>
              <div class="info-valor">{informacionBasica.instrumento}</div>
            </div>
          </div>
        {/if}
      </div>
    </div>

    <!-- 🎯 Información adicional -->
    <div class="seccion informacion-adicional">
      <h2>🎯 Detalles del perfil</h2>
      <div class="detalles-grid">
        
        <div class="detalle-item">
          <div class="detalle-icon">🏆</div>
          <div class="detalle-content">
            <div class="detalle-label">Posición en ranking</div>
            <div class="detalle-valor ranking">
              {#if usuarioPublico?.ranking}
                #{usuarioPublico.ranking}
              {:else}
                Sin clasificar
              {/if}
            </div>
          </div>
        </div>

        <div class="detalle-item">
          <div class="detalle-icon">⭐</div>
          <div class="detalle-content">
            <div class="detalle-label">Nivel actual</div>
            <div class="detalle-valor nivel">Nivel {usuarioPublico?.nivel_usuario || 1}</div>
          </div>
        </div>

        <div class="detalle-item">
          <div class="detalle-icon">📈</div>
          <div class="detalle-content">
            <div class="detalle-label">Progreso</div>
            <div class="detalle-valor progreso">
              <div class="barra-progreso">
                <div class="barra-relleno" style="width: {(usuarioPublico?.nivel_usuario || 1) * 20}%"></div>
              </div>
              <span class="porcentaje">{(usuarioPublico?.nivel_usuario || 1) * 20}%</span>
            </div>
          </div>
        </div>

        <div class="detalle-item">
          <div class="detalle-icon">🕒</div>
          <div class="detalle-content">
            <div class="detalle-label">Tiempo en la plataforma</div>
            <div class="detalle-valor tiempo">{formatearFechaRelativa(informacionBasica.fecha_creacion)}</div>
          </div>
        </div>

        <div class="detalle-item">
          <div class="detalle-icon">📍</div>
          <div class="detalle-content">
            <div class="detalle-label">Última actividad</div>
            <div class="detalle-valor actividad">Recientemente</div>
          </div>
        </div>

        <div class="detalle-item">
          <div class="detalle-icon">🎵</div>
          <div class="detalle-content">
            <div class="detalle-label">Especialidad</div>
            <div class="detalle-valor especialidad">
              {informacionBasica.instrumento || 'Acordeón Vallenato'}
            </div>
          </div>
        </div>

      </div>
    </div>

  </div>
{:else}
  <div class="cargando-perfil">
    <div class="spinner"></div>
    <p>Cargando información del perfil...</p>
  </div>
{/if}

<style>
  .perfil-contenido {
    max-width: 100%;
    margin: 0 auto;
    padding: 0 1rem;
    display: flex;
    flex-direction: column;
    gap: 2.5rem;
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

  /* Estadísticas */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.5rem;
    max-width: 1000px;
    margin: 0 auto;
  }

  .stat-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 2rem;
    border-radius: 20px;
    text-align: center;
    box-shadow: 0 6px 25px rgba(102, 126, 234, 0.3);
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
  }

  .stat-card::before {
    content: '';
    position: absolute;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
    animation: shimmer 3s infinite;
    pointer-events: none;
  }

  @keyframes shimmer {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .stat-card:hover {
    transform: translateY(-8px);
    box-shadow: 0 12px 40px rgba(102, 126, 234, 0.4);
  }

  .stat-card:nth-child(1) {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  }

  .stat-card:nth-child(2) {
    background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  }

  .stat-card:nth-child(3) {
    background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
  }

  .stat-numero {
    font-size: 3rem;
    font-weight: 900;
    margin-bottom: 0.5rem;
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
    position: relative;
    z-index: 1;
  }

  .stat-label {
    font-size: 0.875rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    opacity: 0.9;
    position: relative;
    z-index: 1;
  }

  /* Información */
  .info-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1rem;
  }

  .info-item {
    display: flex;
    align-items: flex-start;
    gap: 1rem;
    padding: 1rem;
    background: #f8fafc;
    border-radius: 12px;
    border: 1px solid #e2e8f0;
    transition: all 0.2s ease;
  }

  .info-item:hover {
    background: #f1f5f9;
    border-color: #cbd5e1;
  }

  .info-item.full-width {
    grid-column: 1 / -1;
  }

  .info-icon {
    font-size: 1.5rem;
    flex-shrink: 0;
    padding: 0.5rem;
    background: white;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  }

  .info-content {
    flex: 1;
    min-width: 0;
  }

  .info-label {
    font-size: 0.875rem;
    font-weight: 600;
    color: #6b7280;
    margin-bottom: 0.25rem;
  }

  .info-valor {
    font-size: 1rem;
    color: #1f2937;
    font-weight: 500;
    word-wrap: break-word;
  }

  .info-valor.biografia {
    line-height: 1.6;
    color: #374151;
  }

  /* Badges */
  .badge {
    display: inline-block;
    padding: 0.375rem 0.75rem;
    border-radius: 20px;
    font-size: 0.875rem;
    font-weight: 600;
    text-transform: capitalize;
  }

  .badge-estudiante {
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    color: white;
  }

  .badge-instructor {
    background: linear-gradient(135deg, #10b981, #059669);
    color: white;
  }

  .badge-administrador {
    background: linear-gradient(135deg, #f59e0b, #d97706);
    color: white;
  }

  .badge-free {
    background: linear-gradient(135deg, #6b7280, #4b5563);
    color: white;
  }

  .badge-premium {
    background: linear-gradient(135deg, #8b5cf6, #7c3aed);
    color: white;
  }

  .badge-pro {
    background: linear-gradient(135deg, #ef4444, #dc2626);
    color: white;
  }

  .badge-habilidad {
    background: linear-gradient(135deg, #06b6d4, #0891b2);
    color: white;
  }

  /* Información adicional */
  .detalles-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 1.5rem;
  }

  .detalle-item {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1.5rem;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    border-radius: 16px;
    border: 1px solid #e2e8f0;
    transition: all 0.3s ease;
  }

  .detalle-item:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
    background: linear-gradient(135deg, #ffffff 0%, #f1f5f9 100%);
  }

  .detalle-icon {
    font-size: 2.5rem;
    flex-shrink: 0;
    opacity: 0.9;
  }

  .detalle-content {
    flex: 1;
  }

  .detalle-label {
    font-size: 0.875rem;
    font-weight: 600;
    color: #6b7280;
    margin-bottom: 0.5rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .detalle-valor {
    font-size: 1.1rem;
    color: #1f2937;
    font-weight: 600;
  }

  .detalle-valor.ranking {
    color: #f59e0b;
    font-size: 1.25rem;
    font-weight: 700;
  }

  .detalle-valor.nivel {
    color: #8b5cf6;
    font-size: 1.25rem;
    font-weight: 700;
  }

  .detalle-valor.progreso {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .barra-progreso {
    flex: 1;
    height: 8px;
    background: #e5e7eb;
    border-radius: 4px;
    overflow: hidden;
  }

  .barra-relleno {
    height: 100%;
    background: linear-gradient(90deg, #3b82f6, #8b5cf6);
    border-radius: 4px;
    transition: width 0.5s ease;
  }

  .porcentaje {
    font-size: 0.875rem;
    font-weight: 600;
    color: #3b82f6;
  }

  .detalle-valor.tiempo {
    color: #059669;
    font-weight: 600;
  }

  .detalle-valor.actividad {
    color: #10b981;
    font-weight: 600;
  }

  .detalle-valor.especialidad {
    color: #dc2626;
    font-weight: 600;
  }

  /* Estado de carga */
  .cargando-perfil {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 2rem;
    text-align: center;
    gap: 1rem;
  }

  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .cargando-perfil p {
    color: #6b7280;
    font-weight: 500;
    font-size: 1.1rem;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .perfil-contenido {
      padding: 1rem;
      gap: 1.5rem;
    }

    .seccion {
      padding: 1rem;
    }

    .seccion h2 {
      font-size: 1.25rem;
    }

    .stats-grid {
      grid-template-columns: repeat(3, 1fr);
      gap: 1rem;
    }

    .stat-card {
      padding: 1.5rem;
    }

    .stat-numero {
      font-size: 2.5rem;
    }

    .info-grid {
      grid-template-columns: 1fr;
    }

    .detalles-grid {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 480px) {
    .perfil-contenido {
      padding: 0.5rem;
    }

    .seccion {
      padding: 0.75rem;
    }

    .info-item {
      padding: 0.75rem;
    }

    .detalle-item {
      padding: 1rem;
    }

    .detalles-grid {
      gap: 1rem;
    }

    .detalle-icon {
      font-size: 2rem;
    }

    .detalle-valor.ranking, .detalle-valor.nivel {
      font-size: 1.1rem;
    }

    .stats-grid {
      gap: 0.75rem;
    }

    .stat-card {
      padding: 1rem;
    }

    .stat-numero {
      font-size: 2rem;
    }

    .stat-label {
      font-size: 0.75rem;
    }
  }
</style> 