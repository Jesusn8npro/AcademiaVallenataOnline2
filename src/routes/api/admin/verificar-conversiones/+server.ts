import { json } from '@sveltejs/kit';
import { leadsService } from '$lib/services/leadsService';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request }) => {
  try {
    console.log('🔄 Iniciando verificación de conversiones...');
    
    // Ejecutar verificación automática
    const conversiones = await leadsService.verificarConversiones();
    
    console.log(`✅ Verificación completada. ${conversiones} leads convertidos.`);
    
    return json({
      success: true,
      message: `Verificación completada exitosamente`,
      conversiones: conversiones,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Error en verificación de conversiones:', error);
    
    return json({
      success: false,
      error: error instanceof Error ? error.message : 'Error desconocido',
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}; 