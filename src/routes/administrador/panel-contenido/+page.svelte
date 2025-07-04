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
  
    // Datos computados para filtros
    $: itemsFiltrados = filtrarContenido(cursos, tutoriales);
    $: stats = { 
      total: cursos.length + tutoriales.length,
      publicados: [...cursos, ...tutoriales].filter(item => item.estado === 'publicado').length,
      filtrados: itemsFiltrados.length
    };
  
    function filtrarContenido(cursos: any[], tutoriales: any[]) {
      let items = [
        ...cursos.map(c => ({ ...c, tipo: 'curso' })),
        ...tutoriales.map(t => ({ ...t, tipo: 'tutorial' }))
      ];
  
      if (textoBusqueda.trim()) {
        const busqueda = textoBusqueda.toLowerCase();
        items = items.filter(item => 
          item.titulo?.toLowerCase().includes(busqueda) ||
          item.descripcion?.toLowerCase().includes(busqueda)
        );
      }
  
      if (filtroEstado !== 'todos') {
        items = items.filter(item => item.estado === filtroEstado);
      }
  
      if (filtroTipo !== 'todos') {
        items = items.filter(item => item.tipo === filtroTipo);
      }
  
      return items.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
    }
  
    onMount(async () => {
      try {
        const [cursosRes, tutorialesRes] = await Promise.all([
          supabase.from('cursos').select('*').order('created_at', { ascending: false }),
          supabase.from('tutoriales').select('*').order('created_at', { ascending: false })
        ]);
  
        cursos = cursosRes.data || [];
        tutoriales = tutorialesRes.data || [];
      } catch (error) {
        console.error('Error cargando datos:', error);
      } finally {
        cargando = false;
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
              <span>{stats.total} total</span>
              <span>{stats.publicados} publicados</span>
              <span>{stats.filtrados} mostrando</span>
            </div>
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
            <input 
              type="text" 
              placeholder="Buscar contenido..." 
              bind:value={textoBusqueda}
              class="search-input"
            />
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
  
            <div class="view-toggle">
              <button 
                class="view-btn {modoVista === 'cuadricula' ? 'active' : ''}"
                on:click={() => modoVista = 'cuadricula'}
              >⊞</button>
              <button 
                class="view-btn {modoVista === 'lista' ? 'active' : ''}"
                on:click={() => modoVista = 'lista'}
              >☰</button>
            </div>
          </div>
        </div>
      </section>
  
      <!-- Contenido -->
      <main class="main-content">
        <div class="content-area">
          <MostradorCursosTutoriales 
            cursos={itemsFiltrados.filter(item => item.tipo === 'curso')} 
            tutoriales={itemsFiltrados.filter(item => item.tipo === 'tutorial')}
            {modoVista}
          />
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
      opacity: 0.8;
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
      max-width: 400px;
    }
  
    .search-input {
      width: 100%;
      padding: 0.75rem 1rem;
      border: 2px solid #e5e7eb;
      border-radius: 8px;
      font-size: 1rem;
      transition: border-color 0.2s;
    }
  
    .search-input:focus {
      outline: none;
      border-color: #667eea;
    }
  
    .filter-controls {
      display: flex;
      gap: 1rem;
      align-items: center;
    }
  
    .filter-select {
      padding: 0.75rem;
      border: 2px solid #e5e7eb;
      border-radius: 8px;
      font-size: 0.9rem;
      cursor: pointer;
      min-width: 140px;
    }
  
    .view-toggle {
      display: flex;
      background: #f1f5f9;
      border-radius: 8px;
      padding: 0.25rem;
    }
  
    .view-btn {
      padding: 0.5rem;
      border: none;
      background: transparent;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.2s;
      font-size: 1.2rem;
    }
  
    .view-btn.active {
      background: white;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
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
  