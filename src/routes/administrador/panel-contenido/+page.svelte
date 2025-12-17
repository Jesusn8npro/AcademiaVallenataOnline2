<script lang="ts">
    import { goto } from '$app/navigation';
    import MostradorCursosTutoriales from './MostradorCursosTutoriales.svelte';
import SidebarResumenAdmin from './SidebarResumenAdmin.svelte';
    import { onMount } from 'svelte';
    import { createClient } from '@supabase/supabase-js';
  
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
    const supabase = createClient(supabaseUrl, supabaseKey);
  
    // Estados principales
    let cursos: any[] = [];
    let tutoriales: any[] = [];
    let cargando = true;
  
    // Estados para filtros
    let textoBusqueda = '';
    let filtroEstado = 'todos';
    let filtroTipo = 'todos';
    let modoVista: 'cuadricula' | 'lista' = 'cuadricula';
  
    // Datos computados para filtros - ARREGLAR REACTIVIDAD
    $: itemsFiltrados = filtrarContenido(cursos, tutoriales, textoBusqueda, filtroEstado, filtroTipo);
    $: stats = { 
      total: cursos.length + tutoriales.length,
      publicados: [...cursos, ...tutoriales].filter(item => item.estado === 'publicado').length,
      filtrados: itemsFiltrados.length
    };
  
        function filtrarContenido(cursos: any[], tutoriales: any[], busqueda: string, estado: string, tipo: string) {
      console.log('🔍 [FILTROS] Aplicando filtros:', { busqueda, estado, tipo });
      console.log('📊 [DATOS] Cursos:', cursos.length, 'Tutoriales:', tutoriales.length);
      
      let items = [
        ...cursos.map(c => ({ ...c, tipo: 'curso' })),
        ...tutoriales.map(t => ({ ...t, tipo: 'tutorial' }))
      ];
  
      console.log('📋 [UNIFICADO] Total items antes de filtrar:', items.length);

      // FILTRO POR TIPO PRIMERO
      if (tipo !== 'todos') {
        items = items.filter(item => item.tipo === tipo);
        console.log(`🎯 [TIPO] Filtrado por "${tipo}":`, items.length, 'items');
      }

      // FILTRO POR ESTADO
      if (estado !== 'todos') {
        items = items.filter(item => item.estado === estado);
        console.log(`📌 [ESTADO] Filtrado por "${estado}":`, items.length, 'items');
      }

      // FILTRO POR BÚSQUEDA
      if (busqueda.trim()) {
        const busquedaLower = busqueda.toLowerCase();
        items = items.filter(item => 
          item.titulo?.toLowerCase().includes(busquedaLower) ||
          item.descripcion?.toLowerCase().includes(busquedaLower) ||
          item.descripcion_corta?.toLowerCase().includes(busquedaLower) ||
          item.artista?.toLowerCase().includes(busquedaLower) ||
          item.acordeonista?.toLowerCase().includes(busquedaLower) ||
          item.tonalidad?.toLowerCase().includes(busquedaLower) ||
          item.categoria?.toLowerCase().includes(busquedaLower) ||
          item.nivel?.toLowerCase().includes(busquedaLower) ||
          item.estado?.toLowerCase().includes(busquedaLower)
        );
        console.log(`🔍 [BÚSQUEDA] Filtrado por "${busqueda}":`, items.length, 'items');
      }
  
      const resultado = items.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
      console.log('✅ [RESULTADO] Items finales:', resultado.length);
      
      return resultado;
    }
  
    onMount(async () => {
      try {
        console.log('🔄 Cargando contenido del panel admin...');
        
        console.log('🔄 Intentando consultas con JOINs...');
        
        const [cursosRes, tutorialesRes, modulosRes, leccionesRes, inscripcionesRes, partesRes] = await Promise.all([
          // CURSOS básicos
          supabase
            .from('cursos')
            .select('*')
            .order('created_at', { ascending: false }),
          
          // TUTORIALES básicos
          supabase
            .from('tutoriales')
            .select('*')
            .order('created_at', { ascending: false }),
            
          // MÓDULOS para contar por curso
          supabase
            .from('modulos')
            .select('curso_id'),
            
          // LECCIONES para contar por curso
          supabase
            .from('lecciones')
            .select('curso_id'),
            
          // INSCRIPCIONES para contar por tutorial
          supabase
            .from('inscripciones')
            .select('*'),
            
          // PARTES DE TUTORIAL
          supabase
            .from('partes_tutorial')
            .select('tutorial_id')
        ]);

        // Verificar errores en las consultas auxiliares
        if (modulosRes.error) console.error('❌ Error módulos:', modulosRes.error);
        if (leccionesRes.error) console.error('❌ Error lecciones:', leccionesRes.error);  
        if (inscripcionesRes.error) console.error('❌ Error inscripciones:', inscripcionesRes.error);
        if (partesRes.error) console.error('❌ Error partes:', partesRes.error);
        
        // Procesar datos y hacer conteos manuales
        const modulosData = modulosRes.data || [];
        const leccionesData = leccionesRes.data || [];
        const inscripcionesData = inscripcionesRes.data || [];
        const partesData = partesRes.data || [];
        
        console.log('📊 Datos auxiliares cargados:');
        console.log('- Módulos:', modulosData.length, modulosRes.error ? '(ERROR)' : '');
        console.log('- Lecciones:', leccionesData.length, leccionesRes.error ? '(ERROR)' : '');
        console.log('- Inscripciones:', inscripcionesData.length, inscripcionesRes.error ? '(ERROR)' : '');
        console.log('- Partes:', partesData.length, partesRes.error ? '(ERROR)' : '');
        
        // Debug: Mostrar estructura de inscripciones
        if (inscripcionesData.length > 0) {
          console.log('🔍 [DEBUG] Muestra de inscripción:', inscripcionesData[0]);
          console.log('🔍 [DEBUG] Campos disponibles:', Object.keys(inscripcionesData[0]));
        } else {
          console.log('⚠️ [DEBUG] No hay inscripciones o error al cargar');
        }
        
        // Debug: Mostrar estructura de lecciones
        if (leccionesData.length > 0) {
          console.log('🔍 [DEBUG] Muestra de lección:', leccionesData[0]);
          console.log('🔍 [DEBUG] Campos disponibles:', Object.keys(leccionesData[0]));
        } else {
          console.log('⚠️ [DEBUG] No hay lecciones o error al cargar');
        }

        if (cursosRes.error) {
          console.error('❌ Error cargando cursos:', cursosRes.error);
        } else {
          // Procesar cursos con conteos MANUALES
          cursos = (cursosRes.data || []).map((curso, index) => {
            const modulosDelCurso = modulosData.filter(m => m.curso_id === curso.id).length;
            const leccionesDelCurso = leccionesData.filter(l => l.curso_id === curso.id).length;
            const estudiantesDelCurso = inscripcionesData.filter(i => i.curso_id === curso.id).length;
            
            // Solo mostrar logs para el primer curso
            if (index === 0) {
              console.log(`🔍 [CURSO ${index}] ${curso.titulo}:`);
              console.log(`📊 [CURSO ${index}] - Módulos reales: ${modulosDelCurso}`);
              console.log(`📊 [CURSO ${index}] - Lecciones reales: ${leccionesDelCurso}`);
              console.log(`📊 [CURSO ${index}] - Estudiantes reales: ${estudiantesDelCurso}`);
              console.log(`📊 [CURSO ${index}] - Campo directo estudiantes_inscritos: ${curso.estudiantes_inscritos}`);
              console.log(`📊 [CURSO ${index}] - Campo directo conteo_lecciones: ${curso.conteo_lecciones}`);
            }
            
                          const cursoFinal = {
                ...curso,
                modulos_count_real: modulosDelCurso,
                lecciones_count_real: leccionesDelCurso,
                estudiantes_inscritos_real: estudiantesDelCurso
              };
              
              // Debug para el primer curso
              if (index === 0) {
                console.log('🎯 [CURSO FINAL]', cursoFinal);
                console.log('🎯 [CURSO FINAL] Campos:', Object.keys(cursoFinal));
              }
              
              return cursoFinal;
          });
          console.log('✅ Cursos procesados:', cursos.length);
        }

        if (tutorialesRes.error) {
          console.error('❌ Error cargando tutoriales:', tutorialesRes.error);
        } else {
          // Procesar tutoriales con conteos MANUALES
          tutoriales = (tutorialesRes.data || []).map((tutorial, index) => {
            const estudiantesDelTutorial = inscripcionesData.filter(i => i.tutorial_id === tutorial.id).length;
            const partesDelTutorial = partesData.filter(p => p.tutorial_id === tutorial.id).length;
            
            // Solo mostrar logs para el primer tutorial  
            if (index === 0) {
              console.log(`🔍 [TUTORIAL ${index}] ${tutorial.titulo}:`);
              console.log(`📊 [TUTORIAL ${index}] - ID: ${tutorial.id}`);
              console.log(`📊 [TUTORIAL ${index}] - Estudiantes reales: ${estudiantesDelTutorial}`);
              console.log(`📊 [TUTORIAL ${index}] - Partes reales: ${partesDelTutorial}`);
              console.log(`📊 [TUTORIAL ${index}] - Inscripciones que coinciden:`, inscripcionesData.filter(i => i.tutorial_id === tutorial.id));
            }
            
                          const tutorialFinal = {
                ...tutorial,
                estudiantes_inscritos_real: estudiantesDelTutorial,
                partes_count_real: partesDelTutorial
              };
              
              // Debug para el primer tutorial
              if (index === 0) {
                console.log('🎯 [TUTORIAL FINAL]', tutorialFinal);
                console.log('🎯 [TUTORIAL FINAL] Campos:', Object.keys(tutorialFinal));
              }
              
              return tutorialFinal;
          });
          console.log('✅ Tutoriales procesados:', tutoriales.length);
        }

      } catch (error) {
        console.error('❌ Error general cargando datos:', error);
      } finally {
        cargando = false;
        console.log('✅ Panel de contenido cargado completamente');
      }
    });
  
    function navegarACrearCurso() {
      goto('/administrador/crear-contenido?tipo=curso');
    }
  
    function navegarACrearTutorial() {
      goto('/administrador/crear-contenido?tipo=tutorial');
    }
  
    function limpiarFiltros() {
      textoBusqueda = '';
      filtroEstado = 'todos';
      filtroTipo = 'todos';
    }
  </script>
  
  <div class="panel-contenido">
    {#if cargando}
      <div class="loading">
        <div class="spinner"></div>
        <p>Cargando panel de contenido...</p>
      </div>
    {:else}
      <!-- Header -->
      <header class="header">
        <div class="header-content">
          <div class="header-info">
            <h1>📚 Panel de Contenido</h1>
            <p>Gestiona tus cursos y tutoriales</p>
            <div class="stats">
              <span class="stat-item">📊 {stats.total} total</span>
              <span class="stat-item">✅ {stats.publicados} publicados</span>
              <span class="stat-item {stats.filtrados !== stats.total ? 'stat-filtrado' : ''}">
                🎯 {stats.filtrados} mostrando
              </span>
            </div>
            
            <!-- Indicadores de filtros activos -->
            {#if textoBusqueda || filtroEstado !== 'todos' || filtroTipo !== 'todos'}
              <div class="filtros-activos">
                <span class="filtros-label">Filtros activos:</span>
                {#if textoBusqueda}
                  <span class="filtro-tag">🔍 "{textoBusqueda}"</span>
                {/if}
                {#if filtroTipo !== 'todos'}
                  <span class="filtro-tag">📁 {filtroTipo === 'curso' ? 'Cursos' : 'Tutoriales'}</span>
                {/if}
                {#if filtroEstado !== 'todos'}
                  <span class="filtro-tag">📌 {filtroEstado === 'publicado' ? 'Publicados' : 'Borradores'}</span>
                {/if}
              </div>
            {/if}
          </div>
          <div class="header-actions">
            <button class="btn-create curso" on:click={navegarACrearCurso}>
              📚 Crear Curso
            </button>
            <button class="btn-create tutorial" on:click={navegarACrearTutorial}>
              🎥 Crear Tutorial
            </button>
          </div>
        </div>
      </header>
  
      <!-- Filtros -->
      <section class="filters">
        <div class="filters-content">
          <div class="search-box">
            <div class="search-input-container">
              <svg class="search-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <circle cx="11" cy="11" r="8"/>
                <path d="m21 21-4.35-4.35"/>
              </svg>
            <input 
              type="text" 
                placeholder="Buscar por título, descripción, artista, tonalidad..." 
              bind:value={textoBusqueda}
              class="search-input"
            />
              {#if textoBusqueda}
                <button class="clear-search" on:click={() => textoBusqueda = ''}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <line x1="18" y1="6" x2="6" y2="18"/>
                    <line x1="6" y1="6" x2="18" y2="18"/>
                  </svg>
                </button>
              {/if}
            </div>
          </div>
          
          <div class="filter-controls">
            <select bind:value={filtroTipo} class="filter-select">
              <option value="todos">🎯 Todos</option>
              <option value="curso">📚 Cursos</option>
              <option value="tutorial">🎥 Tutoriales</option>
            </select>
            
            <select bind:value={filtroEstado} class="filter-select">
              <option value="todos">🔄 Todos</option>
              <option value="publicado">✅ Publicados</option>
              <option value="borrador">📝 Borradores</option>
            </select>
  
            <button class="btn-limpiar" on:click={limpiarFiltros}>
              🔄 Limpiar
            </button>
  
            <div class="view-toggle">
              <button 
                class="view-btn {modoVista === 'cuadricula' ? 'active' : ''}"
                on:click={() => modoVista = 'cuadricula'}
                title="Vista de cuadrícula"
              >⊞</button>
              <button 
                class="view-btn {modoVista === 'lista' ? 'active' : ''}"
                on:click={() => modoVista = 'lista'}
                title="Vista de lista"
              >☰</button>
            </div>
          </div>
        </div>
      </section>
  
      <!-- Contenido -->
      <main class="main-content">
        <div class="content-area">
          {#if itemsFiltrados.length === 0 && (textoBusqueda || filtroEstado !== 'todos' || filtroTipo !== 'todos')}
            <div class="estado-vacio">
              <div class="icono-vacio">🔍</div>
              <h3>No se encontraron resultados</h3>
              <p>Intenta ajustar los filtros o buscar con términos diferentes</p>
              <button class="btn-limpiar-vacio" on:click={limpiarFiltros}>
                🔄 Limpiar filtros
              </button>
            </div>
          {:else if itemsFiltrados.length === 0}
            <div class="estado-vacio">
              <div class="icono-vacio">📚</div>
              <h3>¡Empieza creando contenido!</h3>
              <p>Aún no tienes cursos o tutoriales creados</p>
              <div class="acciones-rapidas">
                <button class="btn-create curso" on:click={navegarACrearCurso}>
                  📚 Crear Primer Curso
                </button>
                <button class="btn-create tutorial" on:click={navegarACrearTutorial}>
                  🎥 Crear Primer Tutorial
                </button>
              </div>
            </div>
          {:else}
          <MostradorCursosTutoriales 
            cursos={itemsFiltrados.filter(item => item.tipo === 'curso')} 
            tutoriales={itemsFiltrados.filter(item => item.tipo === 'tutorial')}
            {modoVista}
          />
          {/if}
        </div>
        <aside class="sidebar">
          <SidebarResumenAdmin />
        </aside>
      </main>
    {/if}
  </div>
  
  <style>
    .panel-contenido {
      font-family: 'Inter', sans-serif;
      min-height: 100vh;
      background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    }
  
    /* Loading */
    .loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      gap: 1rem;
      color: #64748b;
    }
  
    .spinner {
      width: 40px;
      height: 40px;
      border: 3px solid #e2e8f0;
      border-top: 3px solid #667eea;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
  
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  
    /* Header */
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 2rem;
    }
  
    .header-content {
      max-width: 1400px;
      margin: 0 auto;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 2rem;
    }
  
    .header-info h1 {
      font-size: 2rem;
      font-weight: 700;
      margin: 0 0 0.5rem 0;
    }
  
    .header-info p {
      opacity: 0.9;
      margin: 0 0 1rem 0;
    }
  
    .stats {
      display: flex;
      gap: 1rem;
      font-size: 0.9rem;
      opacity: 0.9;
      margin-bottom: 0.5rem;
    }

    .stat-item {
      background: rgba(255, 255, 255, 0.1);
      padding: 0.25rem 0.75rem;
      border-radius: 20px;
      font-weight: 500;
    }

    .stat-filtrado {
      background: rgba(255, 255, 255, 0.2);
      font-weight: 600;
      animation: highlight 2s ease-in-out;
    }

    @keyframes highlight {
      0%, 100% { background: rgba(255, 255, 255, 0.2); }
      50% { background: rgba(255, 255, 255, 0.3); }
    }

    .filtros-activos {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      align-items: center;
      margin-top: 0.5rem;
    }

    .filtros-label {
      font-size: 0.8rem;
      opacity: 0.8;
      font-weight: 500;
    }

    .filtro-tag {
      background: rgba(255, 255, 255, 0.15);
      color: white;
      padding: 0.2rem 0.6rem;
      border-radius: 15px;
      font-size: 0.75rem;
      font-weight: 500;
      border: 1px solid rgba(255, 255, 255, 0.2);
    }
  
    .header-actions {
      display: flex;
      gap: 1rem;
    }
  
    .btn-create {
      padding: 0.75rem 1.5rem;
      border: none;
      border-radius: 10px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
      color: white;
    }
  
    .btn-create.curso {
      background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    }
  
    .btn-create.tutorial {
      background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
    }
  
    .btn-create:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    }
  
    /* Filtros */
    .filters {
      background: white;
      border-bottom: 1px solid #e2e8f0;
      padding: 1.5rem;
    }
  
    .filters-content {
      max-width: 1400px;
      margin: 0 auto;
      padding: 0 2rem;
      display: flex;
      gap: 1.5rem;
      align-items: center;
    }
  
    .search-box {
      flex: 1;
      max-width: 500px;
    }

    .search-input-container {
      position: relative;
      display: flex;
      align-items: center;
    }

    .search-icon {
      position: absolute;
      left: 12px;
      color: #9ca3af;
      z-index: 1;
    }
  
    .search-input {
      width: 100%;
      padding: 0.75rem 1rem 0.75rem 2.5rem;
      padding-right: 2.5rem;
      border: 2px solid #e5e7eb;
      border-radius: 12px;
      font-size: 1rem;
      transition: all 0.2s;
      background: #fafafa;
    }
  
    .search-input:focus {
      outline: none;
      border-color: #667eea;
      background: white;
      box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
    }

    .clear-search {
      position: absolute;
      right: 8px;
      background: #f1f5f9;
      border: none;
      border-radius: 50%;
      width: 24px;
      height: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      color: #64748b;
      transition: all 0.2s;
    }

    .clear-search:hover {
      background: #e2e8f0;
      color: #475569;
    }
  
    .filter-controls {
      display: flex;
      gap: 1rem;
      align-items: center;
    }
  
    .filter-select {
      padding: 0.75rem;
      border: 2px solid #e5e7eb;
      border-radius: 12px;
      font-size: 0.9rem;
      cursor: pointer;
      min-width: 140px;
      background: white;
      transition: all 0.2s;
    }

    .filter-select:focus {
      outline: none;
      border-color: #667eea;
      box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
    }

    .btn-limpiar {
      padding: 0.75rem 1.25rem;
      background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
      color: white;
      border: none;
      border-radius: 12px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
      display: flex;
      align-items: center;
      gap: 0.5rem;
      font-size: 0.9rem;
    }

    .btn-limpiar:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
    }
  
    .view-toggle {
      display: flex;
      background: #f1f5f9;
      border-radius: 12px;
      padding: 0.25rem;
      border: 1px solid #e2e8f0;
    }
  
    .view-btn {
      padding: 0.75rem;
      border: none;
      background: transparent;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s;
      font-size: 1.2rem;
      color: #64748b;
      min-width: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .view-btn:hover {
      background: rgba(255, 255, 255, 0.7);
      color: #475569;
    }
  
    .view-btn.active {
      background: white;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      color: #667eea;
      font-weight: 600;
    }
  
    /* Main Content */
    .main-content {
      width: 100%;
      margin: 0 auto;
      padding: 2rem;
      display: grid;
      grid-template-columns: 1fr 300px;
      gap: 2rem;
    }
  
    .content-area {
      background: white;
      border-radius: 12px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
      padding: 1.5rem;
      min-height: 400px;
    }

    .estado-vacio {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      padding: 3rem 2rem;
      min-height: 300px;
    }

    .icono-vacio {
      font-size: 4rem;
      margin-bottom: 1rem;
      opacity: 0.6;
    }

    .estado-vacio h3 {
      font-size: 1.5rem;
      font-weight: 700;
      color: #374151;
      margin: 0 0 0.5rem 0;
    }

    .estado-vacio p {
      color: #6b7280;
      margin: 0 0 2rem 0;
      max-width: 400px;
      line-height: 1.5;
    }

    .btn-limpiar-vacio {
      padding: 0.75rem 1.5rem;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      border-radius: 12px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .btn-limpiar-vacio:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
    }

    .acciones-rapidas {
      display: flex;
      gap: 1rem;
      flex-wrap: wrap;
      justify-content: center;
    }

    .acciones-rapidas .btn-create {
      margin: 0;
    }
  
    .sidebar {
      background: white;
      border-radius: 12px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
      padding: 1.5rem;
      height: fit-content;
      position: sticky;
      top: 2rem;
    }
  
    /* Responsive */
    @media (max-width: 1024px) {
      .main-content {
        grid-template-columns: 1fr;
      }
      
      .sidebar {
        position: static;
      }
    }
  
    @media (max-width: 768px) {
      .header-content {
        flex-direction: column;
        text-align: center;
      }
  
      .header-actions {
        flex-direction: column;
        width: 100%;
        max-width: 300px;
      }
  
      .filters-content {
        flex-direction: column;
        gap: 1rem;
      }
  
      .search-box {
        max-width: none;
      }
  
      .filter-controls {
        flex-wrap: wrap;
        justify-content: center;
      }
  
      .main-content {
        padding: 1rem;
      }
    }
  
    @media (max-width: 480px) {
      .header {
        padding: 1.5rem 1rem;
      }
  
      .header-info h1 {
        font-size: 1.5rem;
      }
  
      .stats {
        flex-direction: column;
        gap: 0.5rem;
      }
    }
  </style>
  