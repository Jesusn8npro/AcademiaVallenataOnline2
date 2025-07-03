<script lang="ts">
    import { onMount } from 'svelte';
    import { obtenerPaquetesPublicados, buscarPaquetes, formatearPrecio } from '$lib/services/paquetesService';
    import { goto } from '$app/navigation';

    let paquetes: any[] = [];
    let cargando = true;
    let error = '';
    let busqueda = '';
    let filtroCategoria = '';
    let filtroNivel = '';
    let categorias: string[] = [];

    onMount(async () => {
        await cargarPaquetes();
    });

    async function cargarPaquetes() {
        try {
            cargando = true;
            const resultado = await obtenerPaquetesPublicados();
            
            if (resultado.success) {
                paquetes = resultado.data || [];
                
                // Extraer categorías únicas
                const categoriasUnicas = [...new Set(paquetes
                    .map(p => p.categoria)
                    .filter(c => c && c.trim() !== ''))];
                categorias = categoriasUnicas;
            } else {
                error = 'Error cargando paquetes';
            }
        } catch (err) {
            error = 'Error inesperado';
        } finally {
            cargando = false;
        }
    }

    async function aplicarFiltros() {
        if (!busqueda && !filtroCategoria && !filtroNivel) {
            await cargarPaquetes();
            return;
        }

        try {
            cargando = true;
            const resultado = await buscarPaquetes(busqueda, {
                categoria: filtroCategoria || undefined,
                nivel: filtroNivel || undefined
            });

            if (resultado.success) {
                paquetes = resultado.data || [];
            }
        } catch (err) {
            console.error('Error en búsqueda:', err);
        } finally {
            cargando = false;
        }
    }

    function limpiarFiltros() {
        busqueda = '';
        filtroCategoria = '';
        filtroNivel = '';
        cargarPaquetes();
    }

    function calcularDescuento(precioNormal: number, precioRebajado: number) {
        if (precioNormal && precioRebajado && precioRebajado < precioNormal) {
            return Math.round(((precioNormal - precioRebajado) / precioNormal) * 100);
        }
        return 0;
    }

    function verPaquete(slug: string) {
        goto(`/paquetes/${slug}`);
    }
</script>

<svelte:head>
    <title>Paquetes de Tutoriales - Academia Vallenata Online</title>
    <meta name="description" content="Descubre nuestros paquetes de tutoriales de acordeón. Aprende vallenato de forma estructurada y ahorra comprando en paquete." />
</svelte:head>

