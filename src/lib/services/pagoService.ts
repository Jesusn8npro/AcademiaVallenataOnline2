import { createClient } from '@supabase/supabase-js';
import { generarReferencia, calcularIVA } from './ePaycoService';

// Cliente Supabase para operaciones del servidor (bypassa RLS)
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

// Cliente regular para operaciones que no requieren admin
import { supabase } from '$lib/supabase/clienteSupabase';

// Tipos para los pagos
export interface RegistroPago {
	usuario_id: string;
	curso_id?: string;
	tutorial_id?: string;
	nombre_producto: string;
	descripcion?: string;
	valor: number;
	iva?: number;
	ico?: number;
	base_iva?: number;
	moneda?: string;
	ref_payco: string;
	factura?: string;
	cod_respuesta?: string;
	respuesta?: string;
	estado?: string;
	metodo_pago?: string;
	ip_cliente?: string;
	fecha_transaccion?: string;
	datos_adicionales?: any;
}

export interface ResultadoOperacion {
	success: boolean;
	data?: any;
	error?: string;
	message?: string;
	epaycoData?: any;
}

/**
 * Crear un registro de pago en la base de datos
 */
export async function crearRegistroPago(datos: any): Promise<ResultadoOperacion> {
	try {
		console.log('💾 Creando registro de pago en BD:', {
			usuario_id: datos.usuario_id,
			nombre_producto: datos.nombre_producto,
			valor: datos.valor,
			ref_payco: datos.ref_payco
		});

		const registroPago = {
			// Columnas básicas
			usuario_id: datos.usuario_id,
			curso_id: datos.curso_id || null,
			tutorial_id: datos.tutorial_id || null,
			nombre_producto: datos.nombre_producto,
			descripcion: datos.descripcion || null,
			valor: datos.valor,
			iva: datos.iva || 0,
			ico: datos.ico || 0,
			base_iva: datos.base_iva || 0,
			moneda: datos.moneda || 'COP',
			ref_payco: datos.ref_payco,
			factura: datos.factura || null,
			estado: 'pendiente',
			
			// Almacenar datos adicionales en JSONB
			datos_adicionales: {
				datos_personales: {
					nombre: datos.nombre,
					apellido: datos.apellido,
					email: datos.email,
					telefono: datos.telefono,
					whatsapp: datos.whatsapp,
					fecha_nacimiento: datos.fecha_nacimiento,
					profesion: datos.profesion
				},
				identificacion: {
					documento_tipo: datos.documento_tipo || 'CC',
					documento_numero: datos.documento_numero
				},
				direccion: {
					direccion_completa: datos.direccion_completa,
					ciudad: datos.ciudad,
					pais: datos.pais || 'Colombia',
					codigo_postal: datos.codigo_postal
				},
				marketing: {
					como_nos_conocio: datos.como_nos_conocio
				},
				tecnico: {
					ip_cliente: datos.ip_cliente,
					user_agent: datos.user_agent,
					timestamp_creacion: new Date().toISOString()
				}
			}
		};

		const { data, error } = await supabaseAdmin
			.from('pagos_epayco')
			.insert([registroPago])
			.select('*')
			.single();

		if (error) {
			console.error('❌ Error insertando pago en BD:', error);
			return {
				success: false,
				error: error.message,
				message: 'Error al guardar el pago en la base de datos: ' + error.message
			};
		}

		console.log('✅ Registro de pago creado exitosamente:', data.id);
		return {
			success: true,
			data,
			message: 'Registro de pago creado exitosamente'
		};

	} catch (error: any) {
		console.error('💥 Error en crearRegistroPago:', error);
		return {
			success: false,
			error: error.message,
			message: 'Error inesperado al crear el registro de pago: ' + error.message
		};
	}
}

/**
 * Obtener un pago por su referencia
 */
export async function obtenerPagoPorReferencia(refPayco: string): Promise<ResultadoOperacion> {
	try {
		console.log('🔍 Buscando pago por referencia:', refPayco);
		
		const { data, error } = await supabaseAdmin
			.from('pagos_epayco')
			.select(`
				*,
				perfiles:usuario_id (
					nombre,
					apellido,
					correo_electronico
				),
				cursos:curso_id (
					titulo
				),
				tutoriales:tutorial_id (
					titulo
				)
			`)
			.eq('ref_payco', refPayco)
			.single();

		if (error) {
			console.error('❌ Error obteniendo pago:', error);
			return { success: false, error: error.message };
		}

		if (!data) {
			return { success: false, error: 'Pago no encontrado' };
		}

		console.log('✅ Pago encontrado:', data.id);
		return { success: true, data };

	} catch (error) {
		console.error('💥 Error en obtenerPagoPorReferencia:', error);
		return { 
			success: false, 
			error: error instanceof Error ? error.message : 'Error desconocido' 
		};
	}
}

