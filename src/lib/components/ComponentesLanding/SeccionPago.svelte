<!-- SeccionPago.svelte - Sección de pago FUNCIONAL con inscripción -->
<script lang="ts">
  import { goto } from '$app/navigation';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';
  import ModalPagoInteligente from './ModalPagoInteligente.svelte';
  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
  import { get } from 'svelte/store';
  
  export let contenido: any = {}; 
  export let tipo: 'curso' | 'tutorial' = 'curso';
  export let handleCompra: () => void = () => {}; 
  export let estaInscrito: boolean = false; // Nuevo prop para estado de inscripción
  
  // Estado del modal
  let mostrarModal = false;
  let contenidoSeleccionado: any = null;
  let tipoContenido: 'curso' | 'tutorial' = 'curso';
  
  // Formatear precio
  function formatearPrecio(precio: number) {
    return new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency: 'COP',
      minimumFractionDigits: 0
    }).format(precio);
  }
  
  // Calcular precios
  $: precioOriginal = contenido.precio_normal || 0;
  $: precioRebajado = contenido.precio_rebajado || 0;
  $: descuento = contenido.descuento_porcentaje || 0;
  $: precioFinal = precioRebajado > 0 ? precioRebajado : 
                   (descuento > 0 ? precioOriginal * (1 - descuento / 100) : precioOriginal);
  $: esGratis = precioFinal === 0;
  $: ahorros = precioOriginal - precioFinal;
  
  // Debug logs para precios
  $: {
    console.log('[SeccionPago] DEBUG PRECIOS:');
    console.log('- contenido.precio_normal:', contenido.precio_normal);
    console.log('- contenido.precio_rebajado:', contenido.precio_rebajado);
    console.log('- contenido.tipo_acceso:', contenido.tipo_acceso);
    console.log('- precioOriginal:', precioOriginal);
    console.log('- precioRebajado:', precioRebajado);
    console.log('- precioFinal:', precioFinal);
    console.log('- esGratis (CORREGIDO):', esGratis);
    console.log('- tipo:', tipo);
  }
  
  // Estados
  let personasViendo = Math.floor(Math.random() * 50) + 120;
  let isLoading = false;
  let showModal = false;
  let modalMessage = '';
  
  // Función para navegar al contenido (copiada de PremiumView)
  function verContenido() {
    console.log('[verContenido] CONTENIDO:', JSON.stringify(contenido, null, 2));
    console.log('[verContenido] tipo:', tipo);

    if (tipo === 'curso') {
      // Buscar módulos y lecciones anidadas
      const modulos = contenido.modulos || contenido.modulos_preview || [];
      const primerModulo = modulos.find((m: any) => m.lecciones && m.lecciones.length > 0);
      const leccionesSueltas = contenido.lecciones_sueltas || [];

      if (primerModulo && primerModulo.lecciones.length > 0) {
        const cursoSlug = contenido.slug || generateSlug(contenido.titulo);
        const moduloSlug = primerModulo.slug || generateSlug(primerModulo.titulo);
        const leccionSlug = primerModulo.lecciones[0].slug || generateSlug(primerModulo.lecciones[0].titulo);
        const rutaDestino = `/cursos/${cursoSlug}/${moduloSlug}/${leccionSlug}`;
        console.log('[verContenido][CURSO] rutaDestino:', rutaDestino);
        goto(rutaDestino);
        return;
      } else if (leccionesSueltas.length > 0) {
        const primeraLeccion = leccionesSueltas[0];
        const cursoSlug = contenido.slug || generateSlug(contenido.titulo);
        const leccionSlug = primeraLeccion.slug || generateSlug(primeraLeccion.titulo);
        const rutaDestino = `/cursos/${cursoSlug}/leccion/${leccionSlug}`;
        console.log('[verContenido][CURSO][SUELTA] rutaDestino:', rutaDestino);
        goto(rutaDestino);
        return;
      } else {
        alert('Este curso no tiene lecciones disponibles.\n\nVerifica que hayas creado módulos y lecciones correctamente.');
        return;
      }
    }

    // Lógica de tutorial
    if (tipo === 'tutorial' && Array.isArray(contenido.modulos_preview) && contenido.modulos_preview.length > 0) {
      const tutorialSlug = generateSlug(contenido.titulo);
      const primeraClase = contenido.modulos_preview[0];
      const claseSlug = generateSlug(primeraClase.titulo);
      if (tutorialSlug && claseSlug) {
        goto(`/tutoriales/${tutorialSlug}/clase/${claseSlug}`);
        return;
      }
    }

    alert('No se encontró la primera lección o clase.\n\nRevisa la consola (F12) para ver la estructura de datos.');
    console.error('[verContenido][ERROR] contenido:', contenido);
  }
  
  // Función principal del botón
  async function manejarClick() {
    try {
      isLoading = true;
      
      if (estaInscrito) {
        // Si ya está inscrito, navegar al contenido usando la función del padre
        console.log('[SeccionPago] Usuario inscrito, navegando...');
        verContenido();
        return;
      }
      
      if (esGratis) {
        // Inscripción automática para contenido gratuito
        console.log('[SeccionPago] Inscripción gratuita...');
        await handleCompra(); // Ejecutar inscripción
        
        // Mostrar modal de confirmación sin redireccionar
        modalMessage = `¡Felicidades! Te has inscrito exitosamente al ${tipo === 'curso' ? 'curso' : 'tutorial'}: "${contenido.titulo}". Ya puedes comenzar a aprender.`;
        showModal = true;
        // No redirigir automáticamente, solo mostrar el modal
        
      } else {
        // Para contenido de pago, iniciar proceso con ePayco
        console.log('[SeccionPago] Iniciando proceso de pago con ePayco...');
        await iniciarPagoEpayco();
      }
      
    } catch (error) {
      console.error('Error en proceso:', error);
      alert('Hubo un error al procesar tu solicitud. Por favor intenta nuevamente.');
    } finally {
      isLoading = false;
    }
  }
  
  // Nueva función para manejar pagos con ePayco
  async function iniciarPagoEpayco() {
    try {
      // Obtener datos reales del usuario desde el store
      const usuarioData = get(estadoUsuarioActual);
      const usuario = usuarioData.user;
      
      if (!usuario) {
        alert('❌ Debes iniciar sesión para realizar la compra');
        return;
      }
      
      // Obtener datos reales del usuario
      const usuarioActual = {
        id: (usuario as any).id,
        email: (usuario as any).email || (usuario as any).correo_electronico,
        nombre: (usuario as any).user_metadata?.nombre || (usuario as any).full_name || 'Usuario'
      };
      
      const datosCompra: any = {
        usuarioId: usuarioActual.id,
        email: usuarioActual.email,
        nombre: usuarioActual.nombre,
        telefono: '3001234567' // Opcional: puedes pedirlo en un formulario
      };
      
      // Agregar ID del curso o tutorial
      if (tipo === 'curso') {
        datosCompra.cursoId = contenido.id;
      } else {
        datosCompra.tutorialId = contenido.id;
      }
      
      console.log('💳 Enviando datos a ePayco:', datosCompra);
      
      // Llamar a la API para crear el pago
      const response = await fetch('/api/pagos/crear', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(datosCompra)
      });
      
      const resultado = await response.json();
      
      if (resultado.success && resultado.data && resultado.data.bankURL) {
        console.log('✅ Pago creado, redirigiendo a ePayco...');
        // Redirigir a la URL del formulario o directamente a ePayco
        window.location.href = resultado.data.bankURL;
      } else {
        throw new Error(resultado.error || 'Error procesando el pago');
      }
      
    } catch (error: any) {
      console.error('❌ Error en pago ePayco:', error);
      alert(`Error procesando el pago: ${error?.message || 'Error desconocido'}`);
    }
  }
  
  // Determinar texto del botón
  $: textoBoton = estaInscrito 
    ? (tipo === 'curso' ? '🚀 Comenzar Curso' : '🚀 Comenzar Tutorial')
    : esGratis 
      ? '🚀 ¡INSCRIBIRME GRATIS!'
      : '💳 ¡COMPRAR AHORA!';
      
  $: iconoBoton = estaInscrito ? '🚀' : esGratis ? '🚀' : '💳';

  // Determinar qué contenido mostrar
  $: contenidoActual = contenido;
  $: tipoActual = tipo;
  
  function abrirModalPago() {
    contenidoSeleccionado = contenidoActual;
    tipoContenido = tipoActual;
    mostrarModal = true;
  }
  
  function cerrarModalPago() {
    mostrarModal = false;
    contenidoSeleccionado = null;
  }
