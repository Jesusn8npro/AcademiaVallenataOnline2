import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

// ✅ ENDPOINT DE PRUEBA PARA VERIFICAR PROCESADOR DE PAGOS
export const GET: RequestHandler = async () => {
	try {
		console.log('🧪 [TEST] Endpoint de prueba de pagos ejecutándose...');
		
		// Simular datos de prueba
		const datosPrueba = {
			status: 'success',
			message: 'Procesador de pagos funcionando correctamente',
			timestamp: new Date().toISOString(),
			epayco: {
				script_loaded: true,
				handler_available: true,
				credentials: {
					public_key: process.env.VITE_EPAYCO_PUBLIC_KEY ? '✅ Configurada' : '❌ No configurada',
					customer_id: process.env.VITE_EPAYCO_CUSTOMER_ID ? '✅ Configurada' : '❌ No configurada'
				}
			},
			environment: {
				node_env: process.env.NODE_ENV,
				is_dev: process.env.NODE_ENV === 'development'
			}
		};
		
		console.log('✅ [TEST] Datos de prueba generados:', datosPrueba);
		
		return json(datosPrueba);
		
	} catch (error) {
		console.error('❌ [TEST] Error en endpoint de prueba:', error);
		return json({ 
			status: 'error', 
			message: 'Error en endpoint de prueba',
			error: error instanceof Error ? error.message : 'Error desconocido'
		}, { status: 500 });
	}
};

// ✅ ENDPOINT POST PARA SIMULAR PROCESAMIENTO DE PAGO
export const POST: RequestHandler = async ({ request }) => {
	try {
		const datos = await request.json();
		console.log('🧪 [TEST] Simulando procesamiento de pago:', datos);
		
		// Simular respuesta exitosa de ePayco
		const respuestaSimulada = {
			status: 'success',
			message: 'Pago procesado exitosamente (SIMULADO)',
			epayco_response: {
				x_ref_payco: 'TEST-' + Date.now(),
				x_response: 'Aceptada',
				x_cod_response: '1',
				x_amount: datos.monto || '5000',
				x_transaction_date: new Date().toISOString(),
				x_franchise: 'VISA',
				x_customer_email: datos.email || 'test@academia.com',
				x_customer_name: datos.nombre || 'Usuario Test'
			},
			timestamp: new Date().toISOString()
		};
		
		console.log('✅ [TEST] Respuesta simulada generada:', respuestaSimulada);
		
		return json(respuestaSimulada);
		
	} catch (error) {
		console.error('❌ [TEST] Error simulando pago:', error);
		return json({ 
			status: 'error', 
			message: 'Error simulando pago',
			error: error instanceof Error ? error.message : 'Error desconocido'
		}, { status: 500 });
	}
}; 