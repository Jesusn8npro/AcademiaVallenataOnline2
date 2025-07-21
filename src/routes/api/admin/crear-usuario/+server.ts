import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase/clienteSupabase';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request }) => {
  try {
    const { 
      nombre, 
      apellido, 
      nombre_usuario: nombre_usuario_input, 
      correo_electronico, 
      password, 
      rol, 
      suscripcion,
      ciudad,
      pais,
      whatsapp,
      nivel_habilidad,
      documento_tipo,
      documento_numero,
      profesion,
      instrumento
    } = await request.json();

    console.log(`Creando usuario: ${correo_electronico}`);

    // Validaciones básicas
    if (!nombre || !apellido || !correo_electronico || !password) {
      return json({ error: 'Todos los campos obligatorios son requeridos' }, { status: 400 });
    }

    // Generar nombre de usuario automáticamente si no se proporciona
    let nombre_usuario = nombre_usuario_input;
    if (!nombre_usuario || nombre_usuario.trim() === '') {
      // Generar nombre de usuario basado en nombre y apellido
      const baseUsername = (nombre + apellido).toLowerCase()
        .replace(/\s+/g, '')
        .replace(/[^a-zA-Z0-9]/g, '')
        .substring(0, 12);
      
      // Agregar número aleatorio para unicidad
      const randomNum = Math.floor(Math.random() * 1000);
      nombre_usuario = `${baseUsername}${randomNum}`;
    }

    // Verificar si el email ya existe
    const { data: existingEmail } = await supabase
      .from('perfiles')
      .select('correo_electronico')
      .eq('correo_electronico', correo_electronico.toLowerCase())
      .single();

    if (existingEmail) {
      return json({ error: 'Ya existe un usuario registrado con este correo electrónico' }, { status: 400 });
    }

    // Verificar si el nombre de usuario ya existe y generar uno único si es necesario
    let usernameExists = true;
    let attempts = 0;
    while (usernameExists && attempts < 10) {
      const { data: existingUsername } = await supabase
        .from('perfiles')
        .select('nombre_usuario')
        .eq('nombre_usuario', nombre_usuario)
        .single();

      if (!existingUsername) {
        usernameExists = false;
      } else {
        // Si ya existe, generar uno nuevo
        const baseUsername = (nombre + apellido).toLowerCase()
          .replace(/\s+/g, '')
          .replace(/[^a-zA-Z0-9]/g, '')
          .substring(0, 12);
        
        const randomNum = Math.floor(Math.random() * 10000);
        nombre_usuario = `${baseUsername}${randomNum}`;
        attempts++;
      }
    }

    if (usernameExists) {
      return json({ error: 'No se pudo generar un nombre de usuario único' }, { status: 500 });
    }

    // Crear usuario usando signup
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: correo_electronico.toLowerCase(),
      password: password,
      options: {
        data: {
          nombre: nombre,
          apellido: apellido,
          nombre_usuario: nombre_usuario
        }
      }
    });

    if (authError) {
      console.error('Error al crear usuario en Auth:', authError);
      return json({ error: `Error de autenticación: ${authError.message}` }, { status: 500 });
    }

    if (!authData.user) {
      return json({ error: 'No se pudo crear el usuario' }, { status: 500 });
    }

    // Crear perfil del usuario
    const perfilData = {
      id: authData.user.id,
      nombre: nombre,
      apellido: apellido,
      nombre_usuario: nombre_usuario,
      nombre_completo: `${nombre} ${apellido}`,
      correo_electronico: correo_electronico.toLowerCase(),
      rol: rol || 'estudiante',
      suscripcion: suscripcion || 'free',
      ciudad: ciudad || null,
      pais: pais || null,
      whatsapp: whatsapp || null,
      nivel_habilidad: nivel_habilidad || null,
      documento_tipo: documento_tipo || 'CC',
      documento_numero: documento_numero || null,
      profesion: profesion || null,
      instrumento: instrumento || 'acordeon',
      eliminado: false
    };

    const { error: profileError } = await supabase
      .from('perfiles')
      .insert(perfilData);

    if (profileError) {
      console.error('Error al crear perfil:', profileError);
      return json({ error: `Error al crear el perfil: ${profileError.message}` }, { status: 500 });
    }

    console.log(`Usuario creado exitosamente: ${correo_electronico}`);

    // Respuesta exitosa
    return json({
      success: true,
      message: 'Usuario creado exitosamente',
      usuario: {
        id: authData.user.id,
        correo_electronico: correo_electronico,
        nombre: nombre,
        apellido: apellido,
        nombre_usuario: nombre_usuario,
        rol: rol || 'estudiante'
      }
    }, { status: 200 });

  } catch (error: any) {
    console.error('Error inesperado:', error);
    return json({ error: `Error inesperado: ${error.message}` }, { status: 500 });
  }
}; 