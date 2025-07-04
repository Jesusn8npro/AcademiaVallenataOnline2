<script lang="ts">
  import CalendarioEventos from '$lib/components/Eventos/CalendarioEventos.svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { onMount } from 'svelte';


  let vista: 'calendario' | 'grid' | 'lista' = 'grid';
  let mostrarBannerBienvenida = true;

  // Cerrar banner de bienvenida
  function cerrarBanner() {
    mostrarBannerBienvenida = false;
    localStorage.setItem('eventos-banner-cerrado', 'true');
  }

  onMount(() => {
    // Verificar si el banner ya fue cerrado
    const bannerCerrado = localStorage.getItem('eventos-banner-cerrado');
    if (bannerCerrado === 'true') {
      mostrarBannerBienvenida = false;
    }
  });
</script>

<svelte:head>
  <title>Eventos y Masterclasses - Academia Vallenata Online</title>
  <meta 
    name="description" 
    content="Únete a nuestros eventos en vivo: masterclasses, workshops, conciertos y más. Aprende acordeón vallenato con los mejores maestros en tiempo real." 
  />
  <meta name="keywords" content="eventos acordeón vallenato, masterclass, workshops, conciertos vallenatos, clases en vivo" />
  
  <!-- Open Graph -->
  <meta property="og:title" content="Eventos y Masterclasses - Academia Vallenata Online" />
  <meta property="og:description" content="Únete a nuestros eventos en vivo de acordeón vallenato" />
  <meta property="og:type" content="website" />
  <meta property="og:image" content="/images/eventos-og-image.jpg" />
  
  <!-- JSON-LD estructurado -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "EventSeries",
    "name": "Eventos Academia Vallenata Online",
    "description": "Masterclasses, workshops y eventos en vivo de acordeón vallenato",
    "organizer": {
      "@type": "Organization",
      "name": "Academia Vallenata Online",
      "url": "https://academiavallenataonline.com"
    },
    "location": {
      "@type": "VirtualLocation",
      "url": "https://academiavallenataonline.com/eventos"
    }
  }
  </script>
</svelte:head>

<main class="min-h-screen bg-gray-50">
  <!-- Banner de bienvenida -->
  {#if mostrarBannerBienvenida}
    <div class="bg-gradient-to-r from-blue-600 to-purple-700 text-white relative overflow-hidden">
      <div class="absolute inset-0 bg-black/20"></div>
      <div class="relative z-10 max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <button 
          class="absolute top-4 right-4 text-white/80 hover:text-white transition-colors"
          on:click={cerrarBanner}
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
        
        <div class="text-center">
          <div class="inline-flex items-center justify-center w-16 h-16 bg-white/20 rounded-full mb-6">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
              <line x1="16" y1="2" x2="16" y2="6"/>
              <line x1="8" y1="2" x2="8" y2="6"/>
              <line x1="3" y1="10" x2="21" y2="10"/>
            </svg>
          </div>
          
          <h1 class="text-4xl md:text-5xl font-bold mb-4">
            🎵 Eventos en Vivo
          </h1>
          
          <p class="text-xl md:text-2xl mb-8 text-blue-100 max-w-3xl mx-auto">
            Participa en masterclasses exclusivas, workshops interactivos y conciertos en vivo. 
            Aprende directamente con los mejores maestros del acordeón vallenato.
          </p>
          
          <div class="flex flex-wrap justify-center gap-4 text-sm">
            <div class="flex items-center gap-2 bg-white/20 px-4 py-2 rounded-full">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10"/>
                <polyline points="12,6 12,12 16,14"/>
              </svg>
              <span>Eventos en tiempo real</span>
            </div>
            <div class="flex items-center gap-2 bg-white/20 px-4 py-2 rounded-full">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                <circle cx="9" cy="7" r="4"/>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
              </svg>
              <span>Interacción directa</span>
            </div>
            <div class="flex items-center gap-2 bg-white/20 px-4 py-2 rounded-full">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
              </svg>
              <span>Maestros expertos</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  {/if}

  <!-- Acceso rápido para administradores -->
  {#if $usuario && ($usuario.rol === 'admin' || $usuario.rol === 'instructor')}
    <div class="bg-amber-50 border-l-4 border-amber-400 p-4">
      <div class="max-w-7xl mx-auto flex items-center justify-between">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <line x1="12" y1="5" x2="12" y2="19"/>
              <line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm text-amber-700">
              <span class="font-medium">Panel de administración:</span>
              Gestiona eventos, crea nuevas masterclasses y monitorea inscripciones.
            </p>
          </div>
        </div>
        <div class="flex gap-2">
          <a 
            href="/administrador/eventos" 
            class="bg-amber-100 hover:bg-amber-200 text-amber-800 px-4 py-2 rounded-lg text-sm font-medium transition-colors"
          >
            Gestionar Eventos
          </a>
          <a 
            href="/administrador/eventos/crear" 
            class="bg-amber-500 hover:bg-amber-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
          >
            Crear Evento
          </a>
        </div>
      </div>
    </div>
  {/if}

  <!-- Contenido principal -->
  <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
    <!-- Estadísticas rápidas -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
              <div class="bg-white rounded-xl shadow-sm p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <svg class="h-8 w-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
              <line x1="16" y1="2" x2="16" y2="6"/>
              <line x1="8" y1="2" x2="8" y2="6"/>
              <line x1="3" y1="10" x2="21" y2="10"/>
            </svg>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-gray-600">Próximos Eventos</p>
            <p class="text-2xl font-semibold text-gray-900">12</p>
          </div>
        </div>
      </div>
      
      <div class="bg-white rounded-xl shadow-sm p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <svg class="h-8 w-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
            </svg>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-gray-600">Participantes Activos</p>
            <p class="text-2xl font-semibold text-gray-900">1,247</p>
          </div>
        </div>
      </div>
      
      <div class="bg-white rounded-xl shadow-sm p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <svg class="h-8 w-8 text-yellow-600" fill="currentColor" viewBox="0 0 24 24">
              <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
            </svg>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-gray-600">Calificación Promedio</p>
            <p class="text-2xl font-semibold text-gray-900">4.8</p>
          </div>
        </div>
      </div>
      
      <div class="bg-white rounded-xl shadow-sm p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <svg class="h-8 w-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <circle cx="12" cy="12" r="10"/>
              <polyline points="12,6 12,12 16,14"/>
            </svg>
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-gray-600">En Vivo Ahora</p>
            <p class="text-2xl font-semibold text-gray-900">3</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Componente principal del calendario -->
    <CalendarioEventos 
      bind:vista={vista}
      mostrarFiltros={true}
      eventosPorPagina={12}
    />
  </div>
</main>

<style>
  :global(html) {
    scroll-behavior: smooth;
  }
</style> 