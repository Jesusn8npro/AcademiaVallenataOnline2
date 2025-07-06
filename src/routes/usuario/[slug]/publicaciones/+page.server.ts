import { supabase } from '$lib/supabase/clienteSupabase';
import { error } from '@sveltejs/kit';

export async function load({ params }) {
  const { slug } = params;
  
  try {
    // Obtener perfil por nombre_usuario (slug)
    const { data: perfil, error: errorPerfil } = await supabase
      .from('perfiles')
      .select('*')
      .eq('nombre_usuario', slug)
      .single();
      
    if (errorPerfil || !perfil) {
      throw error(404, `Usuario @${slug} no encontrado`);
    }
    
    return {
      perfil,
      slug
    };
  } catch (err) {
    console.error('Error en load:', err);
    throw error(500, 'Error interno del servidor');
  }
} 