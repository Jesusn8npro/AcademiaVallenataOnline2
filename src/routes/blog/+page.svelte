<script lang="ts">
  import HeroBlog from '$lib/components/Blog/HeroBlog.svelte';
  import TarjetaArticulo from '$lib/components/Blog/TarjetaArticulo.svelte';
  import SidebarDerechaBlog from '$lib/components/Blog/SidebarDerechaBlog.svelte';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase.js';

  interface Articulo {
    id: string;
    titulo: string;
    descripcion: string;
    contenido: string;
    imagen_url?: string;
    slug: string;
    estado: 'borrador' | 'publicado';
    creado_en: string;
    actualizado_en: string;
    autor?: string;
    categoria?: string;
    etiquetas?: string[];
    lecturas?: number;
  }

  let articulos: Articulo[] = [];
  let cargando = true;
  let error = '';
  let mostrarContenido = false;
  
  // Paginación
  let paginaActual = 1;
  let articulosPorPagina = 6;
  $: totalPaginas = Math.ceil(articulos.length / articulosPorPagina);
  $: articulosPaginados = articulos.slice(
    (paginaActual - 1) * articulosPorPagina,
    paginaActual * articulosPorPagina
  );

  const scrollToArticulos = () => {
    document.getElementById('articulos')?.scrollIntoView({ behavior: 'smooth' });
  };

  onMount(async () => {
    setTimeout(() => mostrarContenido = true, 500);
    await cargarArticulos();
  });

  async function cargarArticulos() {
    try {
      cargando = true;
      error = '';

      const { data, error: errorSupabase } = await supabase
        .from('blog_articulos')
        .select('*')
        .eq('estado', 'publicado')
        .order('creado_en', { ascending: false });

      if (errorSupabase) {
        throw new Error('Error al cargar los artículos del blog');
      }

      articulos = data || [];
    } catch (e) {
      error = e instanceof Error ? e.message : 'Error inesperado al cargar los artículos';
      console.error('Error cargando artículos:', e);
    } finally {
      cargando = false;
    }
  }

  async function reintentarCarga() {
    await cargarArticulos();
  }

  function cambiarPagina(nuevaPagina: number) {
    if (nuevaPagina >= 1 && nuevaPagina <= totalPaginas) {
      paginaActual = nuevaPagina;
      document.getElementById('articulos')?.scrollIntoView({ behavior: 'smooth' });
    }
  }

  function paginaAnterior() {
    cambiarPagina(paginaActual - 1);
  }

  function paginaSiguiente() {
    cambiarPagina(paginaActual + 1);
  }
</script>

<svelte:head>
  <title>Blog - Academia Vallenata Online | Aprende Acordeón</title>
  <meta name="description" content="Descubre historias inspiradoras, técnicas profesionales y consejos de expertos en acordeón vallenato. Únete a nuestra comunidad de músicos apasionados." />
  <meta name="keywords" content="blog acordeón, vallenato, música, tutoriales, acordeonistas, comunidad musical" />
</svelte:head>

