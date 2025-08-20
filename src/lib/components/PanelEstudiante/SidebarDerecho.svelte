<script lang="ts">
  // 📚 Sidebar Derecho - Panel Estudiante Gaming
  // Información real: Blog + Ranking + Comunidad
  
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { goto } from '$app/navigation';
  import Avatar from '$lib/components/ui/Avatar.svelte';
  import GamificacionService from '$lib/services/gamificacionService';
  import { obtenerSlugUsuario } from '$lib/utilidades/utilidadesSlug';

  // 📊 Estados reactivos
  let cargando = true;
  let articulosBlog: any[] = [];
  let rankingTop: any[] = [];
  let publicacionesRecientes: any[] = [];
  
  // ⚡ ESTADOS DE CARGA INDIVIDUALES
  let cargandoBlog = true;
  let cargandoRanking = true;
  let cargandoComunidad = true;
  
  // 🎯 DATOS POR DEFECTO PARA MOSTRAR INMEDIATAMENTE
  const datosPorDefecto = {
    blog: [
      {
        id: 1,
        titulo: '¿Cómo convertir tu talento musical en un negocio real?',
        fecha: '24 jun',
        vistas: '0',
        estado: 'publicado'
      },
      {
        id: 2,
        titulo: '¿Y si no encuentro mi estilo al tocar acordeón?',
        fecha: '24 jun',
        vistas: '0',
        estado: 'publicado'
      },
      {
        id: 3,
        titulo: 'Cómo estudiar acordeón correctamente y avanzar de forma real',
        fecha: '24 jun',
        vistas: '0',
        estado: 'publicado'
      }
    ],
    ranking: [
      { nombre: 'Jesus Gonzalez', puntos: 3537, posicion: 1 },
      { nombre: 'Robinson Niñez', puntos: 1900, posicion: 2 },
      { nombre: 'John Orozco', puntos: 1900, posicion: 3 },
      { nombre: 'Wilfred José Van Bochove Marín', puntos: 1500, posicion: 4 },
      { nombre: 'Aymer Zaveedra', puntos: 1300, posicion: 5 }
    ]
  };

  // 📰 Cargar artículos del blog (IGUAL que página de blog)
  async function cargarBlog() {
    try {
      // ⚡ MOSTRAR DATOS POR DEFECTO INMEDIATAMENTE
      articulosBlog = datosPorDefecto.blog;
      cargandoBlog = false;
      
      // 📊 CARGAR DATOS REALES EN SEGUNDO PLANO
      const { data: articulos, error } = await supabase
        .from('blog_articulos')
        .select('*')
        .eq('estado', 'publicado')
        .order('creado_en', { ascending: false })
        .limit(3);

      if (error) throw error;
      
      // ✅ ACTUALIZAR CON DATOS REALES
      if (articulos && articulos.length > 0) {
        articulosBlog = articulos;
        console.log('📰 Blog actualizado con datos reales:', articulosBlog.length, 'artículos');
      }
    } catch (error) {
      console.error('Error cargando blog:', error);
      // Mantener datos por defecto si falla
    }
  }

  // 🏆 Cargar ranking top 5 (IGUAL que página de ranking)
  async function cargarRanking() {
    try {
      // ⚡ MOSTRAR DATOS POR DEFECTO INMEDIATAMENTE
      rankingTop = datosPorDefecto.ranking;
      cargandoRanking = false;
      
      // 📊 CARGAR DATOS REALES EN SEGUNDO PLANO
      const ranking = await GamificacionService.obtenerRanking('general', 5);
      
      // ✅ ACTUALIZAR CON DATOS REALES
      if (ranking && ranking.length > 0) {
        rankingTop = ranking;
        console.log('🏆 Ranking actualizado con datos reales:', rankingTop.length, 'usuarios');
      }
    } catch (error) {
      console.error('Error cargando ranking:', error);
      // Mantener datos por defecto si falla
    }
  }

  // 👥 Cargar publicaciones recientes (IGUAL que página de comunidad)
  async function cargarComunidad() {
    try {
      const { data: publicaciones, error } = await supabase
        .from('comunidad_publicaciones')
        .select(`
          *,
          perfiles(nombre_usuario, nombre, apellido, nombre_completo, url_foto_perfil)
        `)
        .not('tipo', 'in', '("foto_perfil","foto_portada")')
        .order('fecha_creacion', { ascending: false })
        .limit(3);

      if (error) throw error;

      // Procesar publicaciones igual que en la página de comunidad
      const publicacionesProcesadas = (publicaciones || []).map((pub: any) => {
        const datosUsuario = {
          nombre_usuario: pub.perfiles?.nombre_usuario,
          nombre: pub.perfiles?.nombre || pub.usuario_nombre,
          apellido: pub.perfiles?.apellido,
          nombre_completo: pub.perfiles?.nombre_completo,
          usuario_nombre: pub.usuario_nombre
        };
        
        const usuarioSlug = obtenerSlugUsuario(datosUsuario);
        
        return {
          ...pub,
          usuario_slug: usuarioSlug,
          contenido: pub.descripcion || pub.contenido || '',
          usuario_nombre: pub.usuario_nombre || pub.perfiles?.nombre || 'Usuario'
        };
      });

      publicacionesRecientes = publicacionesProcesadas;
      console.log('👥 Comunidad cargada:', publicacionesRecientes.length, 'publicaciones');
    } catch (error) {
      console.error('Error cargando comunidad:', error);
      publicacionesRecientes = [];
    }
  }

  // 🚀 Cargar todos los datos
  onMount(async () => {
    // ⚡ MOSTRAR DATOS POR DEFECTO INMEDIATAMENTE
    articulosBlog = datosPorDefecto.blog;
    rankingTop = datosPorDefecto.ranking;
    cargando = false;
    
    // 📊 CARGAR DATOS REALES EN SEGUNDO PLANO
    setTimeout(async () => {
      try {
        await Promise.all([
          cargarBlog(),
          cargarRanking(),
          cargarComunidad()
        ]);
        console.log('✅ [SIDEBAR] Todos los datos cargados en segundo plano');
      } catch (error) {
        console.warn('⚠️ [SIDEBAR] Error cargando datos en segundo plano:', error);
      }
    }, 100); // 100ms después para no bloquear
  });

  // 🔧 Funciones de navegación
  function irABlog() {
    goto('/blog');
  }

  function irAArticulo(slug: string) {
    goto(`/blog/${slug}`);
  }

  function irARanking() {
    goto('/ranking');
  }

  function irAComunidad() {
    goto('/comunidad');
  }

  function irAPublicacion(id: string) {
    goto(`/comunidad/publicacion/${id}`);
  }

  function irAPerfilUsuario(usuarioSlug: string) {
    if (usuarioSlug) {
      goto(`/usuarios/${usuarioSlug}/publicaciones`);
    }
  }

  // 🎨 Formatear fecha
  function formatearFecha(fecha: string): string {
    if (!fecha) return '';
    const ahora = new Date();
    const fechaPost = new Date(fecha);
    const diferencia = ahora.getTime() - fechaPost.getTime();
    const dias = Math.floor(diferencia / (1000 * 60 * 60 * 24));
    
    if (dias === 0) return 'Hoy';
    if (dias === 1) return 'Ayer';
    if (dias < 7) return `${dias} días`;
    return fechaPost.toLocaleDateString('es-ES', { 
      day: 'numeric', 
      month: 'short' 
    });
  }

  // 🎯 Truncar texto
  function truncarTexto(texto: string, limite: number = 80): string {
    if (!texto) return '';
    return texto.length > limite ? texto.substring(0, limite) + '...' : texto;
  }
