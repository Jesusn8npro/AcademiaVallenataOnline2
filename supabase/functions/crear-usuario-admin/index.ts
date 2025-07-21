import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

console.log("Edge Function: crear-usuario-admin iniciada");

// Cliente Supabase con permisos de administrador
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};

serve(async (req) => {
  // Manejar preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { 
      nombre, 
      apellido, 
      nombre_usuario, 
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
    } = await req.json();

    console.log(`Creando usuario: ${correo_electronico}`);

    // Validaciones básicas
    if (!nombre || !apellido || !nombre_usuario || !correo_electronico || !password) {
      return new Response(
        JSON.stringify({ error: 'Todos los campos obligatorios son requeridos' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // Verificar si el email ya existe
    const { data: existingEmail } = await supabaseAdmin
      .from('perfiles')
      .select('correo_electronico')
      .eq('correo_electronico', correo_electronico.toLowerCase())
      .single();

    if (existingEmail) {
      return new Response(
        JSON.stringify({ error: 'Ya existe un usuario registrado con este correo electrónico' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // Verificar si el nombre de usuario ya existe
    const { data: existingUsername } = await supabaseAdmin
      .from('perfiles')
      .select('nombre_usuario')
      .eq('nombre_usuario', nombre_usuario)
      .single();

    if (existingUsername) {
      return new Response(
        JSON.stringify({ error: 'Este nombre de usuario ya está en uso' }),
        { headers: corsHeaders, status: 400 }
      );
    }

    // Crear usuario usando Admin API (NO afecta la sesión del cliente)
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: correo_electronico.toLowerCase(),
      password: password,
      email_confirm: true, // Confirmar email automáticamente
      user_metadata: {
        nombre: nombre,
        apellido: apellido,
        nombre_usuario: nombre_usuario
      }
    });

    if (authError) {
      console.error('Error al crear usuario en Auth:', authError);
      return new Response(
        JSON.stringify({ error: `Error de autenticación: ${authError.message}` }),
        { headers: corsHeaders, status: 500 }
      );
    }

    if (!authData.user) {
      return new Response(
        JSON.stringify({ error: 'No se pudo crear el usuario' }),
        { headers: corsHeaders, status: 500 }
      );
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

    const { error: profileError } = await supabaseAdmin
      .from('perfiles')
      .insert(perfilData);

    if (profileError) {
      console.error('Error al crear perfil:', profileError);
      return new Response(
        JSON.stringify({ error: `Error al crear el perfil: ${profileError.message}` }),
        { headers: corsHeaders, status: 500 }
      );
    }

    console.log(`Usuario creado exitosamente: ${correo_electronico}`);

    // Respuesta exitosa
    return new Response(
      JSON.stringify({
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
      }),
      { headers: corsHeaders, status: 200 }
    );

  } catch (error) {
    console.error('Error inesperado:', error);
    return new Response(
      JSON.stringify({ error: `Error inesperado: ${error.message}` }),
      { headers: corsHeaders, status: 500 }
    );
  }
}); 