</script>

<!-- Modal de Pago Inteligente -->
<ModalPagoInteligente 
  bind:mostrar={mostrarModal}
  contenido={contenidoSeleccionado}
  tipoContenido={tipoContenido}
  on:cerrar={cerrarModalPago}
/>

<section class="seccion-pago" id="seccion-pago">
  <div class="container">
    
    <!-- Urgencia social -->
    <div class="urgencia-social">
      <div class="pulse-dot"></div>
      <span>🔥 {personasViendo} personas viendo esta página ahora</span>
    </div>
    
    <!-- Título -->
    <div class="encabezado">
      {#if estaInscrito}
        <h2 class="titulo">¡Ya Estás Inscrito! 🎉</h2>
        <p class="subtitulo">Comienza tu aprendizaje ahora mismo</p>
      {:else}
        <h2 class="titulo">¡Comienza Tu Transformación Musical!</h2>
        <p class="subtitulo">Únete a los miles de estudiantes que ya están viviendo su sueño</p>
      {/if}
    </div>
    
    <!-- Card de pago -->
    <div class="card-pago">
      
      <!-- Badge popular -->
      {#if !estaInscrito}
        <div class="badge-popular">⭐ MÁS VENDIDO</div>
      {:else}
        <div class="badge-inscrito">✅ INSCRITO</div>
      {/if}
      
      <!-- Info del curso -->
      <div class="curso-info">
        <h3 class="curso-titulo">{contenidoActual?.titulo || 'Curso de Acordeón Vallenato'}</h3>
        <div class="curso-stats">
          <span class="rating">⭐⭐⭐⭐⭐ 4.9 (2,847 reseñas)</span>
          <span class="estudiantes">👥 +{contenidoActual?.estudiantes_inscritos || 15000} estudiantes</span>
        </div>
      </div>
      
      <!-- Precio -->
      {#if !estaInscrito}
        <div class="precio-section">
          {#if !esGratis}
            {#if ahorros > 0}
              <div class="descuento-badge">AHORRA {Math.round((ahorros/precioOriginal)*100)}%</div>
              <div class="precio-original">{formatearPrecio(precioOriginal)}</div>
              <div class="precio-final">{formatearPrecio(precioFinal)}</div>
              <div class="ahorro">¡Ahorras {formatearPrecio(ahorros)}!</div>
            {:else}
              <div class="precio-final">{formatearPrecio(precioFinal)}</div>
            {/if}
            <div class="precio-detalle">Pago único • Acceso de por vida</div>
          {:else}
            <div class="precio-gratis">GRATIS</div>
            <div class="precio-detalle">Acceso completo sin costo</div>
          {/if}
        </div>
      {:else}
        <div class="precio-section inscrito">
          <div class="acceso-completo">✅ ACCESO COMPLETO</div>
          <div class="precio-detalle">Ya tienes acceso de por vida</div>
        </div>
      {/if}
      
      <!-- Beneficios clave -->
      <div class="beneficios">
        <div class="beneficio">⚡ Acceso inmediato</div>
        <div class="beneficio">📱 Cualquier dispositivo</div>
        <div class="beneficio">🏆 Certificado incluido</div>
      </div>
      
      <!-- Botón principal -->
      <button 
        class="btn-comprar {estaInscrito ? 'inscrito' : esGratis ? 'gratis' : 'pago'}" 
        on:click={abrirModalPago}
        disabled={isLoading}
      >
        {#if isLoading}
          <div class="loading-spinner"></div>
          <span class="btn-texto">Procesando...</span>
        {:else}
          <span class="btn-icon">{iconoBoton}</span>
          <span class="btn-texto">{textoBoton}</span>
        {/if}
      </button>
      
      <!-- Garantía -->
      {#if !estaInscrito}
        <div class="garantia">
          <span class="garantia-icon">🛡️</span>
          <span class="garantia-texto">
            <strong>Garantía 30 días</strong> • Pago 100% seguro
          </span>
        </div>
      {:else}
        <div class="garantia inscrito">
          <span class="garantia-icon">🎓</span>
          <span class="garantia-texto">
            <strong>Disfruta tu aprendizaje</strong> • Soporte incluido
          </span>
        </div>
      {/if}
      
    </div>
    
  </div>
</section>

<style>
  /* Sección principal */
  .seccion-pago {
    background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
    padding: 5rem 0;
    position: relative;
  }
  
  .container {
    max-width: 600px;
    margin: 0 auto;
    padding: 0 1rem;
  }
  
  /* Urgencia social */
  .urgencia-social {
    background: linear-gradient(135deg, #fef2f2, #fee2e2);
    border: 1px solid #fca5a5;
    border-radius: 50px;
    padding: 0.75rem 1.5rem;
    text-align: center;
    margin-bottom: 3rem;
    color: #dc2626;
    font-weight: 600;
    font-size: 0.9rem;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
  }
  
  .pulse-dot {
    width: 8px;
    height: 8px;
    background: #dc2626;
    border-radius: 50%;
    animation: pulse 2s infinite;
  }
  
  /* Encabezado */
  .encabezado {
    text-align: center;
    margin-bottom: 3rem;
  }
  
  .titulo {
    font-size: 2.5rem;
    font-weight: 800;
    color: #1e293b;
    margin-bottom: 1rem;
    line-height: 1.2;
  }
  
  .subtitulo {
    font-size: 1.1rem;
    color: #64748b;
    max-width: 500px;
    margin: 0 auto;
  }
  
  /* Card de pago */
  .card-pago {
    background: white;
    border-radius: 25px;
    padding: 3rem;
    box-shadow: 0 25px 50px rgba(0, 0, 0, 0.15);
    border: 1px solid #e2e8f0;
    position: relative;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
  }
  
  .card-pago:hover {
    transform: translateY(-5px);
    box-shadow: 0 35px 70px rgba(0, 0, 0, 0.2);
  }
  
  /* Badges */
  .badge-popular {
    position: absolute;
    top: -15px;
    left: 50%;
    transform: translateX(-50%);
    background: linear-gradient(135deg, #dc2626, #b91c1c);
    color: white;
    padding: 0.5rem 1.5rem;
    border-radius: 50px;
    font-size: 0.8rem;
    font-weight: 700;
    letter-spacing: 0.5px;
    box-shadow: 0 5px 15px rgba(220, 38, 38, 0.4);
  }
  
  .badge-inscrito {
    position: absolute;
    top: -15px;
    left: 50%;
    transform: translateX(-50%);
    background: linear-gradient(135deg, #10b981, #059669);
    color: white;
    padding: 0.5rem 1.5rem;
    border-radius: 50px;
    font-size: 0.8rem;
    font-weight: 700;
    letter-spacing: 0.5px;
    box-shadow: 0 5px 15px rgba(16, 185, 129, 0.4);
  }
  
  /* Info del curso */
  .curso-info {
    text-align: center;
    margin-bottom: 2rem;
  }
  
  .curso-titulo {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1e293b;
    margin-bottom: 1rem;
  }
  
  .curso-stats {
    display: flex;
    justify-content: center;
    gap: 2rem;
    flex-wrap: wrap;
  }
  
  .rating {
    color: #fbbf24;
    font-weight: 600;
    font-size: 0.9rem;
  }
  
  .estudiantes {
    color: #10b981;
    font-weight: 600;
    font-size: 0.9rem;
  }
  
  /* Precio */
  .precio-section {
    text-align: center;
    margin-bottom: 2rem;
    padding: 2rem;
    background: linear-gradient(135deg, #f8fafc, #f1f5f9);
    border-radius: 20px;
    border: 1px solid #e2e8f0;
  }
  
  .precio-section.inscrito {
    background: linear-gradient(135deg, #f0fdf4, #dcfce7);
    border: 1px solid #bbf7d0;
  }
  
  .descuento-badge {
    background: linear-gradient(135deg, #dc2626, #b91c1c);
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 50px;
    font-size: 0.8rem;
    font-weight: 700;
    display: inline-block;
    margin-bottom: 1rem;
    animation: pulse 2s infinite;
  }
  
  .precio-original {
    font-size: 1.2rem;
    color: #94a3b8;
    text-decoration: line-through;
    margin-bottom: 0.5rem;
  }
  
  .precio-final {
    font-size: 3rem;
    font-weight: 900;
    color: #dc2626;
    margin-bottom: 0.5rem;
  }
  
  .precio-gratis {
    font-size: 3rem;
    font-weight: 900;
    color: #10b981;
    margin-bottom: 0.5rem;
  }
  
  .acceso-completo {
    font-size: 2rem;
    font-weight: 900;
    color: #10b981;
    margin-bottom: 0.5rem;
  }
  
  .ahorro {
    background: #fef3c7;
    color: #d97706;
    padding: 0.5rem 1rem;
    border-radius: 50px;
    font-weight: 600;
    display: inline-block;
    margin-bottom: 0.5rem;
    font-size: 0.9rem;
  }
  
  .precio-detalle {
    color: #64748b;
    font-size: 0.9rem;
  }
  
  /* Beneficios */
  .beneficios {
    display: flex;
    justify-content: space-between;
    margin-bottom: 2rem;
    padding: 1.5rem;
    background: linear-gradient(135deg, #f0f9ff, #e0f2fe);
    border-radius: 15px;
    border: 1px solid #bae6fd;
  }
  
  .beneficio {
    text-align: center;
    color: #0369a1;
    font-weight: 600;
    font-size: 0.9rem;
    flex: 1;
  }
  
  /* Botón de compra */
  .btn-comprar {
    width: 100%;
    border: none;
    border-radius: 15px;
    padding: 1.25rem;
    font-size: 1.1rem;
    font-weight: 700;
    cursor: pointer;
    transition: all 0.3s ease;
    margin-bottom: 1.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    letter-spacing: 0.5px;
    position: relative;
  }
  
  .btn-comprar.pago {
    background: linear-gradient(135deg, #dc2626, #b91c1c);
    color: white;
  }
  
  .btn-comprar.gratis {
    background: linear-gradient(135deg, #10b981, #059669);
    color: white;
  }
  
  .btn-comprar.inscrito {
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    color: white;
  }
  
  .btn-comprar:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
  }
  
  .btn-comprar:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }
  
  .btn-icon {
    font-size: 1.2rem;
  }
  
  .loading-spinner {
    width: 20px;
    height: 20px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    border-top-color: white;
    animation: spin 1s ease-in-out infinite;
  }
  
  /* Garantía */
  .garantia {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 1rem;
    background: linear-gradient(135deg, #f0fdf4, #dcfce7);
    border: 1px solid #bbf7d0;
    border-radius: 10px;
    color: #166534;
  }
  
  .garantia.inscrito {
    background: linear-gradient(135deg, #eff6ff, #dbeafe);
    border: 1px solid #93c5fd;
    color: #1e40af;
  }
  
  .garantia-icon {
    font-size: 1.2rem;
  }
  
  .garantia-texto {
    font-size: 0.9rem;
    font-weight: 600;
  }
  
  /* Animaciones */
  @keyframes pulse {
    0%, 100% {
      opacity: 1;
      transform: scale(1);
    }
    50% {
      opacity: 0.8;
      transform: scale(1.05);
    }
  }
  
  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .seccion-pago {
      padding: 4rem 0;
    }
    
    .titulo {
      font-size: 2rem;
    }
    
    .card-pago {
      padding: 2rem;
      margin: 0 1rem;
    }
    
    .curso-stats {
      flex-direction: column;
      gap: 0.5rem;
    }
    
    .precio-final,
    .precio-gratis,
    .acceso-completo {
      font-size: 2.5rem;
    }
    
    .beneficios {
      flex-direction: column;
      gap: 1rem;
    }
    
    .modal-footer {
      flex-direction: column;
    }
  }
  
  @media (max-width: 480px) {
    .titulo {
      font-size: 1.8rem;
    }
    
    .card-pago {
      padding: 1.5rem;
    }
    
    .precio-final,
    .precio-gratis,
    .acceso-completo {
      font-size: 2rem;
    }
    
    .btn-comprar {
      font-size: 1rem;
      padding: 1rem;
    }
  }
</style> 