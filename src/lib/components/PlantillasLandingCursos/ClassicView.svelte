<script lang="ts">
  	import ContadorOferta from '../ComponentesLanding/ContadorOferta.svelte';
	import HeroCurso from '../ComponentesLanding/HeroCurso.svelte';
	import SeccionBeneficios from '../ComponentesLanding/SeccionBeneficios.svelte';
	import SeccionProblema from '../ComponentesLanding/SeccionProblema.svelte';
	import SeccionSolucion from '../ComponentesLanding/SeccionSolucion.svelte';
	import SeccionPago from '../ComponentesLanding/SeccionPago.svelte';
	import { generateSlug } from '$lib/utilidades/utilidadesSlug';
	import { goto } from '$app/navigation';
	import { browser } from '$app/environment';
  
  // Props que recibimos
  export let data: any;
  export let handleInscripcion: () => Promise<void>;
  export let verContenido: (() => void) | null = null; // Puede ser null si no se pasa
  export let irAPrimeraClase: () => void = () => {}; // Para tutoriales
  
  // Datos del contenido (curso o tutorial)
  const contenido = data?.curso || data?.tutorial;
  const tipo = data?.curso ? 'curso' : 'tutorial';
  
  // Estado de inscripción - usar exactamente la misma lógica que PremiumView
  let estaInscrito = data?.estaInscrito || false;
  
  // CRÍTICO: Declaración reactiva para propagación a componentes hijos
  $: estaInscrito = data?.estaInscrito || false;
  
  // Para compatibilidad con componentes existentes
  $: curso = { ...contenido, tipo }; // HeroCurso espera una prop llamada 'curso' con el tipo incluido
  
  // Función para navegar al contenido (copiada de PremiumView)
  function navegarAContenido() {
    console.log('[ClassicView] navegarAContenido - contenido:', contenido);
    console.log('[ClassicView] navegarAContenido - tipo:', tipo);

    if (tipo === 'curso') {
      // Buscar módulos y lecciones anidadas
      const modulos = contenido.modulos || contenido.modulos_preview || [];
      const primerModulo = modulos.find((m: any) => m.lecciones && m.lecciones.length > 0);
      const leccionesSueltas = contenido.lecciones_sueltas || [];

      console.log('[ClassicView] modulos:', modulos);
      console.log('[ClassicView] primerModulo:', primerModulo);
      console.log('[ClassicView] leccionesSueltas:', leccionesSueltas);

      if (primerModulo && primerModulo.lecciones.length > 0) {
        const cursoSlug = contenido.slug || generateSlug(contenido.titulo);
        const moduloSlug = primerModulo.slug || generateSlug(primerModulo.titulo);
        const leccionSlug = primerModulo.lecciones[0].slug || generateSlug(primerModulo.lecciones[0].titulo);
        const rutaDestino = `/cursos/${cursoSlug}/${moduloSlug}/${leccionSlug}`;
        console.log('[ClassicView][CURSO] rutaDestino:', rutaDestino);
        goto(rutaDestino);
        return;
      } else if (leccionesSueltas.length > 0) {
        const primeraLeccion = leccionesSueltas[0];
        const cursoSlug = contenido.slug || generateSlug(contenido.titulo);
        const leccionSlug = primeraLeccion.slug || generateSlug(primeraLeccion.titulo);
        const rutaDestino = `/cursos/${cursoSlug}/leccion/${leccionSlug}`;
        console.log('[ClassicView][CURSO][SUELTA] rutaDestino:', rutaDestino);
        goto(rutaDestino);
        return;
      } else {
        alert('Este curso no tiene lecciones disponibles.\n\nVerifica que hayas creado módulos y lecciones correctamente.\nSi acabas de crear el curso, prueba recargar la página. Revisa la consola (F12) para más detalles.');
        console.error('[ClassicView][ERROR] Sin lecciones:', contenido);
        return;
      }
    }

    // Lógica de tutorial
    if (
      tipo === 'tutorial' &&
      Array.isArray(contenido.modulos_preview) &&
      contenido.modulos_preview.length > 0
    ) {
      const tutorialSlug = generateSlug(contenido.titulo);
      const primeraClase = contenido.modulos_preview[0];
      const claseSlug = generateSlug(primeraClase.titulo);
      if (tutorialSlug && claseSlug) {
        goto(`/tutoriales/${tutorialSlug}/clase/${claseSlug}`);
        return;
      }
      alert('No se encontró la primera clase de este tutorial. Revisa la consola para más detalles.');
      console.error('[ClassicView][ERROR][TUTORIAL] contenido:', contenido);
      return;
    }

    // Fallback: usar la función verContenido si existe
    if (verContenido && typeof verContenido === 'function') {
      verContenido();
      return;
    }

    alert('No se encontró la primera lección o clase.\n\nRevisa la consola (F12) para ver la estructura de datos recibida.');
    console.error('[ClassicView][ERROR][GENERAL] contenido:', contenido);
  }
  
  // Función para hacer scroll a la sección de pago
  function scrollToSeccionPago() {
    if (browser) {
      const seccionPago = document.querySelector('#seccion-pago');
      if (seccionPago) {
        seccionPago.scrollIntoView({ 
          behavior: 'smooth',
          block: 'start'
        });
      }
    }
  }
  
  // Función unificada para manejar la acción principal del HERO
  async function handleAccionPrincipalHero() {
    console.log('[ClassicView] handleAccionPrincipalHero - estaInscrito:', estaInscrito);
    
    if (estaInscrito) {
      // Si ya está inscrito, navegar al contenido
      console.log('[ClassicView] Usuario inscrito, navegando al contenido...');
      navegarAContenido();
    } else {
      // Si no está inscrito, hacer scroll a la sección de pago
      console.log('[ClassicView] Usuario no inscrito, navegando a sección de pago...');
      scrollToSeccionPago();
    }
  }
  
  // Función para manejar la inscripción desde la sección de pago
  async function handleInscripcionConActualizacion() {
    console.log('[ClassicView] handleInscripcionConActualizacion - antes de inscripción, estaInscrito:', estaInscrito);
    console.log('[ClassicView] Tipo de acceso:', contenido?.tipo_acceso);
    console.log('[ClassicView] Precio:', contenido?.precio);
    
    // Verificar si es contenido de pago
    const precioFinal = contenido?.precio_rebajado || contenido?.precio_normal || 0;
    const esGratis = precioFinal === 0;
    
    console.log('[ClassicView] DEBUG PRECIOS:');
    console.log('- contenido.precio_normal:', contenido?.precio_normal);
    console.log('- contenido.precio_rebajado:', contenido?.precio_rebajado);
    console.log('- contenido.tipo_acceso:', contenido?.tipo_acceso);
    console.log('- precioFinal calculado:', precioFinal);
    console.log('- esGratis (CORREGIDO):', esGratis);
    
    if (!esGratis) {
      // CONTENIDO DE PAGO - Abrir modal de checkout
      console.log('[ClassicView] Contenido de pago, abriendo modal de checkout...');
      alert('🚧 Modal de checkout en desarrollo.\n\nPróximamente podrás comprar este contenido.\n\nPor ahora, cambia el precio a 0 para probarlo gratis.');
      return;
    }
    
    // CONTENIDO GRATUITO - Proceder con inscripción
    try {
      console.log('[ClassicView] Contenido gratuito, procediendo con inscripción...');
      
      // Ejecutar la función de inscripción
      await handleInscripcion();
      
      // Actualizar el estado local inmediatamente - CRÍTICO para reactividad
      console.log('[ClassicView] Inscripción completada, actualizando estado...');
      
      // Actualizar directamente el objeto data para trigger reactividad
      data = { ...data, estaInscrito: true };
      
      console.log('[ClassicView] Estado después de inscripción, estaInscrito:', estaInscrito);
      console.log('[ClassicView] data después de actualización:', data);
      
    } catch (error) {
      console.error('[ClassicView] Error en inscripción:', error);
    }
  }
