import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { obtenerPagoPorReferencia } from '$lib/services/pagoService';

export const GET: RequestHandler = async ({ url }) => {
	try {
		const refPayco = url.searchParams.get('ref_payco');
		const estado = url.searchParams.get('estado') || url.searchParams.get('x_cod_response');
		
		console.log('🔄 Usuario regresó de ePayco:', { refPayco, estado });

		if (!refPayco) {
			// Redirigir a página de error
			throw redirect(302, '/pago-error?error=referencia-faltante');
		}

		// Obtener información del pago
		const pagoResult = await obtenerPagoPorReferencia(refPayco);
		
		if (!pagoResult.success) {
			console.error('❌ Pago no encontrado:', refPayco);
			throw redirect(302, '/pago-error?error=pago-no-encontrado');
		}

		const pago = pagoResult.data;
		
		// Redirigir según el estado
		switch (estado) {
			case '1': // Aceptada
				console.log('✅ Pago exitoso, redirigiendo...');
				if (pago.curso_id) {
					throw redirect(302, `/pago-exitoso?ref=${refPayco}&tipo=curso`);
				} else if (pago.tutorial_id) {
					throw redirect(302, `/pago-exitoso?ref=${refPayco}&tipo=tutorial`);
				}
				throw redirect(302, `/pago-exitoso?ref=${refPayco}`);
				
			case '2': // Rechazada
				console.log('❌ Pago rechazado');
				throw redirect(302, `/pago-error?ref=${refPayco}&error=rechazado`);
				
			case '3': // Pendiente
				console.log('⏳ Pago pendiente');
				throw redirect(302, `/pago-pendiente?ref=${refPayco}`);
				
			case '4': // Fallida
			default:
				console.log('💥 Pago fallido');
				throw redirect(302, `/pago-error?ref=${refPayco}&error=fallido`);
		}

	} catch (error) {
		if (error instanceof Response) {
			throw error; // Re-throw redirects
		}
		
		console.error('❌ Error procesando respuesta:', error);
		throw redirect(302, '/pago-error?error=error-interno');
	}
};

export const POST: RequestHandler = async ({ request }) => {
	try {
		const formData = await request.formData();
		const datos = Object.fromEntries(formData);
		
		console.log('📋 POST recibido en respuesta:', datos);
		
		const refPayco = datos.ref_payco as string;
		const estado = datos.x_cod_response as string;
		
		// Redirigir usando los mismos parámetros que GET
		const params = new URLSearchParams({
			ref_payco: refPayco,
			estado: estado
		});
		
		throw redirect(302, `/api/pagos/respuesta?${params.toString()}`);
		
	} catch (error) {
		if (error instanceof Response) {
			throw error;
		}
		
		console.error('❌ Error en POST respuesta:', error);
		throw redirect(302, '/pago-error?error=error-interno');
	}
}; 