import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { crearPagoMembresia, confirmarPagoMembresia } from '$lib/services/membershipPaymentService';

export const POST: RequestHandler = async ({ request, getClientAddress }) => {
	try {
		console.log('🎯 === NUEVA API PAGO MEMBRESÍA ===');
		
		const data = await request.json();
		console.log('📝 Datos recibidos en /api/pagos/membresia:', JSON.stringify(data, null, 2));

		// Validación básica
		const { action, usuarioId, membresiaId, planId, esAnual, email, nombre } = data;
		
		if (!action) {
			return json({
				success: false,
				message: 'Acción requerida (crear o confirmar)'
			}, { status: 400 });
		}

		// IP del cliente
		const clientIp = getClientAddress();
		console.log('🌐 IP del cliente:', clientIp);

		if (action === 'crear') {
			// Validar datos requeridos para creación
			if (!usuarioId || !membresiaId || !planId || !email || !nombre) {
				console.error('❌ Faltan datos requeridos:', { usuarioId, membresiaId, planId, email, nombre });
				return json({
					success: false,
					message: 'Faltan datos requeridos: usuarioId, membresiaId, planId, email, nombre'
				}, { status: 400 });
			}

			// Preparar datos para el pago
			const datosPago = {
				usuarioId,
				membresiaId,
				planId,
				esAnual: esAnual || false,
				email,
				nombre,
				telefono: data.telefono,
				ip_cliente: clientIp
			};

			console.log('🚀 Creando pago de membresía...');
			const resultado = await crearPagoMembresia(datosPago);

			if (!resultado.success) {
				console.error('❌ Error creando pago:', resultado);
				return json({
					success: false,
					message: resultado.message || 'Error creando pago de membresía',
					error: resultado.error
				}, { status: 500 });
			}

			console.log('✅ Pago de membresía creado exitosamente');
			return json({
				success: true,
				epaycoData: resultado.epaycoData,
				message: 'Pago de membresía preparado correctamente'
			});

		} else if (action === 'confirmar') {
			// Validar datos requeridos para confirmación
			const { refPayco, datosConfirmacion } = data;
			
			if (!refPayco || !datosConfirmacion) {
				console.error('❌ Faltan datos para confirmación:', { refPayco, datosConfirmacion });
				return json({
					success: false,
					message: 'Faltan datos de confirmación: refPayco, datosConfirmacion'
				}, { status: 400 });
			}

			console.log('✅ Confirmando pago de membresía...');
			const resultado = await confirmarPagoMembresia(refPayco, datosConfirmacion);

			if (!resultado.success) {
				console.error('❌ Error confirmando pago:', resultado);
				return json({
					success: false,
					message: resultado.message || 'Error confirmando pago de membresía',
					error: resultado.error
				}, { status: 500 });
			}

			console.log('✅ Pago de membresía confirmado exitosamente');
			return json({
				success: true,
				data: resultado.data,
				message: 'Membresía activada exitosamente'
			});

		} else {
			return json({
				success: false,
				message: 'Acción no válida. Use "crear" o "confirmar"'
			}, { status: 400 });
		}

	} catch (error: any) {
		console.error('💥 Error fatal en /api/pagos/membresia:', error);
		console.error('💥 Stack trace:', error.stack);
		return json({
			success: false,
			message: 'Error interno del servidor: ' + error.message,
			error: error.message
		}, { status: 500 });
	}
}; 