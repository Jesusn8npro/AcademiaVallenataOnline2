<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import { 
        crearPaquete,
        agregarTutorialAPaquete,
        validarPaquete,
        formatearPrecio,
        type PaqueteTutorial
    } from '$lib/services/paquetesService';
    import { supabase } from '$lib/supabase/clienteSupabase';
    import SubidorImagenes from '$lib/components/SubidorImagenes.svelte';

    let paquete: Partial<PaqueteTutorial> = {
        titulo: '',
        descripcion: '',
        precio_normal: 0,
        precio_rebajado: 0,
        estado: 'borrador',
        categoria: '',
        nivel: 'principiante',
        destacado: false,
        visible: true
    };

    let tutorialesDisponibles: any[] = [];
    let tutorialesSeleccionados: any[] = [];
    let mostrarModal = false;
    let guardando = false;
    let error = '';
    let exito = '';
    let busquedaTutorial = '';
    let subiendoImagen = false;

    onMount(async () => {
        await cargarTutoriales();
    });

    async function cargarTutoriales() {
        try {
            const { data: tutoriales } = await supabase
                .from('tutoriales')
                .select('*')
                .eq('estado', 'publicado')
                .order('titulo');
            tutorialesDisponibles = tutoriales || [];
        } catch (err) {
            console.error('Error cargando tutoriales:', err);
        }
    }

    async function guardar() {
        if (!paquete.titulo || !paquete.precio_normal) {
            error = 'Título y precio son obligatorios';
            return;
        }

        if (tutorialesSeleccionados.length === 0) {
            error = 'Debe incluir al menos un tutorial';
            return;
        }

        try {
            guardando = true;
            error = '';

            // Crear el paquete
            const paqueteCompleto: PaqueteTutorial = {
                titulo: paquete.titulo || '',
                descripcion: paquete.descripcion || '',
                precio_normal: paquete.precio_normal || 0,
                precio_rebajado: paquete.precio_rebajado || 0,
                estado: paquete.estado || 'borrador',
                categoria: paquete.categoria || '',
                nivel: paquete.nivel || 'principiante',
                destacado: paquete.destacado || false,
                tipo_acceso: 'premium',
                visible: paquete.visible !== undefined ? paquete.visible : true,
                imagen_url: paquete.imagen_url || ''
            };
            
            const resultado = await crearPaquete(paqueteCompleto);
            
            if (resultado.success && resultado.data) {
                const paqueteId = resultado.data.id;
                
                // Agregar tutoriales al paquete
                for (let i = 0; i < tutorialesSeleccionados.length; i++) {
                    const tutorial = tutorialesSeleccionados[i];
                    await agregarTutorialAPaquete({
                        paquete_id: paqueteId,
                        tutorial_id: tutorial.id,
                        orden: i + 1,
                        incluido: true,
                        precio_individual_referencia: tutorial.precio_normal || 0
                    });
                }
                
                exito = 'Paquete creado exitosamente';
                setTimeout(() => goto('/administrador/paquetes'), 1500);
            } else {
                error = resultado.error || 'Error creando paquete';
            }
        } catch (err: any) {
            error = 'Error: ' + err.message;
        } finally {
            guardando = false;
        }
    }

    function agregarTutorial(tutorial: any) {
        if (!tutorialesSeleccionados.find(t => t.id === tutorial.id)) {
            tutorialesSeleccionados = [...tutorialesSeleccionados, tutorial];
            calcularPreciosSugeridos();
        }
        mostrarModal = false;
    }

    function removerTutorial(tutorialId: string) {
        tutorialesSeleccionados = tutorialesSeleccionados.filter(t => t.id !== tutorialId);
        calcularPreciosSugeridos();
    }

    function calcularPreciosSugeridos() {
        if (tutorialesSeleccionados.length > 0) {
            const total = tutorialesSeleccionados.reduce((sum, t) => sum + (t.precio_normal || 0), 0);
            
            // Sugerir con 30% descuento
            if (!paquete.precio_normal || paquete.precio_normal === 0) {
                paquete.precio_normal = Math.round(total * 0.7);
            }
            
            // Sugerir precio rebajado con 40% descuento
            if (!paquete.precio_rebajado || paquete.precio_rebajado === 0) {
                paquete.precio_rebajado = Math.round(total * 0.6);
            }
        }
    }

    function calcularAhorro() {
        const totalIndividual = tutorialesSeleccionados.reduce((sum, t) => sum + (t.precio_normal || 0), 0);
        return totalIndividual - (paquete.precio_normal || 0);
    }

    function calcularDescuento() {
        if (paquete.precio_normal && paquete.precio_rebajado) {
            return Math.round(((paquete.precio_normal - paquete.precio_rebajado) / paquete.precio_normal) * 100);
        }
        return 0;
    }

    // Función para filtrar tutoriales por búsqueda
    function tutorialesFiltrados() {
        if (!busquedaTutorial.trim()) {
            return tutorialesDisponibles;
        }
        
        const termino = busquedaTutorial.toLowerCase().trim();
        return tutorialesDisponibles.filter(tutorial => 
            tutorial.titulo.toLowerCase().includes(termino) ||
            (tutorial.categoria && tutorial.categoria.toLowerCase().includes(termino)) ||
            (tutorial.descripcion && tutorial.descripcion.toLowerCase().includes(termino))
        );
    }

    // Limpiar búsqueda al abrir modal
    function abrirModal() {
        busquedaTutorial = '';
        mostrarModal = true;
    }

    // Funciones para manejo de imágenes
    function manejarImagenSubida(event: CustomEvent) {
        const { url } = event.detail;
        paquete.imagen_url = url;
        error = ''; // Limpiar errores
    }

    function manejarErrorImagen(event: CustomEvent) {
        const { message } = event.detail;
        error = `Error con la imagen: ${message}`;
    }
