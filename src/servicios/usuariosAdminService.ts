import { supabase } from '../servicios/supabaseCliente'

export interface UsuarioAdmin {
  id: string
  nombre?: string | null
  apellido?: string | null
  nombre_completo?: string | null
  correo_electronico?: string | null
  url_foto_perfil?: string | null
  ciudad?: string | null
  pais?: string | null
  rol?: string | null
  suscripcion?: string | null
  fecha_creacion?: string | null
}

export interface EstadisticasUsuarios {
  total: number
  activos: number
  estudiantes: number
  instructores: number
}

export async function cargarUsuarios(mostrarEliminados = false): Promise<UsuarioAdmin[]> {
  const { data } = await supabase
    .from('perfiles')
    .select('id,nombre,apellido,nombre_completo,correo_electronico,url_foto_perfil,ciudad,pais,rol,suscripcion,fecha_creacion')
    .order('fecha_creacion', { ascending: false })
  const usuarios = (data || []) as UsuarioAdmin[]
  return mostrarEliminados ? usuarios : usuarios
}

export function calcularEstadisticas(usuarios: UsuarioAdmin[]): EstadisticasUsuarios {
  const total = usuarios.length
  const activos = usuarios.filter(u => (u.suscripcion || '').toLowerCase() !== 'cancelada').length
  const estudiantes = usuarios.filter(u => (u.rol || '').toLowerCase() === 'estudiante').length
  const instructores = usuarios.filter(u => (u.rol || '').toLowerCase() === 'instructor').length
  return { total, activos, estudiantes, instructores }
}

export async function eliminarUsuario(id: string): Promise<{ success: boolean; error?: string }> {
  try {
    const { error } = await supabase.from('perfiles').delete().eq('id', id)
    if (error) throw error
    return { success: true }
  } catch (e: any) {
    return { success: false, error: e.message }
  }
}

export async function crearUsuario(datos: any): Promise<{ success: boolean; data?: any; error?: string }> {
  try {
    const { data: signData, error: signError } = await supabase.auth.signUp({
      email: datos.correo_electronico,
      password: datos.password,
      options: {
        data: {
          nombre: datos.nombre,
          apellido: datos.apellido,
          nombre_usuario: datos.nombre_usuario || null
        }
      }
    })
    if (signError) throw signError
    const userId = signData.user?.id
    const nombre_completo = `${datos.nombre || ''} ${datos.apellido || ''}`.trim()
    const perfil = {
      id: userId,
      nombre: datos.nombre || null,
      apellido: datos.apellido || null,
      nombre_completo,
      correo_electronico: datos.correo_electronico,
      ciudad: datos.ciudad || null,
      pais: datos.pais || null,
      rol: datos.rol || 'estudiante',
      suscripcion: datos.suscripcion || 'free',
      fecha_creacion: new Date().toISOString(),
      url_foto_perfil: null
    }
    const { data: perfilData, error: perfilError } = await supabase
      .from('perfiles')
      .insert(perfil)
      .select()
      .single()
    if (perfilError) throw perfilError
    return { success: true, data: perfilData }
  } catch (e: any) {
    return { success: false, error: e.message }
  }
}

export async function actualizarUsuario(id: string, cambios: any): Promise<{ success: boolean; data?: any; error?: string }> {
  try {
    const { data, error } = await supabase
      .from('perfiles')
      .update(cambios)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return { success: true, data }
  } catch (e: any) {
    return { success: false, error: e.message }
  }
}
