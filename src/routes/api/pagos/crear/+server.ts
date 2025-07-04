import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { crearPago } from '$lib/services/pagoService';
// Importar cliente admin para operaciones del servidor
import { createClient } from '@supabase/supabase-js';

const supabaseAdmin = createClient(
	import.meta.env.VITE_SUPABASE_URL,
	import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY,
	{
		auth: {
			autoRefreshToken: false,
			persistSession: false
		}
	}
);

export const POST: RequestHandler = async ({ request, getClientAddress }) => {
	try {
		console.log('🚀 === INICIO DE CREACIÓN DE PAGO ===');
		
		const data = await request.json();
		console.log('📝 Datos recibidos en /api/pagos/crear:', JSON.stringify(data, null, 2));

		// Validación básica
		const { email, nombre } = data;
		
		if (!email || !nombre) {
			console.error('❌ Faltan datos básicos:', { email, nombre });
			return json({
				success: false,
				message: 'Email y nombre son obligatorios'
			}, { status: 400 });
		}

		// Verificar que tenemos al menos un curso o tutorial
		if (!data.cursoId && !data.tutorialId) {
			console.error('❌ Falta curso o tutorial');
			return json({
				success: false,
				message: 'Debe especificar un curso o tutorial para el pago'
			}, { status: 400 });
		}

		// IP del cliente
		const clientIp = getClientAddress();
		console.log('🌐 IP del cliente:', clientIp);

		// CREAR USUARIO REAL EN PERFILES - CON NOMBRES CORRECTOS DE COLUMNAS
		let usuarioFinalId = data.usuarioId;
		
		if (!data.usuarioId || data.esUsuarioNuevo) {
			console.log('👤 Creando usuario en perfiles...');
			
			const nuevoUsuarioId = crypto.randomUUID();
			
			// Crear usuario con los nombres CORRECTOS de las columnas + ROL REQUERIDO
			const { data: nuevoUsuario, error: errorUsuario } = await supabaseAdmin
				.from('perfiles')
				.insert({
					id: nuevoUsuarioId,
					nombre: data.nombre,
					apellido: data.apellido || '',
					correo_electronico: data.email,
					rol: 'estudiante', // ✅ ROL CORRECTO PARA USUARIOS QUE COMPRAN
					whatsapp: data.whatsapp || data.telefono || '',
					documento_tipo: data.documento_tipo || 'CC',
					documento_numero: data.documento_numero || '',
					direccion_completa: data.direccion_completa || '',
					ciudad: data.ciudad || '',
					pais: data.pais || 'Colombia',
					codigo_postal: data.codigo_postal || '',
					profesion: data.profesion || '',
					como_nos_conocio: data.como_nos_conocio || '',
					fecha_nacimiento: data.fecha_nacimiento || null
				})
				.select()
				.single();

			if (errorUsuario) {
				console.error('❌ Error creando usuario:', errorUsuario);
				return json({
					success: false,
					message: 'Error creando usuario: ' + errorUsuario.message
				}, { status: 500 });
			}

			usuarioFinalId = nuevoUsuarioId;
			console.log('✅ Usuario creado con ID:', usuarioFinalId);
		} else {
			console.log('✅ Usuario existente:', usuarioFinalId);
		}

		// Preparar datos simplificados
		const datosSimplificados = {
			usuarioId: usuarioFinalId,
			cursoId: data.cursoId,
			tutorialId: data.tutorialId,
			email: data.email,
			nombre: data.nombre,
			telefono: data.telefono || '',
			ip_cliente: clientIp,
			
			// Todos los datos adicionales en un solo objeto
			datosAdicionales: {
				apellido: data.apellido || '',
				whatsapp: data.whatsapp || data.telefono || '',
				documento_tipo: data.documento_tipo || 'CC',
				documento_numero: data.documento_numero || '',
				direccion_completa: data.direccion_completa || '',
				ciudad: data.ciudad || '',
				pais: data.pais || 'Colombia',
				codigo_postal: data.codigo_postal || '',
				fecha_nacimiento: data.fecha_nacimiento || null,
				profesion: data.profesion || '',
				como_nos_conocio: data.como_nos_conocio || '',
				password: data.password || null,
				es_usuario_nuevo: data.esUsuarioNuevo || false,
				timestamp: new Date().toISOString(),
				user_agent: request.headers.get('user-agent') || ''
			}
		};

		console.log('🔧 Datos preparados para crearPago:', JSON.stringify(datosSimplificados, null, 2));
		
		// Crear el pago
		console.log('🚀 Llamando a crearPago...');
		const resultado = await crearPago(datosSimplificados);

		console.log('📊 Resultado de crearPago:', JSON.stringify(resultado, null, 2));

		if (!resultado.success) {
			console.error('❌ Error en crearPago:', resultado);
			return json({
				success: false,
				message: resultado.message || 'Error interno del servidor',
				error: resultado.error
			}, { status: 500 });
		}

		console.log('✅ Pago creado exitosamente');
		console.log('🚀 === FIN DE CREACIÓN DE PAGO ===');
		
		return json({
			success: true,
			epaycoData: resultado.epaycoData,
			message: 'Pago preparado correctamente'
		});

	} catch (error: any) {
		console.error('💥 Error fatal en /api/pagos/crear:', error);
		console.error('💥 Stack trace:', error.stack);
		return json({
			success: false,
			message: 'Error interno del servidor: ' + error.message,
			error: error.message
		}, { status: 500 });
	}
}; 