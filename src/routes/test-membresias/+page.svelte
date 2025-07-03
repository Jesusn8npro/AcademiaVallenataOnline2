<script lang="ts">
	import { onMount } from 'svelte';
	import { usuario } from '$lib/UsuarioActivo/usuario';
	import SelectorMembresias from '$lib/components/Membresias/SelectorMembresias.svelte';

	let mostrarSelector = false;

	onMount(() => {
		console.log('🧪 Página de prueba de membresías cargada');
		console.log('👤 Usuario actual:', $usuario);
	});
</script>

<svelte:head>
	<title>Test Membresías - Academia Vallenata Online</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4">
	<div class="max-w-4xl mx-auto">
		<!-- Header de prueba -->
		<div class="text-center mb-8">
			<h1 class="text-4xl font-bold text-gray-900 mb-4">
				🧪 Test de Membresías
			</h1>
			<p class="text-lg text-gray-600">
				Página de prueba para verificar el flujo completo de pagos de membresías
			</p>
		</div>

		<!-- Información del usuario -->
		<div class="bg-white rounded-lg shadow-md p-6 mb-8">
			<h2 class="text-xl font-semibold mb-4 flex items-center">
				👤 Estado del Usuario
			</h2>
			
			{#if $usuario}
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<div>
						<strong>ID:</strong> {$usuario.id}
					</div>
					<div>
						<strong>Nombre:</strong> {$usuario.nombre}
					</div>
					<div>
						<strong>Email:</strong> {$usuario.correo_electronico}
					</div>
					<div>
						<strong>Rol:</strong> {$usuario.rol}
					</div>
				</div>
				
				<button 
					on:click={() => mostrarSelector = true}
					class="mt-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-lg transition-colors"
				>
					🚀 Probar Selector de Membresías
				</button>
			{:else}
				<div class="text-center py-8">
					<p class="text-gray-600 mb-4">
						❌ Usuario no autenticado
					</p>
					<p class="text-sm text-gray-500">
						Necesitas estar logueado para probar el sistema de membresías
					</p>
				</div>
			{/if}
		</div>

		<!-- Instrucciones de prueba -->
		<div class="bg-yellow-50 border border-yellow-200 rounded-lg p-6 mb-8">
			<h3 class="text-lg font-semibold text-yellow-800 mb-3">
				📋 Instrucciones de Prueba
			</h3>
			<ol class="list-decimal list-inside space-y-2 text-yellow-700">
				<li>Asegúrate de estar logueado</li>
				<li>Haz clic en "Probar Selector de Membresías"</li>
				<li>Selecciona un plan y confirma</li>
				<li>Verifica que se abra el formulario de ePayco</li>
				<li>Usa tarjetas de prueba de ePayco</li>
				<li>Verifica que se active la membresía después del pago</li>
			</ol>
		</div>

		<!-- Datos de prueba -->
		<div class="bg-gray-50 rounded-lg p-6">
			<h3 class="text-lg font-semibold text-gray-800 mb-3">
				💳 Tarjetas de Prueba ePayco
			</h3>
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
				<div>
					<strong>Visa (Exitosa):</strong><br>
					4575623182290326<br>
					CVV: 123, Fecha: 12/29
				</div>
				<div>
					<strong>MasterCard (Exitosa):</strong><br>
					5424180279791732<br>
					CVV: 123, Fecha: 12/29
				</div>
				<div>
					<strong>Visa (Rechazada):</strong><br>
					4151611527583283<br>
					CVV: 123, Fecha: 12/29
				</div>
				<div>
					<strong>Diners (Exitosa):</strong><br>
					36432507068614<br>
					CVV: 123, Fecha: 12/29
				</div>
			</div>
		</div>
	</div>
</div>

<!-- Modal del selector de membresías -->
{#if mostrarSelector}
	<SelectorMembresias 
		bind:mostrarModal={mostrarSelector}
	/>
{/if} 