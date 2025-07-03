<script>
	import { onMount } from 'svelte';
	import { browser } from '$app/environment';

	let diagnostico = {
		epaycoLoaded: false,
		publicKey: '',
		testMode: '',
		customerId: '',
		configOk: false,
		errorMessages: []
	};

	let testResult = '';
	let testParams = '';

	onMount(() => {
		// Verificar variables de entorno (simuladas para el cliente)
		diagnostico.publicKey = import.meta.env.VITE_EPAYCO_PUBLIC_KEY || '❌ NO CONFIGURADA';
		diagnostico.testMode = import.meta.env.VITE_EPAYCO_TEST_MODE || '❌ NO CONFIGURADA';
		diagnostico.customerId = import.meta.env.VITE_EPAYCO_CUSTOMER_ID || '❌ NO CONFIGURADA';

		// Verificar si ePayco está cargado
		if (browser && typeof window !== 'undefined') {
			setTimeout(() => {
				diagnostico.epaycoLoaded = typeof window.ePayco !== 'undefined';
				verificarConfiguracion();
			}, 1000);
		}
	});

	function verificarConfiguracion() {
		diagnostico.errorMessages = [];
		
		if (!diagnostico.epaycoLoaded) {
			diagnostico.errorMessages.push('❌ ePayco no está cargado');
		}
		
		if (!diagnostico.publicKey || diagnostico.publicKey === '❌ NO CONFIGURADA') {
			diagnostico.errorMessages.push('❌ Public Key no configurada');
		}
		
		if (!diagnostico.customerId || diagnostico.customerId === '❌ NO CONFIGURADA') {
			diagnostico.errorMessages.push('❌ Customer ID no configurado');
		}
		
		if (diagnostico.testMode !== 'true') {
			diagnostico.errorMessages.push('❌ Test Mode no está en true');
		}

		diagnostico.configOk = diagnostico.errorMessages.length === 0;
		diagnostico = diagnostico; // Trigger reactivity
	}

	function pruebaSimplificada() {
		if (!browser || typeof window.ePayco === 'undefined') {
			testResult = '❌ ePayco no está disponible';
			return;
		}

		try {
			// Configuración mínima de prueba
			const handler = window.ePayco.checkout.configure({
				key: diagnostico.publicKey,
				test: true
			});

			const data = {
				// Información básica
				name: "Prueba Diagnóstico",
				description: "Prueba de configuración ePayco",
				currency: "cop",
				amount: "1000",
				tax_base: "840",
				tax: "160",
				country: "co",
				lang: "es",
				
				// Información del cliente
				invoice: "TEST-" + Date.now(),
				email_billing: "test@academiavallenata.com",
				name_billing: "Usuario Prueba",
				type_doc_billing: "cc",
				mobilephone_billing: "3001234567",
				
				// URLs (opcionales para prueba)
				external: "false"
			};

			// Mostrar parámetros
			testParams = JSON.stringify(data, null, 2);
			
			// Abrir checkout
			handler.open(data);
			
			testResult = '✅ Checkout abierto correctamente - Si ves el modal de ePayco, la configuración básica funciona.';
			
		} catch (error) {
			testResult = `❌ ERROR: ${error.message}`;
		}
	}

	function copiarTexto(texto) {
		if (browser && navigator.clipboard) {
			navigator.clipboard.writeText(texto);
		}
	}
</script>

<svelte:head>
	<title>Diagnóstico ePayco - Academia Vallenata</title>
	<script src="https://checkout.epayco.co/checkout.js"></script>
</svelte:head>

