<!-- src/routes/cursos/[slug]/+page.svelte -->
<script lang="ts">
  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { onMount } from 'svelte';

  // Importar plantillas (puedes crear variantes si tienes otras para cursos)
  import ClassicView from '$lib/components/PlantillasLandingCursos/ClassicView.svelte';
  import MinimalView from '$lib/components/PlantillasLandingCursos/MinimalView.svelte';
  import VideoHeroView from '$lib/components/PlantillasLandingCursos/VideoHeroView.svelte';
  import PremiumView from '$lib/components/PlantillasLandingCursos/PremiumView.svelte';

  // Datos del curso
  export let data: any;
  const curso = data.curso;

  // Estado
  let isLoading = false;
  let instructorInfo: any = null;
  let checkingInscripcion = true;
  let estaInscrito = false;

  // Si el curso no tiene una plantilla asignada, asignar la plantilla por defecto
  if (!curso.plantilla_vista) {
    curso.plantilla_vista = 'clasica';
  }

  // Registro de plantillas disponibles
  const plantillas = {
    'clasica': ClassicView,
    'minimal': MinimalView,
    'video_hero': VideoHeroView,
    'premium': PremiumView,
  };

  // Determinar qué plantilla usar
  const Vista = plantillas[curso.plantilla_vista as keyof typeof plantillas] || ClassicView;

  // Cargar información adicional y verificar inscripción
  onMount(async () => {
    console.log('[CURSO] Verificando inscripción...');
    console.log('[CURSO] Usuario actual:', $estadoUsuarioActual.user?.id);
    console.log('[CURSO] Curso ID:', curso?.id);
    console.log('[CURSO] Tipo acceso:', curso?.tipo_acceso);
    
    // Verificar inscripción para cualquier usuario logueado
    if ($estadoUsuarioActual.user && curso?.id) {
      try {
        const { data: inscripcionData, error } = await supabase
          .from('inscripciones')
          .select('id, curso_id, tutorial_id')
          .eq('usuario_id', ($estadoUsuarioActual.user as any).id)
          .eq('curso_id', curso.id)
          .maybeSingle();
          
        console.log('[CURSO] Resultado consulta inscripción:', inscripcionData);
        console.log('[CURSO] Error en consulta:', error);
        
        estaInscrito = !!inscripcionData;
        console.log('[CURSO] Estado final estaInscrito:', estaInscrito);
        
      } catch (err) {
        console.error('[CURSO] Error al verificar inscripción:', err);
        estaInscrito = false;
      } finally {
        checkingInscripcion = false;
      }
    } else {
      console.log('[CURSO] No hay usuario logueado');
      estaInscrito = false;
      checkingInscripcion = false;
    }

    // Cargar información del instructor
    if (curso.instructor_id) {
      const { data } = await supabase
        .from('profiles')
        .select('full_name, avatar_url')
        .eq('id', curso.instructor_id)
        .single();
      instructorInfo = data;
    }

  });

  // Handler para inscripción
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';

  async function handleInscripcion() {
    if (!$estadoUsuarioActual.user) {
      goto('/auth?redirect=' + encodeURIComponent($page.url.pathname));
      return;
    }
    
    try {
      isLoading = true;
      console.log('[CURSO] Evaluando tipo de acceso...');
      console.log('[CURSO] Usuario ID:', ($estadoUsuarioActual.user as any).id);
      console.log('[CURSO] Curso ID:', curso.id);
      console.log('[CURSO] Precio normal:', curso.precio_normal);
      console.log('[CURSO] Precio rebajado:', curso.precio_rebajado);
      
      // Determinar si el curso es gratuito o de pago
      const precioFinal = curso.precio_rebajado || curso.precio_normal || 0;
      const esGratis = precioFinal === 0;
      
      console.log('[CURSO] Precio final:', precioFinal);
      console.log('[CURSO] Es gratuito:', esGratis);
      
      if (esGratis) {
        // CURSO GRATUITO - Inscripción directa
        console.log('[CURSO] Procesando inscripción gratuita...');
        
        const { data: inscripcionData, error } = await supabase
          .from('inscripciones')
          .insert({
            usuario_id: ($estadoUsuarioActual.user as any).id,
            curso_id: curso.id,
            fecha_inscripcion: new Date().toISOString(),
            estado: 'activa'
          });
          
        if (error) throw error;
        
        console.log('[CURSO] Inscripción gratuita exitosa:', inscripcionData);
        estaInscrito = true;
        console.log('[CURSO] Estado actualizado estaInscrito:', estaInscrito);
        
      } else {
        // CURSO DE PAGO - Redirigir al sistema de pagos
        console.log('[CURSO] Curso de pago detectado, iniciando proceso...');
        
        const usuario = $estadoUsuarioActual.user as any;
        const datosCompra = {
          usuarioId: usuario.id,
          cursoId: curso.id,
          email: usuario.email || usuario.correo_electronico,
          nombre: usuario.user_metadata?.nombre || usuario.full_name || 'Usuario',
          telefono: usuario.telefono || '3001234567'
        };
        
        console.log('[CURSO] Enviando datos al sistema de pagos:', datosCompra);
        
        // Llamar a la API de pagos
        const response = await fetch('/api/pagos/crear', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(datosCompra)
        });
        
        const resultado = await response.json();
        
        if (resultado.success && resultado.data.url_pago) {
          console.log('[CURSO] Pago creado, redirigiendo a ePayco...');
          window.location.href = resultado.data.url_pago;
        } else {
          throw new Error(resultado.error || 'Error procesando el pago');
        }
      }
      
    } catch (err) {
      console.error('[CURSO] Error en proceso:', err);
      alert(`Error en el proceso: ${(err as any)?.message || 'Error desconocido'}`);
    } finally {
      isLoading = false;
    }
  }

  // Handler para ver contenido (llevar a la primera lección real)
  function verContenido() {
    // Buscar la primera lección de un módulo
    if (curso.modulos && curso.modulos.length > 0) {
      // Buscar el primer módulo que tenga al menos una lección
      const primerModulo = curso.modulos.find((m: any) => m.lecciones && m.lecciones.length > 0);
      if (primerModulo) {
        const primeraLeccion = primerModulo.lecciones[0];
        const cursoSlug = curso.slug || generateSlug(curso.titulo);
        const moduloSlug = primerModulo.slug || generateSlug(primerModulo.titulo);
        const leccionSlug = primeraLeccion.slug || generateSlug(primeraLeccion.titulo);
        const rutaDestino = `/cursos/${cursoSlug}/modulo/${moduloSlug}/leccion/${leccionSlug}`;
        goto(rutaDestino);
        return;
      }
    }
    // Si no hay módulos con lecciones, buscar lecciones sueltas
    if (curso.lecciones_sueltas && curso.lecciones_sueltas.length > 0) {
      const primeraLeccion = curso.lecciones_sueltas.find((l: any) => l && l.slug) || curso.lecciones_sueltas[0];
      const cursoSlug = curso.slug || generateSlug(curso.titulo);
      const leccionSlug = primeraLeccion.slug || generateSlug(primeraLeccion.titulo);
      const rutaDestino = `/cursos/${cursoSlug}/leccion/${leccionSlug}`;
      goto(rutaDestino);
      return;
    }
    alert('Este curso no tiene lecciones disponibles.');
    console.error('[verContenido][ERROR][CURSO] curso:', curso);
  }

  // Handler para ir a la primera clase
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';

  async function irAPrimeraClase() {
    // Buscar la primera clase real en modulos_preview
    let primeraClase = null;
    if (curso.modulos_preview && curso.modulos_preview.length > 0) {
      primeraClase = curso.modulos_preview[0];
    } else {
      const { data: partes, error } = await supabase
        .from('modulos_curso')
        .select('id, titulo, orden')
        .eq('curso_id', curso.id)
        .order('orden', { ascending: true });
      if (error || !partes || partes.length === 0) {
        alert('No se encontró ninguna clase en este curso');
        return;
      }
      primeraClase = partes[0];
    }
    const cursoSlug = generateSlug(curso.titulo);
    const claseSlug = generateSlug(primeraClase.titulo);
    goto(`/cursos/${cursoSlug}/clase/${claseSlug}`);
  }
</script>

<svelte:head>
  <title>{curso.titulo} | Academia Online</title>
  <meta name="description" content={curso.descripcion} />
</svelte:head>

<!-- Renderizar la plantilla seleccionada -->
{#if !checkingInscripcion}
  <Vista 
    data={{ curso, estaInscrito, instructor: instructorInfo }} 
    plantilla={curso.plantilla_vista}
    {handleInscripcion}
    {verContenido}
    {irAPrimeraClase}
  />
{:else}
  <div class="flex justify-center items-center min-h-screen">
    <div class="text-center">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
      <p class="mt-4 text-gray-600">Verificando inscripción...</p>
    </div>
  </div>
{/if}