</script>

<div class="container">
    <header class="header">
        <button class="btn-back" on:click={() => goto('/administrador/paquetes')}>
            ← Volver
        </button>
        <h1>Crear Nuevo Paquete</h1>
    </header>

    {#if error}
        <div class="alert error">❌ {error}</div>
    {/if}

    {#if exito}
        <div class="alert success">✅ {exito}</div>
    {:else}
        <form on:submit|preventDefault={guardar} class="form">
            <!-- Información Básica -->
            <section class="card">
                <h2>📝 Información Básica</h2>
                <div class="fields">
                    <div class="field">
                        <label>Título *</label>
                        <input type="text" bind:value={paquete.titulo} required placeholder="Ej: Binomio de Oro - Completo" />
                    </div>
                    <div class="field">
                        <label>Descripción <span class="char-count">{(paquete.descripcion || '').length}/500</span></label>
                        <textarea 
                            bind:value={paquete.descripcion} 
                            rows="3" 
                            maxlength="500"
                            placeholder="Descripción del paquete (máximo 500 caracteres)..."
                            class:warning={(paquete.descripcion || '').length > 450}
                        ></textarea>
                        {#if (paquete.descripcion || '').length > 450}
                            <small class="text-warning">⚠️ Te quedan {500 - (paquete.descripcion || '').length} caracteres</small>
                        {/if}
                    </div>
                    <div class="field imagen-field">
                        <SubidorImagenes
                            imagenActual={paquete.imagen_url || ''}
                            etiqueta="Imagen del paquete"
                            descripcion="Sube una imagen atractiva para tu paquete"
                            deshabilitado={subiendoImagen}
                            on:imagenSubida={manejarImagenSubida}
                            on:error={manejarErrorImagen}
                        />
                    </div>
                </div>
            </section>

            <!-- Configuración -->
            <section class="card">
                <h2>⚙️ Configuración</h2>
                <div class="fields">
                    <div class="row">
                        <div class="field">
                            <label>Categoría</label>
                            <input type="text" bind:value={paquete.categoria} placeholder="Ej: Binomio de Oro" />
                        </div>
                        <div class="field">
                            <label>Nivel</label>
                            <select bind:value={paquete.nivel}>
                                <option value="principiante">Principiante</option>
                                <option value="intermedio">Intermedio</option>
                                <option value="avanzado">Avanzado</option>
                            </select>
                        </div>
                    </div>
                    <div class="row">
                        <div class="field">
                            <label>Estado</label>
                            <select bind:value={paquete.estado}>
                                <option value="borrador">Borrador</option>
                                <option value="publicado">Publicado</option>
                                <option value="archivado">Archivado</option>
                            </select>
                        </div>
                        <div class="field">
                            <label class="checkbox">
                                <input type="checkbox" bind:checked={paquete.destacado} />
                                Destacado
                            </label>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Tutoriales -->
            <section class="card">
                <div class="section-header">
                    <h2>🎵 Tutoriales ({tutorialesSeleccionados.length})</h2>
                    <button type="button" class="btn btn-secondary" on:click={abrirModal}>
                        + Agregar
                    </button>
                </div>
                
                {#if tutorialesSeleccionados.length === 0}
                    <div class="empty">
                        <p>No hay tutoriales seleccionados</p>
                        <button type="button" class="btn btn-primary" on:click={abrirModal}>
                            Agregar Tutorial
                        </button>
                    </div>
                {:else}
                    <div class="tutorials">
                        {#each tutorialesSeleccionados as tutorial}
                            <div class="tutorial-item">
                                <div class="tutorial-info">
                                    <h4>{tutorial.titulo}</h4>
                                    <span class="price">{formatearPrecio(tutorial.precio_normal || 0)}</span>
                                </div>
                                <button type="button" class="btn-remove" on:click={() => removerTutorial(tutorial.id)}>
                                    ×
                                </button>
                            </div>
                        {/each}
                    </div>
                {/if}
            </section>

            <!-- Precios -->
            <section class="card">
                <h2>💰 Precios</h2>
                <div class="fields">
                    {#if tutorialesSeleccionados.length > 0}
                        <div class="price-info">
                            <p><strong>Total individual:</strong> {formatearPrecio(tutorialesSeleccionados.reduce((sum, t) => sum + (t.precio_normal || 0), 0))}</p>
                            <button type="button" class="btn-suggest" on:click={calcularPreciosSugeridos}>
                                💡 Calcular precios sugeridos
                            </button>
                        </div>
                    {/if}
                    
                    <div class="row">
                        <div class="field">
                            <label>Precio Normal (COP) *</label>
                            <input type="number" bind:value={paquete.precio_normal} step="1000" required />
                        </div>
                        <div class="field">
                            <label>Precio Rebajado (COP)</label>
                            <input type="number" bind:value={paquete.precio_rebajado} step="1000" />
                        </div>
                    </div>
                    
                    {#if paquete.precio_normal && paquete.precio_rebajado && tutorialesSeleccionados.length > 0}
                        <div class="price-preview">
                            <span class="price-current">{formatearPrecio(paquete.precio_rebajado)}</span>
                            <span class="price-original">{formatearPrecio(paquete.precio_normal)}</span>
                            <span class="discount">{calcularDescuento()}% OFF</span>
                            <span class="savings">💾 Ahorro: {formatearPrecio(calcularAhorro())}</span>
                        </div>
                    {/if}
                </div>
            </section>

            <!-- Acciones -->
            <div class="actions">
                <button type="button" class="btn btn-secondary" on:click={() => goto('/administrador/paquetes')}>
                    Cancelar
                </button>
                <button type="submit" class="btn btn-primary" disabled={guardando}>
                    {guardando ? 'Creando...' : '💾 Crear Paquete'}
                </button>
            </div>
        </form>
    {/if}
</div>

<!-- Modal Selector de Tutoriales -->
{#if mostrarModal}
    <div class="modal-overlay" on:click={() => mostrarModal = false}>
        <div class="modal" on:click|stopPropagation>
            <div class="modal-header">
                <h3>Seleccionar Tutoriales</h3>
                <button class="btn-close" on:click={() => mostrarModal = false}>×</button>
            </div>
            <div class="modal-body">
                <!-- Buscador -->
                <div class="search-container">
                    <div class="search-input-wrapper">
                        <input 
                            type="text" 
                            bind:value={busquedaTutorial} 
                            placeholder="🔍 Buscar tutoriales por título, categoría..."
                            class="search-input"
                        />
                        {#if busquedaTutorial}
                            <button class="clear-search" on:click={() => busquedaTutorial = ''}>×</button>
                        {/if}
                    </div>
                    <div class="search-stats">
                        {tutorialesFiltrados().filter(t => !tutorialesSeleccionados.find(s => s.id === t.id)).length} de {tutorialesDisponibles.length} tutoriales
                    </div>
                </div>

                <!-- Grid de tutoriales filtrados -->
                <div class="tutorial-grid">
                    {#each tutorialesFiltrados() as tutorial}
                        {#if !tutorialesSeleccionados.find(s => s.id === tutorial.id)}
                            <div class="tutorial-card">
                                <h4>{tutorial.titulo}</h4>
                                {#if tutorial.categoria}
                                    <span class="tutorial-category">{tutorial.categoria}</span>
                                {/if}
                                <p>{formatearPrecio(tutorial.precio_normal || 0)}</p>
                                <button class="btn btn-sm" on:click={() => agregarTutorial(tutorial)}>
                                    Agregar
                                </button>
                            </div>
                        {/if}
                    {:else}
                        <div class="no-results">
                            <p>😔 No se encontraron tutoriales</p>
                            {#if busquedaTutorial}
                                <p>Intenta con otros términos de búsqueda</p>
                                <button class="btn btn-sm" on:click={() => busquedaTutorial = ''}>
                                    Limpiar búsqueda
                                </button>
                            {/if}
                        </div>
                    {/each}
                </div>
            </div>
        </div>
    </div>
{/if}

<style>
    .container {
        max-width: 1000px;
        margin: 0 auto;
        padding: 2rem;
    }

    .header {
        text-align: center;
        margin-bottom: 2rem;
    }

    .btn-back {
        background: none;
        border: 1px solid #ddd;
        padding: 0.5rem 1rem;
        border-radius: 6px;
        cursor: pointer;
        margin-bottom: 1rem;
    }

    .btn-back:hover {
        background: #f5f5f5;
    }

    .header h1 {
        margin: 0;
        color: #333;
    }

    .alert {
        padding: 1rem;
        border-radius: 6px;
        margin-bottom: 1.5rem;
        text-align: center;
    }

    .alert.error {
        background: #fee;
        color: #c33;
        border: 1px solid #fcc;
    }

    .alert.success {
        background: #efe;
        color: #3c3;
        border: 1px solid #cfc;
    }

    .form {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .card {
        background: white;
        border: 1px solid #ddd;
        border-radius: 8px;
        padding: 1.5rem;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .card h2 {
        margin: 0 0 1rem 0;
        color: #333;
        font-size: 1.25rem;
    }

    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
    }

    .section-header h2 {
        margin: 0;
    }

    .fields {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
    }

    .field {
        display: flex;
        flex-direction: column;
    }

    .field label {
        margin-bottom: 0.5rem;
        font-weight: 500;
        color: #333;
    }

    .field input,
    .field select,
    .field textarea {
        padding: 0.75rem;
        border: 1px solid #ddd;
        border-radius: 6px;
        font-size: 1rem;
    }

    .field input:focus,
    .field select:focus,
    .field textarea:focus {
        outline: none;
        border-color: #007bff;
        box-shadow: 0 0 0 2px rgba(0,123,255,0.25);
    }

    .checkbox {
        flex-direction: row !important;
        align-items: center;
        gap: 0.5rem;
        cursor: pointer;
    }

    .checkbox input {
        width: auto;
        margin: 0;
    }

    .price-info {
        background: #f8f9fa;
        padding: 1rem;
        border-radius: 6px;
        margin-bottom: 1rem;
    }

    .price-info p {
        margin: 0 0 0.5rem 0;
        color: #666;
    }

    .btn-suggest {
        background: #17a2b8;
        color: white;
        border: none;
        padding: 0.5rem 1rem;
        border-radius: 6px;
        cursor: pointer;
        font-size: 0.875rem;
    }

    .btn-suggest:hover {
        background: #138496;
    }

    .price-preview {
        padding: 1rem;
        background: #f8f9fa;
        border-radius: 6px;
        display: flex;
        align-items: center;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .price-current {
        font-size: 1.5rem;
        font-weight: bold;
        color: #007bff;
    }

    .price-original {
        text-decoration: line-through;
        color: #666;
    }

    .discount {
        background: #28a745;
        color: white;
        padding: 0.25rem 0.5rem;
        border-radius: 12px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    .savings {
        color: #28a745;
        font-weight: 500;
    }

    .empty {
        text-align: center;
        padding: 2rem;
        color: #666;
    }

    .tutorials {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }

    .tutorial-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem;
        background: #f8f9fa;
        border-radius: 6px;
        border: 1px solid #e9ecef;
    }

    .tutorial-info h4 {
        margin: 0 0 0.25rem 0;
        color: #333;
    }

    .tutorial-info .price {
        color: #666;
        font-size: 0.9rem;
    }

    .btn-remove {
        background: #dc3545;
        color: white;
        border: none;
        border-radius: 50%;
        width: 30px;
        height: 30px;
        cursor: pointer;
        font-size: 1.2rem;
    }

    .btn-remove:hover {
        background: #c82333;
    }

    .actions {
        display: flex;
        justify-content: center;
        gap: 1rem;
        padding-top: 1rem;
        border-top: 1px solid #ddd;
    }

    .btn {
        padding: 0.75rem 1.5rem;
        border-radius: 6px;
        font-weight: 500;
        cursor: pointer;
        border: none;
        font-size: 1rem;
    }

    .btn-primary {
        background: #007bff;
        color: white;
    }

    .btn-primary:hover:not(:disabled) {
        background: #0056b3;
    }

    .btn-primary:disabled {
        background: #6c757d;
        cursor: not-allowed;
    }

    .btn-secondary {
        background: white;
        color: #333;
        border: 1px solid #ddd;
    }

    .btn-secondary:hover {
        background: #f8f9fa;
    }

    .btn-sm {
        padding: 0.5rem 1rem;
        font-size: 0.875rem;
    }

    /* Modal */
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0,0,0,0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
    }

    .modal {
        background: white;
        border-radius: 8px;
        width: 90%;
        max-width: 600px;
        max-height: 80vh;
        overflow: hidden;
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem 1.5rem;
        border-bottom: 1px solid #ddd;
    }

    .modal-header h3 {
        margin: 0;
    }

    .btn-close {
        background: none;
        border: none;
        font-size: 1.5rem;
        cursor: pointer;
        color: #666;
    }

    .btn-close:hover {
        color: #333;
    }

    .modal-body {
        padding: 1.5rem;
        max-height: 400px;
        overflow-y: auto;
    }

    .tutorial-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
        gap: 1rem;
    }

    .tutorial-card {
        border: 1px solid #ddd;
        border-radius: 6px;
        padding: 1rem;
        text-align: center;
    }

    .tutorial-card h4 {
        margin: 0 0 0.5rem 0;
        font-size: 0.9rem;
    }

    .tutorial-card p {
        margin: 0 0 1rem 0;
        color: #666;
    }

    /* Estilos del buscador */
    .search-container {
        margin-bottom: 1.5rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid #e9ecef;
    }

    .search-input-wrapper {
        position: relative;
        margin-bottom: 0.5rem;
    }

    .search-input {
        width: 100%;
        padding: 0.75rem 1rem;
        padding-right: 2.5rem;
        border: 1px solid #ddd;
        border-radius: 6px;
        font-size: 1rem;
        background: #f8f9fa;
    }

    .search-input:focus {
        outline: none;
        border-color: #007bff;
        box-shadow: 0 0 0 2px rgba(0,123,255,0.25);
        background: white;
    }

    .clear-search {
        position: absolute;
        right: 0.75rem;
        top: 50%;
        transform: translateY(-50%);
        background: none;
        border: none;
        font-size: 1.2rem;
        color: #666;
        cursor: pointer;
        padding: 0;
        width: 20px;
        height: 20px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .clear-search:hover {
        color: #333;
        background: #e9ecef;
        border-radius: 50%;
    }

    .search-stats {
        font-size: 0.875rem;
        color: #666;
        text-align: center;
    }

    .no-results {
        grid-column: 1 / -1;
        text-align: center;
        padding: 2rem;
        color: #666;
    }

    .no-results p {
        margin: 0 0 0.5rem 0;
    }

    .tutorial-category {
        display: inline-block;
        background: #e9ecef;
        color: #495057;
        padding: 0.25rem 0.5rem;
        border-radius: 12px;
        font-size: 0.75rem;
        margin-bottom: 0.5rem;
    }

    /* Estilos para contador de caracteres */
    .char-count {
        float: right;
        font-size: 0.75rem;
        color: #666;
        font-weight: normal;
    }

    .warning {
        border-color: #ffc107 !important;
        background-color: #fff3cd;
    }

    .text-warning {
        color: #856404;
        font-size: 0.75rem;
        margin-top: 0.25rem;
        display: block;
    }

    /* Estilos específicos para el campo de imagen */
    .imagen-field {
        grid-column: 1 / -1; /* Ocupa todo el ancho disponible */
        margin-top: 1rem;
    }

    @media (max-width: 768px) {
        .container {
            padding: 1rem;
        }

        .row {
            grid-template-columns: 1fr;
        }

        .actions {
            flex-direction: column;
        }

        .price-preview {
            flex-direction: column;
            align-items: flex-start;
            gap: 0.5rem;
        }

        .tutorial-grid {
            grid-template-columns: 1fr;
        }
    }
</style> 