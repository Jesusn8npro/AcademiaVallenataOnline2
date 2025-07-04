<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { eventosService } from '$lib/services/eventosService';
  import { goto } from '$app/navigation';

  // Parámetros de la página
  $: slug = $page.params.slug;

  // Estado del componente
  let evento: any = null;
  let comentarios: any[] = [];
  let materiales: any[] = [];
  let cargando = true;
  let error = '';
  let inscrito = false;
  let procesandoInscripcion = false;
  let mostrarComentarios = false;
  let nuevoComentario = '';
  let enviandoComentario = false;

  // Estado de los tabs
  let tabActivo: 'descripcion' | 'comentarios' | 'materiales' = 'descripcion';

  onMount(async () => {
    await cargarEvento();
    if ($usuario && evento) {
      await verificarInscripcion();
    }
  });

  async function cargarEvento() {
    try {
      cargando = true;
      error = '';
      
      const resultado = await eventosService.obtenerEventoPorSlug(slug);
      
      if (resultado.error) {
        error = resultado.error;
        return;
      }
      
      if (!resultado.evento) {
        error = 'Evento no encontrado';
        return;
      }
      
      evento = resultado.evento;

      // Cargar datos adicionales en paralelo
      await Promise.all([
        cargarComentarios(),
        cargarMateriales()
      ]);

    } catch (err: any) {
      console.error('Error cargando evento:', err);
      error = 'Error al cargar el evento';
    } finally {
      cargando = false;
    }
  }

  async function cargarComentarios() {
    try {
      const resultado = await eventosService.obtenerComentariosEvento(evento.id);
      if (resultado.error) {
        console.error('Error cargando comentarios:', resultado.error);
        return;
      }
      comentarios = resultado.comentarios || [];
    } catch (err) {
      console.error('Error cargando comentarios:', err);
    }
  }

  async function cargarMateriales() {
    try {
      const resultado = await eventosService.obtenerMaterialesEvento(evento.id);
      if (resultado.error) {
        console.error('Error cargando materiales:', resultado.error);
        return;
      }
      materiales = resultado.materiales || [];
    } catch (err) {
      console.error('Error cargando materiales:', err);
    }
  }

  async function verificarInscripcion() {
    try {
      if (!$usuario) return;
      const resultado = await eventosService.verificarInscripcion(evento.id, $usuario.id);
      if (resultado.error) {
        console.error('Error verificando inscripción:', resultado.error);
        return;
      }
      inscrito = resultado.inscrito || false;
    } catch (err) {
      console.error('Error verificando inscripción:', err);
    }
  }

  async function inscribirseEvento() {
    if (!$usuario) {
      goto('/login');
      return;
    }

    try {
      procesandoInscripcion = true;
      error = '';

      const resultado = await eventosService.inscribirseEvento(evento.id, $usuario.id);
      
      if (resultado.inscripcion) {
        inscrito = true;
        // Actualizar contador de participantes
        evento.participantes_inscritos = (evento.participantes_inscritos || 0) + 1;
        alert('¡Te has inscrito exitosamente al evento!');
      } else {
        error = resultado.error || 'Error al inscribirse al evento';
      }
    } catch (err: any) {
      console.error('Error en inscripción:', err);
      error = 'Error al procesar la inscripción';
    } finally {
      procesandoInscripcion = false;
    }
  }

  async function cancelarInscripcion() {
    if (!$usuario || !inscrito) return;

    if (!confirm('¿Estás seguro de que quieres cancelar tu inscripción?')) return;

    try {
      procesandoInscripcion = true;
      error = '';

      const resultado = await eventosService.cancelarInscripcion(evento.id, $usuario.id);
      
      if (resultado.success) {
        inscrito = false;
        // Actualizar contador de participantes
        evento.participantes_inscritos = Math.max((evento.participantes_inscritos || 0) - 1, 0);
        alert('Tu inscripción ha sido cancelada');
      } else {
        error = resultado.error || 'Error al cancelar la inscripción';
      }
    } catch (err: any) {
      console.error('Error cancelando inscripción:', err);
      error = 'Error al cancelar la inscripción';
    } finally {
      procesandoInscripcion = false;
    }
  }

  async function enviarComentario() {
    if (!nuevoComentario.trim() || !$usuario) {
      alert('Debes iniciar sesión para comentar');
      return;
    }

    try {
      enviandoComentario = true;
      
      const resultado = await eventosService.agregarComentario(evento.id, $usuario.id, nuevoComentario.trim());
      
      if (resultado.error) {
        alert('Error al enviar el comentario: ' + resultado.error);
        return;
      }
      
      // Recargar comentarios
      await cargarComentarios();
      nuevoComentario = '';
      alert('Comentario enviado correctamente');
      
    } catch (err: any) {
      console.error('Error enviando comentario:', err);
      alert('Error al enviar el comentario: ' + err.message);
    } finally {
      enviandoComentario = false;
    }
  }

  function formatearFecha(fecha: string) {
    return new Date(fecha).toLocaleDateString('es-ES', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }

  function formatearHora(fecha: string) {
    return new Date(fecha).toLocaleTimeString('es-ES', {
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  function obtenerEstadoEvento() {
    if (!evento) return 'programado';
    
    const ahora = new Date();
    const inicio = new Date(evento.fecha_inicio);
    const fin = evento.fecha_fin ? new Date(evento.fecha_fin) : null;
    
    if (evento.estado === 'cancelado') return 'cancelado';
    if (evento.estado === 'pospuesto') return 'pospuesto';
    if (ahora > inicio && (!fin || ahora < fin)) return 'en_vivo';
    if (fin && ahora > fin) return 'finalizado';
    if (ahora < inicio) return 'programado';
    
    return evento.estado || 'programado';
  }

  function obtenerTipoEventoTexto(tipo: string) {
    const tipos: Record<string, string> = {
      'masterclass': 'Masterclass',
      'workshop': 'Workshop',
      'concierto': 'Concierto',
      'concurso': 'Concurso',
      'webinar': 'Webinar',
      'reunion': 'Reunión'
    };
    return tipos[tipo] || tipo;
  }

  function obtenerModalidadTexto(modalidad: string) {
    const modalidades: Record<string, string> = {
      'online': 'Online',
      'presencial': 'Presencial',
      'hibrido': 'Híbrido'
    };
    return modalidades[modalidad] || modalidad;
  }

  $: estadoEvento = obtenerEstadoEvento();
  $: puedeInscribirse = estadoEvento === 'programado' && evento?.requiere_inscripcion && !inscrito;
  $: puedeParticipar = inscrito && (estadoEvento === 'en_vivo' || estadoEvento === 'programado');
</script>

<svelte:head>
  {#if evento}
    <title>{evento.titulo} - Academia Vallenata Online</title>
    <meta name="description" content={evento.descripcion_corta || evento.descripcion} />
    <meta name="keywords" content="evento acordeón vallenato, {obtenerTipoEventoTexto(evento.tipo_evento)}, {evento.instructor_nombre}" />
    
    <!-- Open Graph -->
    <meta property="og:title" content="{evento.titulo} - Academia Vallenata Online" />
    <meta property="og:description" content={evento.descripcion_corta || evento.descripcion} />
    <meta property="og:type" content="event" />
    <meta property="og:image" content={evento.imagen_banner || evento.imagen_portada || "/images/eventos-og-image.jpg"} />
    
    <!-- Event structured data -->
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "Event",
      "name": "{evento.titulo}",
      "description": "{evento.descripcion}",
      "startDate": "{evento.fecha_inicio}",
      "endDate": "{evento.fecha_fin || evento.fecha_inicio}",
      "eventStatus": "https://schema.org/EventScheduled",
      "eventAttendanceMode": "{evento.modalidad === 'online' ? 'https://schema.org/OnlineEventAttendanceMode' : evento.modalidad === 'presencial' ? 'https://schema.org/OfflineEventAttendanceMode' : 'https://schema.org/MixedEventAttendanceMode'}",
      "location": {
        "@type": "{evento.modalidad === 'online' ? 'VirtualLocation' : 'Place'}",
        "name": "{evento.modalidad === 'online' ? 'Online' : evento.ubicacion_fisica || 'Por definir'}",
        "url": "{evento.link_transmision || ''}"
      },
      "image": ["{evento.imagen_banner || evento.imagen_portada}"],
      "organizer": {
        "@type": "Organization",
        "name": "Academia Vallenata Online",
        "url": "https://academiavallenataonline.com"
      },
      "performer": {
        "@type": "Person",
        "name": "{evento.instructor_nombre}"
      },
      "offers": {
        "@type": "Offer",
        "url": "https://academiavallenataonline.com/eventos/{evento.slug}",
        "price": "{evento.precio || 0}",
        "priceCurrency": "{evento.moneda || 'COP'}",
        "availability": "https://schema.org/InStock"
      }
    }
    </script>
  {/if}
</svelte:head>

{#if cargando}
  <div class="min-h-screen bg-gray-50 flex items-center justify-center">
    <div class="text-center">
      <div class="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
      <p class="mt-4 text-gray-600">Cargando evento...</p>
    </div>
  </div>
{:else if error}
  <div class="min-h-screen bg-gray-50 flex items-center justify-center">
    <div class="text-center">
      <div class="text-red-500 text-6xl mb-4">⚠️</div>
      <h1 class="text-2xl font-bold text-gray-900 mb-2">Error</h1>
      <p class="text-gray-600 mb-4">{error}</p>
      <button 
        on:click={() => goto('/eventos')}
        class="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
      >
        Volver a Eventos
      </button>
    </div>
  </div>
{:else if evento}
  <main class="min-h-screen bg-gray-50">
    <!-- Hero del evento -->
    <div class="relative bg-gray-900 text-white">
      {#if evento.imagen_banner || evento.imagen_portada}
        <div class="absolute inset-0">
          <img 
            src={evento.imagen_banner || evento.imagen_portada} 
            alt={evento.titulo}
            class="w-full h-full object-cover opacity-60"
          />
        </div>
      {/if}
      
      <div class="relative z-10 max-w-7xl mx-auto px-4 py-16 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
          <!-- Información del evento -->
          <div>
            <!-- Badges de estado y tipo -->
            <div class="flex flex-wrap gap-2 mb-4">
              <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                {obtenerTipoEventoTexto(evento.tipo_evento)}
              </span>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                {obtenerModalidadTexto(evento.modalidad)}
              </span>
              {#if estadoEvento === 'en_vivo'}
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800 animate-pulse">
                  🔴 En Vivo
                </span>
              {:else if estadoEvento === 'finalizado'}
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800">
                  ✅ Finalizado
                </span>
              {:else if estadoEvento === 'cancelado'}
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800">
                  ❌ Cancelado
                </span>
              {/if}
            </div>

            <h1 class="text-4xl md:text-5xl font-bold mb-4">{evento.titulo}</h1>
            
            {#if evento.descripcion_corta}
              <p class="text-xl text-blue-100 mb-6">{evento.descripcion_corta}</p>
            {/if}

            <!-- Información clave -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-8">
              <div class="flex items-center gap-3">
                <svg class="w-5 h-5 text-blue-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                  <line x1="16" y1="2" x2="16" y2="6"/>
                  <line x1="8" y1="2" x2="8" y2="6"/>
                  <line x1="3" y1="10" x2="21" y2="10"/>
                </svg>
                <div>
                  <p class="text-sm text-blue-200">Fecha</p>
                  <p class="font-semibold">{formatearFecha(evento.fecha_inicio)}</p>
                </div>
              </div>
              
              <div class="flex items-center gap-3">
                <svg class="w-5 h-5 text-blue-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <circle cx="12" cy="12" r="10"/>
                  <polyline points="12,6 12,12 16,14"/>
                </svg>
                <div>
                  <p class="text-sm text-blue-200">Hora</p>
                  <p class="font-semibold">{formatearHora(evento.fecha_inicio)}</p>
                </div>
              </div>
              
              {#if evento.instructor_nombre}
                <div class="flex items-center gap-3">
                  <svg class="w-5 h-5 text-blue-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                    <circle cx="12" cy="7" r="4"/>
                  </svg>
                  <div>
                    <p class="text-sm text-blue-200">Instructor</p>
                    <p class="font-semibold">{evento.instructor_nombre}</p>
                  </div>
                </div>
              {/if}
              
              <div class="flex items-center gap-3">
                <svg class="w-5 h-5 text-blue-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                  <circle cx="9" cy="7" r="4"/>
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                  <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
                <div>
                  <p class="text-sm text-blue-200">Participantes</p>
                  <p class="font-semibold">
                    {evento.participantes_inscritos || 0}
                    {#if evento.capacidad_maxima} / {evento.capacidad_maxima}{/if}
                  </p>
                </div>
              </div>
            </div>

            <!-- Precio -->
            {#if evento.precio > 0}
              <div class="mb-6">
                <div class="text-3xl font-bold">
                  ${evento.precio_rebajado || evento.precio}
                  <span class="text-sm text-blue-200">{evento.moneda || 'COP'}</span>
                </div>
                {#if evento.precio_rebajado && evento.precio_rebajado < evento.precio}
                  <div class="text-lg text-blue-200 line-through">
                    ${evento.precio} {evento.moneda || 'COP'}
                  </div>
                {/if}
              </div>
            {:else}
              <div class="mb-6">
                <span class="text-2xl font-bold text-green-300">¡GRATIS!</span>
              </div>
            {/if}
          </div>

          <!-- Área de acción -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6">
            {#if !$usuario}
              <div class="text-center mb-4">
                <p class="text-blue-100 mb-4">Inicia sesión para inscribirte al evento</p>
                <button 
                  on:click={() => goto('/login')}
                  class="w-full bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold transition-colors"
                >
                  Iniciar Sesión
                </button>
              </div>
            {:else if inscrito}
              <div class="text-center">
                <div class="flex items-center justify-center gap-2 text-green-300 mb-4">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                  <span class="font-semibold">Ya estás inscrito</span>
                </div>
                
                {#if estadoEvento === 'en_vivo' && evento.link_transmision}
                  <a 
                    href={evento.link_transmision}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="w-full bg-red-600 hover:bg-red-700 text-white px-6 py-3 rounded-lg font-semibold transition-colors inline-flex items-center justify-center gap-2 mb-3"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <polygon points="5,3 19,12 5,21"/>
                    </svg>
                    Unirse al Evento
                  </a>
                {:else if estadoEvento === 'programado'}
                  <div class="bg-blue-600 text-white px-6 py-3 rounded-lg font-semibold mb-3 flex items-center justify-center gap-2">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <circle cx="12" cy="12" r="10"/>
                      <polyline points="12,6 12,12 16,14"/>
                    </svg>
                    Evento Próximo
                  </div>
                {/if}
                
                <button 
                  on:click={cancelarInscripcion}
                  disabled={procesandoInscripcion}
                  class="w-full bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg text-sm transition-colors disabled:opacity-50"
                >
                  {procesandoInscripcion ? 'Cancelando...' : 'Cancelar Inscripción'}
                </button>
              </div>
            {:else if puedeInscribirse}
              <div class="text-center">
                <button 
                  on:click={inscribirseEvento}
                  disabled={procesandoInscripcion}
                  class="w-full bg-green-600 hover:bg-green-700 text-white px-6 py-3 rounded-lg font-semibold transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {#if procesandoInscripcion}
                    <div class="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                    Inscribiendo...
                  {:else}
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    Inscribirse al Evento
                  {/if}
                </button>
                
                {#if evento.capacidad_maxima && evento.participantes_inscritos >= evento.capacidad_maxima}
                  <p class="text-red-300 text-sm mt-2">⚠️ Evento lleno</p>
                {/if}
              </div>
            {:else}
              <div class="text-center">
                {#if estadoEvento === 'finalizado'}
                  <div class="text-gray-300">
                    <svg class="w-12 h-12 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <p>Este evento ha finalizado</p>
                  </div>
                {:else if estadoEvento === 'cancelado'}
                  <div class="text-red-300">
                    <svg class="w-12 h-12 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <p>Este evento ha sido cancelado</p>
                  </div>
                {:else}
                  <div class="text-yellow-300">
                    <svg class="w-12 h-12 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"/>
                    </svg>
                    <p>No disponible para inscripción</p>
                  </div>
                {/if}
              </div>
            {/if}
          </div>
        </div>
      </div>
    </div>

    <!-- Contenido principal -->
    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <!-- Navegación de tabs -->
      <div class="border-b border-gray-200 mb-8">
        <nav class="-mb-px flex space-x-8">
          <button 
            class="py-2 px-1 border-b-2 font-medium text-sm {tabActivo === 'descripcion' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
            on:click={() => tabActivo = 'descripcion'}
          >
            <svg class="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            Descripción
          </button>
          <button 
            class="py-2 px-1 border-b-2 font-medium text-sm {tabActivo === 'comentarios' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
            on:click={() => tabActivo = 'comentarios'}
          >
            <svg class="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
            </svg>
            Comentarios ({comentarios.length})
          </button>
          <button 
            class="py-2 px-1 border-b-2 font-medium text-sm {tabActivo === 'materiales' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
            on:click={() => tabActivo = 'materiales'}
          >
            <svg class="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            Materiales ({materiales.length})
          </button>
        </nav>
      </div>

      <!-- Contenido de los tabs -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Contenido principal -->
        <div class="lg:col-span-2">
          {#if tabActivo === 'descripcion'}
            <div class="bg-white rounded-xl shadow-sm p-8">
              <h2 class="text-2xl font-bold text-gray-900 mb-6">Sobre este evento</h2>
              {#if evento.descripcion}
                <div class="prose prose-lg max-w-none">
                  {@html evento.descripcion.replace(/\n/g, '<br>')}
                </div>
              {:else}
                <p class="text-gray-600">No hay descripción disponible para este evento.</p>
              {/if}

              {#if evento.tags && evento.tags.length > 0}
                <div class="mt-8">
                  <h3 class="text-lg font-semibold text-gray-900 mb-3">Etiquetas</h3>
                  <div class="flex flex-wrap gap-2">
                    {#each evento.tags as tag}
                      <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                        #{tag}
                      </span>
                    {/each}
                  </div>
                </div>
              {/if}
            </div>
          {:else if tabActivo === 'comentarios'}
            <div class="bg-white rounded-xl shadow-sm p-8">
              <h2 class="text-2xl font-bold text-gray-900 mb-6">Comentarios</h2>
              
              {#if $usuario}
                <!-- Formulario para nuevo comentario -->
                <div class="mb-8">
                  <div class="flex gap-4">
                    <div class="flex-shrink-0">
                      <div class="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center text-white font-semibold">
                        {$usuario?.nombre?.charAt(0) || $usuario?.correo_electronico?.charAt(0) || 'U'}
                      </div>
                    </div>
                    <div class="flex-1">
                      <textarea 
                        bind:value={nuevoComentario}
                        placeholder="Comparte tus pensamientos sobre este evento..."
                        class="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                        rows="3"
                      ></textarea>
                      <div class="mt-2 flex justify-between items-center">
                        <p class="text-sm text-gray-500">
                          {inscrito ? 'Participante inscrito' : 'Modo de prueba - comentarios habilitados'}
                        </p>
                        <button 
                          on:click={enviarComentario}
                          disabled={!nuevoComentario.trim() || enviandoComentario}
                          class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors disabled:opacity-50"
                        >
                          {enviandoComentario ? 'Enviando...' : 'Comentar'}
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              {:else}
                <div class="bg-gray-50 rounded-lg p-6 mb-8 text-center">
                  <svg class="w-12 h-12 text-gray-400 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                  </svg>
                  <p class="text-gray-600">Debes iniciar sesión para ver y escribir comentarios</p>
                </div>
              {/if}

              <!-- Lista de comentarios -->
              {#if comentarios.length > 0}
                <div class="space-y-6">
                  {#each comentarios as comentario}
                    <div class="flex gap-4">
                      <div class="flex-shrink-0">
                        <div class="w-10 h-10 bg-gray-300 rounded-full flex items-center justify-center text-gray-600 font-semibold">
                          {comentario.usuario?.nombre?.charAt(0) || comentario.usuario?.apellido?.charAt(0) || 'U'}
                        </div>
                      </div>
                      <div class="flex-1">
                        <div class="flex items-center gap-2 mb-1">
                          <h4 class="font-semibold text-gray-900">
                            {comentario.usuario?.nombre || 'Usuario'} {comentario.usuario?.apellido || ''}
                          </h4>
                          <span class="text-sm text-gray-500">
                            {new Date(comentario.created_at).toLocaleDateString('es-ES')}
                          </span>
                        </div>
                        <p class="text-gray-700">{comentario.mensaje}</p>
                      </div>
                    </div>
                  {/each}
                </div>
              {:else}
                <div class="text-center py-8">
                  <svg class="w-16 h-16 text-gray-300 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                  </svg>
                  <p class="text-gray-500">Aún no hay comentarios</p>
                  <p class="text-sm text-gray-400">¡Sé el primero en comentar!</p>
                </div>
              {/if}
            </div>
          {:else if tabActivo === 'materiales'}
            <div class="bg-white rounded-xl shadow-sm p-8">
              <h2 class="text-2xl font-bold text-gray-900 mb-6">Materiales del Evento</h2>
              
              {#if materiales.length > 0}
                <div class="space-y-4">
                  {#each materiales as material}
                    <div class="border border-gray-200 rounded-lg p-4">
                      <div class="flex items-start justify-between">
                        <div class="flex-1">
                          <h3 class="font-semibold text-gray-900 mb-1">{material.titulo}</h3>
                          {#if material.descripcion}
                            <p class="text-gray-600 text-sm mb-2">{material.descripcion}</p>
                          {/if}
                          <div class="flex items-center gap-4 text-sm text-gray-500">
                            <span class="flex items-center gap-1">
                              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                              </svg>
                              {material.tipo}
                            </span>
                            <span>{new Date(material.created_at).toLocaleDateString('es-ES')}</span>
                          </div>
                        </div>
                        {#if material.url}
                          <a 
                            href={material.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors ml-4"
                          >
                            Descargar
                          </a>
                        {/if}
                      </div>
                    </div>
                  {/each}
                </div>
              {:else}
                <div class="text-center py-8">
                  <svg class="w-16 h-16 text-gray-300 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                  </svg>
                  <p class="text-gray-500">No hay materiales disponibles</p>
                  <p class="text-sm text-gray-400">Los materiales aparecerán aquí cuando estén disponibles</p>
                </div>
              {/if}
            </div>
          {/if}
        </div>

        <!-- Sidebar -->
        <div class="lg:col-span-1">
          <div class="bg-white rounded-xl shadow-sm p-6 sticky top-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Detalles del Evento</h3>
            
            <div class="space-y-4">
              <!-- Fecha y hora -->
              <div>
                <dt class="text-sm font-medium text-gray-500">Fecha</dt>
                <dd class="text-gray-900">{formatearFecha(evento.fecha_inicio)}</dd>
              </div>
              
              <div>
                <dt class="text-sm font-medium text-gray-500">Hora</dt>
                <dd class="text-gray-900">{formatearHora(evento.fecha_inicio)}</dd>
              </div>
              
              {#if evento.fecha_fin}
                <div>
                  <dt class="text-sm font-medium text-gray-500">Finaliza</dt>
                  <dd class="text-gray-900">{formatearHora(evento.fecha_fin)}</dd>
                </div>
              {/if}
              
              <!-- Modalidad -->
              <div>
                <dt class="text-sm font-medium text-gray-500">Modalidad</dt>
                <dd class="text-gray-900">{obtenerModalidadTexto(evento.modalidad)}</dd>
              </div>
              
              <!-- Nivel -->
              {#if evento.nivel_dificultad}
                <div>
                  <dt class="text-sm font-medium text-gray-500">Nivel</dt>
                  <dd class="text-gray-900 capitalize">{evento.nivel_dificultad}</dd>
                </div>
              {/if}
              
              <!-- Categoría -->
              {#if evento.categoria}
                <div>
                  <dt class="text-sm font-medium text-gray-500">Categoría</dt>
                  <dd class="text-gray-900 capitalize">{evento.categoria}</dd>
                </div>
              {/if}
              
              <!-- Capacidad -->
              {#if evento.capacidad_maxima}
                <div>
                  <dt class="text-sm font-medium text-gray-500">Capacidad</dt>
                  <dd class="text-gray-900">{evento.capacidad_maxima} participantes</dd>
                </div>
              {/if}
              
              <!-- Precio -->
              <div>
                <dt class="text-sm font-medium text-gray-500">Precio</dt>
                <dd class="text-gray-900">
                  {#if evento.precio > 0}
                    ${evento.precio_rebajado || evento.precio} {evento.moneda || 'COP'}
                  {:else}
                    Gratis
                  {/if}
                </dd>
              </div>
            </div>
            
            <!-- Botón de compartir -->
            <div class="mt-6 pt-6 border-t border-gray-200">
              <button 
                on:click={() => {
                  if (navigator.share) {
                    navigator.share({
                      title: evento.titulo,
                      text: evento.descripcion_corta || evento.descripcion,
                      url: window.location.href
                    });
                  } else {
                    navigator.clipboard.writeText(window.location.href);
                    alert('Enlace copiado al portapapeles');
                  }
                }}
                class="w-full bg-gray-100 hover:bg-gray-200 text-gray-700 px-4 py-2 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-2"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"/>
                </svg>
                Compartir Evento
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </main>
{:else}
  <div class="min-h-screen bg-gray-50 flex items-center justify-center">
    <div class="text-center">
      <div class="text-gray-400 text-6xl mb-4">📅</div>
      <h1 class="text-2xl font-bold text-gray-900 mb-2">Evento no encontrado</h1>
      <p class="text-gray-600 mb-4">El evento que buscas no existe o ha sido eliminado.</p>
      <button 
        on:click={() => goto('/eventos')}
        class="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
      >
        Ver Todos los Eventos
      </button>
    </div>
  </div>
{/if}

<style>
  :global(.prose h1) { @apply text-2xl font-bold mb-4; }
  :global(.prose h2) { @apply text-xl font-bold mb-3; }
  :global(.prose h3) { @apply text-lg font-semibold mb-2; }
  :global(.prose p) { @apply mb-4; }
  :global(.prose ul) { @apply list-disc list-inside mb-4; }
  :global(.prose ol) { @apply list-decimal list-inside mb-4; }
  :global(.prose li) { @apply mb-1; }
  :global(.prose blockquote) { @apply border-l-4 border-blue-200 pl-4 italic text-gray-700 mb-4; }
  :global(.prose code) { @apply bg-gray-100 px-1 py-0.5 rounded text-sm; }
  :global(.prose pre) { @apply bg-gray-100 p-4 rounded-lg overflow-x-auto text-sm mb-4; }
</style> 