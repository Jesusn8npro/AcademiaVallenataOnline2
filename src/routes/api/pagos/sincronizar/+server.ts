import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { sincronizarEstadoConEpayco } from '$lib/services/pagoService';

// ✅ ENDPOINT PARA SINCRONIZAR PAGOS PENDIENTES MANUALMENTE
export const POST: RequestHandler = async ({ request }) => {
	try {
		const { refPayco } = await request.json();
		
		if (!refPayco) {
			return json({ success: false, error: 'Referencia de pago requerida' }, { status: 400 });
		}
		
		console.log('🔄 Sincronización manual solicitada para:', refPayco);
		
		// Ejecutar sincronización
		const resultado = await sincronizarEstadoConEpayco(refPayco);
		
		if (resultado.success) {
			console.log('✅ Sincronización manual exitosa');
			return json({ 
				success: true, 
				message: 'Pago sincronizado correctamente',
				estado: resultado.data?.estado
			});
		} else {
			console.error('❌ Error en sincronización manual:', resultado.error);
			return json({ 
				success: false, 
				error: resultado.error 
			}, { status: 500 });
		}
		
	} catch (error) {
		console.error('💥 Error en sincronización manual:', error);
		return json({ 
			success: false, 
			error: 'Error interno del servidor' 
		}, { status: 500 });
	}
};

// ✅ ENDPOINT GET PARA SINCRONIZAR TODOS LOS PAGOS PENDIENTES
export const GET: RequestHandler = async () => {
	try {
		console.log('🔄 Sincronización masiva de pagos pendientes solicitada');
		
		// Aquí podrías implementar sincronización masiva
		// Por ahora, solo confirmamos que el endpoint funciona
		
		return json({ 
			success: true, 
			message: 'Endpoint de sincronización funcionando',
			nota: 'Usa POST para sincronizar pagos específicos'
		});
		
	} catch (error) {
		console.error('💥 Error en sincronización masiva:', error);
		return json({ 
			success: false, 
			error: 'Error interno del servidor' 
		}, { status: 500 });
	}
}; 