<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
  import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';

  // Props de la página (del servidor)
  export let data: any;
  const { perfil, esUsuarioPropio } = data;

  // Datos de ranking (simulados por ahora)
  let datosRanking: any = {};
  let insignias: any[] = [];
  let cargando = true;

  onMount(async () => {
    // Simular carga de datos de ranking
    setTimeout(() => {
      datosRanking = {
        nivel: 12,
        experiencia_actual: 2850,
        experiencia_siguiente_nivel: 3000,
        puntos_totales: 15420,
        posicion_global: 347,
        racha_dias: 15,
        cursos_completados: 8,
        tiempo_total_estudio: "45h 30m"
      };

      insignias = [
        {
          id: 1,
          nombre: "Primer Paso",
          descripcion: "Completó su primer curso",
          icono: "🎯",
          fecha_obtenida: "2024-01-10",
          rareza: "común"
        },
        {
          id: 2,
          nombre: "Constante",
          descripcion: "7 días consecutivos de estudio",
          icono: "🔥",
          fecha_obtenida: "2024-01-18",
          rareza: "raro"
        },
        {
          id: 3,
          nombre: "Maestro del Acordeón",
          descripcion: "Dominó técnicas avanzadas de acordeón",
          icono: "🪗",
          fecha_obtenida: "2024-02-01",
          rareza: "épico"
        },
        {
          id: 4,
          nombre: "Colaborador",
          descripcion: "Ayudó a 10 compañeros en la comunidad",
          icono: "🤝",
          fecha_obtenida: "2024-02-15",
          rareza: "raro"
        },
        {
          id: 5,
          nombre: "Compositor",
          descripcion: "Creó su primera composición original",
          icono: "🎼",
          fecha_obtenida: "2024-03-01",
          rareza: "épico"
        }
      ];
      cargando = false;
    }, 1000);
  });

  // Calcular progreso de experiencia
  $: progresoExperiencia = datosRanking.experiencia_actual ? 
    (datosRanking.experiencia_actual / datosRanking.experiencia_siguiente_nivel) * 100 : 0;

  // Función para obtener color según rareza
  function getColorRareza(rareza: string) {
    switch(rareza) {
      case 'común': return '#10b981';
      case 'raro': return '#3b82f6';
      case 'épico': return '#8b5cf6';
      case 'legendario': return '#f59e0b';
      default: return '#6b7280';
    }
  }
</script>

<svelte:head>
  <title>Ranking de {perfil.nombre} {perfil.apellido} - Academia Vallenata</title>
  <meta name="description" content="Ve el nivel, logros e insignias de {perfil.nombre} {perfil.apellido} en la Academia Vallenata Online." />
</svelte:head>

