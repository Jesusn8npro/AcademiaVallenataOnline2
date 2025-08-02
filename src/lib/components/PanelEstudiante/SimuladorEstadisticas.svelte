<script lang="ts">
  import { goto } from '$app/navigation';

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

  let caracteristicaActiva = 0;

  // 🔄 Rotar características automáticamente
  setInterval(() => {
    caracteristicaActiva = (caracteristicaActiva + 1) % caracteristicas.length;
  }, 3000);

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
