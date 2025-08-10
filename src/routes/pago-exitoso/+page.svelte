<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { usuario, setUsuario } from '$lib/UsuarioActivo/usuario';

	// Variables para datos del pago
	let datosPago: any = null;
	let cargandoDatos = true;
	let errorCarga = '';
	let mostrandoAnimacion = true;

	// Datos del usuario recién registrado
	let datosUsuarioNuevo: any = null;

	onMount(async () => {
		// Obtener parámetros de ePayco de la URL
		const parametrosUrl = $page.url.searchParams;
		
		console.log('🎉 Página de éxito cargada');
		console.log('📋 Parámetros recibidos:', Object.fromEntries(parametrosUrl));

		// Extraer datos de ePayco
		datosPago = {
			referencia: parametrosUrl.get('x_ref_payco') || parametrosUrl.get('ref_payco'),
			respuesta: parametrosUrl.get('x_response') || 'Aceptada',
			razonRespuesta: parametrosUrl.get('x_response_reason_text') || 'Transacción exitosa',
			codigoRespuesta: parametrosUrl.get('x_cod_response') || '1',
			facturaId: parametrosUrl.get('x_id_invoice'),
			transaccionId: parametrosUrl.get('x_transaction_id'),
			monto: parametrosUrl.get('x_amount'),
			moneda: parametrosUrl.get('x_currency_code') || 'COP',
			fechaTransaccion: parametrosUrl.get('x_transaction_date'),
			metodoPago: parametrosUrl.get('x_franchise') || 'Tarjeta',
			emailCliente: parametrosUrl.get('x_customer_email'),
			nombreCliente: parametrosUrl.get('x_customer_name'),
			banco: parametrosUrl.get('x_bank_name'),
			cuotas: parametrosUrl.get('x_quotas'),
			descripcion: parametrosUrl.get('x_description')
		};

		// Si no hay datos de pago, usar datos de ejemplo para pruebas
		if (!datosPago.referencia) {
			datosPago = {
				referencia: 'AVA-' + Date.now(),
				respuesta: 'Aceptada',
				razonRespuesta: 'Transacción exitosa',
				codigoRespuesta: '1',
				monto: '49000',
				moneda: 'COP',
				fechaTransaccion: new Date().toLocaleString('es-CO'),
				metodoPago: 'VISA',
				emailCliente: 'usuario@test.com',
				nombreCliente: 'Usuario Nuevo',
				descripcion: 'Tutorial de Acordeón'
			};
		}

		// Simular datos del usuario recién registrado
		datosUsuarioNuevo = {
			email: datosPago.emailCliente,
			nombre: datosPago.nombreCliente,
			fechaRegistro: new Date().toLocaleString('es-CO'),
			contenidoAdquirido: datosPago.descripcion
		};

		// Animación de celebración
		setTimeout(() => {
			mostrandoAnimacion = false;
			cargandoDatos = false;
		}, 3000);

		// Auto-login después de 5 segundos
		setTimeout(() => {
			if (datosPago.emailCliente) {
				realizarAutoLogin();
			}
		}, 5000);
	});

	async function realizarAutoLogin() {
		try {
			console.log('🔄 Realizando auto-login...');
			
			// Aquí normalmente harías el login automático
			// Por ahora, simular que el usuario está logueado
			setUsuario({
				id: 'user-' + Date.now(),
				correo_electronico: datosPago.emailCliente,
				nombre: datosPago.nombreCliente,
				rol: 'estudiante'
			});

			console.log('✅ Auto-login exitoso');
		} catch (error) {
			console.error('❌ Error en auto-login:', error);
		}
	}

	function irAPanelEstudiante() {
		goto('/panel-estudiante');
	}

	function irAMisCursos() {
		goto('/mis-cursos');
	}

	function compartirEnWhatsApp() {
		const mensaje = `¡Acabo de adquirir "${datosPago.descripcion}" en Academia Vallenata Online! 🎵 Una experiencia increíble para aprender acordeón vallenato. ¡Te recomiendo visitarlos!`;
		const url = `https://wa.me/?text=${encodeURIComponent(mensaje)}`;
		window.open(url, '_blank');
	}
</script>

<svelte:head>
	<title>¡Gracias por tu Compra! - Academia Vallenata Online</title>
	<meta name="description" content="Pago exitoso en Academia Vallenata Online. Tu cuenta ha sido activada automáticamente." />
