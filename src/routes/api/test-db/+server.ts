import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabase } from '$lib/components/supabase';

export const GET: RequestHandler = async () => {
	try {
		console.log('🔍 Probando conexión a Supabase...');
		
		// Probar conexión básica
		const { data: testData, error: testError } = await supabase
			.from('perfiles')
			.select('count')
			.limit(1);
		
		if (testError) {
			console.error('❌ Error de conexión:', testError);
			return json({ 
				success: false, 
				error: 'Error de conexión a Supabase',
				details: testError
			});
		}
		
		console.log('✅ Conexión a Supabase OK');
		
		// Probar si existe la tabla pagos_epayco
		console.log('🔍 Verificando tabla pagos_epayco...');
		const { data: pagosData, error: pagosError } = await supabase
			.from('pagos_epayco')
			.select('*')
			.limit(1);
		
		if (pagosError) {
			console.error('❌ Error tabla pagos_epayco:', pagosError);
			return json({
				success: false,
				error: 'Tabla pagos_epayco no existe o no es accesible',
				details: pagosError,
				sugerencia: 'Ejecuta el SQL de creación de tablas en Supabase'
			});
		}
		
		console.log('✅ Tabla pagos_epayco existe y es accesible');
		
		// Verificar estructura de la tabla
		const { data: schemaData, error: schemaError } = await supabase
			.rpc('get_table_schema', { table_name: 'pagos_epayco' });
		
		// Obtener últimos 10 pagos con información de membresía
		const { data: pagos, error: errorPagos } = await supabase
			.from('pagos_epayco')
			.select(`
				*,
				membresias (
					nombre,
					precio_mensual,
					precio_anual
				)
			`)
			.order('created_at', { ascending: false })
			.limit(10);

		if (errorPagos) {
			console.error('Error obteniendo pagos:', errorPagos);
		}

		// Obtener últimas 10 suscripciones con información de membresía y usuario
		const { data: suscripciones, error: errorSuscripciones } = await supabase
			.from('suscripciones_usuario')
			.select(`
				*,
				membresias (
					nombre,
					descripcion
				),
				perfiles (
					correo_electronico
				)
			`)
			.order('created_at', { ascending: false })
			.limit(10);

		if (errorSuscripciones) {
			console.error('Error obteniendo suscripciones:', errorSuscripciones);
		}

		// Formatear datos para la respuesta
		const pagosFormateados = (pagos || []).map((pago: any) => ({
			id: pago.id,
			referencia: pago.referencia,
			estado: pago.estado,
			monto: pago.monto,
			membresia_nombre: pago.membresias?.nombre || 'N/A',
			created_at: pago.created_at
		}));

		const suscripcionesFormateadas = (suscripciones || []).map((suscripcion: any) => ({
			id: suscripcion.id,
			usuario_id: suscripcion.usuario_id,
			usuario_email: suscripcion.perfiles?.correo_electronico || 'N/A',
			membresia_nombre: suscripcion.membresias?.nombre || 'N/A',
			estado: suscripcion.estado,
			fecha_inicio: suscripcion.fecha_inicio,
			fecha_fin: suscripcion.fecha_fin,
			created_at: suscripcion.created_at
		}));

		return json({
			success: true,
			message: 'Base de datos OK',
			tablas: {
				perfiles: 'OK',
				pagos_epayco: 'OK'
			},
			schema: schemaData || 'No disponible',
			test_data: pagosData,
			pagos: pagosFormateados,
			suscripciones: suscripcionesFormateadas,
			total_pagos: pagosFormateados.length,
			total_suscripciones: suscripcionesFormateadas.length
		});
		
	} catch (error) {
		console.error('💥 Error crítico:', error);
		return json({
			success: false,
			error: 'Error crítico del servidor',
			details: error instanceof Error ? error.message : 'Error desconocido'
		});
	}
}; 