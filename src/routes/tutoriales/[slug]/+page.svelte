<!-- src/routes/tutoriales/[slug]/+page.svelte -->
<script lang="ts">


  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { onMount } from 'svelte';
  
  // Importar plantillas
  import ClassicView from '$lib/components/PlantillasLandingCursos/ClassicView.svelte';
  import MinimalView from '$lib/components/PlantillasLandingCursos/MinimalView.svelte';
  import VideoHeroView from '$lib/components/PlantillasLandingCursos/VideoHeroView.svelte';
  import PremiumView from '$lib/components/PlantillasLandingCursos/PremiumView.svelte';
  
  // Datos del tutorial
  export let data;
  const tutorial = data.tutorial;
  
  // Estado
  let isLoading = false;
  let instructorInfo: { full_name?: string; avatar_url?: string } | null = null;
  let checkingInscripcion = true;
  let estaInscrito = false;
  
  // Si el tutorial no tiene una plantilla asignada, asignar la plantilla por defecto
  if (!tutorial.plantilla_vista) {
    tutorial.plantilla_vista = 'clasica';
  }
  
  // Registro de plantillas disponibles
  const plantillas = {
    'clasica': ClassicView,
    'minimal': MinimalView,
    'video_hero': VideoHeroView,
    'premium': PremiumView,
  };
  
  // Determinar qué plantilla usar
  const Vista = plantillas[tutorial.plantilla_vista as keyof typeof plantillas] || ClassicView;
  
  // Cargar información adicional y verificar inscripción
  onMount(async () => {
    // Verificar inscripción si el tutorial es de pago
    if ($estadoUsuarioActual.user && tutorial.tipo_acceso !== 'gratuito') {
      try {
        const { data, error } = await supabase
          .from('inscripciones')
          .select('id')
          .eq('usuario_id', $estadoUsuarioActual.user.id)
          .eq('tutorial_id', tutorial.id)
          .maybeSingle();
        estaInscrito = !!data;
      } catch (err) {
        console.error('Error al verificar inscripción:', err);
      } finally {
        checkingInscripcion = false;
      }
    } else {
      // Para cualquier tutorial, verificar inscripción real si hay usuario
      if ($estadoUsuarioActual.user) {
        try {
          const { data, error } = await supabase
            .from('inscripciones')
            .select('id')
            .eq('usuario_id', $estadoUsuarioActual.user.id)
            .eq('tutorial_id', tutorial.id)
            .maybeSingle();
          estaInscrito = !!data;
        } catch (err) {
          console.error('Error al verificar inscripción:', err);
          estaInscrito = false;
        } finally {
          checkingInscripcion = false;
        }
      } else {
        estaInscrito = false;
        checkingInscripcion = false;
      }
    }

    // Cargar información del instructor
    if (tutorial.instructor_id) {
      const { data } = await supabase
        .from('profiles')
        .select('full_name, avatar_url')
        .eq('id', tutorial.instructor_id)
        .single();
      instructorInfo = data;
    }
    // Cargar módulos/partes del tutorial para previsualización
    const { data: partes } = await supabase
      .from('partes_tutorial')
      .select('id, titulo, descripcion, orden')
      .eq('tutorial_id', tutorial.id)
      .order('orden');
    if (partes) {
      tutorial.modulos_preview = partes;
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
      const { data, error } = await supabase
        .from('inscripciones')
        .insert({
          usuario_id: $estadoUsuarioActual.user.id,
          tutorial_id: tutorial.id,
          fecha_inscripcion: new Date().toISOString()
        });
      if (error) throw error;
      estaInscrito = true;
      goto(`/tutoriales/${$page.params.slug}/contenido`);
    } catch (err) {
      console.error('Error al inscribirse:', err);
    } finally {
      isLoading = false;
    }
  }

  // Handler para ver contenido
  function verContenido() {
    goto(`/tutoriales/${$page.params.slug}/contenido`);
  }

  // Handler para ir a la primera clase
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';

  async function irAPrimeraClase() {
    // Buscar la primera clase real en partes_tutorial
    let primeraClase = null;
    if (tutorial.modulos_preview && tutorial.modulos_preview.length > 0) {
      primeraClase = tutorial.modulos_preview[0];
    } else {
      const { data: partes, error } = await supabase
        .from('partes_tutorial')
        .select('id, titulo, orden')
        .eq('tutorial_id', tutorial.id)
        .order('orden', { ascending: true });
      if (error || !partes || partes.length === 0) {
        alert('No se encontró ninguna clase en este tutorial');
        return;
      }
      primeraClase = partes[0];
    }
    const tutorialSlug = generateSlug(tutorial.titulo);
    const claseSlug = generateSlug(primeraClase.titulo);
    goto(`/tutoriales/${tutorialSlug}/clase/${claseSlug}`);
  }
</script>

<svelte:head>
  <title>{tutorial.titulo} | Academia Online</title>
  <meta name="description" content={tutorial.descripcion} />
</svelte:head>

<!-- Renderizar la plantilla seleccionada -->
<Vista 
  data={{ tutorial, estaInscrito, instructor: instructorInfo }} 
  {handleInscripcion} 
  {verContenido}
  {irAPrimeraClase}
/>