<script lang="ts">
    import { page } from '$app/stores';
    import { goto } from '$app/navigation';
    import FormularioPaquete from '$lib/components/FormularioPaquete.svelte';

    $: paqueteId = $page.params.id;

    function manejarGuardado(event: CustomEvent) {
        const { id, esEdicion } = event.detail;
        if (esEdicion) {
            // Redirigir a la lista de paquetes después de actualizar
            setTimeout(() => goto('/administrador/paquetes'), 1500);
        }
    }

    function manejarCancelacion() {
        goto('/administrador/paquetes');
    }
</script>

<div class="contenedor-pagina">
    <div class="barra-navegacion">
        <button class="boton-volver" on:click={() => goto('/administrador/paquetes')}>
            ← Volver
        </button>
    </div>

    <FormularioPaquete
        paqueteId={paqueteId}
        titulo="Editar Paquete"
        on:guardado={manejarGuardado}
        on:cancelar={manejarCancelacion}
    />
</div>

<style>
    .contenedor-pagina {
        min-height: 100vh;
        background: #f8f9fa;
    }

    .barra-navegacion {
        padding: 1rem 2rem;
        background: white;
        border-bottom: 1px solid #e9ecef;
    }

    .boton-volver {
        background: none;
        border: 1px solid #ddd;
        padding: 0.5rem 1rem;
        border-radius: 6px;
        cursor: pointer;
        font-size: 0.875rem;
        color: #666;
        transition: all 0.2s ease;
    }

    .boton-volver:hover {
        background: #f5f5f5;
        border-color: #007bff;
        color: #007bff;
    }

    @media (max-width: 768px) {
        .barra-navegacion {
            padding: 0.75rem 1rem;
        }
    }
</style> 