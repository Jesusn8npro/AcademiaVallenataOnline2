// @ts-nocheck
import { error } from '@sveltejs/kit';
import { supabase } from '$lib/supabase/clienteSupabase';

/** @param {Parameters<import('./$types').PageServerLoad>[0]} event */
export async function load({ params }) {
  try {
    // Obtener datos del tutorial por slug
    // Traer todos los tutoriales y buscar el que coincida el slug generado con el de la URL
    const { data: tutoriales, error: tutorialError } = await supabase
      .from('tutoriales')
      .select('*');
    if (tutorialError) {
      throw tutorialError;
    }
    // Requiere la función generateSlug
    const { generateSlug } = await import('$lib/utilidades/utilidadesSlug');
    const tutorial = (tutoriales || []).find(t => generateSlug(t.titulo) === params.slug);
    if (!tutorial) {
      throw error(404, 'Tutorial no encontrado');
    }
    
    return {
      tutorial
    };
  } catch (err) {
    console.error('Error al cargar datos del tutorial:', err);
    throw error(500, 'Error al cargar el tutorial');
  }
} 