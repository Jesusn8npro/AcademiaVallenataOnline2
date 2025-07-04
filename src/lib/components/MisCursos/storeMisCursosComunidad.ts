import { writable } from 'svelte/store';
import { supabase } from '$lib/supabase/clienteSupabase';
import { obtenerSesion } from '$lib/supabase/autenticacionSupabase';

export const inscripcionesComunidad = writable({
  inscripciones: [],
  isLoading: true,
  error: null
});

export async function cargarInscripcionesComunidad() {
  inscripcionesComunidad.set({ inscripciones: [], isLoading: true, error: null });

  try {
    const sesion = await obtenerSesion();
    if (!sesion?.user) {
      inscripcionesComunidad.set({ inscripciones: [], isLoading: false, error: 'No autenticado' });
      return;
    }

    // Obtener inscripciones básicas
    const { data: inscripcionesData, error: err1 } = await supabase
      .from('inscripciones')
      .select(`id, curso_id, tutorial_id, usuario_id, progreso, completado, fecha_inscripcion`)
      .eq('usuario_id', sesion.user.id);

    if (err1) {
      inscripcionesComunidad.set({ inscripciones: [], isLoading: false, error: 'Error al cargar tus inscripciones.' });
      return;
    }

    if (!inscripcionesData || inscripcionesData.length === 0) {
      inscripcionesComunidad.set({ inscripciones: [], isLoading: false, error: null });
      return;
    }

    // Obtener datos de cursos
    const cursoIds = inscripcionesData.map(insc => insc.curso_id).filter(id => !!id);
    const tutorialIds = inscripcionesData.map(insc => insc.tutorial_id).filter(id => !!id);

    let cursosData = [];
    if (cursoIds.length) {
      const { data: cursos } = await supabase
        .from('cursos')
        .select('id, slug, titulo, imagen_url')
        .in('id', cursoIds);
      cursosData = cursos || [];
    }

    let tutorialesData = [];
    if (tutorialIds.length) {
      const { data: tutoriales } = await supabase
        .from('tutoriales')
        .select('id, slug, titulo, imagen_url')
        .in('id', tutorialIds);
      tutorialesData = tutoriales || [];
    }

    // Mapear resultados
    const cursosMap = new Map();
    cursosData.forEach(curso => cursosMap.set(curso.id, curso));
    
    const tutorialesMap = new Map();
    tutorialesData.forEach(tut => tutorialesMap.set(tut.id, tut));

    const uniqueMap = new Map();
    
    for (const insc of inscripcionesData) {
      let key = null;
      let obj = null;

      if (insc.curso_id && cursosMap.has(insc.curso_id)) {
        key = `curso-${insc.curso_id}`;
        obj = {
          ...insc,
          curso: cursosMap.get(insc.curso_id)
        };
      } else if (insc.tutorial_id && tutorialesMap.has(insc.tutorial_id)) {
        key = `tutorial-${insc.tutorial_id}`;
        obj = {
          ...insc,
          tutorial: tutorialesMap.get(insc.tutorial_id)
        };
      }

      if (key && obj && !uniqueMap.has(key)) {
        uniqueMap.set(key, obj);
      }
    }

    inscripcionesComunidad.set({
      inscripciones: Array.from(uniqueMap.values()),
      isLoading: false,
      error: null
    });

  } catch (err) {
    console.error('Error inesperado en cargarInscripcionesComunidad:', err);
    inscripcionesComunidad.set({
      inscripciones: [],
      isLoading: false,
      error: 'Ocurrió un error inesperado.'
    });
  }
}
