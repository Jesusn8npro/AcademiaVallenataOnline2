<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { onMount } from 'svelte';

  // Props del reproductor
  export let leccionAnterior: any = null;
  export let leccionSiguiente: any = null;
  export let videoUrl: string = '';
  export let thumbnailUrl: string = '';
  export let titulo: string = '';
  export let tipo: 'leccion' | 'clase' = 'leccion';
  export let completada: boolean = false;
  export let cargandoCompletar: boolean = false;
  export let marcarComoCompletada: () => void = () => {};
  export let errorCompletar: string = '';
  export let autoplay: boolean = false;

  // Estado interno del reproductor
  let elementoVideo: HTMLVideoElement | null = null;
  let elementoIframe: HTMLIFrameElement | null = null;
  let cargando = true;
  let tieneError = false;
  let esYouTube = false;
  let esBunny = false;
  let esEmbed = false;
  let idYouTube = '';
  let urlVideoLimpia = '';
  let videoId = '';
  let libraryId = '';
  let duracion = 0;
  let tiempoActual = 0;
  let reproduciendose = false;

  const dispatch = createEventDispatcher();

  function procesarUrl(url: string): string {
    if (!url) return '';
    
    // Detectar si es YouTube
    if (url.includes('youtube.com') || url.includes('youtu.be')) {
      esYouTube = true;
      
      // Extraer ID de YouTube
      let videoId = '';
      const patterns = [
        /youtube\.com\/watch\?v=([^&]+)/,
        /youtu\.be\/([^?]+)/,
        /youtube\.com\/embed\/([^?]+)/
      ];
      
      for (const pattern of patterns) {
        const match = url.match(pattern);
        if (match) {
          videoId = match[1];
          break;
        }
      }
      
      if (videoId) {
        return `https://www.youtube.com/embed/${videoId}?rel=0&showinfo=0`;
      }
    }
    
    // Si es Bunny.net
    if (url.includes('iframe.mediadelivery.net')) {
      esYouTube = false;
      esBunny = true;
      
      // Extraer libraryId y videoId
      const bunnyPattern = /iframe\.mediadelivery\.net\/embed\/([0-9]+)\/([a-zA-Z0-9-]+)/;
      const match = url.match(bunnyPattern);
      if (match) {
        libraryId = match[1];
        videoId = match[2];
      }
      
      // Asegurarse de que la URL use /embed/ en lugar de /play/
      if (url.includes('/play/')) {
        url = url.replace('/play/', '/embed/');
      }
      
      // Agregar o actualizar parámetros para optimizar la carga
      const urlObj = new URL(url);
      urlObj.searchParams.set('autoplay', 'false');
      urlObj.searchParams.set('preload', 'true');
      urlObj.searchParams.set('responsive', 'true');
      urlObj.searchParams.set('muted', 'false');
      urlObj.searchParams.set('quality', 'auto');
      urlObj.searchParams.set('loading', 'eager');
      
      return urlObj.toString();
    }
    
    return url;
  }

  $: urlProcesada = procesarUrl(videoUrl);

  // Funciones de utilidad
  function limpiarUrlVideo(url: string): string {
    if (!url) return '';
    
    console.log('🔍 Procesando URL:', url);
    
    // Detectar si es una URL de Bunny.net
    if (url.includes('iframe.mediadelivery.net') || url.includes('video.bunnycdn.com')) {
      console.log('🐰 Detectada URL de Bunny.net');
      esBunny = true;
      esYouTube = false;
      esEmbed = false;

      // Extraer library ID y video ID
      const matches = url.match(/\/embed\/([^\/]+)\/([^\/\?]+)/);
      if (matches) {
        libraryId = matches[1];
        videoId = matches[2];
        console.log('📊 IDs extraídos:', { libraryId, videoId });
      }

      return url;
    }

    // Detectar YouTube
    if (url.includes('youtube.com') || url.includes('youtu.be')) {
      esYouTube = true;
      esBunny = false;
      esEmbed = false;
      
      // Extraer ID de YouTube
      const regexps = [
        /youtube\.com\/watch\?v=([^&]+)/,
        /youtu\.be\/([^?]+)/,
        /youtube\.com\/embed\/([^?]+)/
      ];
      
      for (const regex of regexps) {
        const match = url.match(regex);
        if (match) {
          idYouTube = match[1];
          break;
        }
      }
      
      return `https://www.youtube.com/embed/${idYouTube}?autoplay=1&rel=0`;
    }

    return url;
  }

  function inicializarBunnyPlayer() {
    if (!videoId || !libraryId) {
      console.error('❌ No se encontraron los IDs necesarios');
      tieneError = true;
      return;
    }
    
    // @ts-ignore
    if (window.BunnyPlayer) {
      console.log('🎬 Inicializando Bunny Player:', { videoId, libraryId });
      try {
        // @ts-ignore
        new window.BunnyPlayer({
          videoId,
          libraryId,
          container: document.getElementById('bunny-player-container'),
          autoplay: true,
          preload: true,
          loop: false,
          muted: false,
          title: titulo,
          enabledViews: true,
          enabledControls: true,
          loadingStyle: 'center'
        });
        cargando = false;
      } catch (error) {
        console.error('❌ Error al inicializar BunnyPlayer:', error);
        tieneError = true;
      }
    } else {
      console.error('❌ BunnyPlayer no está disponible');
      tieneError = true;
    }
  }

  // Cargar el script de Bunny.net
  function cargarScriptBunny() {
    if (document.getElementById('bunny-player-script')) {
      inicializarBunnyPlayer();
      return;
    }

    const script = document.createElement('script');
    script.id = 'bunny-player-script';
    script.src = 'https://iframe.mediadelivery.net/embed/player.js';
    script.async = true;
    script.onload = () => {
      console.log('✅ Script de Bunny cargado');
      inicializarBunnyPlayer();
    };
    script.onerror = (error) => {
      console.error('❌ Error al cargar el script de Bunny:', error);
      tieneError = true;
    };
    document.body.appendChild(script);
  }

  // Reactividad
  $: {
    urlVideoLimpia = limpiarUrlVideo(videoUrl);
    if (esBunny) {
      cargarScriptBunny();
    }
  }

  onMount(() => {
    if (esBunny) {
      cargarScriptBunny();
    }
  });

  function reintentar() {
    console.log('🔄 Reintentando cargar el video...');
    tieneError = false;
    cargando = true;
    
    if (esBunny) {
      inicializarBunnyPlayer();
    } else if (elementoIframe) {
      const urlActual = elementoIframe.src;
      elementoIframe.src = '';
      setTimeout(() => {
        elementoIframe.src = urlActual;
      }, 100);
    }
  }

  function alCargarIframe() {
    console.log('✅ Iframe cargado correctamente');
    console.log('📊 URL actual:', elementoIframe?.src);
    cargando = false;
  }

  function alError(event: Event) {
    console.error('❌ Error en el video:', event);
    console.error('📊 URL que causó el error:', elementoIframe?.src || urlVideoLimpia);
    console.error('📊 Tipo de video:', { esYouTube, esBunny, esEmbed });
    cargando = false;
    tieneError = true;
  }

  // Detectar tipo de video
  function detectarTipoVideo(url: string): void {
    console.log('🔍 DETECTANDO TIPO DE VIDEO:', url);
    
    if (!url) {
      esEmbed = false;
      esYouTube = false;
      esBunny = false;
      console.log('❌ URL vacía');
      return;
    }

    // Detectar YouTube
    const regexYouTube = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
    const coincidenciaYouTube = url.match(regexYouTube);
    
    if (coincidenciaYouTube && coincidenciaYouTube[1]) {
      esYouTube = true;
      esBunny = false;
      esEmbed = true;
      idYouTube = coincidenciaYouTube[1];
      console.log('✅ YouTube detectado - ID:', idYouTube);
      return;
    }

    // Detectar Bunny.net
    if (url.includes('iframe.mediadelivery.net') || url.includes('bunnycdn.com') || url.includes('mediadelivery.net')) {
      esBunny = true;
      esYouTube = false;
      esEmbed = true;
      console.log('✅ Bunny.net detectado');
      return;
    }

    // Detectar otros embeds
    if (url.includes('iframe') || url.includes('embed') || url.includes('player') || url.startsWith('<iframe')) {
      esEmbed = true;
      esYouTube = false;
      esBunny = false;
      console.log('✅ Embed detectado (genérico)');
      return;
    }

    // Video directo
    esEmbed = false;
    esYouTube = false;
    esBunny = false;
    console.log('✅ Video directo detectado');
  }

  // Extraer URL de código de embed
  function extraerUrlEmbed(codigoEmbed: string): string {
    console.log('📝 EXTRAYENDO URL DE EMBED:', codigoEmbed);
    
    if (!codigoEmbed.includes('<iframe')) {
      console.log('🔄 No es iframe, devolviendo original');
      return codigoEmbed;
    }
    
    const coincidenciaSrc = codigoEmbed.match(/src=["'](.+?)["']/i);
    if (coincidenciaSrc && coincidenciaSrc[1]) {
      console.log('✅ URL extraída del iframe:', coincidenciaSrc[1]);
      return coincidenciaSrc[1];
    }
    
    console.log('❌ No se pudo extraer URL del iframe');
    return codigoEmbed;
  }

  // Manejar eventos del video
  function alCargarMetadatos() {
    if (elementoVideo) {
      duracion = elementoVideo.duration;
    }
    cargando = false;
  }

  function alActualizarTiempo() {
    if (elementoVideo) {
      tiempoActual = elementoVideo.currentTime;
    }
  }

  function alTerminar() {
    reproduciendose = false;
    dispatch('finalizado');
  }

  function alReproducir() {
    reproduciendose = true;
  }

  function alPausar() {
    reproduciendose = false;
  }

  function alEsperar() {
    cargando = true;
  }

  function alPoderReproducir() {
    cargando = false;
  }
</script>

<div class="reproductor-container">
  <div class="video-wrapper">
    <iframe
      title={titulo}
      src={urlProcesada}
      class="video-frame"
      allow="accelerometer;gyroscope;encrypted-media;picture-in-picture;"
      allowfullscreen={true}
      referrerpolicy="no-referrer-when-downgrade"
      sandbox="allow-scripts allow-same-origin allow-presentation"
      loading="eager"
      on:load={() => {
        console.log('Video iframe cargado');
        cargando = false;
      }}
    ></iframe>

    {#if cargando}
      <div class="loading-overlay">
        <div class="spinner"></div>
      </div>
    {/if}
  </div>

  <div class="barra-navegacion">
    <button 
      class="boton-nav anterior" 
      on:click={() => dispatch('anterior-leccion', { leccion: leccionAnterior })}
      disabled={!leccionAnterior}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="15 18 9 12 15 6"></polyline>
      </svg>
      <span class="texto-completo">{tipo === 'clase' ? 'Anterior Clase' : 'Anterior Lección'}</span>
      <span class="texto-corto">Anterior</span>
    </button>

    <button 
      class="boton-completar" 
      class:completada 
      disabled={cargandoCompletar} 
      on:click={marcarComoCompletada}
    >
      {#if cargandoCompletar}
        <div class="spinner-boton"></div>
        <span>Marcando...</span>
      {:else if completada}
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        <span>Completada</span>
      {:else}
        <span>Marcar como completada</span>
      {/if}
    </button>

    <button
      class="boton-nav siguiente"
      on:click={() => dispatch('siguiente-leccion', { leccion: leccionSiguiente })}
      disabled={!leccionSiguiente}
    >
      <span class="texto-completo">{tipo === 'clase' ? 'Siguiente Clase' : 'Siguiente Lección'}</span>
      <span class="texto-corto">Siguiente</span>
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="9 18 15 12 9 6"></polyline>
      </svg>
    </button>
  </div>
</div>

<style>
  .reproductor-container {
    width: 100%;
    max-width: 1400px;
    margin: 0 auto;
    background: #000;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);
  }

  .video-wrapper {
    position: relative;
    padding-top: 56.25%;
    background: #000;
  }

  .video-frame {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: 0;
  }

  .loading-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0,0,0,0.5);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid #f3f3f3;
    border-top: 3px solid #2196f3;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  .spinner-boton {
    width: 16px;
    height: 16px;
    border: 2px solid #ffffff;
    border-top: 2px solid transparent;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-right: 8px;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .barra-navegacion {
    display: grid;
    grid-template-columns: 1fr 1.5fr 1fr;
    gap: 1rem;
    padding: 1rem;
    background: #1a1a1a;
    border-top: 1px solid #333;
  }

  .boton-nav,
  .boton-completar {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1.25rem;
    border: none;
    border-radius: 8px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s ease;
    font-size: 0.9rem;
    min-height: 44px;
  }

  .boton-nav {
    background: #2a2a2a;
    color: #ffffff;
  }

  .boton-nav:hover:not(:disabled) {
    background: #3a3a3a;
    transform: translateY(-2px);
  }

  .boton-nav:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
  }

  .boton-completar {
    background: #4CAF50;
    color: white;
    font-weight: 600;
  }

  .boton-completar:hover:not(:disabled) {
    background: #43A047;
    transform: translateY(-2px);
  }

  .boton-completar:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .boton-completar.completada {
    background: #1E88E5;
  }

  .boton-completar.completada:hover:not(:disabled) {
    background: #1976D2;
  }

  .texto-corto {
    display: none;
  }

  @media (max-width: 768px) {
    .barra-navegacion {
      grid-template-columns: 1fr 1.2fr 1fr;
      gap: 0.5rem;
      padding: 0.75rem;
    }

    .boton-nav,
    .boton-completar {
      padding: 0.5rem;
      font-size: 0.8rem;
      min-height: 40px;
    }

    .texto-completo {
      display: none;
    }

    .texto-corto {
      display: inline;
    }

    .boton-completar {
      font-size: 0.75rem;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }

  @media (max-width: 480px) {
    .barra-navegacion {
      grid-template-columns: 1fr 1.5fr 1fr;
      padding: 0.5rem;
    }

    .boton-completar {
      font-size: 0.7rem;
    }

    .boton-nav {
      font-size: 0.7rem;
    }
  }
</style>
