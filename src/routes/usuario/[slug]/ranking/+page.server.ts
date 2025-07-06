import { error, redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
  const { slug } = params;

  try {
    // Reutilizar la misma lógica del perfil público
    const { supabase } = locals as any;

    // Intentar encontrar por nombre_usuario primero
    let { data: perfil, error: errorPerfil } = await supabase
      .from('perfiles')
      .select('*')
      .eq('nombre_usuario', slug)
      .single();
      
    // Si no encuentra por nombre_usuario, buscar por slug generado
    if (errorPerfil || !perfil) {
      const { data: perfiles, error: errorBusqueda } = await supabase
        .from('perfiles')
        .select('*');
        
      if (perfiles && !errorBusqueda) {
        // Buscar por slug generado
        perfil = perfiles.find((p: any) => {
          const nombreCompleto = `${p.nombre || ''} ${p.apellido || ''}`.trim();
          const slugGenerado = p.nombre_usuario || 
            nombreCompleto.toLowerCase()
              .replace(/\s+/g, '-')
              .replace(/[^a-z0-9-]/g, '')
              .replace(/-+/g, '-')
              .replace(/^-|-$/g, '') || 
            `usuario-${p.id.slice(0, 8)}`;
          return slugGenerado === slug;
        });
      }
      
      if (!perfil) {
        throw error(404, `Usuario @${slug} no encontrado`);
      }
    }

    // Verificar si es el usuario actual
    const sesion = await (locals as any).getSession?.() || null;
    const esUsuarioPropio = sesion?.user?.id === perfil.id;

    // Si es el propio usuario, redirigir a su perfil privado
    if (esUsuarioPropio) {
      throw redirect(302, '/ranking');
    }

    return {
      perfil,
      esUsuarioPropio: false
    };
  } catch (err) {
    if (err instanceof Error && 'status' in err) {
      throw err;
    }
    throw error(500, 'Error interno del servidor');
  }
}; 