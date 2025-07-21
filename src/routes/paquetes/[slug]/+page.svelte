<script lang="ts">
    import { onMount } from 'svelte';
    import { page } from '$app/stores';
    import { obtenerPaquetePorSlug, obtenerTutorialesPaquete, formatearPrecio } from '$lib/services/paquetesService';
    import { goto } from '$app/navigation';

    $: slug = $page.params.slug;

    let paquete: any = null;
    let tutoriales: any[] = [];
    let cargando = true;
    let error = '';

    onMount(async () => {
        await cargarPaquete();
    });

    async function cargarPaquete() {
        try {
            console.log('🔍 Buscando paquete con slug:', slug);
            let resultado = await obtenerPaquetePorSlug(slug);
            console.log('📦 Resultado obtenerPaquetePorSlug:', resultado);
            
            if (resultado.success) {
                paquete = resultado.data;
                
                const resultadoTutoriales = await obtenerTutorialesPaquete(paquete.id);
                if (resultadoTutoriales.success) {
                    tutoriales = resultadoTutoriales.data.map((item: any) => ({
                        ...item.tutoriales,  // Cambié de tutorial a tutoriales
                        orden: item.orden
                    })).sort((a: any, b: any) => a.orden - b.orden);
                }
            } else {
                console.error('❌ Error obteniendo paquete:', resultado.error);
                error = 'Paquete no encontrado';
            }
        } catch (err: any) {
            console.error('❌ Error cargando paquete:', err);
            error = 'Error cargando el paquete';
        } finally {
            cargando = false;
        }
    }

    function calcularDescuento() {
        if (paquete?.precio_normal && paquete?.precio_rebajado) {
            return Math.round(((paquete.precio_normal - paquete.precio_rebajado) / paquete.precio_normal) * 100);
        }
        return 0;
    }

    function calcularAhorroTotal() {
        const totalIndividual = tutoriales.reduce((sum, t) => sum + (t.precio_normal || 0), 0);
        const precioFinal = paquete?.precio_rebajado || paquete?.precio_normal || 0;
        return totalIndividual - precioFinal;
    }

    function comprarPaquete() {
        goto(`/pago-confirmacion?tipo=paquete&id=${paquete.id}`);
    }


</script>

<svelte:head>
    <title>{paquete?.titulo || 'Paquete'} - Academia Vallenata Online</title>
    <meta name="description" content={paquete?.descripcion || 'Aprende vallenato con nuestros paquetes'} />
</svelte:head>

