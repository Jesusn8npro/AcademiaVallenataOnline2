<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';

  // 🎯 Estados del componente
  let cargando = true;
  let cursosRecomendados: any[] = [];
  let tutorialesRecomendados: any[] = [];
  let mostrarTodos = false;

  // 🚀 Cargar recomendaciones inteligentes
  async function cargarRecomendaciones() {
    try {
      cargando = true;
      
      if (!$usuario?.id) {
        console.log('❌ [RECOMENDACIONES] Usuario no autenticado');
        return;
      }

      console.log('🎯 [RECOMENDACIONES] Cargando para usuario:', $usuario.id);

      // 📚 Obtener cursos en los que NO está inscrito (tolerante a errores)
      let cursosInscritos: any[] = [];
      try {
        const { data: inscripciones, error } = await supabase
          .from('inscripciones')
          .select('curso_id')
          .eq('usuario_id', $usuario.id);

        if (error) {
          console.log('ℹ️ [RECOMENDACIONES] No hay inscripciones:', error.message);
        } else {
          cursosInscritos = inscripciones?.map((i: any) => i.curso_id) || [];
        }
      } catch (err) {
        console.log('ℹ️ [RECOMENDACIONES] Error al cargar inscripciones:', err);
      }

             // 🎓 Obtener cursos disponibles (NO inscritos)
       let queryCursos = supabase
         .from('cursos')
         .select(`
           id,
           titulo,
           descripcion,
           imagen_url,
           instructor_id,
           precio_normal,
           nivel,
           categoria
         `)
         .eq('estado', 'activo');

      if (cursosInscritos.length > 0) {
        queryCursos = queryCursos.not('id', 'in', `(${cursosInscritos.join(',')})`);
      }

      let cursosData: any[] = [];
      try {
        const { data, error } = await queryCursos.limit(6);
        if (error) {
          console.log('ℹ️ [RECOMENDACIONES] Error al cargar cursos:', error.message);
        } else {
          cursosData = data || [];
        }
      } catch (err) {
        console.log('ℹ️ [RECOMENDACIONES] Error al consultar cursos:', err);
      }

      // 🎵 Obtener tutoriales donde NO tenga progreso (no inscritos) - tolerante a errores
      let tutorialesConProgreso: any[] = [];
      try {
        const { data: progresoTutoriales, error } = await supabase
          .from('progreso_tutorial')
          .select('tutorial_id')
          .eq('usuario_id', $usuario.id);

        if (error) {
          console.log('ℹ️ [RECOMENDACIONES] No hay progreso de tutoriales:', error.message);
        } else {
          tutorialesConProgreso = progresoTutoriales?.map((p: any) => p.tutorial_id) || [];
        }
      } catch (err) {
        console.log('ℹ️ [RECOMENDACIONES] Error al cargar progreso tutoriales:', err);
      }

             // 🎵 Obtener tutoriales recomendados (NO inscritos)
       let queryTutoriales = supabase
         .from('tutoriales')
         .select(`
           id,
           titulo,
           artista,
           imagen_url,
           instructor_id,
           nivel,
           categoria
         `)
         .eq('estado', 'activo');

      if (tutorialesConProgreso.length > 0) {
        queryTutoriales = queryTutoriales.not('id', 'in', `(${tutorialesConProgreso.join(',')})`);
      }

      let tutorialesData: any[] = [];
      try {
        const { data, error } = await queryTutoriales.limit(6);
        if (error) {
          console.log('ℹ️ [RECOMENDACIONES] Error al cargar tutoriales:', error.message);
        } else {
          tutorialesData = data || [];
        }
      } catch (err) {
        console.log('ℹ️ [RECOMENDACIONES] Error al consultar tutoriales:', err);
      }

      // 🎯 Procesar cursos recomendados
      cursosRecomendados = (cursosData || []).map((curso: any) => ({
        id: curso.id,
        titulo: curso.titulo,
        descripcion: curso.descripcion?.substring(0, 80) + '...' || 'Curso de acordeón',
        imagen: curso.imagen_url || '/images/Home/academia-vallenata-1.jpg',
        slug: generateSlug(curso.titulo),
        nivel: curso.nivel || 'Principiante',
        categoria: curso.categoria || 'Vallenato',
        precio: curso.precio_normal || 0,
        tipo: 'curso',
        razon: obtenerRazonRecomendacion('curso', curso.nivel, curso.categoria)
      }));

      // 🎵 Procesar tutoriales recomendados
      tutorialesRecomendados = (tutorialesData || []).map((tutorial: any) => ({
        id: tutorial.id,
        titulo: tutorial.titulo,
        artista: tutorial.artista || 'Artista Desconocido',
        imagen: tutorial.imagen_url || '/images/Home/academia-vallenata-1.jpg',
        slug: generateSlug(tutorial.titulo),
        dificultad: tutorial.nivel || 'Principiante',
        genero: tutorial.categoria || 'Vallenato',
        tipo: 'tutorial',
        razon: obtenerRazonRecomendacion('tutorial', tutorial.nivel, tutorial.categoria)
      }));

      console.log('✅ [RECOMENDACIONES] Cursos:', cursosRecomendados.length);
      console.log('✅ [RECOMENDACIONES] Tutoriales:', tutorialesRecomendados.length);

    } catch (error) {
      console.error('❌ [RECOMENDACIONES] Error general:', error);
    } finally {
      cargando = false;
    }
  }

  // 🧠 Obtener razón de recomendación
  function obtenerRazonRecomendacion(tipo: string, nivel: string, categoria: string): string {
    const razones = [
      `Perfecto para tu nivel ${nivel}`,
      `Complementa tu aprendizaje de ${categoria}`,
      `Popular entre estudiantes`,
      `Recomendado por tu progreso`,
      `Siguiente paso en tu formación`,
      `Ideal para mejorar técnica`
    ];
    return razones[Math.floor(Math.random() * razones.length)];
  }

  // 🎓 Ir a curso
  function irACurso(curso: any) {
    console.log('📚 [NAVEGACIÓN] Yendo a curso:', curso.slug);
    goto(`/cursos/${curso.slug}`);
  }

  // 🎵 Ir a tutorial
  function irATutorial(tutorial: any) {
    console.log('🎵 [NAVEGACIÓN] Yendo a tutorial:', tutorial.slug);
    goto(`/tutoriales/${tutorial.slug}`);
  }

  // 👀 Ver todos los cursos
  function verTodosCursos() {
    console.log('📚 [NAVEGACIÓN] Yendo a todos los cursos...');
    goto('/cursos');
  }

  // 👀 Ver todos los tutoriales
  function verTodosTutoriales() {
    console.log('🎵 [NAVEGACIÓN] Yendo a todos los tutoriales...');
    goto('/tutoriales');
  }

  // 🔄 Alternar vista
  function alternarVista() {
    mostrarTodos = !mostrarTodos;
  }

  onMount(() => {
    cargarRecomendaciones();
  });
