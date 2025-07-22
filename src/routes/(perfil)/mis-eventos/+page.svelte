<script lang="ts">
  import { onMount } from 'svelte';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { eventosService, type EventoCompleto, type FiltrosEventos } from '$lib/services/eventosService';
  import { modoOscuro } from '$lib/stores/temaStore';

  let eventos: EventoCompleto[] = [];
  let cargando = true;
  let error = '';
  let filtroActivo = 'todos';
  let busqueda = '';
  
  const filtros = [
    { valor: 'todos', etiqueta: 'Todos', icono: '📅' },
    { valor: 'proximos', etiqueta: 'Próximos', icono: '🔮' },
    { valor: 'pasados', etiqueta: 'Finalizados', icono: '✅' }
  ];

  $: eventosFiltrados = filtrarEventos(eventos, filtroActivo, busqueda);

  function filtrarEventos(todosEventos: EventoCompleto[], filtro: string, termino: string) {
    let resultado = [...todosEventos];
    const ahora = new Date();
    
    if (filtro === 'proximos') {
      resultado = resultado.filter(e => new Date(e.fecha_inicio) > ahora);
    } else if (filtro === 'pasados') {
      resultado = resultado.filter(e => new Date(e.fecha_inicio) <= ahora);
    }
    
    if (termino.trim()) {
      const buscar = termino.toLowerCase();
      resultado = resultado.filter(e => 
        e.titulo.toLowerCase().includes(buscar) ||
        (e.descripcion && e.descripcion.toLowerCase().includes(buscar)) ||
        (e.categoria && e.categoria.toLowerCase().includes(buscar))
      );
    }
    
    return resultado;
  }

  async function cargarEventos() {
    try {
      cargando = true;
      error = '';

      if (!$perfilStore.perfil?.id) {
        error = 'No se encontró información del usuario';
        return;
      }

      const resultado = await eventosService.obtenerEventosUsuario($perfilStore.perfil.id);
      eventos = resultado || [];
    } catch (err) {
      console.error('Error cargando eventos:', err);
      error = 'Error al cargar los eventos. Intenta de nuevo.';
      eventos = [];
    } finally {
      cargando = false;
    }
  }

  function formatearFecha(fecha: string): string {
    return new Date(fecha).toLocaleDateString('es-CO', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  function formatearPrecio(precio: number, moneda: string = 'COP'): string {
    if (precio === 0) return 'Gratis';
    return new Intl.NumberFormat('es-CO', { 
      style: 'currency', 
      currency: moneda 
    }).format(precio);
  }

  function obtenerEstadoEvento(fecha: string, estado: string = 'activo') {
    const ahora = new Date();
    const fechaEvento = new Date(fecha);
    
    if (estado === 'cancelado') return { texto: 'Cancelado', clase: 'estado-cancelado' };
    if (fechaEvento < ahora) return { texto: 'Finalizado', clase: 'estado-finalizado' };
    if (fechaEvento > ahora) return { texto: 'Próximo', clase: 'estado-proximo' };
    return { texto: 'En vivo', clase: 'estado-envivo' };
  }

  onMount(async () => {
    try {
      if (!$perfilStore.inicializado) {
        await perfilStore.cargarDatosPerfil();
      }
      await cargarEventos();
    } catch (err) {
      console.error('Error en onMount:', err);
      error = 'Error al inicializar la página';
    }
  });

  // Recargar eventos cuando cambia el filtro
  $: if (filtroActivo && !cargando) {
    // Opcional: recargar desde el servidor con filtros
  }
</script>

<svelte:head>
  <title>Mis Eventos - Academia Vallenata</title>
  <meta name="description" content="Administra tus eventos inscritos en Academia Vallenata" />
  <meta name="robots" content="noindex" />
</svelte:head>

<div class="contenido-mis-eventos" class:tema-oscuro={$modoOscuro}>
  <!-- Encabezado -->
  <div class="encabezado">
    <div class="titulo-seccion">
      <h1>📅 Mis Eventos</h1>
      <p>Administra tus eventos inscritos</p>
    </div>
  </div>

  <!-- Barra de filtros y búsqueda -->
  <div class="barra-herramientas">
    <div class="filtros">
      {#each filtros as filtro}
        <button
          class="btn-filtro"
          class:activo={filtroActivo === filtro.valor}
          on:click={() => filtroActivo = filtro.valor}
        >
          <span class="icono">{filtro.icono}</span>
          <span class="texto">{filtro.etiqueta}</span>
        </button>
      {/each}
    </div>
    
    <div class="busqueda">
      <div class="input-busqueda">
        <svg class="icono-busqueda" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/>
          <path d="m21 21-4.35-4.35"/>
        </svg>
        <input
          type="text"
          placeholder="Buscar eventos..."
          bind:value={busqueda}
          class="campo-busqueda"
        />
      </div>
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
        <div class="icono-error">⚠️</div>
        <h3>Error al cargar eventos</h3>
        <p>{error}</p>
        <button class="btn-reintentar" on:click={cargarEventos}>
          🔄 Intentar de nuevo
        </button>
      </div>
    {:else if eventosFiltrados.length === 0}
      <div class="estado-vacio">
        <div class="icono-vacio">🎭</div>
        <h3>
          {filtroActivo === 'todos' ? 'No tienes eventos inscritos' : 
           filtroActivo === 'proximos' ? 'No tienes eventos próximos' :
           'No tienes eventos finalizados'}
        </h3>
        <p>
          {filtroActivo === 'todos' ? 'Explora nuestro catálogo y apúntate a eventos increíbles' : 
           filtroActivo === 'proximos' ? 'Los eventos que reserves aparecerán aquí' :
           'Aquí verás tu historial de eventos'}
        </p>
        <a href="/eventos" class="btn-explorar">
          🌟 Explorar Eventos
        </a>
      </div>
    {:else}
      <div class="lista-eventos">
        {#each eventosFiltrados as evento (evento.id)}
          <div class="tarjeta-evento">
            <div class="imagen-evento">
              {#if evento.imagen_portada}
                <img src={evento.imagen_portada} alt={evento.titulo} />
              {:else}
                <div class="placeholder-imagen">🎭</div>
              {/if}
              <div class="estado-badge {obtenerEstadoEvento(evento.fecha_inicio, evento.estado).clase}">
                {obtenerEstadoEvento(evento.fecha_inicio, evento.estado).texto}
              </div>
            </div>
            
            <div class="info-evento">
              <div class="encabezado-evento">
                <h3 class="titulo-evento">{evento.titulo}</h3>
                <div class="precio-evento">
                  {formatearPrecio(evento.precio, evento.moneda)}
                </div>
              </div>
              
              <div class="detalles-evento">
                <div class="fecha-hora">
                  <svg class="icono" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                  </svg>
                  <span>{formatearFecha(evento.fecha_inicio)}</span>
                </div>
                
                {#if evento.modalidad}
                  <div class="modalidad">
                    <svg class="icono" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                      <circle cx="12" cy="10" r="3"/>
                    </svg>
                    <span>{evento.modalidad}</span>
                  </div>
                {/if}
                
                {#if evento.instructor_nombre}
                  <div class="instructor">
                    <svg class="icono" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                      <circle cx="12" cy="7" r="4"/>
                    </svg>
                    <span>{evento.instructor_nombre}</span>
                  </div>
                {/if}
              </div>
              
              {#if evento.descripcion_corta}
                <p class="descripcion-evento">{evento.descripcion_corta}</p>
              {/if}
              
              <div class="acciones-evento">
                <a href="/eventos/{evento.slug}" class="btn-ver-evento">
                  👁️ Ver Detalles
                </a>
                
                {#if obtenerEstadoEvento(evento.fecha_inicio, evento.estado).texto === 'En vivo'}
                  <a href="/eventos/{evento.slug}/sala" class="btn-unirse">
                    🔴 Unirse Ahora
                  </a>
                {:else if obtenerEstadoEvento(evento.fecha_inicio, evento.estado).texto === 'Finalizado' && evento.enlace_grabacion}
                  <a href={evento.enlace_grabacion} class="btn-ver-grabacion" target="_blank">
                    📹 Ver Grabación
                  </a>
                {/if}
              </div>
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<style>
  .contenido-mis-eventos {
    min-height: 100vh;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    padding: 2rem;
  }

  .encabezado {
    margin-bottom: 2rem;
  }

  .titulo-seccion h1 {
    font-size: 2.5rem;
    font-weight: 800;
    color: #1e293b;
    margin: 0 0 0.5rem 0;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .titulo-seccion p {
    color: #64748b;
    font-size: 1.1rem;
    margin: 0;
  }

  .barra-herramientas {
    display: flex;
    gap: 2rem;
    margin-bottom: 2rem;
    align-items: center;
    flex-wrap: wrap;
  }

  .filtros {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
  }

  .btn-filtro {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    background: white;
    border: 2px solid #e2e8f0;
    border-radius: 12px;
    font-weight: 500;
    color: #64748b;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .btn-filtro:hover {
    border-color: #cbd5e1;
    transform: translateY(-2px);
  }

  .btn-filtro.activo {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-color: #667eea;
    color: white;
  }

  .busqueda {
    flex: 1;
    max-width: 400px;
  }

  .input-busqueda {
    position: relative;
    width: 100%;
  }

  .icono-busqueda {
    position: absolute;
    left: 1rem;
    top: 50%;
    transform: translateY(-50%);
    width: 20px;
    height: 20px;
    color: #94a3b8;
  }

  .campo-busqueda {
    width: 100%;
    padding: 0.75rem 1rem 0.75rem 3rem;
    border: 2px solid #e2e8f0;
    border-radius: 12px;
    font-size: 1rem;
    background: white;
    transition: border-color 0.2s ease;
  }

  .campo-busqueda:focus {
    outline: none;
    border-color: #667eea;
  }

  /* Estados */
  .estado-carga, .estado-error, .estado-vacio {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 2rem;
    text-align: center;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #e2e8f0;
    border-top: 4px solid #667eea;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  .icono-error, .icono-vacio {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .btn-reintentar, .btn-explorar {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    text-decoration: none;
    border: none;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    margin-top: 1rem;
  }

  .btn-reintentar:hover, .btn-explorar:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  }

  /* Lista de eventos */
  .lista-eventos {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
    gap: 2rem;
  }

  .tarjeta-evento {
    background: white;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    transition: all 0.3s ease;
    border: 1px solid #e2e8f0;
  }

  .tarjeta-evento:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  }

  .imagen-evento {
    position: relative;
    height: 200px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .imagen-evento img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .placeholder-imagen {
    font-size: 4rem;
    color: rgba(255, 255, 255, 0.8);
  }

  .estado-badge {
    position: absolute;
    top: 1rem;
    right: 1rem;
    padding: 0.5rem 1rem;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 600;
    color: white;
  }

  .estado-proximo { background: #22c55e; }
  .estado-finalizado { background: #64748b; }
  .estado-envivo { background: #ef4444; animation: pulse 2s infinite; }
  .estado-cancelado { background: #f59e0b; }

  .info-evento {
    padding: 1.5rem;
  }

  .encabezado-evento {
    display: flex;
    justify-content: space-between;
    align-items: start;
    margin-bottom: 1rem;
    gap: 1rem;
  }

  .titulo-evento {
    font-size: 1.25rem;
    font-weight: 700;
    color: #1e293b;
    margin: 0;
    flex: 1;
    line-height: 1.3;
  }

  .precio-evento {
    font-size: 1.1rem;
    font-weight: 700;
    color: #059669;
    white-space: nowrap;
  }

  .detalles-evento {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  .fecha-hora, .modalidad, .instructor {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #64748b;
    font-size: 0.9rem;
  }

  .fecha-hora .icono, .modalidad .icono, .instructor .icono {
    width: 16px;
    height: 16px;
    flex-shrink: 0;
  }

  .descripcion-evento {
    color: #64748b;
    line-height: 1.5;
    margin: 0 0 1rem 0;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .acciones-evento {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
  }

  .btn-ver-evento, .btn-unirse, .btn-ver-grabacion {
    padding: 0.5rem 1rem;
    border-radius: 8px;
    text-decoration: none;
    font-size: 0.9rem;
    font-weight: 600;
    transition: all 0.2s ease;
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
  }

  .btn-ver-evento {
    background: #f1f5f9;
    color: #475569;
    border: 1px solid #cbd5e1;
  }

  .btn-ver-evento:hover {
    background: #e2e8f0;
  }

  .btn-unirse {
    background: #ef4444;
    color: white;
    animation: pulse 2s infinite;
  }

  .btn-ver-grabacion {
    background: #8b5cf6;
    color: white;
  }

  .btn-unirse:hover, .btn-ver-grabacion:hover {
    transform: translateY(-1px);
  }

  /* Modo oscuro */
  .tema-oscuro {
    background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  }

  .tema-oscuro .titulo-seccion h1 {
    color: #f1f5f9;
  }

  .tema-oscuro .titulo-seccion p {
    color: #94a3b8;
  }

  .tema-oscuro .btn-filtro {
    background: #334155;
    border-color: #475569;
    color: #cbd5e1;
  }

  .tema-oscuro .btn-filtro:hover {
    border-color: #64748b;
  }

  .tema-oscuro .campo-busqueda {
    background: #334155;
    border-color: #475569;
    color: #f1f5f9;
  }

  .tema-oscuro .campo-busqueda:focus {
    border-color: #667eea;
  }

  .tema-oscuro .tarjeta-evento {
    background: #1e293b;
    border-color: #334155;
  }

  .tema-oscuro .titulo-evento {
    color: #f1f5f9;
  }

  .tema-oscuro .fecha-hora, 
  .tema-oscuro .modalidad, 
  .tema-oscuro .instructor,
  .tema-oscuro .descripcion-evento {
    color: #94a3b8;
  }

  .tema-oscuro .btn-ver-evento {
    background: #374151;
    color: #d1d5db;
    border-color: #4b5563;
  }

  .tema-oscuro .btn-ver-evento:hover {
    background: #4b5563;
  }

  /* Animaciones */
  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.8; }
  }

  /* Responsive */
  @media (max-width: 768px) {
    .contenido-mis-eventos {
      padding: 1rem;
    }
    
    .barra-herramientas {
      flex-direction: column;
      align-items: stretch;
    }
    
    .lista-eventos {
      grid-template-columns: 1fr;
    }
    
    .encabezado-evento {
      flex-direction: column;
      align-items: start;
    }
    
    .acciones-evento {
      justify-content: space-between;
    }
  }
</style> 