<main class="pagina-blog">
  <HeroBlog onCta={scrollToArticulos} />
  
  <section id="articulos" class="seccion-articulos" class:mostrar={mostrarContenido}>
    <!-- Loading State -->
    {#if cargando}
      <div class="estado-carga">
        <div class="spinner-carga"></div>
        <p>Cargando los mejores artículos...</p>
      </div>
    
    <!-- Error State -->
    {:else if error}
      <div class="estado-error">
        <div class="icono-error">⚠️</div>
        <h3>Oops, algo salió mal</h3>
        <p>{error}</p>
        <button class="boton-reintentar" on:click={reintentarCarga}>
          <span>Reintentar</span>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M1 4v6h6M23 20v-6h-6"/>
            <path d="m20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.36 4.36A9 9 0 0 1 3.51 15"/>
          </svg>
        </button>
      </div>
    
    <!-- Content -->
    {:else}
      <!-- Grid principal con artículos y sidebar -->
      <div class="contenido-principal">
        <!-- Área de artículos -->
        <div class="area-articulos">
          <!-- Header de sección -->
          <div class="encabezado-seccion">
            <h2>Últimos Artículos</h2>
            <p>Explora nuestro contenido más reciente sobre acordeón y vallenato</p>
          </div>
        <!-- Grid de artículos -->
        {#if articulos.length > 0}
          <div class="grilla-articulos">
            {#each articulosPaginados as articulo, index}
              <div 
                class="envoltorio-articulo"
                style="--delay: {index * 0.1}s"
              >
                <TarjetaArticulo {...articulo} />
              </div>
            {/each}
          </div>
          
          <!-- Paginación -->
          {#if totalPaginas > 1}
            <div class="paginacion">
              <button 
                class="boton-pagina" 
                class:deshabilitado={paginaActual === 1}
                on:click={paginaAnterior}
                disabled={paginaActual === 1}
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="15,18 9,12 15,6"></polyline>
                </svg>
                Anterior
              </button>

              <div class="numeros-pagina">
                {#each Array(totalPaginas) as _, i}
                  <button 
                    class="numero-pagina" 
                    class:activa={paginaActual === i + 1}
                    on:click={() => cambiarPagina(i + 1)}
                  >
                    {i + 1}
                  </button>
                {/each}
              </div>

              <button 
                class="boton-pagina" 
                class:deshabilitado={paginaActual === totalPaginas}
                on:click={paginaSiguiente}
                disabled={paginaActual === totalPaginas}
              >
                Siguiente
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="9,18 15,12 9,6"></polyline>
                </svg>
              </button>
            </div>
          {/if}
        {:else}
          <div class="estado-vacio">
            <div class="icono-vacio">📝</div>
            <h3>Próximamente...</h3>
            <p>Estamos preparando contenido increíble para ti. ¡Regresa pronto!</p>
          </div>
        {/if}
        </div>
        
        <!-- Sidebar -->
        <aside class="barra-lateral">
          <SidebarDerechaBlog />
        </aside>
      </div>
    {/if}
  </section>
</main>

<style>
  .pagina-blog {
    width: 100%;
    min-height: 100vh;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
  }

  .seccion-articulos {
    padding: 4rem 2rem;
    max-width: 1600px;
    margin: 0 auto;
    opacity: 0;
    transform: translateY(20px);
    transition: all 0.8s cubic-bezier(0.16, 1, 0.3, 1);
  }

  .seccion-articulos.mostrar {
    opacity: 1;
    transform: translateY(0);
  }

  /* Estados de carga y error */
  .estado-carga, .estado-error {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    min-height: 400px;
    padding: 3rem 2rem;
  }

  .spinner-carga {
    width: 50px;
    height: 50px;
    border: 4px solid #e2e8f0;
    border-top: 4px solid #3b82f6;
    border-radius: 50%;
    animation: girar 1s linear infinite;
    margin-bottom: 1.5rem;
  }

  @keyframes girar {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .estado-carga p {
    color: #64748b;
    font-size: 1.1rem;
    font-weight: 500;
  }

  .estado-error {
    background: rgba(239, 68, 68, 0.05);
    border-radius: 20px;
    border: 1px solid rgba(239, 68, 68, 0.1);
  }

  .icono-error {
    font-size: 3rem;
    margin-bottom: 1rem;
  }

  .estado-error h3 {
    color: #dc2626;
    font-size: 1.5rem;
    font-weight: 700;
    margin-bottom: 0.5rem;
  }

  .estado-error p {
    color: #7f1d1d;
    margin-bottom: 2rem;
  }

  .boton-reintentar {
    background: linear-gradient(135deg, #dc2626, #ef4444);
    color: white;
    border: none;
    border-radius: 25px;
    padding: 0.8rem 2rem;
    font-weight: 600;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    transition: all 0.3s ease;
    box-shadow: 0 4px 15px rgba(220, 38, 38, 0.3);
  }

  .boton-reintentar:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(220, 38, 38, 0.4);
  }

  /* Header de sección */
  .encabezado-seccion {
    text-align: center;
    margin-bottom: 3rem;
  }

  .encabezado-seccion h2 {
    font-size: clamp(2rem, 4vw, 3rem);
    font-weight: 900;
    background: linear-gradient(135deg, #1e40af, #7c3aed, #059669);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    margin-bottom: 1rem;
  }

  .encabezado-seccion p {
    font-size: 1.2rem;
    color: #64748b;
    font-weight: 500;
  }

  /* Contenido principal con grid */
  .contenido-principal {
    display: grid;
    grid-template-columns: 1fr 350px;
    gap: 4rem;
    align-items: start;
  }

  /* Área de artículos */
  .area-articulos {
    width: 100%;
  }

  /* Grid de artículos */
  .grilla-articulos {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 2rem;
  }

  .envoltorio-articulo {
    opacity: 0;
    transform: translateY(30px);
    animation: aparecerArriba 0.6s var(--delay, 0s) forwards ease-out;
  }

  @keyframes aparecerArriba {
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .estado-vacio {
    grid-column: 1 / -1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    min-height: 400px;
    padding: 3rem 2rem;
    background: rgba(59, 130, 246, 0.05);
    border-radius: 20px;
    border: 1px solid rgba(59, 130, 246, 0.1);
  }

  .icono-vacio {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .estado-vacio h3 {
    color: #1e40af;
    font-size: 1.8rem;
    font-weight: 700;
    margin-bottom: 0.5rem;
  }

  .estado-vacio p {
    color: #1e40af;
    font-size: 1.1rem;
  }

  /* Paginación */
  .paginacion {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 1rem;
    margin-top: 3rem;
    padding: 2rem 0;
  }

  .boton-pagina {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: linear-gradient(135deg, #3b82f6, #1e40af);
    color: white;
    border: none;
    border-radius: 25px;
    padding: 0.8rem 1.5rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
  }

  .boton-pagina:hover:not(.deshabilitado) {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(59, 130, 246, 0.4);
  }

  .boton-pagina.deshabilitado {
    background: #e2e8f0;
    color: #94a3b8;
    cursor: not-allowed;
    box-shadow: none;
  }

  .numeros-pagina {
    display: flex;
    gap: 0.5rem;
  }

  .numero-pagina {
    width: 40px;
    height: 40px;
    border: 1px solid #e2e8f0;
    background: white;
    color: #64748b;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.3s ease;
    font-weight: 600;
  }

  .numero-pagina:hover {
    border-color: #3b82f6;
    color: #3b82f6;
    transform: scale(1.1);
  }

  .numero-pagina.activa {
    background: linear-gradient(135deg, #3b82f6, #1e40af);
    color: white;
    border-color: transparent;
    box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
  }

  .barra-lateral {
    position: relative;
  }

  /* Responsive */
  @media (max-width: 1200px) {
    .contenido-principal {
      grid-template-columns: 1fr 280px;
      gap: 3rem;
    }
  }

  @media (max-width: 1400px) {
    .grilla-articulos {
      grid-template-columns: repeat(2, 1fr);
    }
  }

  @media (max-width: 900px) {
    .contenido-principal {
      grid-template-columns: 1fr;
      gap: 2rem;
    }

    .area-articulos {
      order: 1;
    }
    
    .barra-lateral {
      order: 2;
    }

    .encabezado-seccion {
      margin-bottom: 2rem;
    }

    .grilla-articulos {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }

    .seccion-articulos {
      padding: 2rem 1rem;
    }

    .paginacion {
      flex-direction: column;
      gap: 1.5rem;
    }

    .numeros-pagina {
      order: -1;
    }
  }

  @media (max-width: 500px) {
    .estado-carga, .estado-error, .estado-vacio {
      min-height: 300px;
      padding: 2rem 1rem;
    }

    .boton-pagina {
      padding: 0.6rem 1rem;
      font-size: 0.9rem;
    }

    .numero-pagina {
      width: 35px;
      height: 35px;
      font-size: 0.9rem;
    }
  }
</style>
