import { supabase } from '$lib/supabase/clienteSupabase';
import { error } from '@sveltejs/kit';

export async function load({ params, locals }) {
  const { slug } = params;
  
  try {
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
    }
    
    if (!perfil) {
      throw error(404, `Usuario @${slug} no encontrado`);
    }
    
    // Verificar si es el usuario actual
    const sesion = await (locals as any).getSession?.() || null;
    const esUsuarioActual = sesion?.user?.id === perfil.id;
    
    // Cargar estadísticas (mismo código que perfilStore)
    const [publicacionesResult, cursosResult, tutorialesResult, rankingResult] = await Promise.all([
      supabase.from('comunidad_publicaciones').select('*', { count: 'exact', head: true }).eq('usuario_id', perfil.id),
      supabase.from('inscripciones').select('*', { count: 'exact', head: true }).eq('usuario_id', perfil.id),
      supabase.from('progreso_tutorial').select('*', { count: 'exact', head: true }).eq('usuario_id', perfil.id).eq('completado', true),
      supabase.from('perfiles').select('id').order('puntos_comunidad', { ascending: false })
    ]);

    const posicionRanking = rankingResult.data ? 
      rankingResult.data.findIndex((p: any) => p.id === perfil.id) + 1 : 0;

    const stats = {
      publicaciones: publicacionesResult.count || 0,
      cursos: cursosResult.count || 0,
      tutoriales: tutorialesResult.count || 0,
      ranking: posicionRanking || 0
    };
    
    return {
      perfil,
      stats,
      esUsuarioActual,
      slug
    };
  } catch (err) {
    console.error('Error cargando perfil:', err);
    throw error(404, `Usuario @${slug} no encontrado`);
  }
} 