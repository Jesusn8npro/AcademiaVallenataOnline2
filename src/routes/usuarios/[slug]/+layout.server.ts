import { error } from '@sveltejs/kit';
import { supabase } from '$lib/supabase/clienteSupabase';
import { coincideSlug } from '$lib/utilidades/utilidadesSlug';

export const load = async ({ params }: { params: { slug: string } }) => {
  const { slug } = params;

  try {
    console.log(`🔍 Buscando usuario por slug: ${slug}`);
    
    // 1️⃣ Intentar buscar por nombre_usuario exacto
    let { data: usuario, error: errorUsuario } = await supabase
      .from('perfiles')
      .select('*')
      .eq('nombre_usuario', slug)
      .single();
      
    console.log(`📊 Resultado consulta por nombre_usuario:`, { usuario, errorUsuario });

    // 2️⃣ Si no se encuentra, buscar usando función de coincidencia de slug
    if (errorUsuario || !usuario) {
      console.log(`🔄 Intentando búsqueda por coincidencia de slug`);
      
      const { data: usuarios, error: errorBusqueda } = await supabase
        .from('perfiles')
        .select('*');
        
      if (!errorBusqueda && usuarios) {
        // Buscar usuario usando la función de coincidencia
        usuario = usuarios.find((u: any) => coincideSlug(u, slug));
        
        console.log(`📊 Usuario encontrado por coincidencia:`, usuario ? `${usuario.nombre} ${usuario.apellido || ''}`.trim() : 'No encontrado');
      }
    }

    if (!usuario) {
      throw error(404, `Usuario ${slug} no encontrado`);
    }

    // Cargar estadísticas del usuario
    const [cursosResult, publicacionesResult, inscripcionesResult] = await Promise.allSettled([
      // Contar cursos creados por el usuario (si es instructor)
      supabase
        .from('cursos')
        .select('id', { count: 'exact', head: true })
        .eq('creado_por', usuario.id),
      
      // Contar publicaciones del usuario
      supabase
        .from('comunidad_publicaciones')
        .select('id', { count: 'exact', head: true })
        .eq('usuario_id', usuario.id),
      
      // Contar inscripciones del usuario
      supabase
        .from('inscripciones')
        .select('id', { count: 'exact', head: true })
        .eq('usuario_id', usuario.id)
    ]);

    const estadisticas = {
      cursos_creados: cursosResult.status === 'fulfilled' ? cursosResult.value.count || 0 : 0,
      publicaciones: publicacionesResult.status === 'fulfilled' ? publicacionesResult.value.count || 0 : 0,
      cursos_inscritos: inscripcionesResult.status === 'fulfilled' ? inscripcionesResult.value.count || 0 : 0
    };

    const resultado = {
      usuarioPublico: {
        ...usuario,
        estadisticas
      }
    };
    
    console.log('🎯 DEVOLVIENDO DATOS AL CLIENTE:', resultado);
    return resultado;

  } catch (err) {
    console.error('Error cargando perfil público:', err);
    throw error(404, `Usuario ${slug} no encontrado`);
  }
}; 