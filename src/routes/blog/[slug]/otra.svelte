<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { browser } from '$app/environment';
  import { supabase } from '$lib/supabase/clienteSupabase.js';
  import HeroArticulo from '$lib/components/Blog/articulos/HeroArticulo.svelte';
  import SidebarDerechaBlog from '$lib/components/Blog/SidebarDerechaBlog.svelte';
  
  // Utilidades SEO
  import { 
    generarMetadatosArticulo, 
    aplicarMetadatos, 
    generarUrlCanonica,
    generarBreadcrumbs,
    type MetadatosArticulo 
  } from '$lib/utils/metaTags';
  
  interface Articulo {
    id: string;
    titulo: string;
    slug: string;
    autor?: string;
    creado_en: string;
    imagen_url?: string;
    resumen?: string;
    contenido: string;
    categoria?: string;
    etiquetas?: string[];
    lecturas?: number;
  }

  let articulo: Articulo | null = null;
  let cargando = true;
  let error = '';
  let progresoLectura = 0;
  let tiempoEstimadoLectura = 0;
  let mostrarPagina = false;
  
  $: slug = $page.params.slug;
  $: urlCompleta = browser && $page?.url ? $page.url.href : '';

  // Función para embeber videos de YouTube en el contenido
  function embedYouTube(html: string): string {
    if (!html) return '';
    return html.replace(/https?:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)([\w-]{11})/g, (match: string, _: string, __: string, videoId: string) => {
      return `<div class='youtube-embed'><iframe width='100%' height='340' src='https://www.youtube.com/embed/${videoId}' title='YouTube video' frameborder='0' allowfullscreen></iframe></div>`;
    });
  }

  // Calcular tiempo estimado de lectura
  function calcularTiempoLectura(contenido: string): number {
    const palabrasPorMinuto = 200;
    const palabras = contenido.replace(/<[^>]*>/g, '').split(/\s+/).length;
    return Math.ceil(palabras / palabrasPorMinuto);
  }

  // Manejar scroll para barra de progreso
  function manejarScroll() {
    const contenidoElemento = document.querySelector('.contenido-articulo-blog');
    if (!contenidoElemento) return;
    
    const scrollTop = window.scrollY;
    const alturaDocumento = document.documentElement.scrollHeight - window.innerHeight;
    progresoLectura = Math.min((scrollTop / alturaDocumento) * 100, 100);
  }

  // Aplicar metadatos dinámicamente cuando el artículo cambie
  $: if (browser && articulo) {
    const metadatosArticulo: MetadatosArticulo = {
      titulo: articulo.titulo,
      descripcion: articulo.resumen,
      imagen: articulo.imagen_url,
      autor: articulo.autor || 'Jesús González',
      fechaPublicacion: articulo.creado_en,
      categorias: articulo.categoria ? [articulo.categoria] : ['Acordeón Vallenato'],
      etiquetas: articulo.etiquetas || [],
      tiempoLectura: tiempoEstimadoLectura,
      url: urlCompleta
    };

    const metadatos = generarMetadatosArticulo(metadatosArticulo);
    aplicarMetadatos(metadatos);

    // Generar URL canónica
    const urlCanonica = generarUrlCanonica(slug);
    let linkCanonical = document.querySelector('link[rel="canonical"]');
    if (!linkCanonical) {
      linkCanonical = document.createElement('link');
      linkCanonical.setAttribute('rel', 'canonical');
      document.head.appendChild(linkCanonical);
    }
    linkCanonical.setAttribute('href', urlCanonica);

    // Agregar breadcrumbs estructurados
    const breadcrumbs = generarBreadcrumbs(articulo.titulo, slug);
    let scriptBreadcrumbs = document.querySelector('script[data-type="breadcrumbs"]');
    if (!scriptBreadcrumbs) {
      scriptBreadcrumbs = document.createElement('script');
      scriptBreadcrumbs.setAttribute('type', 'application/ld+json');
      scriptBreadcrumbs.setAttribute('data-type', 'breadcrumbs');
      document.head.appendChild(scriptBreadcrumbs);
    }
    scriptBreadcrumbs.textContent = JSON.stringify(breadcrumbs);
  }

  onMount(() => {
    const cargarArticulo = async () => {
      cargando = true;
      error = '';
      articulo = null;
      
      try {
        // Obtener el artículo principal (única llamada a la base de datos)
        const { data: art, error: errorArt } = await supabase
          .from('blog_articulos')
          .select('*')
          .eq('slug', slug)
          .eq('estado', 'publicado')
          .single();
          
        if (errorArt || !art) {
          error = 'No se encontró el artículo.';
        } else {
          articulo = art as Articulo;
          tiempoEstimadoLectura = calcularTiempoLectura(art.contenido || '');
        }
      } catch (e) {
        error = 'Error al cargar los datos.';
        console.error('Error cargando artículo:', e);
      }
      
      cargando = false;
      mostrarPagina = true;
    };
    
    cargarArticulo();
    
    // Configurar listeners para scroll
    window.addEventListener('scroll', manejarScroll, { passive: true });
  });
