<script lang="ts">
  import { onMount } from 'svelte';
  import { editorStore, resetearEditor, editorActions } from './stores/editorStore.js';
  import { EditorService } from './services/EditorService.js';
  import type { TipoContenido, PasoEditor } from './types/tiposEditor.js';
  
  import SelectorTipoContenido from './components/SelectorTipoContenido.svelte';
  import NavegadorPasos from './components/NavegadorPasos.svelte';
  import AlertaMensaje from './components/AlertaMensaje.svelte';
  
  // Componentes específicos para canciones
  import PasoSubirAudio from './components/cancion/PasoSubirAudio.svelte';
  import PasoGrabarNotas from './components/cancion/PasoGrabarNotas.svelte';
  import PasoVistaPrevia from './components/cancion/PasoVistaPrevia.svelte';
  import PasoPublicar from './components/cancion/PasoPublicar.svelte';

  // Variables reactivas
  let cargando = false;
  let error = '';
  let editorService: EditorService;
  let contenedorPrincipal: HTMLDivElement;

  // Suscripción al store
  $: estado = $editorStore;
  $: tipoContenido = estado.tipoContenido;
  $: pasoActual = estado.pasoActual;
  $: progreso = estado.progreso;

  // Inicialización
  onMount(() => {
    editorService = new EditorService();
    resetearEditor();
  });

  // Manejadores de eventos
  const manejarCambioTipo = async (event: CustomEvent<TipoContenido>) => {
    try {
      cargando = true;
      error = '';
      
      await editorService.cambiarTipoContenido(event.detail);
      
    } catch (err) {
      error = err instanceof Error ? err.message : 'Error al cambiar tipo de contenido';
    } finally {
      cargando = false;
    }
  };

  const manejarCambioPaso = async (event: CustomEvent<PasoEditor>) => {
    try {
      cargando = true;
      error = '';
      
      await editorService.navegarPaso(event.detail);
      
    } catch (err) {
      error = err instanceof Error ? err.message : 'Error al navegar al paso';
    } finally {
      cargando = false;
    }
  };

  const manejarGuardar = async () => {
    try {
      cargando = true;
      error = '';
      
      await editorService.guardarContenido();
      
    } catch (err) {
      error = err instanceof Error ? err.message : 'Error al guardar contenido';
    } finally {
      cargando = false;
    }
  };

  const manejarPublicar = async () => {
    try {
      cargando = true;
      error = '';
      
      await editorService.publicarContenido();
      
    } catch (err) {
      error = err instanceof Error ? err.message : 'Error al publicar contenido';
    } finally {
      cargando = false;
    }
  };

  const manejarReset = () => {
    resetearEditor();
    error = '';
  };

  const cerrarError = () => {
    error = '';
  };
</script>

