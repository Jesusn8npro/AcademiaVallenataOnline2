<script lang="ts">
  import WizardContenido from '$lib/components/CrearContenido/WizardContenido.svelte';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { get } from 'svelte/store';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';

  let tipoContenido: 'curso' | 'tutorial' = 'curso';
  let slugContenido: string = '';
  let datosIniciales: any = null;
  let estructuraInicial: any[] = [];
  let cargandoDatos = false;
  let errorCarga = '';
  let modoEdicion = false;

  $: tituloPrincipal = modoEdicion 
    ? `✏️ Editar ${tipoContenido === 'curso' ? 'Curso' : 'Tutorial'}` 
    : `${tipoContenido === 'curso' ? '🎓 Crear Nuevo Curso' : '🎥 Crear Nuevo Tutorial'}`;

  onMount(async () => {
    const parametros = get(page).url.searchParams;
    tipoContenido = (parametros.get('tipo') as 'curso' | 'tutorial') || 'curso';
    slugContenido = parametros.get('editar') || '';
    
    errorCarga = '';
    datosIniciales = null;
    estructuraInicial = [];
    modoEdicion = !!slugContenido;

    if (slugContenido) {
      await cargarDatosParaEdicion();
    }
  });

  async function cargarDatosParaEdicion() {
    cargandoDatos = true;
    
    try {
      let datosContenido, errorConsulta;

      // Lógica unificada para ambos tipos - detectar si es ID o slug
      const esUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(slugContenido);
      const esNumerico = /^\d+$/.test(slugContenido);
      
      if (tipoContenido === 'curso') {
        if (esUUID || esNumerico) {
          // Es un ID válido, buscar directamente
          ({ data: datosContenido, error: errorConsulta } = await supabase
            .from('cursos')
            .select('*')
            .eq('id', slugContenido)
            .single());
        } else {
          // Es un slug, buscar por slug o título
          ({ data: datosContenido, error: errorConsulta } = await supabase
            .from('cursos')
            .select('*')
            .eq('slug', slugContenido)
            .single());
            
          // Si no se encuentra por slug, intentar por título
          if (errorConsulta || !datosContenido) {
            const tituloDesdeSlug = slugContenido.replace(/-/g, ' ');
            ({ data: datosContenido, error: errorConsulta } = await supabase
              .from('cursos')
              .select('*')
              .ilike('titulo', `%${tituloDesdeSlug}%`));
            
            if (Array.isArray(datosContenido) && datosContenido.length > 0) {
              datosContenido = datosContenido[0];
              errorConsulta = null;
            }
          }
        }
      } else {
        // Para tutoriales (lógica existente)
        if (esUUID) {
          // Es un ID válido, buscar directamente
          ({ data: datosContenido, error: errorConsulta } = await supabase
            .from('tutoriales')
            .select('*')
            .eq('id', slugContenido)
            .single());
        } else {
          // Es un slug, convertir a título y buscar (método legacy)
          const tituloDesdeSlug = slugContenido.replace(/-/g, ' ');
          ({ data: datosContenido, error: errorConsulta } = await supabase
            .from('tutoriales')
            .select('*')
            .ilike('titulo', `%${tituloDesdeSlug}%`));
          
          if (Array.isArray(datosContenido) && datosContenido.length > 0) {
            datosContenido = datosContenido[0];
          }
        }
      }

      if (errorConsulta || !datosContenido) {
        console.error('Error o datos no encontrados:', errorConsulta, datosContenido);
        throw new Error(`${tipoContenido === 'curso' ? 'Curso' : 'Tutorial'} no encontrado`);
      }

      console.log('✅ Datos cargados correctamente:', datosContenido);
      console.log('🔑 ID del contenido:', datosContenido.id, 'Tipo:', typeof datosContenido.id);
      datosIniciales = datosContenido;
      await cargarEstructuraContenido(datosContenido.id);

    } catch (error: any) {
      console.error('Error cargando contenido:', error);
      errorCarga = error.message || 'No se pudo cargar el contenido';
    } finally {
      cargandoDatos = false;
    }
  }

  async function cargarEstructuraContenido(idContenido: string | number) {
    try {
      console.log(`🔍 Cargando estructura para ${tipoContenido} con ID:`, idContenido);
      
      if (tipoContenido === 'curso') {
        const { data: modulos, error: errorModulos } = await supabase
          .from('modulos')
          .select('*, lecciones(*)')
          .eq('curso_id', idContenido)
          .order('orden', { ascending: true });

        console.log('📚 Módulos encontrados:', modulos, 'Error:', errorModulos);

        if (!errorModulos && modulos) {
          estructuraInicial = modulos.map((modulo: any) => ({
            ...modulo,
            lecciones: (modulo.lecciones || []).sort((a: any, b: any) => (a.orden || 0) - (b.orden || 0))
          }));
          console.log('✅ Estructura de curso cargada:', estructuraInicial);
        }
      } else {
        const { data: partes, error: errorPartes } = await supabase
          .from('partes_tutorial')
          .select('*')
          .eq('tutorial_id', idContenido)
          .order('orden', { ascending: true });

        console.log('🎥 Partes encontradas:', partes, 'Error:', errorPartes);

        if (!errorPartes && partes) {
          estructuraInicial = partes;
          console.log('✅ Estructura de tutorial cargada:', estructuraInicial);
        }
      }
    } catch (error) {
      console.error('❌ Error cargando estructura:', error);
    }
  }

  function volverAlPanel() {
    goto('/administrador/panel-contenido');
  }

  function reintentar() {
    errorCarga = '';
    if (slugContenido) {
      cargarDatosParaEdicion();
    }
  }