<div class="container">
    <!-- Hero -->
    <header class="hero">
        <div class="hero-content">
            <h1>🎁 Paquetes de Tutoriales</h1>
            <p>Aprende vallenato de forma organizada y ahorra comprando nuestros paquetes especiales</p>
        </div>
    </header>

    <!-- Filtros -->
    <section class="filters">
        <div class="search-bar">
            <input 
                type="text" 
                placeholder="Buscar paquetes..." 
                bind:value={busqueda}
                on:input={aplicarFiltros}
            />
        </div>
        
        <div class="filter-controls">
            <select bind:value={filtroCategoria} on:change={aplicarFiltros}>
                <option value="">Todas las categorías</option>
                {#each categorias as categoria}
                    <option value={categoria}>{categoria}</option>
                {/each}
            </select>
            
            <select bind:value={filtroNivel} on:change={aplicarFiltros}>
                <option value="">Todos los niveles</option>
                <option value="principiante">Principiante</option>
                <option value="intermedio">Intermedio</option>
                <option value="avanzado">Avanzado</option>
            </select>
            
            <button class="btn-clear" on:click={limpiarFiltros}>
                Limpiar
            </button>
        </div>
    </section>

    <!-- Contenido -->
    <main class="content">
        {#if cargando}
            <div class="loading">
                <div class="spinner"></div>
                <p>Cargando paquetes...</p>
            </div>
        {:else if error}
            <div class="error">
                <h2>❌ {error}</h2>
                <p>No pudimos cargar los paquetes en este momento.</p>
                <button class="btn" on:click={cargarPaquetes}>Reintentar</button>
            </div>
        {:else if paquetes.length === 0}
            <div class="empty">
                <h2>📦 No hay paquetes disponibles</h2>
                <p>Próximamente tendremos paquetes increíbles para ti.</p>
                <button class="btn" on:click={() => goto('/')}>Ir al inicio</button>
            </div>
        {:else}
            <div class="packages-grid">
                {#each paquetes as paquete}
                    <article class="package-card" on:click={() => verPaquete(paquete.slug)}>
                        <!-- Imagen -->
                        <div class="card-image">
                            {#if paquete.imagen_url}
                                <img src={paquete.imagen_url} alt={paquete.titulo} />
                            {:else}
                                <div class="placeholder">🎵</div>
                            {/if}
                            
                            {#if paquete.destacado}
                                <div class="featured-badge">⭐ Destacado</div>
                            {/if}
                        </div>

                        <!-- Contenido -->
                        <div class="card-content">
                            <div class="card-header">
                                <h3>{paquete.titulo}</h3>
                                {#if paquete.categoria}
                                    <span class="category">{paquete.categoria}</span>
                                {/if}
                            </div>
                            
                            <p class="description">{paquete.descripcion || 'Paquete de tutoriales de acordeón'}</p>
                            
                            <div class="card-meta">
                                <div class="stats">
                                    <span class="stat">
                                        <strong>{paquete.total_tutoriales || 0}</strong>
                                        Tutoriales
                                    </span>
                                    <span class="stat">
                                        <strong>{paquete.nivel}</strong>
                                        Nivel
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- Precio -->
                        <div class="card-footer">
                            <div class="pricing">
                                {#if paquete.precio_rebajado && paquete.precio_rebajado < paquete.precio_normal}
                                    <div class="price-current">{formatearPrecio(paquete.precio_rebajado)}</div>
                                    <div class="price-original">{formatearPrecio(paquete.precio_normal)}</div>
                                    <div class="discount">{calcularDescuento(paquete.precio_normal, paquete.precio_rebajado)}% OFF</div>
                                {:else}
                                    <div class="price-current">{formatearPrecio(paquete.precio_normal)}</div>
                                {/if}
                            </div>
                            
                            <button class="btn-buy">
                                Ver Paquete
                            </button>
                        </div>
                    </article>
                {/each}
            </div>
        {/if}
    </main>
</div>

<style>
    .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 2rem;
    }

    /* Hero */
    .hero {
        text-align: center;
        padding: 3rem 2rem;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border-radius: 12px;
        margin-bottom: 2rem;
    }

    .hero h1 {
        font-size: 2.5rem;
        margin: 0 0 1rem 0;
        font-weight: 700;
    }

    .hero p {
        font-size: 1.125rem;
        opacity: 0.9;
        max-width: 600px;
        margin: 0 auto;
        line-height: 1.5;
    }

    /* Filtros */
    .filters {
        background: white;
        padding: 1.5rem;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        margin-bottom: 2rem;
    }

    .search-bar {
        margin-bottom: 1rem;
    }

    .search-bar input {
        width: 100%;
        padding: 0.75rem;
        border: 1px solid #ddd;
        border-radius: 6px;
        font-size: 1rem;
    }

    .search-bar input:focus {
        outline: none;
        border-color: #007bff;
        box-shadow: 0 0 0 2px rgba(0,123,255,0.25);
    }

    .filter-controls {
        display: flex;
        gap: 1rem;
        align-items: center;
        flex-wrap: wrap;
    }

    .filter-controls select {
        padding: 0.5rem;
        border: 1px solid #ddd;
        border-radius: 6px;
        font-size: 0.9rem;
    }

    .btn-clear {
        background: #6c757d;
        color: white;
        border: none;
        padding: 0.5rem 1rem;
        border-radius: 6px;
        cursor: pointer;
        font-size: 0.9rem;
    }

    .btn-clear:hover {
        background: #545b62;
    }

    /* Loading & States */
    .loading,
    .error,
    .empty {
        text-align: center;
        padding: 3rem;
    }

    .spinner {
        width: 40px;
        height: 40px;
        border: 4px solid #f3f3f3;
        border-top: 4px solid #007bff;
        border-radius: 50%;
        animation: spin 1s linear infinite;
        margin: 0 auto 1rem;
    }

    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }

    .error h2 {
        color: #dc3545;
        margin-bottom: 1rem;
    }

    .empty h2 {
        color: #6c757d;
        margin-bottom: 1rem;
    }

    .btn {
        background: #007bff;
        color: white;
        border: none;
        padding: 0.75rem 1.5rem;
        border-radius: 6px;
        cursor: pointer;
        font-size: 1rem;
    }

    .btn:hover {
        background: #0056b3;
    }

    /* Grid de Paquetes */
    .packages-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
        gap: 1.5rem;
    }

    .package-card {
        background: white;
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        cursor: pointer;
        display: flex;
        flex-direction: column;
    }

    .package-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 16px rgba(0,0,0,0.15);
    }

    /* Imagen */
    .card-image {
        position: relative;
        height: 200px;
        overflow: hidden;
    }

    .card-image img {
        width: 100%;
        height: 100%;
        object-fit: cover;
    }

    .placeholder {
        width: 100%;
        height: 100%;
        background: linear-gradient(135deg, #f8f9fa, #e9ecef);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 3rem;
        color: #6c757d;
    }

    .featured-badge {
        position: absolute;
        top: 12px;
        right: 12px;
        background: rgba(255, 193, 7, 0.9);
        color: #333;
        padding: 0.25rem 0.75rem;
        border-radius: 20px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    /* Contenido */
    .card-content {
        padding: 1.5rem;
        flex: 1;
    }

    .card-header {
        margin-bottom: 1rem;
    }

    .card-header h3 {
        margin: 0 0 0.5rem 0;
        color: #333;
        font-size: 1.25rem;
        font-weight: 600;
        line-height: 1.3;
    }

    .category {
        background: #e9ecef;
        color: #495057;
        padding: 0.25rem 0.5rem;
        border-radius: 12px;
        font-size: 0.75rem;
        font-weight: 500;
        text-transform: uppercase;
    }

    .description {
        margin: 0 0 1rem 0;
        color: #666;
        font-size: 0.9rem;
        line-height: 1.4;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    .card-meta {
        margin-bottom: 1rem;
    }

    .stats {
        display: flex;
        gap: 1rem;
    }

    .stat {
        display: flex;
        flex-direction: column;
        align-items: center;
        text-align: center;
    }

    .stat strong {
        display: block;
        font-size: 1rem;
        font-weight: 600;
        color: #333;
    }

    .stat {
        font-size: 0.75rem;
        color: #666;
        text-transform: uppercase;
    }

    /* Footer */
    .card-footer {
        padding: 1rem 1.5rem;
        border-top: 1px solid #f1f3f4;
        background: #fafbfc;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .pricing {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }

    .price-current {
        font-size: 1.25rem;
        font-weight: 700;
        color: #007bff;
    }

    .price-original {
        font-size: 0.9rem;
        text-decoration: line-through;
        color: #6c757d;
    }

    .discount {
        background: #28a745;
        color: white;
        padding: 0.125rem 0.375rem;
        border-radius: 8px;
        font-size: 0.7rem;
        font-weight: 600;
        align-self: flex-start;
    }

    .btn-buy {
        background: #007bff;
        color: white;
        border: none;
        padding: 0.625rem 1rem;
        border-radius: 6px;
        cursor: pointer;
        font-size: 0.9rem;
        font-weight: 500;
        transition: background 0.2s ease;
    }

    .btn-buy:hover {
        background: #0056b3;
    }

    /* Responsive */
    @media (max-width: 768px) {
        .container {
            padding: 1rem;
        }

        .hero {
            padding: 2rem 1rem;
        }

        .hero h1 {
            font-size: 2rem;
        }

        .packages-grid {
            grid-template-columns: 1fr;
        }

        .filter-controls {
            flex-direction: column;
            align-items: stretch;
        }

        .filter-controls select,
        .btn-clear {
            width: 100%;
        }

        .card-footer {
            flex-direction: column;
            gap: 1rem;
            align-items: stretch;
        }

        .btn-buy {
            width: 100%;
        }
    }
</style> 