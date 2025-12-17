import type { PageServerLoad } from './$types';
import { obtenerCursoCompletoPorSlug } from '$lib/services/cursoService';
import { error } from '@sveltejs/kit';
import { generateSlug } from '$lib/utilidades/utilidadesSlug';

export const load = (async ({ params }) => {
  const { slug, modulo, leccion } = params;
  const { curso, error: cursoError } = await obtenerCursoCompletoPorSlug(slug);

  if (cursoError || !curso) {
    throw error(404, {
      message: 'Curso no encontrado'
    });
  }

  // Buscar el módulo por slug
  let moduloEncontrado = null;
  let leccionEncontrada = null;
  if (curso.modulos && curso.modulos.length > 0) {
    for (const mod of curso.modulos) {
      const slugModulo = mod.slug || generateSlug(mod.titulo);
      if (slugModulo === modulo) {
        moduloEncontrado = mod;
        break;
      }
    }
    if (!moduloEncontrado) {
      moduloEncontrado = curso.modulos[0];
    }
    // Buscar la lección dentro del módulo
    if (moduloEncontrado && moduloEncontrado.lecciones && moduloEncontrado.lecciones.length > 0) {
      for (const lec of moduloEncontrado.lecciones) {
        const slugLeccion = lec.slug || generateSlug(lec.titulo);
        if (slugLeccion === leccion) {
          leccionEncontrada = lec;
          break;
        }
      }
      if (!leccionEncontrada) {
        leccionEncontrada = moduloEncontrado.lecciones[0];
      }
    }
  }

  // Obtener lección anterior y siguiente
  const todasLasLecciones = [];
  if (curso.modulos) {
    curso.modulos.forEach(mod => {
      if (mod.lecciones) {
        mod.lecciones.forEach(lec => {
          todasLasLecciones.push({
            ...lec,
            modulo_id: mod.id,
            modulo_titulo: mod.titulo,
            modulo_slug: mod.slug || generateSlug(mod.titulo)
          });
        });
      }
    });
  }
  // Ordenar lecciones por módulo y orden
  todasLasLecciones.sort((a, b) => {
    const moduloA = curso.modulos.find(m => m.id === a.modulo_id);
    const moduloB = curso.modulos.find(m => m.id === b.modulo_id);
    if (moduloA.orden !== moduloB.orden) {
      return moduloA.orden - moduloB.orden;
    }
    return a.orden - b.orden;
  });
  const leccionIndex = leccionEncontrada ? todasLasLecciones.findIndex(l => l.id === leccionEncontrada.id) : -1;
  const leccionAnterior = leccionIndex > 0 ? todasLasLecciones[leccionIndex - 1] : null;
  const leccionSiguiente = leccionIndex < todasLasLecciones.length - 1 ? todasLasLecciones[leccionIndex + 1] : null;

  return {
    curso,
    modulo: moduloEncontrado,
    leccion: leccionEncontrada,
    leccionAnterior,
    leccionSiguiente,
    params
  };
}) satisfies PageServerLoad;