</script>

<div class="pagina-crear-contenido">
  <header class="header-principal">
    <div class="contenedor-header">
      <button class="boton-volver" on:click={volverAlPanel} title="Volver al Panel">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
        </svg>
        <span>Panel</span>
      </button>
      
      <div class="info-header">
        <h1 class="titulo-principal">{tituloPrincipal}</h1>
        <div class="indicador-modo">
          <span class="badge-tipo {tipoContenido}">
            {tipoContenido === 'curso' ? '📚 Curso' : '🎥 Tutorial'}
          </span>
          <span class="badge-modo">
            {modoEdicion ? '✏️ Editando' : '✨ Creando'}
          </span>
        </div>
      </div>
    </div>
  </header>

  <main class="contenido-principal">
    {#if cargandoDatos}
      <div class="estado-carga">
        <div class="contenedor-carga">
          <div class="spinner-futurista">
            <div class="anillo anillo-1"></div>
            <div class="anillo anillo-2"></div>
            <div class="anillo anillo-3"></div>
            <div class="icono-central">
              {tipoContenido === 'curso' ? '📚' : '🎥'}
            </div>
          </div>
          <h2 class="titulo-carga">Cargando {tipoContenido}...</h2>
          <p class="descripcion-carga">Preparando el contenido para edición</p>
        </div>
      </div>

    {:else if errorCarga}
      <div class="estado-error">
        <div class="contenedor-error">
          <div class="icono-error">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <circle cx="12" cy="12" r="10"/>
              <line x1="12" y1="8" x2="12" y2="12"/>
              <line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
          </div>
          <h2 class="titulo-error">¡Ups! Algo salió mal</h2>
          <p class="descripcion-error">{errorCarga}</p>
          <div class="acciones-error">
            <button class="boton-reintentar" on:click={reintentar}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
              </svg>
              Reintentar
            </button>
            <button class="boton-panel" on:click={volverAlPanel}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"/>
              </svg>
              Ir al Panel
            </button>
          </div>
        </div>
      </div>

    {:else}
      <WizardContenido 
        tipo={tipoContenido} 
        datosIniciales={datosIniciales}
        estructuraInicial={estructuraInicial}
      />
    {/if}
  </main>
</div>

<style>
  .pagina-crear-contenido {
    min-height: 100vh;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 25%, #f093fb 100%);
    padding: 2rem 0;
  }

  .header-principal {
    max-width: 1400px;
    margin: 0 auto 2rem;
    padding: 0 2rem;
  }

  .contenedor-header {
    display: flex;
    align-items: center;
    gap: 2rem;
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(20px);
    border-radius: 2rem;
    padding: 1.5rem 2rem;
    border: 1px solid rgba(255, 255, 255, 0.2);
  }

  .boton-volver {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem 1.5rem;
    background: rgba(255, 255, 255, 0.2);
    border: none;
    border-radius: 1rem;
    color: white;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    backdrop-filter: blur(10px);
  }

  .boton-volver:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-2px);
  }

  .boton-volver svg {
    width: 1.25rem;
    height: 1.25rem;
  }

  .info-header {
    flex: 1;
    text-align: center;
  }

  .titulo-principal {
    font-size: 2.5rem;
    font-weight: 900;
    color: white;
    margin: 0 0 1rem 0;
    text-shadow: 0 4px 20px rgba(0,0,0,0.3);
    letter-spacing: -1px;
  }

  .indicador-modo {
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
  }

  .badge-tipo, .badge-modo {
    padding: 0.5rem 1.25rem;
    border-radius: 2rem;
    font-size: 0.875rem;
    font-weight: 600;
    background: rgba(255, 255, 255, 0.2);
    color: white;
    border: 1px solid rgba(255, 255, 255, 0.3);
    backdrop-filter: blur(10px);
  }

  .badge-tipo.curso {
    background: rgba(16, 185, 129, 0.3);
    border-color: rgba(16, 185, 129, 0.5);
  }

  .badge-tipo.tutorial {
    background: rgba(59, 130, 246, 0.3);
    border-color: rgba(59, 130, 246, 0.5);
  }

  .contenido-principal {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 2rem;
  }

  .estado-carga {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 60vh;
  }

  .contenedor-carga {
    text-align: center;
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px);
    border-radius: 2rem;
    padding: 4rem 3rem;
    border: 1px solid rgba(255, 255, 255, 0.2);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  }

  .spinner-futurista {
    position: relative;
    width: 100px;
    height: 100px;
    margin: 0 auto 2rem;
  }

  .anillo {
    position: absolute;
    border-radius: 50%;
    border: 3px solid transparent;
    animation: spin 2s linear infinite;
  }

  .anillo-1 {
    width: 100px;
    height: 100px;
    border-top-color: #667eea;
    animation-duration: 2s;
  }

  .anillo-2 {
    width: 80px;
    height: 80px;
    top: 10px;
    left: 10px;
    border-top-color: #764ba2;
    animation-duration: 1.5s;
    animation-direction: reverse;
  }

  .anillo-3 {
    width: 60px;
    height: 60px;
    top: 20px;
    left: 20px;
    border-top-color: #f093fb;
    animation-duration: 1s;
  }

  .icono-central {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-size: 2rem;
    animation: pulse 2s infinite;
  }

  .titulo-carga {
    font-size: 1.75rem;
    font-weight: 700;
    color: #2d3748;
    margin: 0 0 0.5rem 0;
  }

  .descripcion-carga {
    color: #64748b;
    font-size: 1.1rem;
    margin: 0;
  }

  .estado-error {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 60vh;
  }

  .contenedor-error {
    text-align: center;
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px);
    border-radius: 2rem;
    padding: 4rem 3rem;
    border: 1px solid rgba(255, 255, 255, 0.2);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
    max-width: 500px;
  }

  .icono-error {
    width: 80px;
    height: 80px;
    margin: 0 auto 2rem;
    color: #ef4444;
  }

  .icono-error svg {
    width: 100%;
    height: 100%;
  }

  .titulo-error {
    font-size: 1.75rem;
    font-weight: 700;
    color: #dc2626;
    margin: 0 0 1rem 0;
  }

  .descripcion-error {
    color: #6b7280;
    font-size: 1.1rem;
    margin: 0 0 2rem 0;
    line-height: 1.6;
  }

  .acciones-error {
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
  }

  .boton-reintentar, .boton-panel {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 1rem 2rem;
    border: none;
    border-radius: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    font-size: 1rem;
  }

  .boton-reintentar {
    background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
    color: white;
    box-shadow: 0 8px 25px rgba(59, 130, 246, 0.3);
  }

  .boton-reintentar:hover {
    transform: translateY(-3px);
    box-shadow: 0 12px 35px rgba(59, 130, 246, 0.4);
  }

  .boton-panel {
    background: rgba(107, 114, 128, 0.1);
    color: #6b7280;
    border: 2px solid rgba(107, 114, 128, 0.2);
  }

  .boton-panel:hover {
    background: rgba(107, 114, 128, 0.15);
    border-color: rgba(107, 114, 128, 0.3);
    transform: translateY(-2px);
  }

  .boton-reintentar svg, .boton-panel svg {
    width: 1.25rem;
    height: 1.25rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  @keyframes pulse {
    0%, 100% { transform: translate(-50%, -50%) scale(1); }
    50% { transform: translate(-50%, -50%) scale(1.1); }
  }

  @media (max-width: 768px) {
    .pagina-crear-contenido {
      padding: 1rem 0;
    }

    .contenedor-header {
      flex-direction: column;
      gap: 1rem;
      padding: 1.5rem;
    }

    .titulo-principal {
      font-size: 1.75rem;
    }

    .indicador-modo {
      flex-direction: column;
      align-items: center;
    }

    .contenedor-carga, .contenedor-error {
      padding: 2rem 1.5rem;
      margin: 0 1rem;
    }

    .acciones-error {
      flex-direction: column;
      align-items: center;
    }
  }
</style>