{#if cargando}
    <div class="loading">
        <div class="spinner"></div>
        <p>Cargando paquete...</p>
    </div>
{:else if error}
    <div class="error-page">
        <h1>❌ {error}</h1>
        <p>El paquete que buscas no está disponible.</p>
        <div class="error-actions">
            <button class="btn" on:click={() => goto('/')}>Ir al inicio</button>
        </div>
        <p style="margin-top: 1rem; font-size: 0.9rem; color: #666;">
            URL actual: <code>{slug}</code>
        </p>
    </div>
{:else if paquete}
    <div class="container">
        <!-- Hero -->
        <header class="hero">
            <div class="hero-content">
                <div class="hero-text">
                    {#if paquete.destacado}
                        <span class="badge">⭐ Destacado</span>
                    {/if}
                    <h1>{paquete.titulo}</h1>
                    <p>{paquete.descripcion}</p>
                    
                    <div class="stats">
                        <div class="stat">
                            <strong>{tutoriales.length}</strong>
                            <span>Tutoriales</span>
                        </div>
                        <div class="stat">
                            <strong>{paquete.nivel}</strong>
                            <span>Nivel</span>
                        </div>
                        {#if paquete.categoria}
                            <div class="stat">
                                <strong>{paquete.categoria}</strong>
                                <span>Categoría</span>
                            </div>
                        {/if}
                    </div>
                </div>
                
                <div class="hero-image">
                    {#if paquete.imagen_url}
                        <img src={paquete.imagen_url} alt={paquete.titulo} />
                    {:else}
                        <div class="placeholder">🎵</div>
                    {/if}
                </div>
            </div>
        </header>

        <div class="main-grid">
            <!-- Contenido -->
            <main class="content">
                <section class="tutorials">
                    <h2>📚 Tutoriales Incluidos</h2>
                    
                    {#if tutoriales.length > 0}
                        <div class="tutorial-list">
                            {#each tutoriales as tutorial, index}
                                <div class="tutorial-card">
                                    <div class="tutorial-number">{index + 1}</div>
                                    <div class="tutorial-info">
                                        <h3>{tutorial.titulo}</h3>
                                        <p>{tutorial.descripcion || 'Tutorial de acordeón'}</p>
                                        <span class="price">Individual: {formatearPrecio(tutorial.precio_normal || 0)}</span>
                                    </div>
                                </div>
                            {/each}
                        </div>
                    {:else}
                        <p>No hay tutoriales disponibles.</p>
                    {/if}
                </section>
            </main>

            <!-- Sidebar de compra -->
            <aside class="sidebar">
                <div class="price-card">
                    <div class="prices">
                        {#if paquete.precio_rebajado && paquete.precio_rebajado < paquete.precio_normal}
                            <div class="price-current">{formatearPrecio(paquete.precio_rebajado)}</div>
                            <div class="price-original">{formatearPrecio(paquete.precio_normal)}</div>
                            <div class="discount">{calcularDescuento()}% OFF</div>
                        {:else}
                            <div class="price-current">{formatearPrecio(paquete.precio_normal)}</div>
                        {/if}
                    </div>

                    {#if tutoriales.length > 0}
                        <div class="savings">
                            <div class="savings-row">
                                <span>Total individual:</span>
                                <span>{formatearPrecio(tutoriales.reduce((sum, t) => sum + (t.precio_normal || 0), 0))}</span>
                            </div>
                            <div class="savings-row total">
                                <span>Tu ahorro:</span>
                                <span class="amount">💰 {formatearPrecio(calcularAhorroTotal())}</span>
                            </div>
                        </div>
                    {/if}

                    <button class="btn-purchase" on:click={comprarPaquete}>
                        🛒 Comprar Paquete
                    </button>

                    <div class="features">
                        <div class="feature">✅ Acceso inmediato</div>
                        <div class="feature">✅ Sin límite de tiempo</div>
                        <div class="feature">✅ Soporte incluido</div>
                    </div>
                </div>

                <div class="info-card">
                    <h3>📊 Información</h3>
                    <div class="info-list">
                        <div class="info-row">
                            <span>Tutoriales:</span>
                            <span>{tutoriales.length}</span>
                        </div>
                        <div class="info-row">
                            <span>Nivel:</span>
                            <span>{paquete.nivel}</span>
                        </div>
                        {#if paquete.categoria}
                            <div class="info-row">
                                <span>Categoría:</span>
                                <span>{paquete.categoria}</span>
                            </div>
                        {/if}
                    </div>
                </div>
            </aside>
        </div>
    </div>
{/if}

<style>
    .loading {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 400px;
        gap: 1rem;
    }

    .spinner {
        width: 40px;
        height: 40px;
        border: 4px solid #f3f3f3;
        border-top: 4px solid #007bff;
        border-radius: 50%;
        animation: spin 1s linear infinite;
    }

    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }

    .error-page {
        text-align: center;
        padding: 3rem;
        max-width: 500px;
        margin: 0 auto;
    }

    .error-page h1 {
        color: #dc3545;
        margin-bottom: 1rem;
    }

    .error-actions {
        display: flex;
        gap: 1rem;
        justify-content: center;
        flex-wrap: wrap;
    }

    .btn-secondary {
        background: #6c757d;
        color: white;
    }

    .btn-secondary:hover {
        background: #5a6268;
    }

    code {
        background: #f8f9fa;
        padding: 0.2rem 0.4rem;
        border-radius: 3px;
        font-family: 'Courier New', monospace;
        font-size: 0.85rem;
    }

    .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 2rem;
    }

    /* Hero */
    .hero {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border-radius: 12px;
        padding: 2rem;
        margin-bottom: 2rem;
    }

    .hero-content {
        display: grid;
        grid-template-columns: 2fr 1fr;
        gap: 2rem;
        align-items: center;
    }

    .badge {
        display: inline-block;
        background: rgba(255, 255, 255, 0.2);
        padding: 0.5rem 1rem;
        border-radius: 20px;
        font-size: 0.875rem;
        margin-bottom: 1rem;
    }

    .hero h1 {
        font-size: 2rem;
        margin: 0 0 1rem 0;
        font-weight: 700;
    }

    .hero p {
        font-size: 1.125rem;
        margin-bottom: 1.5rem;
        opacity: 0.9;
        line-height: 1.5;
    }

    .stats {
        display: flex;
        gap: 1.5rem;
    }

    .stat {
        text-align: center;
    }

    .stat strong {
        display: block;
        font-size: 1.25rem;
        font-weight: 700;
    }

    .stat span {
        font-size: 0.75rem;
        opacity: 0.8;
        text-transform: uppercase;
    }

    .hero-image {
        text-align: center;
    }

    .hero-image img {
        width: 100%;
        max-width: 250px;
        border-radius: 12px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
    }

    .placeholder {
        width: 200px;
        height: 200px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 3rem;
        margin: 0 auto;
    }

    /* Main Grid */
    .main-grid {
        display: grid;
        grid-template-columns: 2fr 1fr;
        gap: 2rem;
    }

    /* Content */
    .tutorials h2 {
        font-size: 1.5rem;
        margin-bottom: 1.5rem;
        color: #333;
    }

    .tutorial-list {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .tutorial-card {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1rem;
        background: white;
        border: 1px solid #e9ecef;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .tutorial-number {
        background: #007bff;
        color: white;
        width: 30px;
        height: 30px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        flex-shrink: 0;
        font-size: 0.9rem;
    }

    .tutorial-info {
        flex: 1;
    }

    .tutorial-info h3 {
        margin: 0 0 0.5rem 0;
        color: #333;
        font-size: 1rem;
    }

    .tutorial-info p {
        margin: 0 0 0.5rem 0;
        color: #666;
        font-size: 0.875rem;
    }

    .tutorial-info .price {
        font-size: 0.75rem;
        color: #28a745;
        font-weight: 500;
    }

    /* Sidebar */
    .sidebar {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .price-card,
    .info-card {
        background: white;
        border: 1px solid #e9ecef;
        border-radius: 8px;
        padding: 1.5rem;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .prices {
        text-align: center;
        margin-bottom: 1rem;
    }

    .price-current {
        font-size: 2rem;
        font-weight: 700;
        color: #007bff;
        margin-bottom: 0.5rem;
    }

    .price-original {
        font-size: 1rem;
        text-decoration: line-through;
        color: #6c757d;
        margin-bottom: 0.5rem;
    }

    .discount {
        display: inline-block;
        background: #28a745;
        color: white;
        padding: 0.25rem 0.5rem;
        border-radius: 12px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    .savings {
        background: #f8f9fa;
        padding: 1rem;
        border-radius: 6px;
        margin-bottom: 1rem;
    }

    .savings-row {
        display: flex;
        justify-content: space-between;
        margin-bottom: 0.5rem;
        font-size: 0.875rem;
        color: #666;
    }

    .savings-row.total {
        border-top: 1px solid #dee2e6;
        padding-top: 0.5rem;
        margin-top: 0.5rem;
        font-weight: 600;
        color: #333;
    }

    .amount {
        color: #28a745 !important;
        font-weight: 700;
    }

    .btn-purchase {
        width: 100%;
        background: #28a745;
        color: white;
        border: none;
        padding: 1rem;
        font-size: 1rem;
        font-weight: 600;
        border-radius: 6px;
        cursor: pointer;
        margin-bottom: 1rem;
    }

    .btn-purchase:hover {
        background: #218838;
    }

    .features {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    .feature {
        font-size: 0.875rem;
        color: #28a745;
    }

    .info-card h3 {
        margin: 0 0 1rem 0;
        color: #333;
        font-size: 1rem;
    }

    .info-list {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    .info-row {
        display: flex;
        justify-content: space-between;
        font-size: 0.875rem;
    }

    .info-row span:first-child {
        color: #666;
    }

    .info-row span:last-child {
        font-weight: 500;
        color: #333;
        text-transform: capitalize;
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

    /* Responsive */
    @media (max-width: 768px) {
        .container {
            padding: 1rem;
        }

        .hero {
            padding: 1.5rem;
        }

        .hero-content {
            grid-template-columns: 1fr;
            text-align: center;
        }

        .hero h1 {
            font-size: 1.5rem;
        }

        .stats {
            justify-content: center;
        }

        .main-grid {
            grid-template-columns: 1fr;
        }

        .tutorial-card {
            flex-direction: column;
            text-align: center;
            gap: 0.75rem;
        }

        .price-current {
            font-size: 1.75rem;
        }
    }
</style> 