</script>

<!-- 📚 SIDEBAR DERECHO -->
<aside class="sidebar-derecho">
  
  {#if cargando}
    <!-- Estado de carga -->
    <div class="loading-sidebar">
      <div class="spinner"></div>
      <p>Cargando...</p>
    </div>
  {:else}
    
    <!-- 📰 BLOG RECIENTE -->
    <div class="widget-card blog-widget">
      <div class="widget-header">
        <h4>📰 Blog Reciente</h4>
        <button class="ver-todo" on:click={irABlog}>Ver todo</button>
      </div>
      
      {#if articulosBlog.length > 0}
        <div class="blog-lista">
          {#each articulosBlog as articulo}
            <div class="blog-item" on:click={() => irAArticulo(articulo.slug)} role="button" tabindex="0">
                             <div class="blog-imagen">
                 <img src={articulo.imagen_url || '/images/Home/academia-vallenata-1.jpg'} 
                      alt={articulo.titulo} />
               </div>
                             <div class="blog-info">
                 <h5>{truncarTexto(articulo.titulo, 60)}</h5>
                 <p class="blog-fecha">{formatearFecha(articulo.creado_en)}</p>
                 <div class="blog-stats">
                   <span>👁️ {articulo.lecturas || 0}</span>
                 </div>
               </div>
            </div>
          {/each}
        </div>
      {:else}
        <div class="no-data">
          <p>📰 No hay artículos recientes</p>
        </div>
      {/if}
    </div>

    <!-- 🏆 RANKING TOP 5 -->
    <div class="widget-card ranking-widget">
      <div class="widget-header">
        <h4>🏆 Top Ranking</h4>
        <button class="ver-todo" on:click={irARanking}>Ver todo</button>
      </div>
      
      {#if rankingTop.length > 0}
        <div class="ranking-lista">
          {#each rankingTop as usuario, index}
            <div class="ranking-item">
              <div class="ranking-posicion">
                <span class="posicion-numero {index < 3 ? 'top-tres' : ''}">{usuario.posicion || index + 1}</span>
              </div>
              <div class="ranking-avatar">
                <Avatar 
                  src={usuario.perfiles?.url_foto_perfil}
                  alt={usuario.perfiles?.nombre}
                  nombreCompleto="{usuario.perfiles?.nombre || ''} {usuario.perfiles?.apellido || ''}"
                  size="small"
                />
              </div>
              <div class="ranking-info">
                <h6>{usuario.perfiles?.nombre || 'Usuario'} {usuario.perfiles?.apellido || ''}</h6>
                <div class="ranking-stats">
                  <span class="xp">Pos. #{usuario.posicion}</span>
                  <span class="puntos">{(usuario.puntuacion || 0).toLocaleString()} pts</span>
                </div>
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <div class="no-data">
          <p>🏆 Ranking no disponible</p>
        </div>
      {/if}
    </div>

    <!-- 👥 COMUNIDAD RECIENTE -->
    <div class="widget-card comunidad-widget">
      <div class="widget-header">
        <h4>👥 Comunidad</h4>
        <button class="ver-todo" on:click={irAComunidad}>Ver todo</button>
      </div>
      
            {#if publicacionesRecientes.length > 0}
        <div class="comunidad-lista">
          {#each publicacionesRecientes.slice(0, 3) as publicacion}
            <div class="comunidad-item" on:click={() => irAPerfilUsuario(publicacion.usuario_slug)} role="button" tabindex="0">
              <div class="publicacion-avatar">
                <Avatar 
                  src={publicacion.perfiles?.url_foto_perfil}
                  alt={publicacion.usuario_nombre}
                  nombreCompleto="{publicacion.perfiles?.nombre || publicacion.usuario_nombre} {publicacion.perfiles?.apellido || ''}"
                  size="small"
                />
              </div>
              <div class="publicacion-info">
                <h6>{publicacion.usuario_nombre}</h6>
                <p>{truncarTexto(publicacion.contenido, 50)}</p>
                <div class="publicacion-stats">
                  <span>❤️ {publicacion.total_comentarios || 0}</span>
                  <span>{formatearFecha(publicacion.fecha_creacion)}</span>
                </div>
              </div>
            </div>
          {/each}
        </div>
      {:else}
        <div class="no-data">
          <p>👥 No hay publicaciones recientes</p>
        </div>
      {/if}
    </div>

  {/if}

</aside>

<style>
  /* 📚 SIDEBAR DERECHO FIJO */
  .sidebar-derecho {
    display: flex;
    flex-direction: column;
    gap: 16px;
    height: 100%; /* Altura fija */
    overflow-y: auto; /* Scroll vertical cuando sea necesario */
    overflow-x: hidden;
    grid-area: widgets;
    padding-right: 8px; /* Espacio para scrollbar */
  }

  /* 🎨 Estilizar scrollbar del sidebar */
  .sidebar-derecho::-webkit-scrollbar {
    width: 6px;
  }

  .sidebar-derecho::-webkit-scrollbar-track {
    background: rgba(100, 116, 139, 0.1);
    border-radius: 3px;
  }

  .sidebar-derecho::-webkit-scrollbar-thumb {
    background: rgba(100, 116, 139, 0.3);
    border-radius: 3px;
  }

  .sidebar-derecho::-webkit-scrollbar-thumb:hover {
    background: rgba(100, 116, 139, 0.5);
  }

  /* 🔄 Loading */
  .loading-sidebar {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 40px 20px;
    color: #94a3b8;
  }

  .spinner {
    width: 32px;
    height: 32px;
    border: 3px solid rgba(99, 102, 241, 0.2);
    border-top: 3px solid #6366f1;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 12px;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  /* 🎮 WIDGET BASE */
  .widget-card {
    background: rgba(30, 41, 59, 0.8);
    backdrop-filter: blur(20px);
    border-radius: 16px;
    padding: 16px;
    border: 1px solid rgba(100, 116, 139, 0.2);
    transition: all 0.3s ease;
    flex-shrink: 0; /* Evitar que se compriman demasiado */
  }

  .widget-card:hover {
    border-color: rgba(99, 102, 241, 0.4);
    box-shadow: 0 8px 32px rgba(99, 102, 241, 0.2);
  }

  .widget-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    padding-bottom: 12px;
    border-bottom: 1px solid rgba(100, 116, 139, 0.3);
  }

  .widget-header h4 {
    font-size: 1.1rem;
    font-weight: bold;
    margin: 0;
  }

  .ver-todo {
    background: transparent;
    border: 1px solid #6366f1;
    color: #6366f1;
    padding: 4px 12px;
    border-radius: 6px;
    font-size: 0.8rem;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .ver-todo:hover {
    background: #6366f1;
    color: white;
  }

  .no-data {
    text-align: center;
    color: #64748b;
    padding: 20px;
    font-style: italic;
  }

  /* 📰 BLOG WIDGET */
  .blog-widget {
    border-left: 4px solid #f59e0b;
  }

  .blog-lista {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .blog-item {
    display: flex;
    gap: 12px;
    padding: 12px;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.3s ease;
    background: rgba(245, 158, 11, 0.05);
  }

  .blog-item:hover {
    background: rgba(245, 158, 11, 0.15);
    transform: translateX(4px);
  }

  .blog-imagen {
    width: 48px;
    height: 48px;
    border-radius: 8px;
    overflow: hidden;
    flex-shrink: 0;
  }

  .blog-imagen img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .blog-info h5 {
    font-size: 0.9rem;
    margin: 0 0 4px 0;
    color: white;
    font-weight: 600;
    line-height: 1.3;
  }

  .blog-fecha {
    font-size: 0.75rem;
    color: #94a3b8;
    margin: 0 0 4px 0;
  }

  .blog-stats {
    font-size: 0.7rem;
    color: #f59e0b;
  }

  /* 🏆 RANKING WIDGET */
  .ranking-widget {
    border-left: 4px solid #fbbf24;
  }

  .ranking-lista {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .ranking-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 8px;
    border-radius: 8px;
    background: rgba(251, 191, 36, 0.05);
    transition: all 0.3s ease;
  }

  .ranking-item:hover {
    background: rgba(251, 191, 36, 0.15);
  }

  .ranking-posicion {
    width: 28px;
    height: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    background: rgba(100, 116, 139, 0.3);
    font-weight: bold;
    font-size: 0.8rem;
  }

  .posicion-numero.top-tres {
    background: linear-gradient(135deg, #fbbf24, #f59e0b);
    color: white;
  }

  .ranking-info {
    flex: 1;
  }

  .ranking-info h6 {
    font-size: 0.85rem;
    margin: 0 0 2px 0;
    color: white;
    font-weight: 600;
  }

  .ranking-stats {
    display: flex;
    gap: 8px;
    font-size: 0.7rem;
  }

  .ranking-stats .xp {
    color: #8b5cf6;
    font-weight: 600;
  }

  .ranking-stats .puntos {
    color: #fbbf24;
  }

  /* 👥 COMUNIDAD WIDGET */
  .comunidad-widget {
    border-left: 4px solid #10b981;
  }

  .comunidad-lista {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .comunidad-item {
    display: flex;
    gap: 10px;
    padding: 12px;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.3s ease;
    background: rgba(16, 185, 129, 0.05);
  }

  .comunidad-item:hover {
    background: rgba(16, 185, 129, 0.15);
    transform: translateX(4px);
  }

  .publicacion-info {
    flex: 1;
  }

  .publicacion-info h6 {
    font-size: 0.8rem;
    margin: 0 0 4px 0;
    color: white;
    font-weight: 600;
  }

  .publicacion-info p {
    font-size: 0.75rem;
    color: #94a3b8;
    margin: 0 0 6px 0;
    line-height: 1.3;
  }

  .publicacion-stats {
    display: flex;
    gap: 12px;
    font-size: 0.7rem;
    color: #64748b;
  }

  /* 📱 RESPONSIVE */
  @media (max-width: 900px) {
    .sidebar-derecho {
      margin-top: 20px;
    }
  }

  /* 📌 SIDEBAR FIJO - Sin scroll interno */
</style> 