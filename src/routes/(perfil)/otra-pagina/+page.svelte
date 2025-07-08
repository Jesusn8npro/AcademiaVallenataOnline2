<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { eventosService } from '$lib/services/eventosService';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { temaOscuro } from '$lib/stores/temaStore';
  import type { EventoUsuario } from '$lib/services/eventosService';

  // Estados
  let eventos: EventoUsuario[] = [];
  let cargando = true;
  let error: string | null = null;
  let filtroActivo = 'todos'; // todos, proximos, pasados, cancelados
  let busqueda = '';

  // Cargar eventos del usuario
  onMount(async () => {
    await cargarEventos();
  });

  async function cargarEventos() {
    try {
      cargando = true;
      error = null;
      
      if (!$usuario?.id) {
        error = 'Usuario no autenticado';
        return;
      }

      const { eventos: eventosObtenidos, error: errorEventos } = await eventosService.obtenerEventosUsuario($usuario.id);
      
      if (errorEventos) {
        error = errorEventos;
        return;
      }

      eventos = eventosObtenidos || [];
      console.log('🎉 Eventos cargados:', eventos);
      
    } catch (err) {
      console.error('Error cargando eventos:', err);
      error = 'Error inesperado al cargar eventos';
    } finally {
      cargando = false;
    }
  }

  // Filtrar eventos
  $: eventosFiltrados = eventos.filter(evento => {
    // Filtro por búsqueda
    if (busqueda) {
      const terminoBusqueda = busqueda.toLowerCase();
      const coincideTexto = evento.titulo.toLowerCase().includes(terminoBusqueda) ||
                           evento.descripcion?.toLowerCase().includes(terminoBusqueda) ||
                           evento.tipo_evento.toLowerCase().includes(terminoBusqueda);
      if (!coincideTexto) return false;
    }

    // Filtro por estado
    if (filtroActivo === 'todos') return true;
    
    const ahora = new Date();
    const fechaEvento = new Date(evento.fecha_inicio);
    
    switch (filtroActivo) {
      case 'proximos':
        return fechaEvento > ahora && evento.estado !== 'cancelado';
      case 'pasados':
        return fechaEvento < ahora || evento.estado === 'finalizado';
      case 'cancelados':
        return evento.estado === 'cancelado';
      default:
        return true;
    }
  });

  // Funciones auxiliares
  function formatearFecha(fecha: string): string {
    return new Date(fecha).toLocaleDateString('es-ES', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  function formatearFechaCorta(fecha: string): string {
    return new Date(fecha).toLocaleDateString('es-ES', {
      month: 'short',
      day: 'numeric'
    });
  }

  function obtenerColorEstado(estado: string): string {
    switch (estado) {
      case 'confirmado': return 'success';
      case 'cancelado': return 'danger';
      case 'finalizado': return 'secondary';
      case 'pendiente': return 'warning';
      default: return 'primary';
    }
  }

  function obtenerColorTipo(tipo: string): string {
    switch (tipo) {
      case 'taller': return 'blue';
      case 'conferencia': return 'purple';
      case 'curso': return 'green';
      case 'reunion': return 'orange';
      default: return 'gray';
    }
  }

  function navegarAEvento(evento: EventoUsuario): void {
    goto(`/eventos/${evento.slug}`);
  }

  function obtenerContadorEventos(filtro: string): number {
    return eventos.filter(evento => {
      const ahora = new Date();
      const fechaEvento = new Date(evento.fecha_inicio);
      
      switch (filtro) {
        case 'todos': return true;
        case 'proximos': return fechaEvento > ahora && evento.estado !== 'cancelado';
        case 'pasados': return fechaEvento < ahora || evento.estado === 'finalizado';
        case 'cancelados': return evento.estado === 'cancelado';
        default: return true;
      }
    }).length;
  }
</script>

<svelte:head>
  <title>Mis eventos - Academia Vallenata</title>
  <meta name="description" content="Eventos y actividades en los que estás registrado" />
</svelte:head>

<div class="eventos-container" class:tema-oscuro={$temaOscuro}>
  <!-- Encabezado -->
  <div class="encabezado">
    <div class="titulo-section">
      <h1>🎭 Mis eventos</h1>
      <p class="subtitulo">Eventos y actividades en los que estás registrado</p>
    </div>
    
    <!-- Barra de búsqueda -->
    <div class="busqueda-container">
      <div class="input-busqueda">
        <svg class="icono-busqueda" width="20" height="20" viewBox="0 0 24 24">
          <circle cx="11" cy="11" r="8" stroke="currentColor" stroke-width="2"/>
          <path d="M21 21l-4.35-4.35" stroke="currentColor" stroke-width="2"/>
        </svg>
        <input 
          type="text" 
          placeholder="Buscar eventos..."
          bind:value={busqueda}
          class="input-search"
        />
      </div>
    </div>
  </div>

  <!-- Filtros -->
  <div class="filtros-container">
    <div class="filtros-tabs">
      <button 
        class="tab-filtro" 
        class:activo={filtroActivo === 'todos'}
        on:click={() => filtroActivo = 'todos'}
      >
        Todos
        <span class="contador">{obtenerContadorEventos('todos')}</span>
      </button>
      <button 
        class="tab-filtro" 
        class:activo={filtroActivo === 'proximos'}
        on:click={() => filtroActivo = 'proximos'}
      >
        Próximos
        <span class="contador">{obtenerContadorEventos('proximos')}</span>
      </button>
      <button 
        class="tab-filtro" 
        class:activo={filtroActivo === 'pasados'}
        on:click={() => filtroActivo = 'pasados'}
      >
        Pasados
        <span class="contador">{obtenerContadorEventos('pasados')}</span>
      </button>
      <button 
        class="tab-filtro" 
        class:activo={filtroActivo === 'cancelados'}
        on:click={() => filtroActivo = 'cancelados'}
      >
        Cancelados
        <span class="contador">{obtenerContadorEventos('cancelados')}</span>
      </button>
    </div>
  </div>

  <!-- Contenido principal -->
  <div class="contenido-principal">
    {#if cargando}
      <div class="estado-carga">
        <div class="spinner"></div>
        <p>Cargando tus eventos...</p>
      </div>
    {:else if error}
      <div class="estado-error">
        <div class="icono-error">❌</div>
        <h3>Error al cargar eventos</h3>
        <p>{error}</p>
        <button class="btn-reintentar" on:click={cargarEventos}>
          Reintentar
        </button>
      </div>
    {:else if eventosFiltrados.length === 0}
      <div class="estado-vacio">
        {#if eventos.length === 0}
          <div class="icono-vacio">🎭</div>
          <h3>No tienes eventos registrados</h3>
          <p>Aún no te has registrado en ningún evento. ¡Explora nuestros eventos disponibles!</p>
          <button class="btn-explorar" on:click={() => goto('/eventos')}>
            Explorar eventos
          </button>
        {:else}
          <div class="icono-vacio">🔍</div>
          <h3>No se encontraron eventos</h3>
          <p>No hay eventos que coincidan con tu búsqueda o filtro seleccionado.</p>
        {/if}
      </div>
    {:else}
      <!-- Grid de eventos -->
      <div class="eventos-grid">
        {#each eventosFiltrados as evento}
          <div class="evento-card" on:click={() => navegarAEvento(evento)}>
            <!-- Imagen del evento -->
            <div class="evento-imagen">
              {#if evento.imagen_url}
                <img src={evento.imagen_url} alt={evento.titulo} />
              {:else}
                <div class="imagen-placeholder">
                  <span class="icono-evento">🎭</span>
                </div>
              {/if}
              
              <!-- Badges -->
              <div class="badges-container">
                <span class="badge badge-tipo {obtenerColorTipo(evento.tipo_evento)}">
                  {evento.tipo_evento}
                </span>
                {#if evento.es_gratuito}
                  <span class="badge badge-gratuito">Gratuito</span>
                {/if}
              </div>
            </div>

            <!-- Información del evento -->
            <div class="evento-info">
              <!-- Fecha -->
              <div class="evento-fecha">
                <div class="fecha-numero">{formatearFechaCorta(evento.fecha_inicio)}</div>
                <div class="fecha-hora">
                  {new Date(evento.fecha_inicio).toLocaleTimeString('es-ES', {
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </div>
              </div>

              <!-- Contenido principal -->
              <div class="evento-contenido">
                <h3 class="evento-titulo">{evento.titulo}</h3>
                
                {#if evento.descripcion_corta}
                  <p class="evento-descripcion">{evento.descripcion_corta}</p>
                {/if}

                <!-- Detalles -->
                <div class="evento-detalles">
                  <div class="detalle-item">
                    <span class="icono">📍</span>
                    <span class="texto">{evento.modalidad}</span>
                  </div>
                  
                  {#if evento.ubicacion}
                    <div class="detalle-item">
                      <span class="icono">🏢</span>
                      <span class="texto">{evento.ubicacion}</span>
                    </div>
                  {/if}

                  {#if evento.instructor_nombre}
                    <div class="detalle-item">
                      <span class="icono">👨‍🏫</span>
                      <span class="texto">{evento.instructor_nombre}</span>
                    </div>
                  {/if}
                </div>

                <!-- Estado y acciones -->
                <div class="evento-footer">
                  <span class="estado-badge estado-{obtenerColorEstado(evento.estado)}">
                    {evento.estado}
                  </span>
                  
                  {#if evento.estado === 'confirmado'}
                    <span class="fecha-completa">
                      {formatearFecha(evento.fecha_inicio)}
                    </span>
                  {/if}
                </div>
              </div>
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<style>
  .eventos-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    min-height: 100vh;
  }

  /* Encabezado */
  .encabezado {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
    gap: 20px;
  }

  .titulo-section h1 {
    font-size: 2.5rem;
    font-weight: 700;
    color: var(--color-texto-principal);
    margin: 0;
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .subtitulo {
    color: var(--color-texto-secundario);
    font-size: 1.1rem;
    margin: 5px 0 0 0;
  }

  /* Búsqueda */
  .busqueda-container {
    flex: 1;
    max-width: 400px;
  }

  .input-busqueda {
    position: relative;
    width: 100%;
  }

  .icono-busqueda {
    position: absolute;
    left: 12px;
    top: 50%;
    transform: translateY(-50%);
    color: var(--color-texto-secundario);
    pointer-events: none;
  }

  .input-search {
    width: 100%;
    padding: 12px 16px 12px 44px;
    border: 2px solid var(--color-borde);
    border-radius: 12px;
    font-size: 1rem;
    background: var(--color-fondo-secundario);
    color: var(--color-texto-principal);
    transition: all 0.3s ease;
  }

  .input-search:focus {
    outline: none;
    border-color: var(--color-primario);
    box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.1);
  }

  /* Filtros */
  .filtros-container {
    margin-bottom: 30px;
  }

  .filtros-tabs {
    display: flex;
    gap: 8px;
    background: var(--color-fondo-secundario);
    padding: 4px;
    border-radius: 12px;
    border: 1px solid var(--color-borde);
  }

  .tab-filtro {
    flex: 1;
    padding: 12px 16px;
    background: none;
    border: none;
    border-radius: 8px;
    font-size: 0.95rem;
    font-weight: 500;
    color: var(--color-texto-secundario);
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
  }

  .tab-filtro:hover {
    background: var(--color-hover);
    color: var(--color-texto-principal);
  }

  .tab-filtro.activo {
    background: var(--color-primario);
    color: white;
    font-weight: 600;
  }

  .contador {
    background: rgba(255, 255, 255, 0.2);
    padding: 2px 8px;
    border-radius: 12px;
    font-size: 0.8rem;
    font-weight: 600;
  }

  .tab-filtro.activo .contador {
    background: rgba(255, 255, 255, 0.3);
  }

  /* Estados */
  .estado-carga, .estado-error, .estado-vacio {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 300px;
    text-align: center;
    padding: 40px;
  }

  .spinner {
    width: 48px;
    height: 48px;
    border: 4px solid var(--color-borde);
    border-top: 4px solid var(--color-primario);
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 20px;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .icono-error, .icono-vacio {
    font-size: 4rem;
    margin-bottom: 20px;
  }

  .estado-error h3, .estado-vacio h3 {
    color: var(--color-texto-principal);
    margin-bottom: 10px;
  }

  .estado-error p, .estado-vacio p {
    color: var(--color-texto-secundario);
    margin-bottom: 20px;
  }

  .btn-reintentar, .btn-explorar {
    padding: 12px 24px;
    background: var(--color-primario);
    color: white;
    border: none;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .btn-reintentar:hover, .btn-explorar:hover {
    background: var(--color-primario-hover);
    transform: translateY(-2px);
  }

  /* Grid de eventos */
  .eventos-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 24px;
  }

  .evento-card {
    background: var(--color-fondo-secundario);
    border: 1px solid var(--color-borde);
    border-radius: 16px;
    overflow: hidden;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }

  .evento-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
    border-color: var(--color-primario);
  }

  /* Imagen del evento */
  .evento-imagen {
    position: relative;
    height: 200px;
    overflow: hidden;
  }

  .evento-imagen img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .imagen-placeholder {
    width: 100%;
    height: 100%;
    background: linear-gradient(135deg, var(--color-primario), var(--color-secundario));
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .icono-evento {
    font-size: 4rem;
    opacity: 0.7;
  }

  .badges-container {
    position: absolute;
    top: 12px;
    right: 12px;
    display: flex;
    gap: 8px;
  }

  .badge {
    padding: 4px 8px;
    border-radius: 6px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    backdrop-filter: blur(10px);
  }

  .badge-tipo.blue { background: rgba(59, 130, 246, 0.9); color: white; }
  .badge-tipo.purple { background: rgba(139, 92, 246, 0.9); color: white; }
  .badge-tipo.green { background: rgba(34, 197, 94, 0.9); color: white; }
  .badge-tipo.orange { background: rgba(251, 146, 60, 0.9); color: white; }
  .badge-tipo.gray { background: rgba(107, 114, 128, 0.9); color: white; }

  .badge-gratuito {
    background: rgba(34, 197, 94, 0.9);
    color: white;
  }

  /* Información del evento */
  .evento-info {
    padding: 20px;
    display: flex;
    gap: 16px;
  }

  .evento-fecha {
    flex-shrink: 0;
    text-align: center;
    background: var(--color-fondo-terciario);
    padding: 12px;
    border-radius: 8px;
    border: 1px solid var(--color-borde);
  }

  .fecha-numero {
    font-size: 1.1rem;
    font-weight: 700;
    color: var(--color-primario);
    line-height: 1;
  }

  .fecha-hora {
    font-size: 0.8rem;
    color: var(--color-texto-secundario);
    margin-top: 4px;
  }

  .evento-contenido {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .evento-titulo {
    font-size: 1.3rem;
    font-weight: 700;
    color: var(--color-texto-principal);
    margin: 0;
    line-height: 1.3;
  }

  .evento-descripcion {
    color: var(--color-texto-secundario);
    font-size: 0.95rem;
    line-height: 1.4;
    margin: 0;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .evento-detalles {
    display: flex;
    flex-direction: column;
    gap: 4px;
    margin: 8px 0;
  }

  .detalle-item {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 0.9rem;
    color: var(--color-texto-secundario);
  }

  .detalle-item .icono {
    width: 16px;
    text-align: center;
  }

  .detalle-item .texto {
    flex: 1;
  }

  .evento-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
    margin-top: auto;
    padding-top: 12px;
    border-top: 1px solid var(--color-borde);
  }

  .estado-badge {
    padding: 4px 8px;
    border-radius: 6px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
  }

  .estado-success { background: rgba(34, 197, 94, 0.1); color: #22c55e; }
  .estado-danger { background: rgba(239, 68, 68, 0.1); color: #ef4444; }
  .estado-warning { background: rgba(251, 146, 60, 0.1); color: #fb923c; }
  .estado-secondary { background: rgba(107, 114, 128, 0.1); color: #6b7280; }
  .estado-primary { background: rgba(139, 92, 246, 0.1); color: #8b5cf6; }

  .fecha-completa {
    font-size: 0.75rem;
    color: var(--color-texto-secundario);
  }

  /* Tema oscuro */
  .tema-oscuro {
    --color-fondo-principal: #0f0f0f;
    --color-fondo-secundario: #1a1a1a;
    --color-fondo-terciario: #262626;
    --color-texto-principal: #ffffff;
    --color-texto-secundario: #a3a3a3;
    --color-borde: #404040;
    --color-hover: #2a2a2a;
    --color-primario: #8b5cf6;
    --color-primario-hover: #7c3aed;
    --color-secundario: #06b6d4;
  }

  /* Responsivo */
  @media (max-width: 768px) {
    .eventos-container {
      padding: 16px;
    }

    .encabezado {
      flex-direction: column;
      align-items: stretch;
      gap: 16px;
    }

    .titulo-section h1 {
      font-size: 2rem;
    }

    .busqueda-container {
      max-width: none;
    }

    .filtros-tabs {
      flex-direction: column;
      gap: 4px;
    }

    .tab-filtro {
      justify-content: space-between;
    }

    .eventos-grid {
      grid-template-columns: 1fr;
      gap: 16px;
    }

    .evento-card {
      border-radius: 12px;
    }

    .evento-info {
      flex-direction: column;
      gap: 12px;
    }

    .evento-fecha {
      align-self: flex-start;
    }

    .evento-footer {
      flex-direction: column;
      align-items: flex-start;
      gap: 8px;
    }
  }
</style> 