import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase/clienteSupabase';

export async function GET({ url }) {
  const chatId = url.searchParams.get('chatId') || 'guest_U2hhbG9t_2025-07-23';
  
  try {
    console.log('🧪 TEST: Obteniendo conversaciones para:', chatId);
    
    // Simular datos del lead
    const lead = { chat_id: chatId };
    
    // Obtener datos raw de Supabase
    const { data: conversaciones, error } = await supabase
      .from('chats_envivo_academia')
      .select('*')
      .or(`session_id.eq.${chatId},chat_id.eq.${chatId}`)
      .order('created_at', { ascending: true });

    if (error) {
      return json({ error: error.message }, { status: 500 });
    }

    console.log('📖 Conversaciones raw:', conversaciones?.length);

    // Aplicar el mismo mapeo que en el dashboard
    const conversacionesMapeadas = conversaciones?.map((conv) => {
      let mensaje = '';
      let tipo = 'usuario';
      let timestamp = conv.created_at;

      // Verificar si message es objeto JSONB
      if (conv.message && typeof conv.message === 'object') {
        // Estructura de N8N (bot)
        if (conv.message.content) {
          mensaje = conv.message.content;
          tipo = conv.message.type === 'ai' ? 'bot' : 'usuario';
        }
        // Estructura de nuestra app (usuario)
        else if (conv.message.texto) {
          mensaje = conv.message.texto;
          tipo = conv.message.tipo || 'usuario';
        }
        // Fallback para otros casos
        else {
          mensaje = JSON.stringify(conv.message);
          tipo = 'sistema';
        }
      } else {
        // Si message no es objeto, usarlo directamente
        mensaje = conv.message || 'Mensaje vacío';
      }

      return {
        id: conv.id,
        mensaje: mensaje,
        tipo_mensaje: tipo,
        timestamp: timestamp,
        created_at: timestamp,
        metadata: conv.message?.metadata || {}
      };
    }) || [];

    return json({
      chatId,
      totalRaw: conversaciones?.length || 0,
      totalMapeadas: conversacionesMapeadas.length,
      conversacionesRaw: conversaciones,
      conversacionesMapeadas: conversacionesMapeadas,
      exito: true
    });

  } catch (error) {
    console.error('❌ Error en test:', error);
    return json({ error: String(error) }, { status: 500 });
  }
} 