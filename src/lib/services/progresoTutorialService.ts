import { supabase } from '$lib/supabase';
import { get } from 'svelte/store';
import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';

/**
 * Marca el progreso de una parte de tutorial para el usuario actual
 */
export async function actualizarProgresoTutorial(parteId: string, completada: boolean, tutorialId?: string) {
  const { user } = get(estadoUsuarioActual);
  
  if (!user || !user.id) {
    console.error('[PROGRESO] Usuario no autenticado');
    return { error: { message: 'Usuario no autenticado' } };
  }
  
  if (!tutorialId || !parteId) {
    console.error('[PROGRESO] Faltan campos obligatorios', { usuario_id: user.id, tutorial_id: tutorialId, parte_tutorial_id: parteId });
    return { error: { message: 'Faltan campos obligatorios', payload: { usuario_id: user.id, tutorial_id: tutorialId, parte_tutorial_id: parteId } } };
  }
  
  try {
    // Busca si ya existe el registro
    const { data: progresoExistente, error: errorBusqueda } = await supabase
      .from('progreso_tutorial')
      .select('*')
      .eq('usuario_id', user.id)
      .eq('parte_tutorial_id', parteId)
      .maybeSingle();

    let resultado;
    if (errorBusqueda && errorBusqueda.code !== 'PGRST116') {
      console.error('[PROGRESO] Error buscando progreso existente:', errorBusqueda);
      return { error: { message: 'Error buscando progreso existente', detail: errorBusqueda } };
    }
    
    if (progresoExistente) {
      // Ya existe, actualiza
      resultado = await supabase
        .from('progreso_tutorial')
        .update({
          completado: completada,
          fecha_actualizacion: new Date().toISOString()
        })
        .eq('id', progresoExistente.id);
        
      if (resultado.error) {
        console.error('[PROGRESO] Error UPDATE:', resultado.error);
        return { error: { message: resultado.error.message, detail: resultado.error } };
      }
    } else {
      // No existe, inserta
      const payload = {
        usuario_id: user.id,
        tutorial_id: tutorialId,
        parte_tutorial_id: parteId,
        completado: completada,
        fecha_inicio: new Date().toISOString(),
        fecha_actualizacion: new Date().toISOString()
      };
      
      resultado = await supabase
        .from('progreso_tutorial')
        .insert([payload]);
        
      if (resultado.error) {
        console.error('[PROGRESO] Error INSERT:', resultado.error);
        return { error: { message: resultado.error.message, detail: resultado.error, payload } };
      }
    }
    return { data: resultado?.data, error: resultado?.error };
  } catch (err) {
    console.error('[PROGRESO] Error inesperado al actualizar progreso:', err);
    return { error: { message: 'Error inesperado al actualizar progreso', detail: err } };
  }
}

/**
 * Obtiene el progreso de una parte específica del tutorial para el usuario actual
 */
export async function obtenerProgresoTutorialDeParte(parteId: string) {
  const { user } = get(estadoUsuarioActual);
  
  if (!user || !user.id) {
    return { data: null, error: { message: 'Usuario no autenticado' } };
  }
  
  try {
    const { data, error } = await supabase
      .from('progreso_tutorial')
      .select('*')
      .eq('usuario_id', user.id)
      .eq('parte_tutorial_id', parteId)
      .single();
      
    return { data, error };
  } catch (err) {
    console.error('Error al obtener progreso de la parte:', err);
    return { data: null, error: { message: 'Error al obtener progreso de la parte' } };
  }
}

/**
 * Obtiene el progreso general del tutorial para el usuario actual
 */
export async function obtenerProgresoTutorial(tutorialId: string) {
  const { user } = get(estadoUsuarioActual);
  
  if (!user || !user.id) {
    return { data: null, error: { message: 'Usuario no autenticado' } };
  }
  
  try {
    // Obtener todas las partes del tutorial
    const { data: partes, error: errorPartes } = await supabase
      .from('partes_tutorial')
      .select('id')
      .eq('tutorial_id', tutorialId);
      
    if (errorPartes) {
      return { data: null, error: errorPartes };
    }
    
    if (!partes || partes.length === 0) {
      return { data: { progreso: 0, partes_completadas: 0, total_partes: 0 }, error: null };
    }
    
    const parteIds = partes.map(p => p.id);
    // Obtener progreso del usuario en esas partes
    const { data: progreso, error: errorProgreso } = await supabase
      .from('progreso_tutorial')
      .select('*')
      .eq('usuario_id', user.id)
      .in('parte_tutorial_id', parteIds);
    
    if (errorProgreso) {
      console.error('[ERROR] Error al obtener progreso del tutorial:', errorProgreso);
      return { data: null, error: errorProgreso };
    }
    
    const partesCompletadas = progreso ? progreso.filter(p => p.completado).length : 0;
    const totalPartes = partes.length;
    const porcentajeProgreso = totalPartes > 0 ? Math.round((partesCompletadas / totalPartes) * 100) : 0;
    
    return {
      data: {
        progreso: porcentajeProgreso,
        partes_completadas: partesCompletadas,
        total_partes: totalPartes,
        detalle: progreso || []
      },
      error: null
    };
  } catch (err) {
    console.error('Error al obtener progreso del tutorial:', err);
    return { data: null, error: { message: 'Error al obtener progreso del tutorial' } };
  }
}

/**
 * Verifica si una parte del tutorial está completada
 */
export async function verificarParteCompletada(tutorialId: string, parteId: string) {
  const { data, error } = await obtenerProgresoTutorialDeParte(parteId);
  
  if (error || !data) {
    return false;
  }
  
  return data.completado;
}