<div bind:this={contenedorPrincipal} class="editor-interactivo">
  <!-- Header -->
  <header class="editor-header">
    <div class="titulo-seccion">
      <h1>🎮 Editor Interactivo</h1>
      <p>Crea contenido musical interactivo con gamificación</p>
    </div>
    
    <div class="controles-header">
      <button 
        class="btn-reset" 
        on:click={manejarReset}
        disabled={cargando}
      >
        🔄 Reset
      </button>
      
      <div class="progreso-header">
        <span>Progreso: {progreso}%</span>
        <div class="barra-progreso">
          <div 
            class="progreso-fill" 
            style="width: {progreso}%"
          ></div>
        </div>
      </div>
    </div>
  </header>

  <!-- Alerta de error -->
  {#if error}
    <AlertaMensaje 
      tipo="error" 
      mensaje={error} 
      on:cerrar={cerrarError}
    />
  {/if}

  <!-- Contenido principal -->
  <main class="editor-contenido">
    {#if cargando}
      <div class="cargando">
        <div class="spinner"></div>
        <p>Procesando...</p>
      </div>
    {:else}
      <!-- Selector de tipo de contenido -->
      <section class="seccion-selector">
        <SelectorTipoContenido 
          tipoSeleccionado={tipoContenido}
          on:cambioTipo={manejarCambioTipo}
        />
      </section>

      <!-- Navegador de pasos -->
      {#if tipoContenido}
        <section class="seccion-navegador">
          <NavegadorPasos 
            tipoContenido={tipoContenido}
            pasoActual={pasoActual}
            on:cambioPaso={manejarCambioPaso}
          />
        </section>

        <!-- Área de trabajo -->
        <section class="area-trabajo">
          <div class="contenedor-paso">
            {#if tipoContenido === 'cancion'}
              {#if pasoActual === 1}
                                 <PasoSubirAudio 
                   contenido={estado.contenidoActual}
                   on:avanzar={(e: CustomEvent) => {
                     editorActions.actualizarContenido(e.detail);
                     manejarCambioPaso(new CustomEvent('cambioPaso', { detail: 2 }));
                   }}
                   on:actualizar={(e: CustomEvent) => {
                     editorActions.actualizarContenido(e.detail);
                   }}
                 />
              {:else if pasoActual === 2}
                                 <PasoGrabarNotas 
                   contenido={estado.contenidoActual}
                   on:avanzar={(e: CustomEvent) => {
                     editorActions.actualizarContenido(e.detail);
                     manejarCambioPaso(new CustomEvent('cambioPaso', { detail: 3 }));
                   }}
                   on:actualizar={(e: CustomEvent) => {
                     editorActions.actualizarContenido(e.detail);
                   }}
                   on:regresar={() => {
                     manejarCambioPaso(new CustomEvent('cambioPaso', { detail: 1 }));
                   }}
                 />
              {:else if pasoActual === 3}
                                 <PasoVistaPrevia 
                   contenido={estado.contenidoActual}
                   on:avanzar={(e: CustomEvent) => {
                     editorActions.actualizarContenido(e.detail);
                     manejarCambioPaso(new CustomEvent('cambioPaso', { detail: 4 }));
                   }}
                   on:actualizar={(e: CustomEvent) => {
                     editorActions.actualizarContenido(e.detail);
                   }}
                   on:regresar={() => {
                     manejarCambioPaso(new CustomEvent('cambioPaso', { detail: 2 }));
                   }}
                 />
              {:else if pasoActual === 4}
                                 <PasoPublicar 
                   contenido={estado.contenidoActual}
                   on:finalizar={(e: CustomEvent) => {
                     console.log('Canción publicada exitosamente:', e.detail);
                     // Aquí se podría redirigir o mostrar mensaje de éxito
                   }}
                   on:regresar={() => {
                     manejarCambioPaso(new CustomEvent('cambioPaso', { detail: 3 }));
                   }}
                 />
              {/if}
            {:else}
              <!-- Placeholder para otros tipos de contenido -->
              <div class="placeholder-contenido">
                <p>🚧 Contenido del paso {pasoActual} para {tipoContenido}</p>
                <p>Aquí se renderizarían los componentes específicos según el tipo y paso</p>
              </div>
            {/if}
          </div>
        </section>

        <!-- Controles de acción -->
        <section class="controles-accion">
          <div class="botones-navegacion">
            <button 
              class="btn-secundario"
              disabled={pasoActual === 1 || cargando}
              on:click={() => manejarCambioPaso(new CustomEvent('cambioPaso', { detail: (pasoActual - 1) as PasoEditor }))}
            >
              ← Anterior
            </button>
            
            <button 
              class="btn-principal"
              disabled={cargando}
              on:click={manejarGuardar}
            >
              💾 Guardar
            </button>
            
            <button 
              class="btn-secundario"
              disabled={pasoActual === (estado.configuracion?.pasos?.length || 4) || cargando}
              on:click={() => manejarCambioPaso(new CustomEvent('cambioPaso', { detail: (pasoActual + 1) as PasoEditor }))}
            >
              Siguiente →
            </button>
          </div>
          
          {#if pasoActual === (estado.configuracion?.pasos?.length || 4)}
            <button 
              class="btn-publicar"
              disabled={cargando || progreso < 100}
              on:click={manejarPublicar}
            >
              🚀 Publicar
            </button>
          {/if}
        </section>
      {/if}
    {/if}
  </main>
</div>

<style>
  .editor-interactivo {
    min-height: 100vh;
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
    color: white;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    padding-top: 80px;
  }

  .editor-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
    padding: 1rem;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 15px;
    backdrop-filter: blur(10px);
  }

  .titulo-seccion h1 {
    font-size: 2.5rem;
    margin: 0;
    background: linear-gradient(45deg, #ff6b6b, #4ecdc4);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .titulo-seccion p {
    margin: 0.5rem 0 0 0;
    color: #b8b8d4;
    font-size: 1.1rem;
  }

  .controles-header {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .btn-reset {
    padding: 0.5rem 1rem;
    background: linear-gradient(45deg, #ff6b6b, #ff8e8e);
    border: none;
    border-radius: 25px;
    color: white;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .btn-reset:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(255, 107, 107, 0.4);
  }

  .btn-reset:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .progreso-header {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 0.5rem;
  }

  .barra-progreso {
    width: 150px;
    height: 8px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 10px;
    overflow: hidden;
  }

  .progreso-fill {
    height: 100%;
    background: linear-gradient(90deg, #4ecdc4, #44a08d);
    transition: width 0.3s ease;
  }

  .editor-contenido {
    max-width: 1200px;
    margin: 0 auto;
  }

  .cargando {
    text-align: center;
    padding: 3rem;
  }

  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid rgba(255, 255, 255, 0.3);
    border-top: 4px solid #4ecdc4;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 1rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .seccion-selector,
  .seccion-navegador,
  .area-trabajo,
  .controles-accion {
    margin-bottom: 2rem;
  }

  .area-trabajo {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 20px;
    padding: 2rem;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .contenedor-paso h3 {
    font-size: 1.5rem;
    margin-bottom: 1rem;
    color: #4ecdc4;
  }

  .placeholder-contenido {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 2rem;
    text-align: center;
    border: 2px dashed rgba(255, 255, 255, 0.3);
  }

  .controles-accion {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 15px;
  }

  .botones-navegacion {
    display: flex;
    gap: 1rem;
  }

  .btn-principal,
  .btn-secundario,
  .btn-publicar {
    padding: 0.8rem 1.5rem;
    border: none;
    border-radius: 25px;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    font-size: 1rem;
  }

  .btn-principal {
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
  }

  .btn-secundario {
    background: linear-gradient(45deg, #667eea, #764ba2);
    color: white;
  }

  .btn-publicar {
    background: linear-gradient(45deg, #ff6b6b, #ff8e8e);
    color: white;
    font-size: 1.1rem;
    padding: 1rem 2rem;
  }

  .btn-principal:hover:not(:disabled),
  .btn-secundario:hover:not(:disabled),
  .btn-publicar:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }

  .btn-principal:disabled,
  .btn-secundario:disabled,
  .btn-publicar:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .editor-header {
      flex-direction: column;
      gap: 1rem;
    }

    .controles-header {
      flex-direction: column;
      width: 100%;
    }

    .titulo-seccion h1 {
      font-size: 2rem;
    }

    .controles-accion {
      flex-direction: column;
      gap: 1rem;
    }

    .botones-navegacion {
      width: 100%;
      justify-content: center;
    }
  }
</style> 