</script>

<!-- Barra de progreso de lectura -->
<div class="barra-progreso-lectura" style="width: {progresoLectura}%"></div>

<main class="pagina-articulo-blog" class:visible={mostrarPagina}>
  {#if cargando}
    <div class="estado-carga">
      <div class="spinner-vallenato">
        <div class="acordeon-animado">🪗</div>
      </div>
      <h3>Cargando artículo musical...</h3>
      <p>Preparando el mejor contenido sobre acordeón vallenato</p>
    </div>
  {:else if error}
    <div class="estado-error">
      <div class="icono-error">🎵💔</div>
      <h3>¡Ups! No encontramos este artículo</h3>
      <p>{error}</p>
      <button class="boton-volver" on:click={() => window.history.back()}>
        ← Volver al Blog
      </button>
    </div>
  {:else if articulo}
    <div class="contenedor-articulo">
      <div class="layout-articulo">
        <section class="contenido-principal">
          <HeroArticulo
            titulo={articulo.titulo}
            autor={articulo.autor || 'Jesús González'}
            fecha={articulo.creado_en}
            imagen_url={articulo.imagen_url}
            resumen={articulo.resumen}
            contenidoHtml={articulo.contenido}
            slug={articulo.slug}
          />
          
          <article class="contenido-articulo-blog">
            {@html embedYouTube(articulo.contenido)}
          </article>

          <!-- Call to Action final -->
          <div class="cta-final-articulo">
            <div class="cta-contenido">
              <h3>¿Te gustó este artículo? 🎵</h3>
              <p>Únete a nuestra academia y aprende acordeón vallenato con Jesús González</p>
              <div class="botones-cta">
                <a href="/cursos" class="boton-cta-principal">Ver Cursos</a>
                <a href="/blog" class="boton-cta-secundario">Más Artículos</a>
              </div>
            </div>
          </div>
        </section>
        
        <SidebarDerechaBlog />
      </div>
    </div>
  {/if}
</main>

<style>
  :root {
    --color-vallenato-primario: #ff6b35;
    --color-vallenato-secundario: #f7931e;
    --color-verde-acordeon: #2d5a3d;
    --color-dorado-vallenato: #ffd700;
    --color-tierra-vallenato: #8b4513;
    --color-cielo-caribe: #87ceeb;
    --sombra-vallenata: 0 8px 32px rgba(255, 107, 53, 0.15);
    --sombra-acordeon: 0 12px 40px rgba(45, 90, 61, 0.2);
  }

  /* === PÁGINA PRINCIPAL === */
  .pagina-articulo-blog {
    max-width: 1536px;
    margin: 0 auto;
    padding: 2rem 1rem;
    transition: opacity 0.5s ease-out;
    opacity: 0;
  }

  .pagina-articulo-blog.visible {
    opacity: 1;
  }

  /* === CONTENEDOR PRINCIPAL === */
  .contenedor-articulo {
    max-width: 1500px;
    margin: 0 auto;
    padding: 0;
    position: relative;
    z-index: 2;
  }

  /* === LAYOUT PRINCIPAL === */
  .layout-articulo {
    display: grid;
    grid-template-columns: 1fr 320px;
    gap: 3rem;
    align-items: flex-start;
    margin-top: 0;
  }

  .contenido-principal {
    min-width: 0;
  }

  /* === CONTENIDO ARTÍCULO === */
  .contenido-articulo-blog {
    background: rgba(255, 255, 255, 0.95);
    border-radius: 24px;
    box-shadow: var(--sombra-vallenata);
    padding: 2.5rem;
    margin-top: 1.5rem;
    font-size: 1.1rem;
    color: #2c3e50;
    line-height: 1.8;
    word-break: break-word;
    overflow-wrap: anywhere;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    position: relative;
  }



  /* === CTA FINAL === */
  .cta-final-articulo {
    background: linear-gradient(135deg, var(--color-vallenato-primario), var(--color-vallenato-secundario));
    border-radius: 24px;
    padding: 3rem 2rem;
    margin-top: 3rem;
    text-align: center;
    color: white;
    box-shadow: var(--sombra-vallenata);
    position: relative;
    overflow: hidden;
  }

  .cta-final-articulo::before {
    content: '🎵🪗🎵';
    position: absolute;
    top: 1rem;
    right: 2rem;
    font-size: 2rem;
    opacity: 0.3;
    animation: brillarCta 2s ease-in-out infinite;
  }

  @keyframes brillarCta {
    0%, 100% { opacity: 0.3; transform: scale(1); }
    50% { opacity: 0.6; transform: scale(1.1); }
  }

  .cta-contenido h3 {
    font-size: 2rem;
    font-weight: 800;
    margin-bottom: 1rem;
    color: white;
  }

  .cta-contenido p {
    font-size: 1.2rem;
    margin-bottom: 2rem;
    opacity: 0.9;
  }

  .botones-cta {
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
  }

  .boton-cta-principal, .boton-cta-secundario {
    padding: 1rem 2rem;
    border-radius: 50px;
    text-decoration: none;
    font-weight: 700;
    font-size: 1.1rem;
    transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    border: 2px solid transparent;
  }

  .boton-cta-principal {
    background: var(--color-dorado-vallenato);
    color: var(--color-verde-acordeon);
    box-shadow: 0 8px 25px rgba(255, 215, 0, 0.3);
  }

  .boton-cta-secundario {
    background: transparent;
    color: white;
    border-color: white;
  }

  .boton-cta-principal:hover {
    transform: translateY(-3px) scale(1.05);
    box-shadow: 0 15px 35px rgba(255, 215, 0, 0.4);
  }

  .boton-cta-secundario:hover {
    background: white;
    color: var(--color-vallenato-primario);
    transform: translateY(-3px) scale(1.05);
  }

  /* === ESTADOS CARGA Y ERROR === */
  .estado-carga, .estado-error {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    min-height: 60vh;
    padding: 3rem 2rem;
  }

  .spinner-vallenato {
    position: relative;
    margin-bottom: 2rem;
  }

  .acordeon-animado {
    font-size: 4rem;
    animation: tocarAcordeon 1.5s ease-in-out infinite;
  }

  @keyframes tocarAcordeon {
    0%, 100% { transform: scale(1) rotate(0deg); }
    50% { transform: scale(1.1) rotate(5deg); }
  }

  .estado-carga h3 {
    color: var(--color-verde-acordeon);
    font-size: 1.8rem;
    font-weight: 700;
    margin-bottom: 1rem;
  }

  .estado-carga p {
    color: var(--color-tierra-vallenato);
    font-size: 1.1rem;
  }

  .estado-error {
    background: rgba(255, 107, 53, 0.05);
    border-radius: 24px;
    border: 2px solid rgba(255, 107, 53, 0.2);
  }

  .icono-error {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .estado-error h3 {
    color: var(--color-vallenato-primario);
    font-size: 1.8rem;
    font-weight: 700;
    margin-bottom: 1rem;
  }

  .estado-error p {
    color: var(--color-tierra-vallenato);
    margin-bottom: 2rem;
  }

  .boton-volver {
    background: linear-gradient(135deg, var(--color-vallenato-primario), var(--color-vallenato-secundario));
    color: white;
    border: none;
    border-radius: 50px;
    padding: 1rem 2rem;
    font-weight: 700;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: var(--sombra-vallenata);
  }

  .boton-volver:hover {
    transform: translateY(-2px);
    box-shadow: 0 12px 35px rgba(255, 107, 53, 0.3);
  }

  /* === RESPONSIVE DESIGN === */
  @media (max-width: 1200px) {
    .layout-articulo {
      grid-template-columns: 1fr 300px;
      gap: 2rem;
    }
  }

  @media (max-width: 900px) {
    .layout-articulo,
    .layout-principal {
      grid-template-columns: 1fr;
      gap: 2rem;
    }
    
    .contenedor-articulo {
      padding: 1rem;
    }
    
    .contenido-articulo-blog {
      padding: 1.5rem;
    }
    
    .cta-final-articulo {
      padding: 2rem 1rem;
    }
    
    .botones-cta {
      flex-direction: column;
      align-items: center;
    }
  }

  @media (max-width: 500px) {
    .boton-cta-principal, .boton-cta-secundario {
      width: 100%;
      text-align: center;
    }
    
    .cta-contenido h3 {
      font-size: 1.5rem;
    }
    
    .estado-carga, .estado-error {
      padding: 2rem 1rem;
    }
  }

  /* === ESTILOS PARA YOUTUBE EMBEDS === */
  :global(.youtube-embed) {
    position: relative;
    width: 100%;
    height: 0;
    padding-bottom: 56.25%;
    margin: 2rem 0;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: var(--sombra-vallenata);
  }

  :global(.youtube-embed iframe) {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: none;
  }

  .prose-lg :global(h2),
  .prose-lg :global(h3) {
    scroll-margin-top: 100px; /* Espacio para el anclaje de la TOC */
  }

  @media (max-width: 900px) {
    .layout-principal {
      grid-template-columns: 1fr; /* Apila el contenido en móvil */
    }
  }

  /* === ESTILOS GLOBALES PARA EL CONTENIDO DEL ARTÍCULO (AHORA ENCAPSULADOS) === */
  /* Al prefijar con .contenido-articulo-blog, nos aseguramos que estos estilos
     NO se filtren y afecten a otros componentes como el menú. */
  .contenido-articulo-blog :global(h1),
  .contenido-articulo-blog :global(h2),
  .contenido-articulo-blog :global(h3),
  .contenido-articulo-blog :global(p),
  .contenido-articulo-blog :global(ul),
  .contenido-articulo-blog :global(ol),
  .contenido-articulo-blog :global(li),
  .contenido-articulo-blog :global(blockquote),
  .contenido-articulo-blog :global(img),
  .contenido-articulo-blog :global(pre),
  .contenido-articulo-blog :global(code),
  .contenido-articulo-blog :global(strong),
  .contenido-articulo-blog :global(b) {
    font-family: 'Montserrat', 'Segoe UI', Arial, sans-serif;
    color: #232323;
    font-size: 1.09rem;
    line-height: 1.75;
    max-width: 100%;
    word-break: break-word;
    overflow-wrap: anywhere;
    box-sizing: border-box;
  }
  .contenido-articulo-blog :global(h1) {
    font-size: 2.1rem;
    font-weight: 800;
    border-bottom: 2.5px solid #13b67a22;
    padding-bottom: 0.18em;
  }
  .contenido-articulo-blog :global(h2) {
    font-size: 1.5rem;
    font-weight: 800;
    border-bottom: 2px solid #13b67a22;
    padding-bottom: 0.13em;
  }
  .contenido-articulo-blog :global(h3) {
    font-size: 1.18rem;
    font-weight: 700;
    color: #1976d2;
  }
  .contenido-articulo-blog :global(strong),
  .contenido-articulo-blog :global(b) {
    font-weight: bold;
    color: #222;
  }
  .contenido-articulo-blog :global(p) {
    margin-bottom: 1.1em;
  }
  .contenido-articulo-blog :global(ul) {
    margin-left: 2em;
    margin-bottom: 1.1em;
    padding-left: 1.2em;
    list-style-type: disc;
    list-style-position: inside;
  }
  .contenido-articulo-blog :global(ul li)::marker {
    color: #13b67a;
    font-size: 1.15em;
  }
  .contenido-articulo-blog :global(ol) {
    margin-left: 2em;
    margin-bottom: 1.1em;
    padding-left: 1.2em;
    list-style-type: decimal;
    list-style-position: inside;
  }
  .contenido-articulo-blog :global(ol li)::marker {
    color: #1976d2;
    font-size: 1.1em;
  }
  .contenido-articulo-blog :global(li) {
    margin-bottom: 0.45em;
  }
  .contenido-articulo-blog :global(blockquote) {
    border-left: 4px solid #b6e7a0;
    background: #f8fff3;
    margin: 1.2em 0;
    padding: 0.9em 1.3em;
    color: #3a5c3c;
    font-style: italic;
    border-radius: 0 14px 14px 0;
  }
  .contenido-articulo-blog :global(img) {
    display: block;
    margin: 20px auto;
    max-width: 100%;
    border-radius: 12px;
    box-shadow: 0 2px 12px #0001;
  }
  .contenido-articulo-blog :global(pre) {
    background: #f4fcff;
    border-radius: 7px;
    padding: 1em;
    overflow-x: auto;
    margin-bottom: 1.2em;
  }
  .contenido-articulo-blog :global(code) {
    background: #eafbe6;
    border-radius: 4px;
    padding: 0.15em 0.5em;
    font-size: 0.97em;
  }
</style>