/**
 * Actualizar el estado de un pago
 */
export async function actualizarEstadoPago(
	refPayco: string, 
	nuevoEstado: string, 
	datosAdicionales?: any
): Promise<ResultadoOperacion> {
	try {
		console.log('🔄 Actualizando estado de pago:', { refPayco, nuevoEstado });
		
		const datosActualizacion: any = {
			estado: nuevoEstado,
			updated_at: new Date().toISOString()
		};

		// Agregar datos adicionales de la transacción si existen
		if (datosAdicionales) {
			if (datosAdicionales.cod_respuesta) datosActualizacion.cod_respuesta = datosAdicionales.cod_respuesta;
			if (datosAdicionales.respuesta) datosActualizacion.respuesta = datosAdicionales.respuesta;
			if (datosAdicionales.metodo_pago) datosActualizacion.metodo_pago = datosAdicionales.metodo_pago;
			if (datosAdicionales.fecha_transaccion) datosActualizacion.fecha_transaccion = datosAdicionales.fecha_transaccion;
		}

		const { data, error } = await supabaseAdmin
			.from('pagos_epayco')
			.update(datosActualizacion)
			.eq('ref_payco', refPayco)
			.select('*')
			.single();

		if (error) {
			console.error('❌ Error actualizando estado:', error);
			return { success: false, error: error.message };
		}

		console.log('✅ Estado actualizado exitosamente');
		return { success: true, data };

	} catch (error) {
		console.error('💥 Error en actualizarEstadoPago:', error);
		return { 
			success: false, 
			error: error instanceof Error ? error.message : 'Error desconocido' 
		};
	}
}

/**
 * Inscribir usuario después de un pago exitoso
 */
export async function inscribirUsuarioDespuesDePago(
	usuarioId: string,
	cursoId?: string,
	tutorialId?: string,
	pagoId?: string
): Promise<ResultadoOperacion> {
	try {
		console.log('🎓 Iniciando inscripción automática después del pago...');
		
		// Verificar si ya está inscrito
		const tablaInscripcion = cursoId ? 'inscripciones' : 'progreso_tutorial';
		const campoContenido = cursoId ? 'curso_id' : 'tutorial_id';
		const valorContenido = cursoId || tutorialId;
		
		const { data: inscripcionExistente } = await supabase
			.from(tablaInscripcion)
			.select('id')
			.eq('usuario_id', usuarioId)
			.eq(campoContenido, valorContenido)
			.single();

		if (inscripcionExistente) {
			console.log('ℹ️ Usuario ya está inscrito');
			return { success: true, data: { mensaje: 'Usuario ya inscrito' } };
		}

		// Crear inscripción
		const datosInscripcion = {
			usuario_id: usuarioId,
			[campoContenido]: valorContenido,
			fecha_inscripcion: new Date().toISOString(),
			progreso: 0,
			activo: true,
			metodo_inscripcion: 'pago_epayco',
			...(pagoId && { pago_id: pagoId })
		};

		const { data, error } = await supabase
			.from(tablaInscripcion)
			.insert([datosInscripcion])
			.select()
			.single();

		if (error) {
			console.error('❌ Error creando inscripción:', error);
			return { success: false, error: error.message };
		}

		console.log('✅ Usuario inscrito exitosamente');
		return { success: true, data };

	} catch (error) {
		console.error('💥 Error en inscribirUsuarioDespuesDePago:', error);
		return { 
			success: false, 
			error: error instanceof Error ? error.message : 'Error desconocido' 
		};
	}
}

/**
 * Función principal para crear un pago
 */
