import { supabase } from './clienteSupabase';

// Obtener la sesión actual del usuario
export const obtenerSesion = async () => {
  const { data, error } = await supabase.auth.getSession();
  if (error) return null;
  return data.session;
};

// Iniciar sesión con correo electrónico y contraseña
export const iniciarSesionConCorreo = async (correoElectronico, contrasena) => {
  const { data, error } = await supabase.auth.signInWithPassword({ email: correoElectronico, password: contrasena });
  if (error) return { usuario: null, error: error.message };
  return { usuario: data.user, error: null };
};

// Registrar un nuevo usuario y crear su perfil en la tabla 'perfiles' (incluyendo whatsapp y rol estudiante)
export const registrarUsuario = async (
  correoElectronico: string,
  contrasena: string,
  datosPerfil: { nombre?: string; apellido?: string; whatsapp?: string }
) => {
  const { data, error } = await supabase.auth.signUp({ email: correoElectronico, password: contrasena });
  if (error) return { usuario: null, error: error.message };
  if (data.user) {
    const perfilData = { id: data.user.id, correo_electronico: correoElectronico, rol: 'estudiante', ...datosPerfil };
    const resultado = await supabase
      .from('perfiles')
      .insert([perfilData]);
    if (resultado.error) {
      console.error('FALLA SUPABASE PERFIL:', {
        errorPerfil: resultado.error,
        perfilData,
        resultadoCompleto: resultado
      });
      return { usuario: null, error: resultado.error.message };
    }
    return { usuario: perfilData, error: null };

  }
  return { usuario: null, error: 'No se pudo registrar el usuario' };
};

// Cerrar sesión del usuario
export const cerrarSesion = async () => {
  const { error } = await supabase.auth.signOut();
  if (error) return error.message;
  return null;
};

// Obtener el perfil del usuario actual desde la tabla 'perfiles'
export const obtenerPerfil = async (id) => {
  const { data, error } = await supabase
    .from('perfiles')
    .select('*')
    .eq('id', id)
    .single();
  if (error) return { perfil: null, error: error.message };
  return { perfil: data, error: null };
};