</script>

<svelte:head>
  <title>{contenido?.titulo || 'Contenido'} | Academia Vallenata</title>
</svelte:head>

<!-- Contador de oferta (si hay fecha de expiración) -->
{#if contenido?.fecha_expiracion}
  <ContadorOferta 
    fechaExpiracion={contenido.fecha_expiracion}
    descuento={contenido.descuento_porcentaje || 0}
    mostrarDescuento={contenido.descuento_porcentaje > 0}
  />
{/if}

<!-- Hero principal del curso -->
<HeroCurso 
  {curso}
  {estaInscrito}
  handleInscripcion={handleAccionPrincipalHero}
  verContenido={navegarAContenido}
/>

<!-- 🔥 SECCIÓN PROBLEMA - Amplifica el dolor del cliente (POSICIÓN CORRECTA) -->
<SeccionProblema 
  {tipo} 
/>

<!-- ⚡ SECCIÓN SOLUCIÓN - LA RESPUESTA al problema del cliente -->
<SeccionSolucion 
  {tipo} 
/>

<!-- 💰 SECCIÓN PAGO - CIERRE DE VENTA -->
<div id="seccion-pago">
  <SeccionPago 
    {contenido}
    {tipo}
    {estaInscrito}
    handleCompra={handleInscripcionConActualizacion}
  />
</div>

<!-- ✨ SECCIÓN BENEFICIOS - TEMPORALMENTE OCULTA -->
<!-- <SeccionBeneficios 
  {contenido} 
  {tipo} 
/> -->

<style>
  /* Estilos globales para la página de curso */
  :global(body) {
    margin: 0;
    padding: 0;
    background-color: #f0f0f0;
  }
</style>