export async function crearPago(datosEntrada: {
	usuarioId?: string | null;
	cursoId?: string;
	tutorialId?: string;
	email: string;
	nombre: string;
	telefono: string;
	ip_cliente?: string;
	datosAdicionales?: any;
}): Promise<ResultadoOperacion> {
	try {
		console.log('🚀 === INICIO crearPago ===');
		console.log('📋 Datos de entrada:', datosEntrada);

		const { usuarioId, cursoId, tutorialId, email, nombre, telefono, ip_cliente, datosAdicionales } = datosEntrada;

		// 1. Obtener contenido (curso o tutorial)
		let contenido;
		let precio = 0;
		let nombreProducto = '';
		let descripcion = '';

		if (cursoId) {
			const { data: curso, error } = await supabase
				.from('cursos')
				.select('id, titulo, precio_normal, precio_rebajado')
				.eq('id', cursoId)
				.single();

			if (error || !curso) {
				return { success: false, error: 'Curso no encontrado' };
			}

			contenido = curso;
			precio = curso.precio_rebajado || curso.precio_normal || 15000;
			nombreProducto = curso.titulo;
			descripcion = `Curso: ${curso.titulo}`;
		} else if (tutorialId) {
			const { data: tutorial, error } = await supabase
				.from('tutoriales')
				.select('id, titulo, precio_normal, precio_rebajado')
				.eq('id', tutorialId)
				.single();

			if (error || !tutorial) {
				return { success: false, error: 'Tutorial no encontrado' };
			}

			contenido = tutorial;
			precio = tutorial.precio_rebajado || tutorial.precio_normal || 15000;
			nombreProducto = tutorial.titulo;
			descripcion = `Tutorial: ${tutorial.titulo}`;
		} else {
			return { success: false, error: 'Debe especificar un curso o tutorial' };
		}

		// 2. Crear usuario si no existe
		let finalUserId = usuarioId;
		if (!usuarioId) {
			finalUserId = crypto.randomUUID();
			console.log('👤 Creando nuevo usuario temporal:', finalUserId);
		}

		// 3. Calcular valores
		const { base, iva, total } = calcularIVA(precio);

		// 4. Generar referencia única
		const refPayco = generarReferencia(
			cursoId ? 'curso' : 'tutorial',
			cursoId || tutorialId || '',
			finalUserId || ''
		);

		// 5. Crear registro en BD
		const datosRegistro = {
			usuario_id: finalUserId,
			curso_id: cursoId,
			tutorial_id: tutorialId,
			nombre_producto: nombreProducto,
			descripcion: descripcion,
			valor: total,
			iva: iva,
			base_iva: base,
			moneda: 'COP',
			ref_payco: refPayco,
			factura: refPayco,
			ip_cliente: ip_cliente,
			...datosAdicionales
		};

		const resultadoRegistro = await crearRegistroPago(datosRegistro);
		if (!resultadoRegistro.success) {
			return resultadoRegistro;
		}

		// 6. Preparar URLs de respuesta
		const baseUrl = 'https://academiavallenataonline.com';
		const responseUrl = `${baseUrl}/api/pagos/respuesta`;
		const confirmationUrl = `${baseUrl}/api/pagos/confirmar`;

		// 7. Preparar datos finales para ePayco
		const calculosIVA = calcularIVA(precio);
		const epaycoData = {
			// Datos transaccionales
			invoice: refPayco,
			name: nombreProducto,
			description: descripcion || nombreProducto,
			currency: 'cop',
			amount: String(total),
			tax_base: String(calculosIVA.base),
			tax: String(calculosIVA.iva),
			tax_ico: '0',
			country: (datosAdicionales?.pais === 'Colombia' ? 'co' : 'us'),
			lang: 'ES',

			// Datos de facturación (ePayco espera estos nombres)
			email_billing: email,
			name_billing: `${nombre} ${datosAdicionales?.apellido || ''}`.trim(),
			address_billing: datosAdicionales?.direccion_completa || 'No aplica',
			type_doc_billing: (datosAdicionales?.documento_tipo || 'cc').toLowerCase(),
			number_doc_billing: datosAdicionales?.documento_numero || '00000000',
			type_person: datosAdicionales?.documento_tipo === 'NIT' ? '1' : '0',
			mobilephone_billing: telefono || '0000000000',

			// Forzar el modo On-Page (no redirect) - ¡Debe ser un string!
			external: 'false',

			// URLs de respuesta y confirmación
			response: `${import.meta.env.VITE_BASE_URL}/pago-respuesta`,
			confirmation: `https://webhook.site/a0b1c2d3-e4f5-a6b7-c8d9-e0f1a2b3c4d5`
		};

		console.log('✅ Datos preparados para ePayco:', epaycoData);
		console.log('🚀 === FIN crearPago EXITOSO ===');

		return {
			success: true,
			message: 'Pago preparado exitosamente',
			epaycoData: {
				...epaycoData,
				key: import.meta.env.VITE_EPAYCO_PUBLIC_KEY || 'a04d60e2e678d5bd89a58d26f3413fdb', 
				test: String(import.meta.env.VITE_EPAYCO_TEST_MODE !== 'false')
			}
		};

	} catch (error) {
		console.error('💥 Error fatal en crearPago:', error);
		return {
			success: false,
			message: 'Error interno del servidor en crearPago: ' + (error instanceof Error ? error.message : 'Error desconocido'),
			error: error instanceof Error ? error.message : 'Error desconocido'
		};
	}
} 