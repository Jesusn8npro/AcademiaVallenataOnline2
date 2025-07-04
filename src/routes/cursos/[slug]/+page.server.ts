import { error } from '@sveltejs/kit';
import { obtenerCursoCompletoPorSlug } from '$lib/services/cursoService';

/** @type {import('./$types').PageServerLoad} */
export const load = async ({ params }) => {
  const { curso, error: cursoError } = await obtenerCursoCompletoPorSlug(params.slug);
  if (cursoError || !curso) {
    throw error(404, 'Curso no encontrado');
  }
  return { curso };
};