</script>

<!-- 🚀 RECOMENDACIONES INTELIGENTES -->
<div class="recomendaciones-cursos">
  
  {#if cargando}
    <!-- Estado de carga -->
    <div class="cargando-recomendaciones">
      <div class="skeleton-recomendaciones"></div>
    </div>
    
  {:else}
    <!-- 🎯 Tarjeta principal de recomendaciones -->
    <div class="tarjeta-recomendaciones">
      
      <!-- 🚀 Header con título y toggle -->
      <div class="recomendaciones-header">
        <div class="header-info">
          <h3>🚀 Recomendaciones Para Ti</h3>
          <p class="subtitulo">Descubre contenido perfecto para tu nivel</p>
        </div>
        <button class="toggle-vista" on:click={alternarVista}>
          {mostrarTodos ? '📚' : '🎵'}
        </button>
      </div>

      <!-- 📊 Pestañas de contenido -->
      <div class="tabs-container">
        <button 
          class="tab-btn" 
          class:active={!mostrarTodos}
          on:click={() => mostrarTodos = false}
        >
          📚 Cursos ({cursosRecomendados.length})
        </button>
        <button 
          class="tab-btn" 
          class:active={mostrarTodos}
          on:click={() => mostrarTodos = true}
        >
          🎵 Tutoriales ({tutorialesRecomendados.length})
        </button>
      </div>

      <!-- 📚 CURSOS RECOMENDADOS -->
      {#if !mostrarTodos}
        <div class="contenido-recomendaciones">
          <div class="lista-recomendaciones">
            {#each cursosRecomendados.slice(0, 3) as curso}
              <div class="item-recomendacion curso" on:click={() => irACurso(curso)}>
                <div class="item-imagen">
                  <img src={curso.imagen} alt={curso.titulo} loading="lazy" />
                  <div class="nivel-badge">{curso.nivel}</div>
                </div>
                <div class="item-info">
                  <h4 class="item-titulo">{curso.titulo}</h4>
                  <p class="item-descripcion">{curso.descripcion}</p>
                  <div class="item-meta">
                    <span class="categoria">📖 {curso.categoria}</span>
                    <span class="precio">{curso.precio > 0 ? `$${curso.precio.toLocaleString()}` : 'Gratis'}</span>
                  </div>
                  <div class="razon-recomendacion">
                    <span class="icono-razon">💡</span>
                    <span class="texto-razon">{curso.razon}</span>
                  </div>
                </div>
              </div>
            {/each}
          </div>
          
          {#if cursosRecomendados.length > 3}
            <button class="ver-mas-btn" on:click={verTodosCursos}>
              <span>👀 Ver Todos los Cursos</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M5 12h14M12 5l7 7-7 7"/>
              </svg>
            </button>
          {/if}
        </div>

      <!-- 🎵 TUTORIALES RECOMENDADOS -->
      {:else}
        <div class="contenido-recomendaciones">
          <div class="lista-recomendaciones">
            {#each tutorialesRecomendados.slice(0, 3) as tutorial}
              <div class="item-recomendacion tutorial" on:click={() => irATutorial(tutorial)}>
                <div class="item-imagen">
                  <img src={tutorial.imagen} alt={tutorial.titulo} />
                  <div class="nivel-badge">{tutorial.dificultad}</div>
                </div>
                <div class="item-info">
                  <h4 class="item-titulo">{tutorial.titulo}</h4>
                  <p class="item-artista">🎤 {tutorial.artista}</p>
                  <div class="item-meta">
                    <span class="categoria">🎵 {tutorial.genero}</span>
                    <span class="gratis">Gratis</span>
                  </div>
                  <div class="razon-recomendacion">
                    <span class="icono-razon">💡</span>
                    <span class="texto-razon">{tutorial.razon}</span>
                  </div>
                </div>
              </div>
            {/each}
          </div>
          
          {#if tutorialesRecomendados.length > 3}
            <button class="ver-mas-btn" on:click={verTodosTutoriales}>
              <span>👀 Ver Todos los Tutoriales</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M5 12h14M12 5l7 7-7 7"/>
              </svg>
            </button>
          {/if}
        </div>
      {/if}

      <!-- 📊 Estadísticas rápidas -->
      <div class="stats-rapidas">
        <div class="stat-item">
          <span class="stat-icono">📚</span>
          <span class="stat-texto">{cursosRecomendados.length} cursos nuevos</span>
        </div>
        <div class="stat-item">
          <span class="stat-icono">🎵</span>
          <span class="stat-texto">{tutorialesRecomendados.length} tutoriales gratis</span>
        </div>
      </div>

    </div>
  {/if}
  
</div>

<style>
  /* 🚀 CONTENEDOR PRINCIPAL */
  .recomendaciones-cursos {
    width: 100%;
    height: 100%;
  }

  /* 🎯 TARJETA DE RECOMENDACIONES */
  .tarjeta-recomendaciones {
    background: linear-gradient(135deg, #7c3aed 0%, #a855f7 50%, #c084fc 100%);
    border-radius: 20px;
    padding: 20px;
    color: white;
    position: relative;
    overflow: hidden;
    box-shadow: 0 8px 32px rgba(124, 58, 237, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    height: 100%;
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .tarjeta-recomendaciones::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: radial-gradient(circle at 80% 20%, rgba(255, 255, 255, 0.1) 0%, transparent 50%);
    pointer-events: none;
  }

  /* 🚀 HEADER */
  .recomendaciones-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  }

  .header-info h3 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 700;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  }

  .subtitulo {
    margin: 0;
    font-size: 0.85rem;
    opacity: 0.8;
    margin-top: 2px;
  }

  .toggle-vista {
    background: rgba(255, 255, 255, 0.15);
    border: none;
    border-radius: 8px;
    padding: 8px;
    color: white;
    font-size: 1.2rem;
    cursor: pointer;
    transition: all 0.3s ease;
    backdrop-filter: blur(10px);
  }

  .toggle-vista:hover {
    background: rgba(255, 255, 255, 0.25);
    transform: scale(1.1);
  }

  /* 📊 PESTAÑAS */
  .tabs-container {
    display: flex;
    gap: 8px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 4px;
  }

  .tab-btn {
    flex: 1;
    background: transparent;
    border: none;
    color: white;
    padding: 8px 12px;
    border-radius: 8px;
    font-size: 0.85rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    opacity: 0.7;
  }

  .tab-btn.active {
    background: rgba(255, 255, 255, 0.2);
    opacity: 1;
    backdrop-filter: blur(10px);
  }

  .tab-btn:hover {
    opacity: 1;
  }

  /* 📚 CONTENIDO DE RECOMENDACIONES */
  .contenido-recomendaciones {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .lista-recomendaciones {
    display: flex;
    flex-direction: column;
    gap: 10px;
    flex: 1;
  }

  /* 🎯 ITEM DE RECOMENDACIÓN */
  .item-recomendacion {
    background: rgba(255, 255, 255, 0.15);
    border-radius: 12px;
    padding: 12px;
    display: flex;
    gap: 12px;
    cursor: pointer;
    transition: all 0.3s ease;
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
  }

  .item-recomendacion:hover {
    background: rgba(255, 255, 255, 0.2);
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
  }

  .item-imagen {
    position: relative;
    width: 60px;
    height: 60px;
    border-radius: 8px;
    overflow: hidden;
    flex-shrink: 0;
  }

  .item-imagen img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .nivel-badge {
    position: absolute;
    top: 4px;
    right: 4px;
    background: rgba(0, 0, 0, 0.7);
    color: white;
    font-size: 0.6rem;
    padding: 2px 6px;
    border-radius: 4px;
    font-weight: 600;
  }

  .item-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
  }

  .item-titulo {
    margin: 0;
    font-size: 0.9rem;
    font-weight: 700;
    line-height: 1.2;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .item-descripcion,
  .item-artista {
    margin: 0;
    font-size: 0.75rem;
    opacity: 0.8;
    line-height: 1.3;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .item-meta {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 8px;
    margin-top: 2px;
  }

  .categoria {
    font-size: 0.7rem;
    opacity: 0.8;
  }

  .precio {
    font-size: 0.7rem;
    font-weight: 600;
    color: #fbbf24;
  }

  .gratis {
    font-size: 0.7rem;
    font-weight: 600;
    color: #10b981;
  }

  .razon-recomendacion {
    display: flex;
    align-items: center;
    gap: 4px;
    margin-top: 4px;
  }

  .icono-razon {
    font-size: 0.7rem;
  }

  .texto-razon {
    font-size: 0.7rem;
    opacity: 0.9;
    font-style: italic;
  }

  /* 👀 BOTÓN VER MÁS */
  .ver-mas-btn {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 10px;
    padding: 10px 16px;
    color: white;
    font-size: 0.85rem;
    font-weight: 600;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    cursor: pointer;
    transition: all 0.3s ease;
    backdrop-filter: blur(10px);
  }

  .ver-mas-btn:hover {
    background: rgba(255, 255, 255, 0.2);
    transform: translateY(-1px);
  }

  .ver-mas-btn svg {
    width: 16px;
    height: 16px;
    transition: transform 0.3s ease;
  }

  .ver-mas-btn:hover svg {
    transform: translateX(4px);
  }

  /* 📊 ESTADÍSTICAS RÁPIDAS */
  .stats-rapidas {
    display: flex;
    gap: 12px;
    padding-top: 8px;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
  }

  .stat-item {
    flex: 1;
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 0.75rem;
    opacity: 0.8;
  }

  .stat-icono {
    font-size: 0.9rem;
  }

  /* 🔄 LOADING */
  .cargando-recomendaciones {
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 40px 20px;
  }

  .skeleton-recomendaciones {
    background: linear-gradient(135deg, #7c3aed 0%, #a855f7 50%, #c084fc 100%);
    border-radius: 20px;
    width: 100%;
    height: 100%;
    position: relative;
    overflow: hidden;
  }

  .skeleton-recomendaciones::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, 
      transparent 0%, 
      rgba(255, 255, 255, 0.1) 50%, 
      transparent 100%
    );
    animation: shimmer 2s infinite;
  }

  @keyframes shimmer {
    0% { left: -100%; }
    100% { left: 100%; }
  }

  /* 📱 RESPONSIVE */
  @media (max-width: 900px) {
    .tarjeta-recomendaciones {
      padding: 16px;
      gap: 12px;
    }

    .recomendaciones-header {
      gap: 8px;
    }

    .header-info h3 {
      font-size: 1.1rem;
    }

    .item-imagen {
      width: 50px;
      height: 50px;
    }

    .item-titulo {
      font-size: 0.85rem;
    }

    .item-descripcion,
    .item-artista {
      font-size: 0.7rem;
    }

    .lista-recomendaciones {
      gap: 8px;
    }

    .item-recomendacion {
      padding: 10px;
      gap: 10px;
    }
  }
</style>
