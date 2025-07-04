// @ts-nocheck
import { error } from '@sveltejs/kit';
import { obtenerCursoCompletoPorSlug } from '$lib/services/cursoService';

/** @param {Parameters<import('./$types').PageServerLoad>[0]} event */
export const load = async ({ params }) => {
  const { curso, error: cursoError } = await obtenerCursoCompletoPorSlug(params.slug);
  if (cursoError || !curso) {
    throw error(404, 'Curso no encontrado');
  }
  return { curso };
};
