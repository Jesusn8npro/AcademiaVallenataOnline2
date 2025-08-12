import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { supabase } from '$lib/supabase';

// ✅ ENDPOINT DE PRUEBA PARA VERIFICAR TABLA PROGRESO_LECCIONES
export const GET: RequestHandler = async () => {
	try {
		console.log('🧪 [TEST PROGRESO] Verificando tabla progreso_lecciones...');
		
		// 1. Verificar estructura de la tabla
		const { data: estructura, error: errorEstructura } = await supabase
			.from('progreso_lecciones')
			.select('*')
			.limit(1);
		
		if (errorEstructura) {
			console.error('❌ [TEST PROGRESO] Error accediendo a la tabla:', errorEstructura);
			return json({ 
				status: 'error', 
				message: 'Error accediendo a la tabla progreso_lecciones',
				error: errorEstructura
			}, { status: 500 });
		}
		
		// 2. Verificar permisos de lectura
		const { data: permisos, error: errorPermisos } = await supabase
			.from('progreso_lecciones')
			.select('id, usuario_id, leccion_id, estado')
			.limit(5);
		
		if (errorPermisos) {
			console.error('❌ [TEST PROGRESO] Error de permisos:', errorPermisos);
			return json({ 
				status: 'error', 
				message: 'Error de permisos en progreso_lecciones',
				error: errorPermisos
			}, { status: 500 });
		}
		
		// 3. Verificar consulta específica (como la que falla)
		const { data: consultaEspecifica, error: errorConsulta } = await supabase
			.from('progreso_lecciones')
			.select('leccion_id, estado')
			.not('usuario_id', 'is', null)
			.limit(5);
		
		if (errorConsulta) {
			console.error('❌ [TEST PROGRESO] Error en consulta específica:', errorConsulta);
			return json({ 
				status: 'error', 
				message: 'Error en consulta específica',
				error: errorConsulta
			}, { status: 500 });
		}
		
		console.log('✅ [TEST PROGRESO] Todas las pruebas pasaron');
		
		return json({
			status: 'success',
			message: 'Tabla progreso_lecciones funcionando correctamente',
			tests: {
				estructura: '✅ OK',
				permisos: '✅ OK',
				consulta_especifica: '✅ OK'
			},
			datos_muestra: {
				total_registros: estructura?.length || 0,
				permisos_muestra: permisos?.length || 0,
				consulta_muestra: consultaEspecifica?.length || 0
			},
			timestamp: new Date().toISOString()
		});
		
	} catch (error) {
		console.error('❌ [TEST PROGRESO] Error inesperado:', error);
		return json({ 
			status: 'error', 
			message: 'Error inesperado en test de progreso',
			error: error instanceof Error ? error.message : 'Error desconocido'
		}, { status: 500 });
	}
};

// ✅ ENDPOINT POST PARA SIMULAR CONSULTA DE PROGRESO
export const POST: RequestHandler = async ({ request }) => {
	try {
		const { usuario_id, leccion_ids } = await request.json();
		console.log('🧪 [TEST PROGRESO] Simulando consulta con:', { usuario_id, leccion_ids });
		
		if (!usuario_id || !leccion_ids || !Array.isArray(leccion_ids)) {
			return json({ 
				status: 'error', 
				message: 'Datos inválidos: usuario_id y leccion_ids (array) son requeridos'
			}, { status: 400 });
		}
		
		// Simular la consulta que está fallando
		const { data, error } = await supabase
			.from('progreso_lecciones')
			.select('leccion_id, estado')
			.not('usuario_id', 'is', null)
			.eq('usuario_id', usuario_id)
			.in('leccion_id', leccion_ids);
		
		if (error) {
			console.error('❌ [TEST PROGRESO] Error en consulta simulada:', error);
			return json({ 
				status: 'error', 
				message: 'Error en consulta simulada',
				error: error
			}, { status: 500 });
		}
		
		console.log('✅ [TEST PROGRESO] Consulta simulada exitosa');
		
		return json({
			status: 'success',
			message: 'Consulta simulada exitosa',
			datos: data,
			parametros_usados: {
				usuario_id,
				leccion_ids,
				total_lecciones_consultadas: leccion_ids.length
			},
			timestamp: new Date().toISOString()
		});
		
	} catch (error) {
		console.error('❌ [TEST PROGRESO] Error en POST:', error);
		return json({ 
			status: 'error', 
			message: 'Error procesando consulta simulada',
			error: error instanceof Error ? error.message : 'Error desconocido'
		}, { status: 500 });
	}
}; 