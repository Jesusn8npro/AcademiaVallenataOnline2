import { json } from '@sveltejs/kit';
import type { RequestHandler } from '@sveltejs/kit';
import { supabase } from '$lib/supabase/clienteSupabase';

export const GET: RequestHandler = async ({ url }) => {
  try {
    const userId = url.searchParams.get('userId');
    
    if (!userId) {
      return json({ error: 'Se requiere userId' }, { status: 400 });
    }
    
    // Verificar rol del usuario
    const { data: perfil, error: perfilError } = await supabase
      .from('perfiles')
      .select('id, nombre, rol')
      .eq('id', userId)
      .single();
    
    if (perfilError) {
      return json({ error: 'Error consultando perfil', details: perfilError }, { status: 500 });
    }
    
    // Consultar también todos los roles existentes
    const { data: todosRoles, error: rolesError } = await supabase
      .from('perfiles')
      .select('id, nombre, rol')
      .not('rol', 'eq', 'user')
      .limit(10);
    
    return json({
      usuario: perfil,
      todosRoles: todosRoles || [],
      mensaje: `El usuario ${perfil.nombre} tiene rol: ${perfil.rol}`
    });
    
  } catch (error) {
    console.error('Error en test-rol:', error);
    return json({ error: 'Error interno del servidor' }, { status: 500 });
  }
}; 