import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabase } from '$lib/supabase/clienteSupabase';

export const POST: RequestHandler = async ({ request, getClientAddress }) => {
	try {
		console.log('🔔 [WEBHOOK EPAYCO] Nueva notificación recibida');
		
		const body = await request.formData();
		const clientIP = getClientAddress();
		const userAgent = request.headers.get('user-agent') || '';
		
		// Extraer todos los datos de ePayco
		const datosEpayco = {
			x_cust_id_cliente: body.get('x_cust_id_cliente')?.toString(),
			x_ref_payco: body.get('x_ref_payco')?.toString(),
			x_id_invoice: body.get('x_id_invoice')?.toString(),
			x_description: body.get('x_description')?.toString(),
			x_amount: parseFloat(body.get('x_amount')?.toString() || '0'),
			x_amount_country: parseFloat(body.get('x_amount_country')?.toString() || '0'),
			x_amount_ok: parseFloat(body.get('x_amount_ok')?.toString() || '0'),
			x_tax: parseFloat(body.get('x_tax')?.toString() || '0'),
			x_amount_base: parseFloat(body.get('x_amount_base')?.toString() || '0'),
			x_currency_code: body.get('x_currency_code')?.toString(),
			x_date_transaction: body.get('x_date_transaction')?.toString(),
			x_approval_code: body.get('x_approval_code')?.toString(),
			x_transaction_id: body.get('x_transaction_id')?.toString(),
			x_response: body.get('x_response')?.toString(),
			x_response_reason_text: body.get('x_response_reason_text')?.toString(),
			x_cod_response: body.get('x_cod_response')?.toString(),
			x_cod_transaction_state: body.get('x_cod_transaction_state')?.toString(),
			x_signature: body.get('x_signature')?.toString(),
			x_test_request: body.get('x_test_request')?.toString(),
			x_transaction_state: body.get('x_transaction_state')?.toString(),
			x_franchise: body.get('x_franchise')?.toString(),
			x_bank_name: body.get('x_bank_name')?.toString(),
			x_cardnumber: body.get('x_cardnumber')?.toString()
		};

		console.log('📋 [WEBHOOK EPAYCO] Datos recibidos:', {
			ref_payco: datosEpayco.x_ref_payco,
			cod_response: datosEpayco.x_cod_response,
			response: datosEpayco.x_response,
			transaction_state: datosEpayco.x_transaction_state,
			franchise: datosEpayco.x_franchise
		});

		// Validar que tenemos los datos mínimos necesarios
		if (!datosEpayco.x_ref_payco) {
			console.error('❌ [WEBHOOK EPAYCO] Falta referencia de pago');
			return json({ error: 'Referencia de pago requerida' }, { status: 400 });
		}

		// Buscar el pago existente para determinar el estado anterior
		const { data: pagoExistente, error: errorBusqueda } = await supabase
			.from('pagos_epayco')
			.select('estado')
			.eq('ref_payco', datosEpayco.x_ref_payco)
			.single();

		if (errorBusqueda && errorBusqueda.code !== 'PGRST116') {
			console.error('❌ [WEBHOOK EPAYCO] Error al buscar pago:', errorBusqueda);
			return json({ error: 'Error interno del servidor' }, { status: 500 });
		}

		// Determinar estado nuevo basado en código de respuesta
		let estadoNuevo = 'desconocida';
		switch (datosEpayco.x_cod_response) {
			case '1':
				estadoNuevo = 'aceptada';
				break;
			case '2':
			case '6':
				estadoNuevo = 'rechazada';
				break;
			case '3':
			case '9':
				estadoNuevo = 'pendiente';
				break;
			case '4':
				estadoNuevo = 'fallida';
				break;
			case '10':
				estadoNuevo = 'cancelada';
				break;
			case '11':
				estadoNuevo = 'expirada';
				break;
		}

		console.log(`🔄 [WEBHOOK EPAYCO] Cambio de estado: ${pagoExistente?.estado || 'N/A'} → ${estadoNuevo}`);

		// Insertar en tabla de notificaciones (esto disparará el trigger automático)
		const { error: errorNotificacion } = await supabase
			.from('notificaciones_epayco')
			.insert({
				ref_payco: datosEpayco.x_ref_payco,
				estado_anterior: pagoExistente?.estado || null,
				estado_nuevo: estadoNuevo,
				x_cust_id_cliente: datosEpayco.x_cust_id_cliente,
				x_ref_payco: datosEpayco.x_ref_payco,
				x_id_invoice: datosEpayco.x_id_invoice,
				x_description: datosEpayco.x_description,
				x_amount: datosEpayco.x_amount,
				x_amount_country: datosEpayco.x_amount_country,
				x_amount_ok: datosEpayco.x_amount_ok,
				x_tax: datosEpayco.x_tax,
				x_amount_base: datosEpayco.x_amount_base,
				x_currency_code: datosEpayco.x_currency_code,
				x_date_transaction: datosEpayco.x_date_transaction ? new Date(datosEpayco.x_date_transaction) : null,
				x_approval_code: datosEpayco.x_approval_code,
				x_transaction_id: datosEpayco.x_transaction_id,
				x_response: datosEpayco.x_response,
				x_response_reason_text: datosEpayco.x_response_reason_text,
				x_cod_response: datosEpayco.x_cod_response,
				x_cod_transaction_state: datosEpayco.x_cod_transaction_state,
				x_signature: datosEpayco.x_signature,
				x_test_request: datosEpayco.x_test_request,
				x_transaction_state: datosEpayco.x_transaction_state,
				x_franchise: datosEpayco.x_franchise,
				x_bank_name: datosEpayco.x_bank_name,
				x_cardnumber: datosEpayco.x_cardnumber,
				ip_origen: clientIP,
				user_agent: userAgent,
				datos_completos: datosEpayco
			});

		if (errorNotificacion) {
			console.error('❌ [WEBHOOK EPAYCO] Error al insertar notificación:', errorNotificacion);
			return json({ error: 'Error al procesar notificación' }, { status: 500 });
		}

		console.log('✅ [WEBHOOK EPAYCO] Notificación procesada exitosamente');

		// Respuesta exitosa para ePayco
		return json({ 
			status: 'success',
			message: 'Notificación procesada correctamente',
			ref_payco: datosEpayco.x_ref_payco,
			estado_actualizado: estadoNuevo
		});

	} catch (error) {
		console.error('💥 [WEBHOOK EPAYCO] Error inesperado:', error);
		return json({ error: 'Error interno del servidor' }, { status: 500 });
	}
};

// Endpoint GET para verificar que el webhook está funcionando
export const GET: RequestHandler = async () => {
	return json({
		status: 'webhook_active',
		message: 'Webhook de ePayco funcionando correctamente',
		timestamp: new Date().toISOString()
	});
}; 