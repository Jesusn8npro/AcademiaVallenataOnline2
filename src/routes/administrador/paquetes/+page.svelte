<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import { 
        obtenerTodosPaquetes, 
        eliminarPaquete, 
        formatearPrecio,
        type PaqueteTutorial 
    } from '$lib/services/paquetesService';
    import { supabase } from '$lib/supabase/clienteSupabase';

    // Estados
    let paquetes: PaqueteTutorial[] = [];
    let cargando = true;
    let error = '';
    let exito = '';

    // Filtros
    let filtroEstado = 'todos';
    let filtroCategoria = 'todas';
    let textoBusqueda = '';
    let modoVista: 'cuadricula' | 'lista' = 'cuadricula';

    // Datos computados
    $: paquetesFiltrados = filtrarPaquetes(paquetes);
    $: stats = calcularEstadisticas(paquetes);

    // Funciones
    function filtrarPaquetes(paquetes: PaqueteTutorial[]) {
        let resultado = [...paquetes];

        if (filtroEstado !== 'todos') {
            resultado = resultado.filter(p => p.estado === filtroEstado);
        }

        if (filtroCategoria !== 'todas') {
            resultado = resultado.filter(p => p.categoria === filtroCategoria);
        }

        if (textoBusqueda.trim()) {
            const busqueda = textoBusqueda.toLowerCase();
            resultado = resultado.filter(p => 
                p.titulo.toLowerCase().includes(busqueda) ||
                p.descripcion?.toLowerCase().includes(busqueda) ||
                p.categoria?.toLowerCase().includes(busqueda)
            );
        }

        return resultado.sort((a, b) => new Date(b.created_at || '').getTime() - new Date(a.created_at || '').getTime());
    }

    function calcularEstadisticas(paquetes: PaqueteTutorial[]) {
        return {
            total: paquetes.length,
            publicados: paquetes.filter(p => p.estado === 'publicado').length,
            borradores: paquetes.filter(p => p.estado === 'borrador').length,
            destacados: paquetes.filter(p => p.destacado).length
        };
    }

    async function cargarDatos() {
        try {
            cargando = true;
            error = '';

            const resultadoPaquetes = await obtenerTodosPaquetes();
            if (resultadoPaquetes.success) {
                paquetes = resultadoPaquetes.data;
            } else {
                throw new Error(resultadoPaquetes.error);
            }

        } catch (err: any) {
            error = 'Error cargando datos: ' + err.message;
            console.error('Error:', err);
        } finally {
            cargando = false;
        }
    }

    async function eliminarPaqueteConfirmado(id: string, titulo: string) {
        if (!confirm(`¿Estás seguro de eliminar el paquete "${titulo}"? Esta acción no se puede deshacer.`)) {
            return;
        }

        try {
            const resultado = await eliminarPaquete(id);
            if (resultado.success) {
                exito = resultado.message || 'Paquete eliminado exitosamente';
                await cargarDatos();
                setTimeout(() => exito = '', 3000);
            } else {
                error = resultado.error || 'Error eliminando paquete';
                setTimeout(() => error = '', 5000);
            }
        } catch (err: any) {
            error = 'Error eliminando paquete: ' + err.message;
            setTimeout(() => error = '', 5000);
        }
    }

    function limpiarFiltros() {
        filtroEstado = 'todos';
        filtroCategoria = 'todas';
        textoBusqueda = '';
    }

    function obtenerCategorias() {
        const categorias = [...new Set(paquetes.map(p => p.categoria).filter(Boolean))];
        return categorias.sort();
    }

    function getEstadoBadge(estado: string) {
        switch (estado) {
            case 'publicado': return 'success';
            case 'borrador': return 'warning';
            case 'archivado': return 'secondary';
            default: return 'info';
        }
    }

    function formatearFecha(fecha: string) {
        return new Date(fecha).toLocaleDateString('es-CO', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }

    function irACrearPaquete() {
        goto('/administrador/paquetes/crear');
    }

    function irAEditarPaquete(id: string) {
        goto(`/administrador/paquetes/editar/${id}`);
    }

    function verPaquete(slug: string) {
        goto(`/paquetes/${slug}`);
    }

    onMount(() => {
        cargarDatos();
    });
</script>

<svelte:head>
    <title>Gestión de Paquetes - Academia Vallenata</title>
</svelte:head>

<div class="admin-paquetes">
    <!-- Header Hero Moderno -->
    <section class="hero-section">
        <div class="hero-background">
            <div class="gradient-overlay"></div>
            <div class="hero-pattern"></div>
        </div>
        
        <div class="hero-content">
            <div class="hero-text">
                <h1 class="hero-title">
                    <span class="icon">🎁</span>
                    Gestión de Paquetes
                </h1>
                <p class="hero-subtitle">
                    Crea y administra paquetes irresistibles para tus estudiantes
                </p>
                
                <!-- Estadísticas Hero -->
                {#if stats}
                    <div class="stats-hero">
                        <div class="stat-item">
                            <div class="stat-number">{stats.total}</div>
                            <div class="stat-label">Total</div>
                        </div>
                        <div class="stat-divider"></div>
                        <div class="stat-item">
                            <div class="stat-number">{stats.publicados}</div>
                            <div class="stat-label">Publicados</div>
                        </div>
                        <div class="stat-divider"></div>
                        <div class="stat-item">
                            <div class="stat-number">{stats.borradores}</div>
                            <div class="stat-label">Borradores</div>
                        </div>
                        <div class="stat-divider"></div>
                        <div class="stat-item">
                            <div class="stat-number">{stats.destacados}</div>
                            <div class="stat-label">Destacados</div>
                        </div>
                    </div>
                {/if}
            </div>
            
            <div class="hero-actions">
                <button class="btn-primary-hero" on:click={irACrearPaquete}>
                    <span class="btn-icon">✨</span>
                    Crear Paquete
                </button>
            </div>
        </div>
    </section>

    <!-- Mensajes -->
    {#if error}
        <div class="alert error">
            <span class="alert-icon">❌</span>
            <span class="alert-text">{error}</span>
        </div>
    {/if}

    {#if exito}
        <div class="alert success">
            <span class="alert-icon">✅</span>
            <span class="alert-text">{exito}</span>
        </div>
    {/if}

    <!-- Panel de Filtros Modernos -->
    <section class="filters-panel">
        <div class="filters-container">
            <div class="filters-row">
                <!-- Búsqueda -->
                <div class="search-container">
                    <div class="search-input-group">
                        <span class="search-icon">🔍</span>
                        <input 
                            type="text" 
                            placeholder="Buscar paquetes..." 
                            bind:value={textoBusqueda}
                            class="search-input"
                        />
                        {#if textoBusqueda}
                            <button class="clear-search" on:click={() => textoBusqueda = ''}>
                                ✕
                            </button>
                        {/if}
                    </div>
                </div>

                <!-- Filtros -->
                <div class="filters-group">
                    <select bind:value={filtroEstado} class="filter-select">
                        <option value="todos">📊 Todos los estados</option>
                        <option value="publicado">✅ Publicados</option>
                        <option value="borrador">📝 Borradores</option>
                        <option value="archivado">📦 Archivados</option>
                    </select>
                    
                    <select bind:value={filtroCategoria} class="filter-select">
                        <option value="todas">🎵 Todas las categorías</option>
                        {#each obtenerCategorias() as categoria}
                            <option value={categoria}>{categoria}</option>
                        {/each}
                    </select>
                </div>

                <!-- Controles de Vista -->
                <div class="view-controls">
                    <div class="view-toggle">
                        <button 
                            class="view-btn {modoVista === 'cuadricula' ? 'active' : ''}"
                            on:click={() => modoVista = 'cuadricula'}
                            title="Vista en cuadrícula"
                        >
                            <span>⊞</span>
                        </button>
                        <button 
                            class="view-btn {modoVista === 'lista' ? 'active' : ''}"
                            on:click={() => modoVista = 'lista'}
                            title="Vista de lista"
                        >
                            <span>☰</span>
                        </button>
                    </div>
                    
                    {#if textoBusqueda || filtroEstado !== 'todos' || filtroCategoria !== 'todas'}
                        <button class="btn-clear-filters" on:click={limpiarFiltros}>
                            <span>🔄</span>
                            Limpiar
                        </button>
                    {/if}
                </div>
            </div>
        </div>
    </section>

    <!-- Contenido Principal -->
    <section class="content-section">
        <div class="content-container">
            {#if cargando}
                <div class="loading-state">
                    <div class="loading-spinner"></div>
                    <h3>Cargando paquetes...</h3>
                    <p>Un momento por favor</p>
                </div>
            {:else if paquetesFiltrados.length === 0}
                <div class="empty-state">
                    <div class="empty-icon">📦</div>
                    <h3>No hay paquetes disponibles</h3>
                    <p>
                        {#if textoBusqueda || filtroEstado !== 'todos' || filtroCategoria !== 'todas'}
                            No se encontraron paquetes con los filtros aplicados.
                        {:else}
                            Comienza creando tu primer paquete de tutoriales.
                        {/if}
                    </p>
                    {#if !textoBusqueda && filtroEstado === 'todos' && filtroCategoria === 'todas'}
                        <button class="btn-primary" on:click={irACrearPaquete}>
                            <span>✨</span>
                            Crear Primer Paquete
                        </button>
                    {:else}
                        <button class="btn-secondary" on:click={limpiarFiltros}>
                            <span>🔄</span>
                            Limpiar Filtros
                        </button>
                    {/if}
                </div>
            {:else}
                <!-- Vista Cuadrícula Moderna -->
                {#if modoVista === 'cuadricula'}
                    <div class="paquetes-grid">
                        {#each paquetesFiltrados as paquete}
                            <article class="paquete-card">
                                <div class="card-image-container">
                                    {#if paquete.imagen_url}
                                        <img 
                                            src={paquete.imagen_url} 
                                            alt={paquete.titulo} 
                                            class="card-image"
                                            loading="lazy" 
                                        />
                                    {:else}
                                        <div class="card-placeholder">
                                            <span class="placeholder-icon">🎁</span>
                                        </div>
                                    {/if}
                                    
                                    <!-- Badges Flotantes -->
                                    <div class="card-badges">
                                        {#if paquete.destacado}
                                            <span class="badge featured">⭐ Destacado</span>
                                        {/if}
                                        <span class="badge {getEstadoBadge(paquete.estado || '')}">
                                            {paquete.estado}
                                        </span>
                                    </div>

                                    <!-- Overlay de Acciones -->
                                    <div class="card-overlay">
                                        <div class="card-actions">
                                            <button 
                                                class="action-btn edit" 
                                                on:click={() => irAEditarPaquete(paquete.id || '')}
                                                title="Editar paquete"
                                            >
                                                <span>✏️</span>
                                            </button>
                                            {#if paquete.estado === 'publicado'}
                                                <button 
                                                    class="action-btn view" 
                                                    on:click={() => verPaquete(paquete.slug || '')}
                                                    title="Ver paquete"
                                                >
                                                    <span>👁️</span>
                                                </button>
                                            {/if}
                                            <button 
                                                class="action-btn delete" 
                                                on:click={() => eliminarPaqueteConfirmado(paquete.id || '', paquete.titulo)}
                                                title="Eliminar paquete"
                                            >
                                                <span>🗑️</span>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="card-content">
                                    <h3 class="card-title">{paquete.titulo}</h3>
                                    
                                    {#if paquete.descripcion_corta}
                                        <p class="card-description">{paquete.descripcion_corta}</p>
                                    {/if}
                                    
                                    <div class="card-meta">
                                        <div class="meta-item">
                                            <span class="meta-icon">🎵</span>
                                            <span>{paquete.categoria || 'Sin categoría'}</span>
                                        </div>
                                        <div class="meta-item">
                                            <span class="meta-icon">📚</span>
                                            <span>{paquete.total_tutoriales || 0} tutoriales</span>
                                        </div>
                                        <div class="meta-item">
                                            <span class="meta-icon">🎯</span>
                                            <span>{paquete.nivel}</span>
                                        </div>
                                    </div>
                                    
                                    <div class="card-pricing">
                                        {#if paquete.precio_rebajado && paquete.precio_rebajado < paquete.precio_normal}
                                            <div class="price-group">
                                                <span class="price-current">{formatearPrecio(paquete.precio_rebajado)}</span>
                                                <span class="price-original">{formatearPrecio(paquete.precio_normal)}</span>
                                                <span class="price-discount">
                                                    -{Math.round(((paquete.precio_normal - paquete.precio_rebajado) / paquete.precio_normal) * 100)}%
                                                </span>
                                            </div>
                                        {:else}
                                            <span class="price-current">{formatearPrecio(paquete.precio_normal)}</span>
                                        {/if}
                                    </div>
                                    
                                    <div class="card-footer">
                                        <span class="created-date">
                                            {formatearFecha(paquete.created_at || '')}
                                        </span>
                                    </div>
                                </div>
                            </article>
                        {/each}
                    </div>
                {:else}
                    <!-- Vista de Lista Moderna -->
                    <div class="paquetes-list">
                        {#each paquetesFiltrados as paquete}
                            <article class="list-item">
                                <div class="item-image">
                                    {#if paquete.imagen_url}
                                        <img src={paquete.imagen_url} alt={paquete.titulo} />
                                    {:else}
                                        <div class="item-placeholder">🎁</div>
                                    {/if}
                                </div>
                                
                                <div class="item-content">
                                    <div class="item-header">
                                        <h3 class="item-title">{paquete.titulo}</h3>
                                        <div class="item-badges">
                                            {#if paquete.destacado}
                                                <span class="badge featured">⭐</span>
                                            {/if}
                                            <span class="badge {getEstadoBadge(paquete.estado || '')}">
                                                {paquete.estado}
                                            </span>
                                        </div>
                                    </div>
                                    
                                    <div class="item-meta">
                                        <span class="meta-item">🎵 {paquete.categoria}</span>
                                        <span class="meta-item">📚 {paquete.total_tutoriales || 0} tutoriales</span>
                                        <span class="meta-item">🎯 {paquete.nivel}</span>
                                        <span class="meta-item">📅 {formatearFecha(paquete.created_at || '')}</span>
                                    </div>
                                </div>
                                
                                <div class="item-pricing">
                                    {#if paquete.precio_rebajado && paquete.precio_rebajado < paquete.precio_normal}
                                        <div class="price-group">
                                            <span class="price-current">{formatearPrecio(paquete.precio_rebajado)}</span>
                                            <span class="price-original">{formatearPrecio(paquete.precio_normal)}</span>
                                        </div>
                                    {:else}
                                        <span class="price-current">{formatearPrecio(paquete.precio_normal)}</span>
                                    {/if}
                                </div>
                                
                                <div class="item-actions">
                                    <button 
                                        class="action-btn edit" 
                                        on:click={() => irAEditarPaquete(paquete.id || '')}
                                        title="Editar"
                                    >✏️</button>
                                    {#if paquete.estado === 'publicado'}
                                        <button 
                                            class="action-btn view" 
                                            on:click={() => verPaquete(paquete.slug || '')}
                                            title="Ver"
                                        >👁️</button>
                                    {/if}
                                    <button 
                                        class="action-btn delete" 
                                        on:click={() => eliminarPaqueteConfirmado(paquete.id || '', paquete.titulo)}
                                        title="Eliminar"
                                    >🗑️</button>
                                </div>
                            </article>
                        {/each}
                    </div>
                {/if}
            {/if}
        </div>
    </section>
</div>

<style>
    /* Variables CSS locales */
    .admin-paquetes {
        --gradiente-primario: linear-gradient(135deg, var(--primary-color) 0%, #764ba2 100%);
        --gradiente-exito: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        --patron-hero: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.05'%3E%3Ccircle cx='30' cy='30' r='4'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
        --sombra-elevada: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        --sombra-tarjeta: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        --sombra-boton: 0 4px 14px 0 rgba(0, 0, 0, 0.1);
        --transicion: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .admin-paquetes {
        min-height: 100vh;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
    }

    /* Sección Hero */
    .hero-section {
        position: relative;
        padding: 4rem 2rem;
        overflow: hidden;
    }

    .hero-background {
        position: absolute;
        inset: 0;
        background: var(--gradiente-primario);
    }

    .gradient-overlay {
        position: absolute;
        inset: 0;
        background: linear-gradient(135deg, rgba(102, 126, 234, 0.9), rgba(118, 75, 162, 0.8));
    }

    .hero-pattern {
        position: absolute;
        inset: 0;
        background-image: var(--patron-hero);
        opacity: 0.1;
    }

    .hero-content {
        position: relative;
        max-width: 1200px;
        margin: 0 auto;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 3rem;
    }

    .hero-title {
        font-size: 3.5rem;
        font-weight: 800;
        color: white;
        margin: 0 0 1rem 0;
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .hero-title .icon {
        font-size: 4rem;
        filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.2));
    }

    .hero-subtitle {
        font-size: 1.25rem;
        color: rgba(255, 255, 255, 0.9);
        margin: 0 0 2rem 0;
        max-width: 500px;
        line-height: 1.6;
    }

    .stats-hero {
        display: flex;
        align-items: center;
        gap: 1.5rem;
        background: rgba(255, 255, 255, 0.1);
        backdrop-filter: blur(10px);
        padding: 1.5rem 2rem;
        border-radius: var(--radius);
        border: 1px solid rgba(255, 255, 255, 0.2);
    }

    .stat-item {
        text-align: center;
    }

    .stat-number {
        display: block;
        font-size: 2rem;
        font-weight: 700;
        color: white;
        line-height: 1;
    }

    .stat-label {
        display: block;
        font-size: 0.875rem;
        color: rgba(255, 255, 255, 0.8);
        margin-top: 0.25rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .stat-divider {
        width: 1px;
        height: 3rem;
        background: rgba(255, 255, 255, 0.3);
    }

    .btn-primary-hero {
        background: var(--gradiente-exito);
        color: white;
        border: none;
        padding: 1rem 2rem;
        border-radius: var(--radio);
        font-size: 1.125rem;
        font-weight: 600;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        cursor: pointer;
        transition: var(--transicion);
        box-shadow: var(--sombra-boton);
        white-space: nowrap;
    }

    .btn-primary-hero:hover {
        transform: translateY(-2px);
        box-shadow: var(--sombra-elevada);
    }

    .btn-icon {
        font-size: 1.25rem;
    }

    /* Alertas y Panel de Filtros */
    .alert {
        max-width: 1200px;
        margin: 2rem auto;
        padding: 1rem 2rem;
        border-radius: var(--radio);
        display: flex;
        align-items: center;
        gap: 1rem;
        font-weight: 500;
    }

    .alert.error {
        background: linear-gradient(135deg, #fee2e2, #fecaca);
        color: #dc2626;
        border: 1px solid #f87171;
    }

    .alert.success {
        background: linear-gradient(135deg, #dcfce7, #bbf7d0);
        color: #16a34a;
        border: 1px solid #4ade80;
    }

    .filters-panel {
        background: white;
        border-bottom: 1px solid #e5e7eb;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        position: sticky;
        top: 0;
        z-index: 100;
    }

    .filters-container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 1.5rem 2rem;
    }

    .filters-row {
        display: flex;
        align-items: center;
        gap: 2rem;
        flex-wrap: wrap;
    }

    .search-container {
        flex: 1;
        min-width: 300px;
    }

    .search-input-group {
        position: relative;
        display: flex;
        align-items: center;
    }

    .search-icon {
        position: absolute;
        left: 1rem;
        color: #6b7280;
        z-index: 1;
    }

    .search-input {
        width: 100%;
        padding: 0.875rem 1rem 0.875rem 3rem;
        border: 2px solid #e5e7eb;
        border-radius: var(--radio);
        font-size: 1rem;
        transition: var(--transicion);
        background: white;
    }

    .search-input:focus {
        outline: none;
        border-color: #667eea;
        box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
    }

    .clear-search {
        position: absolute;
        right: 1rem;
        background: none;
        border: none;
        color: #6b7280;
        cursor: pointer;
        padding: 0.25rem;
        border-radius: 50%;
        transition: var(--transicion);
    }

    .clear-search:hover {
        background: #f3f4f6;
        color: #374151;
    }

    .filters-group {
        display: flex;
        gap: 1rem;
    }

    .filter-select {
        padding: 0.875rem 1rem;
        border: 2px solid #e5e7eb;
        border-radius: var(--radio);
        background: white;
        font-size: 1rem;
        cursor: pointer;
        transition: var(--transicion);
    }

    .filter-select:focus {
        outline: none;
        border-color: #667eea;
        box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
    }

    .view-controls {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .view-toggle {
        display: flex;
        background: #f3f4f6;
        border-radius: var(--radio);
        padding: 0.25rem;
    }

    .view-btn {
        padding: 0.75rem 1rem;
        border: none;
        background: transparent;
        border-radius: calc(var(--radio) - 0.25rem);
        cursor: pointer;
        transition: var(--transicion);
        color: #6b7280;
    }

    .view-btn.active {
        background: white;
        color: #667eea;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }

    .btn-clear-filters {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.875rem 1.5rem;
        background: #f3f4f6;
        border: 1px solid #d1d5db;
        border-radius: var(--radio);
        color: #374151;
        cursor: pointer;
        transition: var(--transicion);
        font-weight: 500;
    }

    .btn-clear-filters:hover {
        background: #e5e7eb;
    }

    /* Sección de Contenido y Estados */
    .content-section {
        padding: 3rem 2rem;
    }

    .content-container {
        max-width: 1200px;
        margin: 0 auto;
    }

    .loading-state, .empty-state {
        text-align: center;
        padding: 4rem 2rem;
    }

    .loading-spinner {
        width: 60px;
        height: 60px;
        margin: 0 auto 2rem;
        border: 4px solid #e5e7eb;
        border-top: 4px solid #667eea;
        border-radius: 50%;
        animation: spin 1s linear infinite;
    }

    .loading-state h3, .empty-state h3 {
        font-size: 1.5rem;
        font-weight: 600;
        color: #374151;
        margin: 0 0 1rem 0;
    }

    .loading-state p, .empty-state p {
        color: #6b7280;
        font-size: 1rem;
        margin: 0 0 2rem 0;
        max-width: 400px;
        margin-left: auto;
        margin-right: auto;
    }

    .empty-icon {
        font-size: 4rem;
        margin-bottom: 1.5rem;
        opacity: 0.6;
    }

    .btn-primary, .btn-secondary {
        display: inline-flex;
        align-items: center;
        gap: 0.75rem;
        padding: 1rem 2rem;
        border-radius: var(--radio);
        font-size: 1rem;
        font-weight: 600;
        cursor: pointer;
        transition: var(--transicion);
        border: none;
    }

    .btn-primary {
        background: var(--gradiente-primario);
        color: white;
        box-shadow: var(--sombra-boton);
    }

    .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: var(--sombra-elevada);
    }

    .btn-secondary {
        background: white;
        color: #6b7280;
        border: 2px solid #e5e7eb;
    }

    .btn-secondary:hover {
        border-color: #d1d5db;
        color: #374151;
    }

    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }

    /* Tarjetas de Paquetes */
    .paquetes-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
        gap: 2rem;
    }

    .paquete-card {
        background: white;
        border-radius: var(--radius-lg);
        overflow: hidden;
        box-shadow: var(--sombra-tarjeta);
        transition: var(--transicion);
        position: relative;
    }

    .paquete-card:hover {
        transform: translateY(-4px);
        box-shadow: var(--sombra-elevada);
    }

    .card-image-container {
        position: relative;
        height: 200px;
        overflow: hidden;
    }

    .card-image {
        width: 100%;
        height: 100%;
        object-fit: cover;
        transition: var(--transicion);
    }

    .paquete-card:hover .card-image {
        transform: scale(1.05);
    }

    .card-placeholder {
        width: 100%;
        height: 100%;
        background: var(--gradiente-primario);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .placeholder-icon {
        font-size: 3rem;
        color: white;
        opacity: 0.8;
    }

    .card-badges {
        position: absolute;
        top: 1rem;
        right: 1rem;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    .badge {
        padding: 0.5rem 1rem;
        border-radius: 50px;
        font-size: 0.75rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255, 255, 255, 0.2);
    }

    .badge.success { background: rgba(34, 197, 94, 0.9); color: white; }
    .badge.warning { background: rgba(245, 158, 11, 0.9); color: white; }
    .badge.secondary { background: rgba(107, 114, 128, 0.9); color: white; }
    .badge.featured { background: rgba(255, 215, 0, 0.9); color: #1f2937; }

    .card-overlay {
        position: absolute;
        inset: 0;
        background: linear-gradient(to top, rgba(0, 0, 0, 0.8), transparent);
        display: flex;
        align-items: flex-end;
        justify-content: center;
        padding: 1rem;
        opacity: 0;
        transition: var(--transicion);
    }

    .paquete-card:hover .card-overlay {
        opacity: 1;
    }

    .card-actions {
        display: flex;
        gap: 0.75rem;
    }

    .action-btn {
        width: 3rem;
        height: 3rem;
        border-radius: 50%;
        border: none;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.25rem;
        transition: var(--transicion);
        backdrop-filter: blur(10px);
    }

    .action-btn.edit { background: rgba(59, 130, 246, 0.9); color: white; }
    .action-btn.view { background: rgba(34, 197, 94, 0.9); color: white; }
    .action-btn.delete { background: rgba(239, 68, 68, 0.9); color: white; }

    .action-btn:hover {
        transform: scale(1.1);
    }

    .card-content {
        padding: 1.5rem;
    }

    .card-title {
        font-size: 1.25rem;
        font-weight: 700;
        color: #1f2937;
        margin: 0 0 0.75rem 0;
        line-height: 1.4;
    }

    .card-description {
        color: #6b7280;
        font-size: 0.875rem;
        line-height: 1.5;
        margin: 0 0 1rem 0;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    .card-meta {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        margin-bottom: 1.5rem;
    }

    .meta-item {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        color: #6b7280;
    }

    .meta-icon {
        font-size: 1rem;
    }

    .card-pricing {
        margin-bottom: 1rem;
    }

    .price-group {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        flex-wrap: wrap;
    }

    .price-current {
        font-size: 1.5rem;
        font-weight: 700;
        color: #059669;
    }

    .price-original {
        font-size: 1rem;
        text-decoration: line-through;
        color: #9ca3af;
    }

    .price-discount {
        background: #dc2626;
        color: white;
        padding: 0.25rem 0.75rem;
        border-radius: 50px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    .card-footer {
        padding-top: 1rem;
        border-top: 1px solid #f3f4f6;
    }

    .created-date {
        font-size: 0.875rem;
        color: #9ca3af;
    }

    /* Vista de Lista */
    .paquetes-list {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .list-item {
        background: white;
        border-radius: var(--radio);
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1.5rem;
        box-shadow: var(--sombra-tarjeta);
        transition: var(--transicion);
    }

    .list-item:hover {
        box-shadow: var(--sombra-elevada);
    }

    .item-image {
        width: 80px;
        height: 80px;
        border-radius: var(--radio);
        overflow: hidden;
        flex-shrink: 0;
    }

    .item-image img {
        width: 100%;
        height: 100%;
        object-fit: cover;
    }

    .item-placeholder {
        width: 100%;
        height: 100%;
        background: var(--gradiente-primario);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 2rem;
        color: white;
    }

    .item-content {
        flex: 1;
    }

    .item-header {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        margin-bottom: 0.75rem;
    }

    .item-title {
        font-size: 1.25rem;
        font-weight: 600;
        color: #1f2937;
        margin: 0;
    }

    .item-badges {
        display: flex;
        gap: 0.5rem;
    }

    .item-meta {
        display: flex;
        gap: 1.5rem;
        flex-wrap: wrap;
    }

    .item-meta .meta-item {
        font-size: 0.875rem;
        color: #6b7280;
    }

    .item-pricing {
        margin-right: 1.5rem;
    }

    .item-actions {
        display: flex;
        gap: 0.5rem;
    }

    /* Responsive */
    @media (max-width: 1024px) {
        .hero-content { flex-direction: column; text-align: center; }
        .filters-row { flex-direction: column; align-items: stretch; }
        .search-container { min-width: auto; }
        .filters-group { flex-wrap: wrap; }
    }

    @media (max-width: 768px) {
        .hero-section { padding: 3rem 1rem; }
        .hero-title { font-size: 2.5rem; }
        .stats-hero { flex-wrap: wrap; gap: 1rem; }
        .stat-divider { display: none; }
        .paquetes-grid { grid-template-columns: 1fr; }
        .list-item { flex-direction: column; align-items: stretch; text-align: center; }
        .item-header { flex-direction: column; align-items: center; gap: 0.75rem; }
        .content-section { padding: 2rem 1rem; }
        .filters-container { padding: 1rem; }
    }

    @media (max-width: 480px) {
        .hero-title { font-size: 2rem; }
        .hero-title .icon { font-size: 2.5rem; }
        .btn-primary-hero { padding: 0.875rem 1.5rem; font-size: 1rem; }
    }
</style> 