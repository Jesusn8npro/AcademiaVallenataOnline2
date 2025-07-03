import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { actualizarEstadoPago, inscribirUsuarioDespuesDePago, obtenerPagoPorReferencia } from '$lib/services/pagoService';
import { verificarPago } from '$lib/services/ePaycoService';
import { confirmarPagoMembresia } from '$lib/services/membershipPaymentService';

export const POST: RequestHandler = async ({ request }) => {
	try {
		console.log('🔔 Webhook de confirmación recibido');
		
		const formData = await request.formData();
		const datos = Object.fromEntries(formData);
		
		console.log('📋 Datos recibidos del webhook:', datos);

		// Extraer datos importantes
		const {
			x_ref_payco,
			x_transaction_id,
			x_amount,
			x_currency_code,
			x_signature,
			x_approval_code,
			x_transaction_date,
			x_cod_response,
			x_response,
			x_response_reason_text,
			x_franchise,
			x_bank_name,
			x_cardnumber,
			x_customer_email,
			x_customer_name,
			x_customer_phone,
			x_customer_mobile,
			x_customer_document,
			x_customer_ip,
			x_test_request
		} = datos;

		if (!x_ref_payco) {
			console.error('❌ No se recibió referencia de pago');
			return json({ success: false, error: 'Referencia de pago requerida' }, { status: 400 });
		}

		// Obtener el pago de nuestra base de datos
		const pagoResult = await obtenerPagoPorReferencia(x_ref_payco as string);
		if (!pagoResult.success) {
			console.error('❌ Pago no encontrado en BD:', x_ref_payco);
			return json({ success: false, error: 'Pago no encontrado' }, { status: 404 });
		}

		const pago = pagoResult.data;
		console.log('💳 Pago encontrado:', pago.id);

		// Verificar el pago con ePayco para mayor seguridad
		const verificacion = await verificarPago(x_ref_payco as string);
		console.log('🔍 Verificación ePayco:', verificacion);

		// Determinar el estado basado en el código de respuesta
		let nuevoEstado = 'pendiente';
		const codigoRespuesta = x_cod_response as string;

		switch (codigoRespuesta) {
			case '1':
				nuevoEstado = 'aceptada';
				break;
			case '2':
				nuevoEstado = 'rechazada';
				break;
			case '3':
				nuevoEstado = 'pendiente';
				break;
			case '4':
				nuevoEstado = 'fallida';
				break;
			default:
				nuevoEstado = 'fallida';
		}

		console.log(`📊 Estado del pago: ${nuevoEstado} (código: ${codigoRespuesta})`);

		// Preparar datos adicionales para guardar
		const datosAdicionales = {
			cod_respuesta: codigoRespuesta,
			respuesta: x_response,
			metodo_pago: x_franchise || 'Desconocido',
			fecha_transaccion: x_transaction_date,
			transaction_id: x_transaction_id,
			approval_code: x_approval_code,
			bank_name: x_bank_name,
			cardnumber: x_cardnumber,
			customer_email: x_customer_email,
			customer_name: x_customer_name,
			customer_phone: x_customer_phone,
			customer_mobile: x_customer_mobile,
			customer_document: x_customer_document,
			customer_ip: x_customer_ip,
			is_test: x_test_request === 'TRUE',
			webhook_data: datos
		};

		// Actualizar el estado del pago
		const actualizacion = await actualizarEstadoPago(
			x_ref_payco as string,
			nuevoEstado,
			datosAdicionales
		);

		if (!actualizacion.success) {
			console.error('❌ Error actualizando pago:', actualizacion.error);
			return json({ success: false, error: 'Error actualizando pago' }, { status: 500 });
		}

		console.log('✅ Pago actualizado correctamente');

		// Si el pago fue aceptado, procesar según el tipo
		if (nuevoEstado === 'aceptada') {
			// Verificar si es un pago de membresía
			if (pago.membresia_id) {
				console.log('🎯 Activando membresía automáticamente...');
				
				const activacionMembresia = await confirmarPagoMembresia(
					x_ref_payco as string,
					datos
				);

				if (activacionMembresia.success) {
					console.log('✅ Membresía activada correctamente');
				} else {
					console.error('❌ Error activando membresía:', activacionMembresia.error);
					// No retornamos error aquí porque el pago ya fue procesado
				}
			} else {
				// Es un pago de curso/tutorial tradicional
				console.log('🎓 Inscribiendo usuario a curso/tutorial...');
			
			const inscripcion = await inscribirUsuarioDespuesDePago(
				pago.usuario_id,
				pago.curso_id,
				pago.tutorial_id,
				pago.id
			);

			if (inscripcion.success) {
				console.log('✅ Usuario inscrito correctamente');
			} else {
				console.error('❌ Error inscribiendo usuario:', inscripcion.error);
				// No retornamos error aquí porque el pago ya fue procesado
				}
			}
		}

		// Responder a ePayco
		return json({ 
			success: true, 
			message: 'Confirmación procesada correctamente',
			estado: nuevoEstado
		});

	} catch (error) {
		console.error('❌ Error procesando webhook:', error);
		return json({ 
			success: false, 
			error: 'Error interno del servidor' 
		}, { status: 500 });
	}
};

// También manejar GET para pruebas
export const GET: RequestHandler = async ({ url }) => {
	const refPayco = url.searchParams.get('ref_payco');
	
	if (!refPayco) {
		return json({ error: 'Referencia de pago requerida' }, { status: 400 });
	}

	try {
		const pago = await obtenerPagoPorReferencia(refPayco);
		return json({ success: true, data: pago });
	} catch (error) {
		console.error('Error obteniendo pago:', error);
		return json({ error: 'Error interno' }, { status: 500 });
	}
}; 