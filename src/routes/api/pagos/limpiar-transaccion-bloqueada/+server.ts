import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabase } from '$lib/supabase/clienteSupabase';

export const POST: RequestHandler = async ({ request }) => {
	try {
		console.log('🚨 [EMERGENCIA] Limpiando transacción bloqueada...');
		
		const { ref_payco } = await request.json();
		
		if (!ref_payco) {
			return json({ success: false, error: 'Referencia de pago requerida' }, { status: 400 });
		}
		
		console.log('🔍 [EMERGENCIA] Buscando transacción:', ref_payco);
		
		// 1. Buscar la transacción bloqueada
		const { data: transaccion, error: errorBusqueda } = await supabase
			.from('pagos_epayco')
			.select('*')
			.eq('ref_payco', ref_payco)
			.single();
			
		if (errorBusqueda) {
			console.error('❌ [EMERGENCIA] Transacción no encontrada:', errorBusqueda);
			return json({ success: false, error: 'Transacción no encontrada' }, { status: 404 });
		}
		
		console.log('📋 [EMERGENCIA] Transacción encontrada:', {
			id: transaccion.id,
			estado: transaccion.estado,
			ref_payco: transaccion.ref_payco
		});
		
		// 2. 🚨 FORZAR ESTADO A ACEPTADA (EMERGENCIA)
		const { data: transaccionActualizada, error: errorActualizacion } = await supabase
			.from('pagos_epayco')
			.update({
				estado: 'aceptada',
				cod_respuesta: '1',
				respuesta: 'Aceptada por limpieza de emergencia',
				fecha_transaccion: new Date().toISOString(),
				transaction_id: transaccion.transaction_id || `EMERGENCY-${Date.now()}`,
				approval_code: 'EMERGENCY-APPROVED',
				updated_at: new Date().toISOString()
			})
			.eq('ref_payco', ref_payco)
			.select('*')
			.single();
			
		if (errorActualizacion) {
			console.error('❌ [EMERGENCIA] Error actualizando transacción:', errorActualizacion);
			return json({ success: false, error: 'Error actualizando transacción' }, { status: 500 });
		}
		
		console.log('✅ [EMERGENCIA] Transacción limpiada exitosamente:', {
			id: transaccionActualizada.id,
			estado: transaccionActualizada.estado,
			ref_payco: transaccionActualizada.ref_payco
		});
		
		// 3. 🚨 INSCRIBIR AL USUARIO AUTOMÁTICAMENTE (EMERGENCIA)
		if (transaccionActualizada.usuario_id && (transaccionActualizada.curso_id || transaccionActualizada.tutorial_id)) {
			console.log('🎓 [EMERGENCIA] Inscribiendo usuario automáticamente...');
			
			try {
				// Inscribir en curso o tutorial
				if (transaccionActualizada.curso_id) {
					const { error: errorInscripcion } = await supabase
						.from('inscripciones')
						.insert({
							usuario_id: transaccionActualizada.usuario_id,
							curso_id: transaccionActualizada.curso_id,
							fecha_inscripcion: new Date().toISOString(),
							estado: 'activa',
							pago_id: transaccionActualizada.id
						});
						
					if (errorInscripcion) {
						console.warn('⚠️ [EMERGENCIA] Error inscribiendo en curso:', errorInscripcion);
					} else {
						console.log('✅ [EMERGENCIA] Usuario inscrito en curso exitosamente');
					}
				}
				
				if (transaccionActualizada.tutorial_id) {
					const { error: errorInscripcion } = await supabase
						.from('inscripciones')
						.insert({
							usuario_id: transaccionActualizada.usuario_id,
							tutorial_id: transaccionActualizada.tutorial_id,
							fecha_inscripcion: new Date().toISOString(),
							estado: 'activa',
							pago_id: transaccionActualizada.id
						});
						
					if (errorInscripcion) {
						console.warn('⚠️ [EMERGENCIA] Error inscribiendo en tutorial:', errorInscripcion);
					} else {
						console.log('✅ [EMERGENCIA] Usuario inscrito en tutorial exitosamente');
					}
				}
			} catch (error) {
				console.warn('⚠️ [EMERGENCIA] Error en inscripción automática:', error);
			}
		}
		
		return json({ 
			success: true, 
			message: 'Transacción bloqueada limpiada exitosamente',
			transaccion: transaccionActualizada
		});
		
	} catch (error) {
		console.error('💥 [EMERGENCIA] Error limpiando transacción:', error);
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
		return json({ success: false, error: 'Referencia de pago requerida' }, { status: 400 });
	}
	
	console.log('🔍 [GET] Verificando transacción:', refPayco);
	
	// Buscar la transacción
	const { data: transaccion, error } = await supabase
		.from('pagos_epayco')
		.select('*')
		.eq('ref_payco', refPayco)
		.single();
		
	if (error) {
		return json({ success: false, error: 'Transacción no encontrada' }, { status: 404 });
	}
	
	return json({ 
		success: true, 
		transaccion: transaccion
	});
}; 