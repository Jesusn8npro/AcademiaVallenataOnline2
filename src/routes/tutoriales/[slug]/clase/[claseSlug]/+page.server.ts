import { error } from '@sveltejs/kit';
import { supabase } from '$lib/supabase/clienteSupabase';
import { generateSlug } from '$lib/utilidades/utilidadesSlug';

interface Tutorial {
  id: string;
  titulo: string;
  slug?: string;
  [key: string]: any;
}

interface Clase {
  id: string;
  titulo: string;
  slug?: string;
  tutorial_id: string;
  orden: number;
  [key: string]: any;
}

export const load = async ({ params }) => {
  const { slug: tutorialSlug, claseSlug } = params;

  try {
    // 1. Obtener el tutorial
    let tutorialData: Tutorial;
    const { data: tutorialPorSlug, error: tutorialError } = await supabase
      .from('tutoriales')
      .select('*')
      .eq('slug', tutorialSlug)
      .single();

    if (tutorialError) {
      // Si no se encuentra por slug, buscar por título
      const { data: tutorialesPorTitulo, error: errorTitulo } = await supabase
        .from('tutoriales')
        .select('*');
      
      if (errorTitulo || !tutorialesPorTitulo) {
        throw error(404, 'Tutorial no encontrado');
      }

      const tutorialPorTitulo = tutorialesPorTitulo.find((t: Tutorial) => generateSlug(t.titulo) === tutorialSlug);
      if (!tutorialPorTitulo) {
        throw error(404, 'Tutorial no encontrado');
      }
      // Asignar el tutorial encontrado
      tutorialData = {
        ...tutorialPorTitulo,
        slug: tutorialPorTitulo.slug || generateSlug(tutorialPorTitulo.titulo)
      };
    } else {
      tutorialData = {
        ...tutorialPorSlug,
        slug: tutorialPorSlug.slug || generateSlug(tutorialPorSlug.titulo)
      };
    }

    // 2. Obtener todas las clases del tutorial, ordenadas
    const { data: clases, error: clasesError } = await supabase
      .from('partes_tutorial')
      .select('*')
      .eq('tutorial_id', tutorialData.id)
      .order('orden', { ascending: true });

    if (clasesError || !clases || clases.length === 0) {
      throw error(404, 'No se encontraron clases para este tutorial');
    }

    // 3. Asignar slugs a todas las clases si no los tienen
    const clasesConSlugs: Clase[] = clases.map((c: Clase) => ({
      ...c,
      slug: c.slug || generateSlug(c.titulo)
    }));

    // 4. Buscar la clase actual
    let claseActual = clasesConSlugs.find((c: Clase) => c.slug === claseSlug);
    if (!claseActual) {
      claseActual = clasesConSlugs.find((c: Clase) => generateSlug(c.titulo) === claseSlug);
    }
    if (!claseActual && !isNaN(Number(claseSlug))) {
      claseActual = clasesConSlugs.find((c: Clase) => String(c.id) === claseSlug);
    }
    if (!claseActual) {
      throw error(404, 'Clase no encontrada');
    }

    // 5. Obtener clases anterior y siguiente
    const indiceActual = clasesConSlugs.findIndex((c: Clase) => c.id === claseActual?.id);
    const claseAnterior = indiceActual > 0 ? clasesConSlugs[indiceActual - 1] : null;
    const claseSiguiente = indiceActual < clasesConSlugs.length - 1 ? clasesConSlugs[indiceActual + 1] : null;

    // 6. Retornar datos estructurados
    return {
      tutorial: tutorialData,
      clase: claseActual,
      clases: clasesConSlugs,
      claseAnterior,
      claseSiguiente
    };
  } catch (e) {
    console.error('Error cargando tutorial/clase:', e);
    throw error(500, 'Error interno del servidor');
  }
};
