import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase/clienteSupabase';

export async function GET() {
  try {
    // Obtener todos los perfiles con nombre_usuario no nulo
    const { data, error } = await supabase
      .from('perfiles')
      .select('id, nombre_usuario, nombre_completo, nombre')
      .not('nombre_usuario', 'is', null)
      .limit(10);

    if (error) {
      return json({ error: error.message }, { status: 500 });
    }

    return json({ 
      perfiles: data,
      total: data?.length || 0,
      message: 'Usuarios con nombre_usuario configurado'
    });

  } catch (err) {
    return json({ error: 'Error interno del servidor' }, { status: 500 });
  }
} 