<div class="contenedor-perfil">
  <!-- Encabezado del perfil -->
  <EncabezadoPerfil 
    bind:nombreCompleto={perfil.nombre_completo} 
    bind:correoElectronico={perfil.correo_electronico} 
    bind:urlAvatar={perfil.url_foto_perfil} 
    bind:urlPortada={perfil.portada_url} 
    bind:posicionPortadaY={perfil.posicion_img_portada}
    userId={perfil.id}
    stats={{ publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 }}
    esEditable={esUsuarioPropio}
  />

  <!-- Pestañas de navegación -->
  <PestanasPerfil 
    esPerfilPublico={!esUsuarioPropio}
    usuarioSlug={perfil.nombre_usuario || 'usuario'}
  />

  <!-- Contenido de ranking -->
  <div class="contenedor-ranking">
    {#if cargando}
      <div class="cargando">
        <div class="spinner"></div>
        <p>Cargando estadísticas...</p>
      </div>
    {:else}
      <!-- Estadísticas principales -->
      <div class="seccion-estadisticas">
        <h2>📊 Estadísticas de Progreso</h2>
        
        <div class="grid-stats">
          <!-- Nivel y Experiencia -->
          <div class="card-stat principal">
            <div class="nivel-badge">
              <span class="numero-nivel">{datosRanking.nivel}</span>
              <span class="texto-nivel">NIVEL</span>
            </div>
            <div class="experiencia-info">
              <div class="barra-experiencia">
                <div class="progreso-experiencia" style="width: {progresoExperiencia}%"></div>
              </div>
              <div class="numeros-experiencia">
                <span>{datosRanking.experiencia_actual} / {datosRanking.experiencia_siguiente_nivel} XP</span>
              </div>
            </div>
          </div>

          <!-- Puntos Totales -->
          <div class="card-stat">
            <div class="icono-stat">🏆</div>
            <div class="contenido-stat">
              <div class="numero-stat">{datosRanking.puntos_totales.toLocaleString()}</div>
              <div class="label-stat">Puntos Totales</div>
            </div>
          </div>

          <!-- Posición Global -->
          <div class="card-stat">
            <div class="icono-stat">🌟</div>
            <div class="contenido-stat">
              <div class="numero-stat">#{datosRanking.posicion_global}</div>
              <div class="label-stat">Posición Global</div>
            </div>
          </div>

          <!-- Racha de Días -->
          <div class="card-stat">
            <div class="icono-stat">🔥</div>
            <div class="contenido-stat">
              <div class="numero-stat">{datosRanking.racha_dias}</div>
              <div class="label-stat">Días de Racha</div>
            </div>
          </div>

          <!-- Cursos Completados -->
          <div class="card-stat">
            <div class="icono-stat">📚</div>
            <div class="contenido-stat">
              <div class="numero-stat">{datosRanking.cursos_completados}</div>
              <div class="label-stat">Cursos Completados</div>
            </div>
          </div>

          <!-- Tiempo de Estudio -->
          <div class="card-stat">
            <div class="icono-stat">⏰</div>
            <div class="contenido-stat">
              <div class="numero-stat">{datosRanking.tiempo_total_estudio}</div>
              <div class="label-stat">Tiempo de Estudio</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Insignias y Logros -->
      <div class="seccion-insignias">
        <h2>🏅 Insignias y Logros</h2>
        
        {#if insignias.length === 0}
          <div class="sin-insignias">
            <div class="icono-vacio">🏅</div>
            <h3>No hay insignias</h3>
            <p>{esUsuarioPropio ? 'Completa cursos y actividades para obtener insignias.' : `${perfil.nombre} no ha obtenido insignias aún.`}</p>
          </div>
        {:else}
          <div class="grid-insignias">
            {#each insignias as insignia (insignia.id)}
              <div class="card-insignia" style="border-color: {getColorRareza(insignia.rareza)}">
                <div class="icono-insignia" style="background: {getColorRareza(insignia.rareza)}">
                  {insignia.icono}
                </div>
                <div class="info-insignia">
                  <h3 class="nombre-insignia">{insignia.nombre}</h3>
                  <p class="descripcion-insignia">{insignia.descripcion}</p>
                  <div class="metadata-insignia">
                    <span class="rareza-badge" style="background: {getColorRareza(insignia.rareza)}">
                      {insignia.rareza}
                    </span>
                    <span class="fecha-insignia">
                      {new Date(insignia.fecha_obtenida).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        {/if}
      </div>
    {/if}
  </div>
</div>

<style>
  .contenedor-perfil {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0;
  }

  .contenedor-ranking {
    background: white;
    border-radius: 16px;
    padding: 2rem;
    margin-top: 1rem;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  }

  .cargando {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 0;
    color: #64748b;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #f1f5f9;
    border-top: 4px solid #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .seccion-estadisticas, .seccion-insignias {
    margin-bottom: 3rem;
  }

  .seccion-estadisticas h2, .seccion-insignias h2 {
    font-size: 1.75rem;
    font-weight: 700;
    color: #1e293b;
    margin: 0 0 2rem 0;
    padding-bottom: 1rem;
    border-bottom: 2px solid #f1f5f9;
  }

  .grid-stats {
    display: grid;
    grid-template-columns: 2fr 1fr 1fr;
    grid-template-rows: auto auto;
    gap: 1.5rem;
  }

  .card-stat {
    background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
    border-radius: 16px;
    padding: 1.5rem;
    border: 1px solid #e2e8f0;
    transition: all 0.2s ease;
  }

  .card-stat:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  }

  .card-stat.principal {
    grid-row: span 2;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    text-align: center;
  }

  .nivel-badge {
    width: 120px;
    height: 120px;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    border-radius: 50%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: white;
    margin-bottom: 2rem;
    box-shadow: 0 8px 25px rgba(59, 130, 246, 0.3);
  }

  .numero-nivel {
    font-size: 3rem;
    font-weight: 800;
    line-height: 1;
  }

  .texto-nivel {
    font-size: 0.75rem;
    font-weight: 600;
    letter-spacing: 0.1em;
  }

  .experiencia-info {
    width: 100%;
  }

  .barra-experiencia {
    width: 100%;
    height: 12px;
    background: #e2e8f0;
    border-radius: 6px;
    overflow: hidden;
    margin-bottom: 0.5rem;
  }

  .progreso-experiencia {
    height: 100%;
    background: linear-gradient(90deg, #10b981, #059669);
    border-radius: 6px;
    transition: width 0.3s ease;
  }

  .numeros-experiencia {
    font-size: 0.875rem;
    color: #64748b;
    font-weight: 500;
  }

  .icono-stat {
    font-size: 2.5rem;
    margin-bottom: 1rem;
  }

  .numero-stat {
    font-size: 2rem;
    font-weight: 700;
    color: #1e293b;
    margin-bottom: 0.25rem;
  }

  .label-stat {
    font-size: 0.875rem;
    color: #64748b;
    font-weight: 500;
  }

  .grid-insignias {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1.5rem;
  }

  .card-insignia {
    background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
    border-radius: 16px;
    padding: 1.5rem;
    border: 2px solid #e2e8f0;
    transition: all 0.2s ease;
    display: flex;
    gap: 1rem;
  }

  .card-insignia:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  }

  .icono-insignia {
    width: 60px;
    height: 60px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.75rem;
    color: white;
    flex-shrink: 0;
  }

  .info-insignia {
    flex: 1;
  }

  .nombre-insignia {
    font-size: 1.125rem;
    font-weight: 600;
    color: #1e293b;
    margin: 0 0 0.5rem 0;
  }

  .descripcion-insignia {
    font-size: 0.875rem;
    color: #64748b;
    margin: 0 0 1rem 0;
    line-height: 1.4;
  }

  .metadata-insignia {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .rareza-badge {
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    color: white;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .fecha-insignia {
    font-size: 0.75rem;
    color: #64748b;
  }

  .sin-insignias {
    text-align: center;
    padding: 4rem 0;
    color: #64748b;
  }

  .icono-vacio {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .sin-insignias h3 {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0 0 0.5rem 0;
    color: #475569;
  }

  @media (max-width: 768px) {
    .contenedor-ranking {
      padding: 1rem;
      margin-top: 0.5rem;
    }

    .grid-stats {
      grid-template-columns: 1fr;
      grid-template-rows: auto;
    }

    .card-stat.principal {
      grid-row: span 1;
    }

    .nivel-badge {
      width: 100px;
      height: 100px;
      margin-bottom: 1.5rem;
    }

    .numero-nivel {
      font-size: 2.5rem;
    }

    .grid-insignias {
      grid-template-columns: 1fr;
    }

    .card-insignia {
      padding: 1rem;
    }

    .icono-insignia {
      width: 50px;
      height: 50px;
      font-size: 1.5rem;
    }
  }
</style> 