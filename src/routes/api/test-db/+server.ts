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
		
		return json({
			success: true,
			message: 'Base de datos OK',
			tablas: {
				perfiles: 'OK',
				pagos_epayco: 'OK'
			},
			schema: schemaData || 'No disponible',
			test_data: pagosData
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