</svelte:head>

<div class="fondo-celebracion min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 relative overflow-hidden">
	<!-- Partículas de celebración -->
	{#if mostrandoAnimacion}
		<div class="particulas-celebracion absolute inset-0 pointer-events-none">
			{#each Array(50) as _, i}
				<div 
					class="particula absolute w-2 h-2 bg-yellow-400 rounded-full animate-bounce"
					style="left: {Math.random() * 100}%; top: {Math.random() * 100}%; animation-delay: {Math.random() * 2}s;"
				></div>
			{/each}
		</div>
	{/if}

	<div class="contenedor-principal relative z-10 container mx-auto px-4 py-8 min-h-screen flex flex-col justify-center">
		
		{#if cargandoDatos}
			<!-- Estado de carga con animación -->
			<div class="tarjeta-carga bg-white/10 backdrop-blur-lg rounded-3xl p-8 text-center max-w-md mx-auto">
				<div class="icono-carga mb-6">
					<svg class="w-16 h-16 mx-auto animate-spin text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6l4 2"></path>
						<circle cx="12" cy="12" r="10"></circle>
					</svg>
				</div>
				<h2 class="texto-carga text-2xl font-bold text-white mb-2">Procesando tu compra...</h2>
				<p class="descripcion-carga text-purple-200">Activando tu cuenta en nuestra academia</p>
			</div>
		{:else}
			<!-- Contenido principal de éxito -->
			<div class="tarjeta-exito max-w-4xl mx-auto">
				
				<!-- Encabezado de éxito -->
				<div class="encabezado-exito text-center mb-8">
					<div class="icono-exito mb-6">
						<svg class="w-24 h-24 mx-auto text-green-400 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
						</svg>
					</div>
					<h1 class="titulo-principal text-5xl md:text-6xl font-extrabold bg-gradient-to-r from-yellow-400 via-orange-400 to-red-400 bg-clip-text text-transparent mb-4">
						¡Felicitaciones!
					</h1>
					<h2 class="subtitulo-principal text-2xl md:text-3xl font-bold text-white mb-2">
						Tu compra fue exitosa
					</h2>
					<p class="descripcion-principal text-xl text-purple-200">
						Ya eres parte oficial de nuestra academia musical 🎵
					</p>
				</div>

				<!-- Información del pago -->
				<div class="seccion-pago bg-white/10 backdrop-blur-lg rounded-2xl p-6 mb-6 border border-white/20">
					<h3 class="titulo-seccion text-xl font-bold text-white mb-4 flex items-center">
						<svg class="w-6 h-6 mr-2 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
						</svg>
						Detalles de tu Transacción
					</h3>
					
					<div class="detalles-pago grid md:grid-cols-2 gap-4">
						<div class="detalle-item">
							<span class="etiqueta-detalle text-purple-300 font-medium">Referencia:</span>
							<span class="valor-detalle text-white font-mono">{datosPago.referencia}</span>
						</div>
						<div class="detalle-item">
							<span class="etiqueta-detalle text-purple-300 font-medium">Estado:</span>
							<span class="valor-detalle text-green-400 font-semibold">{datosPago.respuesta}</span>
						</div>
						<div class="detalle-item">
							<span class="etiqueta-detalle text-purple-300 font-medium">Monto Pagado:</span>
							<span class="valor-detalle text-yellow-400 font-bold">${parseInt(datosPago.monto || '0').toLocaleString()} {datosPago.moneda}</span>
						</div>
						<div class="detalle-item">
							<span class="etiqueta-detalle text-purple-300 font-medium">Método de Pago:</span>
							<span class="valor-detalle text-white">{datosPago.metodoPago}</span>
						</div>
						<div class="detalle-item">
							<span class="etiqueta-detalle text-purple-300 font-medium">Fecha:</span>
							<span class="valor-detalle text-white">{datosPago.fechaTransaccion}</span>
						</div>
						<div class="detalle-item">
							<span class="etiqueta-detalle text-purple-300 font-medium">Contenido:</span>
							<span class="valor-detalle text-white font-semibold">{datosPago.descripcion}</span>
						</div>
					</div>
				</div>

				<!-- Información de la cuenta -->
				<div class="seccion-cuenta bg-gradient-to-r from-green-500/20 to-blue-500/20 rounded-2xl p-6 mb-6 border border-green-400/30">
					<h3 class="titulo-seccion text-xl font-bold text-white mb-4 flex items-center">
						<svg class="w-6 h-6 mr-2 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
						</svg>
						Tu Cuenta en Academia Vallenata
					</h3>
					
					<div class="informacion-cuenta space-y-3">
						<div class="mensaje-bienvenida bg-white/10 rounded-lg p-4">
							<p class="texto-bienvenida text-white text-lg">
								¡Hola <strong class="text-yellow-400">{datosUsuarioNuevo.nombre}</strong>! 
								Tu cuenta ha sido <strong class="text-green-400">activada automáticamente</strong> 
								y ya tienes acceso completo a tu contenido.
							</p>
						</div>
						
						<div class="detalles-cuenta grid md:grid-cols-2 gap-4">
							<div class="detalle-cuenta">
								<span class="etiqueta-cuenta text-purple-300">Email registrado:</span>
								<span class="valor-cuenta text-white font-mono">{datosUsuarioNuevo.email}</span>
							</div>
							<div class="detalle-cuenta">
								<span class="etiqueta-cuenta text-purple-300">Fecha de registro:</span>
								<span class="valor-cuenta text-white">{datosUsuarioNuevo.fechaRegistro}</span>
							</div>
						</div>

						<div class="estado-acceso bg-green-500/20 rounded-lg p-4 border border-green-400/30">
							<p class="texto-acceso text-center text-white">
								🎉 <strong>¡Ya estás dentro!</strong> En unos segundos serás redirigido automáticamente a tu panel de estudiante.
							</p>
						</div>
					</div>
				</div>

				<!-- Botones de acción -->
				<div class="botones-accion flex flex-wrap gap-4 justify-center mb-6">
					<button 
						onclick={irAPanelEstudiante}
						class="boton-principal bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-bold py-4 px-8 rounded-xl transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl"
					>
						<svg class="w-5 h-5 inline-block mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4"></path>
						</svg>
						Ir a Mi Panel
					</button>
					
					<button 
						onclick={irAMisCursos}
						class="boton-secundario bg-gradient-to-r from-green-600 to-teal-600 hover:from-green-700 hover:to-teal-700 text-white font-bold py-4 px-8 rounded-xl transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl"
					>
						<svg class="w-5 h-5 inline-block mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
						</svg>
						Ver Mis Cursos
					</button>
					
					<button 
						onclick={compartirEnWhatsApp}
						class="boton-compartir bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white font-bold py-4 px-8 rounded-xl transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl"
					>
						<svg class="w-5 h-5 inline-block mr-2" fill="currentColor" viewBox="0 0 24 24">
							<path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.886 3.488"></path>
						</svg>
						Compartir Experiencia
					</button>
				</div>

				<!-- Mensaje de soporte -->
				<div class="seccion-soporte bg-white/5 rounded-xl p-4 text-center border border-white/10">
					<p class="texto-soporte text-purple-200 mb-2">
						¿Tienes alguna pregunta? Nuestro equipo está aquí para ayudarte.
					</p>
					<p class="contacto-soporte text-white font-semibold">
						📧 soporte@academiavallentaonline.com | 📱 WhatsApp: +57 300 123 4567
					</p>
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	.fondo-celebracion {
		background-image: 
			radial-gradient(circle at 25% 25%, rgba(255, 255, 255, 0.1) 0%, transparent 50%),
			radial-gradient(circle at 75% 75%, rgba(255, 255, 255, 0.1) 0%, transparent 50%);
	}

	.particula {
		animation: particula-flotante 3s infinite ease-in-out;
	}

	@keyframes particula-flotante {
		0%, 100% { transform: translateY(0px) rotate(0deg); }
		50% { transform: translateY(-20px) rotate(180deg); }
	}

	.detalle-item, .detalle-cuenta {
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.etiqueta-detalle, .etiqueta-cuenta {
		font-size: 0.875rem;
	}

	.valor-detalle, .valor-cuenta {
		font-size: 1rem;
	}

	/* Responsive para móviles */
	@media (max-width: 768px) {
		.titulo-principal {
			font-size: 2.5rem;
		}
		
		.subtitulo-principal {
			font-size: 1.5rem;
		}
		
		.botones-accion {
			flex-direction: column;
		}
		
		.boton-principal, .boton-secundario, .boton-compartir {
			width: 100%;
		}
	}
</style> 