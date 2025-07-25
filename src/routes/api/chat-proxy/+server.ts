import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { webhookUrl, data } = await request.json();
		
		// 🔍 DEBUG: Log de datos recibidos
		console.log('🔄 Proxy recibió:', { webhookUrl, data });
		
		// Enviar al webhook N8N
		const response = await fetch(webhookUrl, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify(data)
		});
		
		// 🔍 DEBUG: Log de respuesta
		console.log('📡 Respuesta N8N status:', response.status);
		
		if (!response.ok) {
			console.error('❌ Error N8N:', response.status, response.statusText);
			return json({
				success: false,
				error: `HTTP ${response.status}: ${response.statusText}`,
				respuesta: 'Lo siento, hay un problema con el servicio de chat. Por favor intenta más tarde.'
			}, { status: response.status });
		}
		
		// Intentar parsear respuesta JSON con manejo de errores
		let resultado;
		const contentType = response.headers.get('content-type');
		
		try {
			if (contentType && contentType.includes('application/json')) {
				const responseText = await response.text();
				console.log('📝 Respuesta raw N8N:', responseText);
				
				if (responseText.trim()) {
					resultado = JSON.parse(responseText);
				} else {
					// N8N devolvió respuesta vacía, pero exitosa
					resultado = { 
						respuesta: 'Mensaje recibido correctamente. Nuestro asistente está procesando tu consulta.',
						success: true 
					};
				}
			} else {
				const textoRespuesta = await response.text();
				console.log('📝 Respuesta texto N8N:', textoRespuesta);
				resultado = { 
					respuesta: textoRespuesta || 'Mensaje recibido correctamente. Te responderemos pronto.',
					success: true 
				};
			}
		} catch (parseError) {
			console.error('❌ Error parseando JSON:', parseError);
			resultado = { 
				respuesta: 'Mensaje procesado, pero hubo un error en la respuesta',
				success: true 
			};
		}
		
		console.log('✅ Resultado procesado:', resultado);
		
		// 🎯 MEJOR MANEJO DE RESPUESTA
		let respuestaFinal = resultado.respuesta || resultado.output || resultado.message;
		
		// Si aún no hay respuesta, usar mensaje por defecto más amigable
		if (!respuestaFinal || respuestaFinal.trim() === '') {
			respuestaFinal = 'Tu mensaje ha sido recibido correctamente. Nuestro asistente está procesando tu consulta y te responderá en breve.';
		}

		return json({
			success: true,
			...resultado,
			respuesta: respuestaFinal
		});
		
	} catch (error) {
		console.error('🚨 Error en proxy chat:', error);
		
		return json({
			success: false,
			error: error instanceof Error ? error.message : 'Error desconocido',
			respuesta: 'Lo siento, hay un problema de conexión. Por favor intenta nuevamente.'
		}, { status: 500 });
	}
}; 