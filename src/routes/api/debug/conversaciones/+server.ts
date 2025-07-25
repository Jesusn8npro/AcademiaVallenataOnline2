import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase/clienteSupabase';

export async function GET({ url }) {
  const chatId = url.searchParams.get('chatId');
  
  if (!chatId) {
    return json({ error: 'chatId es requerido' }, { status: 400 });
  }

  try {
    console.log('🔍 ANÁLISIS COMPLETO para chatId:', chatId);

    // 🔧 PASO 1: PROBAR INSERTAR UN MENSAJE DE PRUEBA con estructura correcta
    const mensajePrueba = {
      session_id: chatId,
      chat_id: chatId,
      message: {
        texto: `Mensaje de prueba - ${new Date().toISOString()}`,
        tipo: 'usuario',
        es_usuario_registrado: false,
        metadata: { debug: true }
      }
    };

    const { data: insertResult, error: insertError } = await supabase
      .from('chats_envivo_academia')
      .insert([mensajePrueba])
      .select();

    console.log('🔧 Resultado insertar:', insertResult, 'Error:', insertError);

    // 🔧 PASO 2: Intentar leer inmediatamente después de insertar
    const { data: lecturaInmediata, error: errorLectura } = await supabase
      .from('chats_envivo_academia')
      .select('*')
      .or(`session_id.eq.${chatId},chat_id.eq.${chatId}`)
      .order('created_at', { ascending: false })
      .limit(5);

    console.log('📖 Lectura inmediata:', lecturaInmediata, 'Error:', errorLectura);

    // 🔧 PASO 3: Verificar conteo total
    const { data: todasFilas, error: errorTodas, count } = await supabase
      .from('chats_envivo_academia')
      .select('*', { count: 'exact' })
      .limit(10);

    // 🔧 PASO 4: Información del lead
    const { data: lead, error: leadError } = await supabase
      .from('leads_chat_anonimos')
      .select('*')
      .eq('chat_id', chatId)
      .single();

    return json({
      chatId,
      pruebas: {
        insertar: { 
          exitoso: !!insertResult,
          datos: insertResult, 
          error: insertError?.message || insertError 
        },
        lecturaInmediata: { 
          exitoso: !!lecturaInmediata && lecturaInmediata.length > 0,
          count: lecturaInmediata?.length || 0,
          datos: lecturaInmediata, 
          error: errorLectura?.message || errorLectura 
        },
        lecturaGeneral: {
          totalEnBD: count,
          primerasFilas: todasFilas,
          error: errorTodas?.message || errorTodas
        }
      },
      lead: { data: lead, error: leadError?.message || leadError },
      diagnostico: {
        puedeInsertar: !insertError,
        puedeLeer: !errorLectura && lecturaInmediata && lecturaInmediata.length > 0,
        problemaRLS: insertError ? false : (!errorLectura && lecturaInmediata && lecturaInmediata.length === 0),
        estructuraCorrecta: !insertError
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error general:', error);
    return json({ error: 'Error interno del servidor', details: String(error) }, { status: 500 });
  }
} 