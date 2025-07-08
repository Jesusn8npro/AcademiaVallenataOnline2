<script lang="ts">
  import { onMount } from 'svelte';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { eventosService, type EventoCompleto, type FiltrosEventos } from '$lib/services/eventosService';
  import { temaOscuro } from '$lib/stores/temaStore';

  let eventos: EventoCompleto[] = [];
  let cargando = true;
  let error = '';
  let filtroActivo = 'todos';
  let busqueda = '';
  
  const filtros = [
    { valor: 'todos', etiqueta: 'Todos', icono: '📅' },
    { valor: 'proximos', etiqueta: 'Próximos', icono: '🔮' },
    { valor: 'pasados', etiqueta: 'Finalizados', icono: '✅' },
    { valor: 'cancelados', etiqueta: 'Cancelados', icono: '❌' }
  ];

  $: eventosFiltrados = filtrarEventos(eventos, filtroActivo, busqueda);

  function filtrarEventos(todosEventos: EventoCompleto[], filtro: string, termino: string) {
    let resultado = [...todosEventos];
    
    if (filtro === 'proximos') {
      resultado = resultado.filter(e => new Date(e.fecha_inicio) > new Date());
    } else if (filtro === 'pasados') {
      resultado = resultado.filter(e => new Date(e.fecha_inicio) <= new Date());
    } else if (filtro === 'cancelados') {
      resultado = resultado.filter(e => e.estado === 'cancelado');
    }
    
    if (termino.trim()) {
      const buscar = termino.toLowerCase();
      resultado = resultado.filter(e => 
        e.titulo.toLowerCase().includes(buscar) ||
        e.descripcion?.toLowerCase().includes(buscar) ||
        e.categoria?.toLowerCase().includes(buscar)
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

      const filtrosEventos: FiltrosEventos = {
        estado: filtroActivo !== 'todos' ? filtroActivo : undefined,
        busqueda: busqueda.trim() || undefined
      };

      eventos = await eventosService.obtenerEventosUsuario($perfilStore.perfil.id, filtrosEventos);
    } catch (err) {
      console.error('Error cargando eventos:', err);
      error = 'Error al cargar los eventos. Intenta de nuevo.';
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

  function obtenerEstadoEvento(fecha: string, estado: string) {
    const ahora = new Date();
    const fechaEvento = new Date(fecha);
    
    if (estado === 'cancelado') return { texto: 'Cancelado', clase: 'estado-cancelado' };
    if (fechaEvento < ahora) return { texto: 'Finalizado', clase: 'estado-finalizado' };
    if (fechaEvento > ahora) return { texto: 'Próximo', clase: 'estado-proximo' };
    return { texto: 'En vivo', clase: 'estado-envivo' };
  }

  onMount(async () => {
    if (!$perfilStore.inicializado) {
      await perfilStore.cargarDatosPerfil();
    }
    cargarEventos();
  });
</script>

<svelte:head>
  <title>Mis Eventos - Academia Vallenata</title>
  <meta name="description" content="Gestiona tus eventos de acordeón y masterclasses" />
</svelte:head>

<div class="contenido-mis-eventos" class:tema-oscuro={$temaOscuro}>
  <!-- Encabezado -->
  <div class="encabezado">
    <h1 class="titulo-principal">🎵 Mis Eventos</h1>
    <p class="subtitulo">Gestiona tus masterclasses y eventos de acordeón</p>
  </div>

  <!-- Barra de búsqueda y filtros -->
  <div class="barra-busqueda">
    <!-- Búsqueda -->
    <div class="campo-busqueda">
      <input
        type="text"
        placeholder="Buscar eventos..."
        bind:value={busqueda}
        class="input-busqueda"
      />
      <svg class="icono-busqueda" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m21 21-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      </svg>
    </div>

    <!-- Filtros -->
    <div class="contenedor-filtros">
      {#each filtros as filtro}
        <button
          class="boton-filtro {filtroActivo === filtro.valor ? 'activo' : ''}"
          on:click={() => { filtroActivo = filtro.valor; cargarEventos(); }}
        >
          <span>{filtro.icono}</span>
          <span class="texto-filtro">{filtro.etiqueta}</span>
        </button>
      {/each}
    </div>
  </div>

  <!-- Contenido principal -->
  {#if cargando}
    <div class="estado-cargando">
      <div class="spinner"></div>
      <p>Cargando eventos...</p>
    </div>
  {:else if error}
    <div class="estado-error">
      <div class="icono-error">⚠️</div>
      <h3>Error al cargar</h3>
      <p>{error}</p>
      <button class="boton-reintentar" on:click={cargarEventos}>
        Reintentar
      </button>
    </div>
  {:else if eventosFiltrados.length === 0}
    <div class="estado-vacio">
      <div class="icono-vacio">🎼</div>
      <h3>
        {filtroActivo === 'todos' ? 'No tienes eventos' : `No hay eventos ${filtros.find(f => f.valor === filtroActivo)?.etiqueta.toLowerCase()}`}
      </h3>
      <p>
        {filtroActivo === 'todos' 
          ? 'Inscríbete en masterclasses para empezar a aprender' 
          : 'Prueba cambiando el filtro o buscando otros términos'
        }
      </p>
    </div>
  {:else}
    <!-- Lista de eventos -->
    <div class="grilla-eventos">
      {#each eventosFiltrados as evento (evento.id)}
        {@const estado = obtenerEstadoEvento(evento.fecha_inicio, evento.estado)}
        <div class="tarjeta-evento">
          <!-- Imagen -->
          <div class="imagen-evento">
            {#if evento.imagen_portada}
              <img src={evento.imagen_portada} alt={evento.titulo} />
            {:else}
              <div class="imagen-placeholder">
                <span>🎵</span>
              </div>
            {/if}
            
            <!-- Estado -->
            <div class="contenedor-estado">
              <span class="etiqueta-estado {estado.clase}">
                {estado.texto}
              </span>
            </div>
          </div>

          <!-- Contenido -->
          <div class="contenido-evento">
            <h3 class="titulo-evento">{evento.titulo}</h3>
            <p class="descripcion-evento">{evento.descripcion_corta || evento.descripcion}</p>

            <!-- Fecha y precio -->
            <div class="info-evento">
              <div class="fecha-evento">
                <svg class="icono-fecha" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <span>{formatearFecha(evento.fecha_inicio)}</span>
              </div>
              
              <div class="precio-evento">
                {formatearPrecio(evento.precio, evento.moneda)}
              </div>
            </div>

            <!-- Categoría y modalidad -->
            <div class="etiquetas-evento">
              {#if evento.categoria}
                <span class="etiqueta categoria">{evento.categoria}</span>
              {/if}
              <span class="etiqueta modalidad">{evento.modalidad}</span>
            </div>

            <!-- Acciones -->
            <div class="acciones-evento">
              <button
                class="boton-principal"
                on:click={() => window.open(`/eventos/${evento.slug}`, '_blank')}
              >
                Ver evento
              </button>
              
              {#if evento.link_transmision && new Date(evento.fecha_inicio) <= new Date()}
                <button
                  class="boton-envivo"
                  on:click={() => evento.link_transmision && window.open(evento.link_transmision, '_blank')}
                >
                  🔴 En vivo
                </button>
              {/if}
            </div>
          </div>
        </div>
      {/each}
    </div>

    <!-- Paginación -->
    {#if eventosFiltrados.length > 0}
      <div class="paginacion">
        <p>Mostrando {eventosFiltrados.length} de {eventos.length} eventos</p>
      </div>
    {/if}
  {/if}
</div>

<style>
  /* === CONTENEDOR PRINCIPAL === */
  .contenido-mis-eventos {
    padding: 2rem;
  }

  /* === VARIABLES CSS === */
  :root {
    --color-fondo: #f9fafb;
    --color-fondo-tarjeta: #ffffff;
    --color-texto-principal: #111827;
    --color-texto-secundario: #6b7280;
    --color-borde: #d1d5db;
    --color-amarillo: #eab308;
    --color-amarillo-hover: #ca8a04;
    --color-rojo: #ef4444;
    --color-verde: #10b981;
    --color-azul: #3b82f6;
    --color-gris: #9ca3af;
  }

  /* === TEMA OSCURO === */
  .tema-oscuro {
    --color-fondo: #111827;
    --color-fondo-tarjeta: #1f2937;
    --color-texto-principal: #f9fafb;
    --color-texto-secundario: #d1d5db;
    --color-borde: #374151;
  }

  /* === ENCABEZADO === */
  .encabezado {
    margin-bottom: 2rem;
  }

  .titulo-principal {
    font-size: 2rem;
    font-weight: 700;
    color: var(--color-texto-principal);
    margin-bottom: 0.5rem;
  }

  .subtitulo {
    color: var(--color-texto-secundario);
    font-size: 1.1rem;
  }

  /* === BARRA DE BÚSQUEDA === */
  .barra-busqueda {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-bottom: 1.5rem;
  }

  @media (min-width: 640px) {
    .barra-busqueda {
      flex-direction: row;
    }
  }

  .campo-busqueda {
    flex: 1;
    position: relative;
  }

  .input-busqueda {
    width: 100%;
    padding: 0.75rem 1rem 0.75rem 2.5rem;
    border: 1px solid var(--color-borde);
    border-radius: 0.5rem;
    background-color: var(--color-fondo-tarjeta);
    color: var(--color-texto-principal);
    font-size: 1rem;
  }

  .input-busqueda:focus {
    outline: none;
    box-shadow: 0 0 0 2px var(--color-amarillo);
    border-color: var(--color-amarillo);
  }

  .icono-busqueda {
    position: absolute;
    left: 0.75rem;
    top: 50%;
    transform: translateY(-50%);
    height: 1.25rem;
    width: 1.25rem;
    color: var(--color-gris);
  }

  /* === FILTROS === */
  .contenedor-filtros {
    display: flex;
    gap: 0.5rem;
  }

  .boton-filtro {
    padding: 0.5rem 1rem;
    border-radius: 0.5rem;
    font-weight: 500;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    border: 1px solid var(--color-borde);
    background-color: var(--color-fondo-tarjeta);
    color: var(--color-texto-secundario);
    cursor: pointer;
  }

  .boton-filtro:hover {
    background-color: var(--color-fondo);
  }

  .boton-filtro.activo {
    background-color: var(--color-amarillo);
    color: white;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }

  .texto-filtro {
    display: none;
  }

  @media (min-width: 640px) {
    .texto-filtro {
      display: inline;
    }
  }

  /* === ESTADOS === */
  .estado-cargando {
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    padding: 5rem 0;
    color: var(--color-texto-secundario);
  }

  .spinner {
    width: 3rem;
    height: 3rem;
    border: 2px solid transparent;
    border-top: 2px solid var(--color-amarillo);
    border-radius: 50%;
    animation: girar 1s linear infinite;
    margin-bottom: 1rem;
  }

  @keyframes girar {
    to {
      transform: rotate(360deg);
    }
  }

  .estado-error {
    background-color: rgba(239, 68, 68, 0.1);
    border: 1px solid rgba(239, 68, 68, 0.2);
    border-radius: 0.5rem;
    padding: 2rem;
    text-align: center;
  }

  .icono-error {
    font-size: 2.5rem;
    margin-bottom: 1rem;
  }

  .estado-error h3 {
    font-size: 1.125rem;
    font-weight: 600;
    color: #dc2626;
    margin-bottom: 0.5rem;
  }

  .estado-error p {
    color: #dc2626;
    margin-bottom: 1rem;
  }

  .boton-reintentar {
    padding: 0.5rem 1.5rem;
    background-color: var(--color-rojo);
    color: white;
    border-radius: 0.5rem;
    border: none;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .boton-reintentar:hover {
    background-color: #dc2626;
  }

  .estado-vacio {
    text-align: center;
    padding: 5rem 0;
  }

  .icono-vacio {
    font-size: 3.75rem;
    color: var(--color-gris);
    margin-bottom: 1rem;
  }

  .estado-vacio h3 {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--color-texto-principal);
    margin-bottom: 0.5rem;
  }

  .estado-vacio p {
    color: var(--color-texto-secundario);
  }

  /* === GRILLA DE EVENTOS === */
  .grilla-eventos {
    display: grid;
    gap: 1.5rem;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  }

  /* === TARJETA DE EVENTO === */
  .tarjeta-evento {
    background-color: var(--color-fondo-tarjeta);
    border-radius: 0.75rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    overflow: hidden;
    transition: box-shadow 0.3s;
  }

  .tarjeta-evento:hover {
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  }

  /* === IMAGEN EVENTO === */
  .imagen-evento {
    height: 12rem;
    background: linear-gradient(to bottom right, #fbbf24, #f97316);
    position: relative;
  }

  .imagen-evento img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .imagen-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 2.5rem;
    color: white;
  }

  .contenedor-estado {
    position: absolute;
    top: 0.75rem;
    right: 0.75rem;
  }

  .etiqueta-estado {
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 500;
  }

  .estado-cancelado {
    background-color: rgba(239, 68, 68, 0.1);
    color: #dc2626;
  }

  .tema-oscuro .estado-cancelado {
    background-color: rgba(239, 68, 68, 0.2);
    color: #fca5a5;
  }

  .estado-finalizado {
    background-color: rgba(107, 114, 128, 0.1);
    color: #374151;
  }

  .tema-oscuro .estado-finalizado {
    background-color: rgba(107, 114, 128, 0.2);
    color: #d1d5db;
  }

  .estado-proximo {
    background-color: rgba(59, 130, 246, 0.1);
    color: #1d4ed8;
  }

  .tema-oscuro .estado-proximo {
    background-color: rgba(59, 130, 246, 0.2);
    color: #93c5fd;
  }

  .estado-envivo {
    background-color: rgba(16, 185, 129, 0.1);
    color: #047857;
  }

  .tema-oscuro .estado-envivo {
    background-color: rgba(16, 185, 129, 0.2);
    color: #6ee7b7;
  }

  /* === CONTENIDO EVENTO === */
  .contenido-evento {
    padding: 1.5rem;
  }

  .titulo-evento {
    font-size: 1.125rem;
    font-weight: 600;
    color: var(--color-texto-principal);
    margin-bottom: 0.5rem;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .descripcion-evento {
    color: var(--color-texto-secundario);
    font-size: 0.875rem;
    margin-bottom: 1rem;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .info-evento {
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-size: 0.875rem;
    margin-bottom: 0.75rem;
  }

  .fecha-evento {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: var(--color-texto-secundario);
  }

  .icono-fecha {
    height: 1rem;
    width: 1rem;
  }

  .precio-evento {
    font-weight: 600;
    color: #d97706;
  }

  .tema-oscuro .precio-evento {
    color: #fbbf24;
  }

  /* === ETIQUETAS === */
  .etiquetas-evento {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  .etiqueta {
    padding: 0.25rem 0.5rem;
    border-radius: 0.25rem;
    font-size: 0.75rem;
  }

  .etiqueta.categoria {
    background-color: rgba(107, 114, 128, 0.1);
    color: var(--color-texto-secundario);
  }

  .tema-oscuro .etiqueta.categoria {
    background-color: rgba(107, 114, 128, 0.2);
  }

  .etiqueta.modalidad {
    background-color: rgba(59, 130, 246, 0.1);
    color: #1d4ed8;
  }

  .tema-oscuro .etiqueta.modalidad {
    background-color: rgba(59, 130, 246, 0.2);
    color: #93c5fd;
  }

  /* === ACCIONES === */
  .acciones-evento {
    display: flex;
    gap: 0.5rem;
  }

  .boton-principal {
    flex: 1;
    padding: 0.5rem 1rem;
    background-color: var(--color-amarillo);
    color: white;
    border-radius: 0.5rem;
    border: none;
    font-weight: 500;
    font-size: 0.875rem;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .boton-principal:hover {
    background-color: var(--color-amarillo-hover);
  }

  .boton-envivo {
    padding: 0.5rem 1rem;
    background-color: var(--color-verde);
    color: white;
    border-radius: 0.5rem;
    border: none;
    font-weight: 500;
    font-size: 0.875rem;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .boton-envivo:hover {
    background-color: #059669;
  }

  /* === PAGINACIÓN === */
  .paginacion {
    margin-top: 2rem;
    text-align: center;
  }

  .paginacion p {
    color: var(--color-texto-secundario);
  }

  /* === RESPONSIVE === */
  @media (max-width: 900px) {
    .contenido-mis-eventos {
      padding: 1.5rem;
    }

    .titulo-principal {
      font-size: 1.875rem;
    }

    .grilla-eventos {
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    }
  }

  @media (max-width: 640px) {
    .contenido-mis-eventos {
      padding: 1rem;
    }

    .grilla-eventos {
      grid-template-columns: 1fr;
    }
  }
</style> 