<div class="container mx-auto px-4 py-8">
	<h1 class="text-3xl font-bold text-gray-900 mb-8">🔍 Diagnóstico Completo ePayco</h1>
	
	<!-- Variables de Entorno -->
	<div class="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
		<h2 class="text-xl font-semibold text-blue-800 mb-4">📋 Variables de Entorno</h2>
		<div class="bg-gray-100 p-4 rounded-lg">
			<div class="grid grid-cols-1 gap-2 text-sm">
				<div><strong>🔑 VITE_EPAYCO_PUBLIC_KEY:</strong> {diagnostico.publicKey}</div>
				<div><strong>🧪 VITE_EPAYCO_TEST_MODE:</strong> {diagnostico.testMode}</div>
				<div><strong>👤 VITE_EPAYCO_CUSTOMER_ID:</strong> {diagnostico.customerId}</div>
				<div><strong>📜 ePayco Script:</strong> {diagnostico.epaycoLoaded ? '✅ Cargado' : '❌ No cargado'}</div>
			</div>
		</div>
	</div>

	<!-- Verificación de Configuración -->
	<div class="bg-yellow-50 border border-yellow-200 rounded-lg p-6 mb-6">
		<h2 class="text-xl font-semibold text-yellow-800 mb-4">⚠️ Verificación de Configuración</h2>
		<button 
			on:click={verificarConfiguracion}
			class="bg-yellow-600 text-white px-4 py-2 rounded-lg hover:bg-yellow-700 mb-4"
		>
			🔄 Verificar Configuración ePayco
		</button>
		
		{#if diagnostico.configOk}
			<div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
				✅ <strong>Configuración correcta</strong>
			</div>
		{:else}
			<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
				❌ <strong>ERRORES ENCONTRADOS:</strong><br>
				{#each diagnostico.errorMessages as error}
					• {error}<br>
				{/each}
			</div>
		{/if}
	</div>

	<!-- Prueba de Pago Simplificada -->
	<div class="bg-white border border-gray-200 rounded-lg p-6 mb-6">
		<h2 class="text-xl font-semibold text-gray-800 mb-4">🧪 Prueba de Pago Simplificada</h2>
		<button 
			on:click={pruebaSimplificada}
			class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 mb-4"
		>
			🚀 Probar Pago Básico
		</button>
		
		{#if testResult}
			<div class="bg-gray-100 p-4 rounded-lg">
				{@html testResult}
			</div>
		{/if}
	</div>

	<!-- Parámetros de Prueba -->
	{#if testParams}
		<div class="bg-gray-50 border border-gray-200 rounded-lg p-6 mb-6">
			<h2 class="text-xl font-semibold text-gray-800 mb-4">📊 Parámetros de Prueba</h2>
			<pre class="bg-white p-4 rounded border text-xs overflow-x-auto">{testParams}</pre>
		</div>
	{/if}

	<!-- Tarjetas de Prueba Oficiales -->
	<div class="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
		<h2 class="text-xl font-semibold text-blue-800 mb-4">🎯 Tarjetas de Prueba Oficiales Bold</h2>
		<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
			<div class="bg-white p-4 rounded-lg border">
				<h3 class="font-semibold text-green-700 mb-2">✅ PAGOS EXITOSOS</h3>
				<div class="space-y-2 text-sm">
					<div class="bg-gray-50 p-2 rounded">
						<strong>VISA:</strong> 4111111111111111<br>
						<strong>CVV:</strong> 123 | <strong>Fecha:</strong> 12/29<br>
						<strong>Nombre:</strong> APPROVED
						<button 
							on:click={() => copiarTexto('4111111111111111')}
							class="ml-2 text-blue-600 hover:text-blue-800 text-xs"
						>
							📋 Copiar
						</button>
					</div>
					<div class="bg-gray-50 p-2 rounded">
						<strong>MASTERCARD:</strong> 5100010000000015<br>
						<strong>CVV:</strong> 123 | <strong>Fecha:</strong> 12/29<br>
						<strong>Nombre:</strong> APPROVED
						<button 
							on:click={() => copiarTexto('5100010000000015')}
							class="ml-2 text-blue-600 hover:text-blue-800 text-xs"
						>
							📋 Copiar
						</button>
					</div>
				</div>
			</div>
			
			<div class="bg-white p-4 rounded-lg border">
				<h3 class="font-semibold text-red-700 mb-2">❌ PAGOS RECHAZADOS</h3>
				<div class="space-y-2 text-sm">
					<div class="bg-gray-50 p-2 rounded">
						<strong>RECHAZADA:</strong> 4970110000000062<br>
						<strong>CVV:</strong> 123 | <strong>Fecha:</strong> 12/29<br>
						<strong>Nombre:</strong> DECLINED
					</div>
					<div class="bg-gray-50 p-2 rounded">
						<strong>FALLIDA:</strong> 5204730000008404<br>
						<strong>CVV:</strong> 123 | <strong>Fecha:</strong> 12/29<br>
						<strong>Nombre:</strong> FAILED
					</div>
				</div>
			</div>
		</div>
	</div>

	<!-- Problemas Comunes -->
	<div class="bg-orange-50 border border-orange-200 rounded-lg p-6 mb-6">
		<h2 class="text-xl font-semibold text-orange-800 mb-4">🚨 Problemas Comunes</h2>
		<ul class="space-y-2 text-sm">
			<li><strong>Tarjeta restringida:</strong> Comercio no configurado para sandbox en ePayco</li>
			<li><strong>Error 300:</strong> Parámetros incorrectos en la request</li>
			<li><strong>Error 400:</strong> Llaves públicas/privadas incorrectas</li>
			<li><strong>Error 401:</strong> Sin permisos o llaves expiradas</li>
			<li><strong>Modal no abre:</strong> Script de ePayco no cargado</li>
		</ul>
	</div>

	<!-- Soluciones -->
	<div class="bg-green-50 border border-green-200 rounded-lg p-6">
		<h2 class="text-xl font-semibold text-green-800 mb-4">💡 Soluciones</h2>
		<div class="space-y-3 text-sm">
			<div>
				<strong>1. Contacta a Bold/ePayco:</strong><br>
				• Email: soporte@bold.co<br>
				• Teléfono: +57 (1) 508-9999<br>
				• Web: https://bold.co/soporte
			</div>
			<div>
				<strong>2. Pregunta específicamente:</strong><br>
				"¿Mi comercio está configurado para modo SANDBOX/TEST? Tengo error 'Tarjeta restringida por centro de autorizaciones'"
			</div>
			<div>
				<strong>3. Pide que verifiquen:</strong><br>
				• Activar modo SANDBOX en tu comercio<br>
				• Verificar que tu Public Key sea de TEST<br>
				• Configurar comercio para aceptar tarjetas de prueba
			</div>
		</div>
	</div>

	<!-- Botón para volver -->
	<div class="mt-8 text-center">
		<a 
			href="/test-membresias" 
			class="bg-gray-600 text-white px-6 py-3 rounded-lg hover:bg-gray-700 inline-block"
		>
			← Volver a Pruebas de Membresías
		</a>
	</div>
</div>

<style>
	.container {
		max-width: 1200px;
	}
</style> 