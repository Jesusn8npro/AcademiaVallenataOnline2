import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { obtenerPagoPorReferencia } from '$lib/services/pagoService';
import { verificarPago } from '$lib/services/ePaycoService';
import { supabase } from '$lib/supabase/clienteSupabase';

export const GET: RequestHandler = async ({ url }) => {
	try {
		const referencia = url.searchParams.get('ref');
		
		if (!referencia) {
			return json({
				success: false,
				error: 'Referencia es requerida'
			}, { status: 400 });
		}
		
		console.log('🔍 ESTADO PAGO: Consultando referencia:', referencia);
		
		// Obtener información del pago desde nuestra base de datos
		const infoPago = await obtenerPagoPorReferencia(referencia);
		
		if (!infoPago.success || !infoPago.data) {
			return json({
				success: false,
				error: 'Pago no encontrado'
			}, { status: 404 });
		}
		
		const pago = infoPago.data;
		console.log('📊 ESTADO PAGO: Información del pago:', pago);
		
		// Obtener datos del usuario
		let datosUsuario = null;
		if (pago.usuario_id) {
			const { data: usuario, error: errorUsuario } = await supabase
				.from('perfiles')
				.select('nombre_completo, nombre, email, whatsapp, telefono, ciudad')
				.eq('id', pago.usuario_id)
				.single();
				
			if (!errorUsuario && usuario) {
				datosUsuario = {
					nombre: usuario.nombre_completo || usuario.nombre,
					email: usuario.email,
					telefono: usuario.whatsapp || usuario.telefono,
					ciudad: usuario.ciudad
				};
			}
		}
		
		// Obtener información del contenido
		let datosContenido = null;
		if (pago.curso_id) {
			const { data: curso, error: errorCurso } = await supabase
				.from('cursos')
				.select('titulo, descripcion_corta, precio_normal, precio_rebajado')
				.eq('id', pago.curso_id)
				.single();
				
			if (!errorCurso && curso) {
				datosContenido = {
					tipo: 'curso',
					titulo: curso.titulo,
					descripcion: curso.descripcion_corta,
					precio_normal: curso.precio_normal,
					precio_rebajado: curso.precio_rebajado
				};
			}
		} else if (pago.tutorial_id) {
			const { data: tutorial, error: errorTutorial } = await supabase
				.from('tutoriales')
				.select('titulo, descripcion, precio_normal, precio_rebajado')
				.eq('id', pago.tutorial_id)
				.single();
				
			if (!errorTutorial && tutorial) {
				datosContenido = {
					tipo: 'tutorial',
					titulo: tutorial.titulo,
					descripcion: tutorial.descripcion,
					precio_normal: tutorial.precio_normal,
					precio_rebajado: tutorial.precio_rebajado
				};
			}
		}
		
		// Verificar estado actual con ePayco si el pago está pendiente
		let estadoEpayco = null;
		if (pago.estado === 'pendiente') {
			console.log('⏳ ESTADO PAGO: Verificando estado con ePayco...');
			try {
				estadoEpayco = await verificarPago(referencia);
				console.log('📊 ESTADO PAGO: Respuesta de ePayco:', estadoEpayco);
			} catch (error) {
				console.error('❌ ESTADO PAGO: Error verificando con ePayco:', error);
			}
		}
		
		// Preparar respuesta completa
		const respuesta = {
			success: true,
			data: {
				// Información básica del pago
				referencia: pago.ref_payco,
				estado: pago.estado,
				valor: pago.valor,
				iva: pago.iva,
				base_iva: pago.base_iva,
				moneda: pago.moneda,
				factura: pago.factura,
				fecha_creacion: pago.created_at,
				
				// Información del usuario
				usuario: datosUsuario,
				
				// Información del contenido
				contenido: datosContenido,
				
				// Información de la transacción
				transaccion: {
					metodo_pago: pago.metodo_pago || 'N/A',
					nombre_banco: pago.nombre_banco || null,
					numero_tarjeta: pago.numero_tarjeta_enmascarado || null,
					codigo_aprobacion: pago.codigo_aprobacion || null,
					transaction_id: pago.transaction_id || null,
					fecha_transaccion: pago.fecha_transaccion || null,
					respuesta: pago.respuesta || null,
					cod_respuesta: pago.cod_respuesta || null,
					razon_respuesta: pago.razon_respuesta || null
				},
				
				// Estado en tiempo real de ePayco (si está disponible)
				estado_epayco: estadoEpayco,
				
				// Información adicional
				ip_cliente: pago.ip_cliente,
				datos_adicionales: pago.datos_adicionales
			}
		};
		
		console.log('✅ ESTADO PAGO: Respuesta preparada exitosamente');
		return json(respuesta);
		
	} catch (error) {
		console.error('💥 ESTADO PAGO: Error crítico:', error);
		return json({
			success: false,
			error: 'Error interno del servidor'
		}, { status: 500 });
	}
};

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { referencia } = await request.json();
		
		if (!referencia) {
			return json({
				success: false,
				error: 'Referencia es requerida'
			}, { status: 400 });
		}
		
		// Redirigir al método GET
		return GET({ url: new URL(`?ref=${referencia}`, 'http://localhost') } as any);
		
	} catch (error) {
		console.error('💥 ESTADO PAGO POST: Error:', error);
		return json({
			success: false,
			error: 'Error interno del servidor'
		}, { status: 500 });
	}
}; 