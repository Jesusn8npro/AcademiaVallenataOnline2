<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	function probarPagoExitoso() {
		// Simular datos de ePayco que se envían normalmente a la página de éxito
		const parametrosSimulados = new URLSearchParams({
			x_ref_payco: 'CUR-001234-567890-ABCD-12345678',
			x_response: 'Aceptada',
			x_response_reason_text: 'Transacción exitosa',
			x_cod_response: '1',
			x_id_invoice: 'INV-123456',
			x_transaction_id: 'TXN-789012',
			x_amount: '49900',
			x_currency_code: 'COP',
			x_transaction_date: new Date().toLocaleString('es-CO'),
			x_franchise: 'VISA',
			x_customer_email: 'usuario@test.com',
			x_customer_name: 'Usuario de Prueba',
			x_bank_name: 'BANCO DE PRUEBA',
			x_quotas: '1',
			x_description: 'Plan Intermedio - Academia Vallenata'
		});

		// Redirigir a la página de éxito con los parámetros
		goto(`/pago-exitoso?${parametrosSimulados.toString()}`);
	}

	function probarPagoSinDatos() {
		// Probar la página sin parámetros (debe usar datos de fallback)
		goto('/pago-exitoso');
	}
</script>

<svelte:head>
	<title>Prueba Pago Exitoso - Academia Vallenata</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 flex items-center justify-center p-4">
	<div class="bg-white/10 backdrop-blur-lg rounded-3xl p-8 max-w-md w-full text-center border border-white/20">
		<h1 class="text-3xl font-bold text-white mb-6">🧪 Prueba de Pago Exitoso</h1>
		
		<p class="text-purple-200 mb-8">
			Prueba la funcionalidad de la página "Gracias por tu compra" para verificar que todo funcione correctamente.
		</p>

		<div class="space-y-4">
			<button 
				on:click={probarPagoExitoso}
				class="w-full bg-gradient-to-r from-green-500 to-blue-600 hover:from-green-600 hover:to-blue-700 text-white font-bold py-3 px-6 rounded-xl transition-all duration-300 transform hover:scale-105"
			>
				🎉 Probar con Datos de Pago
			</button>

			<button 
				on:click={probarPagoSinDatos}
				class="w-full bg-gradient-to-r from-purple-500 to-pink-600 hover:from-purple-600 hover:to-pink-700 text-white font-bold py-3 px-6 rounded-xl transition-all duration-300 transform hover:scale-105"
			>
				📝 Probar sin Datos (Fallback)
			</button>
		</div>

		<div class="mt-8 text-sm text-purple-300">
			<p class="mb-2">✅ Página de éxito: <code>/pago-exitoso</code></p>
			<p class="mb-2">✅ Auto-login configurado</p>
			<p class="mb-2">✅ Datos de ePayco procesados</p>
			<p>✅ Animaciones y diseño listo</p>
		</div>

		<a 
			href="/"
			class="inline-block mt-6 text-yellow-400 hover:text-yellow-300 font-semibold transition-colors"
		>
			← Volver al Inicio
		</a>
	</div>
</div>

<style>
	code {
		background: rgba(255, 255, 255, 0.1);
		padding: 0.2rem 0.4rem;
		border-radius: 0.25rem;
		font-family: 'Courier New', monospace;
	}
</style> 