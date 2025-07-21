<script lang="ts">
  import { onMount } from 'svelte';
  import { generateNextGenSrc, generateSrcSet, generateSizes, supportsWebP, supportsAVIF } from '$lib/utils/image-optimizer';
  
  // Props para imagen optimizada
  export let src: string;
  export let alt: string;
  export let width: number | string = 'auto';
  export let height: number | string = 'auto';
  export let lazy = true;
  export let priority = false;
  export let className = '';
  export let aspectRatio = '';
  
  // Estados internos
  let imageElement: HTMLImageElement;
  let loaded = false;
  let error = false;
  let observer: IntersectionObserver;
  let supportsModernFormats = false;
  
  // Generar srcset para responsive images con next-gen formats
  $: webpSrc = generateNextGenSrc(src, 'webp');
  $: avifSrc = generateNextGenSrc(src, 'avif');
  $: srcset = generateSrcSet(src);
  $: sizes = generateSizes();
  
  // Detectar soporte de formatos modernos
  onMount(async () => {
    supportsModernFormats = await supportsWebP() || await supportsAVIF();
  });
  
  onMount(() => {
    if (!lazy || priority) {
      loadImage();
      return;
    }
    
    // Lazy loading con Intersection Observer
    observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            loadImage();
            observer.unobserve(entry.target);
          }
        });
      },
      { rootMargin: '50px' }
    );
    
    if (imageElement) {
      observer.observe(imageElement);
    }
    
    return () => {
      if (observer) observer.disconnect();
    };
  });
  
  function loadImage() {
    if (!imageElement || loaded) return;
    
    const img = new Image();
    img.onload = () => {
      loaded = true;
      if (imageElement) {
        imageElement.src = src;
      }
    };
    img.onerror = () => {
      error = true;
    };
    img.src = src;
  }
  
  function handleImageLoad() {
    loaded = true;
  }
  
  function handleImageError() {
    error = true;
  }
</script>

<div 
  class="image-container {className}"
  style="
    width: {typeof width === 'number' ? width + 'px' : width};
    height: {typeof height === 'number' ? height + 'px' : height};
    aspect-ratio: {aspectRatio};
  "
>
  <!-- Placeholder mientras carga -->
  {#if !loaded && !error}
    <div class="image-placeholder" style="aspect-ratio: {aspectRatio}">
      <div class="placeholder-content">
        <div class="placeholder-animation"></div>
      </div>
    </div>
  {/if}
  
  <!-- Imagen principal con formatos next-gen -->
  <picture>
    <!-- AVIF para navegadores que lo soporten (mejor compresión) -->
    {#if supportsModernFormats}
      <source 
        srcset={loaded ? generateSrcSet(avifSrc) : undefined}
        sizes={sizes}
        type="image/avif" 
      />
      
      <!-- WebP como fallback -->
      <source 
        srcset={loaded ? generateSrcSet(webpSrc) : undefined}
        sizes={sizes}
        type="image/webp" 
      />
    {/if}
    
    <!-- Imagen original como fallback final -->
    <img
      bind:this={imageElement}
      {alt}
      width={typeof width === 'number' ? width : undefined}
      height={typeof height === 'number' ? height : undefined}
      src={priority ? src : undefined}
      srcset={loaded ? srcset : undefined}
      sizes={sizes}
      loading={lazy && !priority ? 'lazy' : 'eager'}
      decoding={priority ? 'sync' : 'async'}
      fetchpriority={priority ? 'high' : 'low'}
      class="optimized-image"
      class:loaded
      class:error
      on:load={handleImageLoad}
      on:error={handleImageError}
      style="aspect-ratio: {aspectRatio}"
    />
  </picture>
  
  <!-- Fallback de error -->
  {#if error}
    <div class="image-error" style="aspect-ratio: {aspectRatio}">
      <span>❌ Error cargando imagen</span>
    </div>
  {/if}
</div>

<style>
  .image-container {
    position: relative;
    display: block;
    overflow: hidden;
  }
  
  .optimized-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: opacity 0.3s ease-in-out;
    opacity: 0;
  }
  
  .optimized-image.loaded {
    opacity: 1;
  }
  
  .optimized-image.error {
    display: none;
  }
  
  .image-placeholder {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: #f3f4f6;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .placeholder-content {
    width: 40px;
    height: 40px;
  }
  
  .placeholder-animation {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background: linear-gradient(90deg, transparent, rgba(255,255,255,0.6), transparent);
    animation: shimmer 2s infinite;
  }
  
  @keyframes shimmer {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(100%); }
  }
  
  .image-error {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: #fee2e2;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #dc2626;
    font-size: 14px;
    text-align: center;
  }
  
  /* Responsive optimizations */
  @media (max-width: 640px) {
    .placeholder-content {
      width: 24px;
      height: 24px;
    }
  }
</style> 