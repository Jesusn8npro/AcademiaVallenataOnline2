<script lang="ts">
	import { onMount } from 'svelte';
	import { usuario } from '$lib/UsuarioActivo/usuario';
	import SelectorMembresias from '$lib/components/Membresias/SelectorMembresias.svelte';

	let mostrarSelector = false;
	let testResults = {
		pagos: [] as any[],
		suscripciones: [] as any[],
		loading: false
	};

	onMount(() => {
		console.log('🧪 Página de prueba de membresías cargada');
		console.log('👤 Usuario actual:', $usuario);
	});

	async function verificarBaseDatos() {
		testResults.loading = true;
		try {
			// Verificar últimos pagos
			const resPagos = await fetch('/api/test-db');
			const dataPagos = await resPagos.json();
			
			testResults.pagos = dataPagos.pagos || [];
			testResults.suscripciones = dataPagos.suscripciones || [];
		} catch (error) {
			console.error('Error verificando BD:', error);
		}
		testResults.loading = false;
	}
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
			<p class="text-lg text-gray-600 mb-6">
				Página de pruebas para el sistema de membresías con ePayco
			</p>
			
			<!-- Estado del usuario -->
			{#if $usuario}
				<div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
					✅ Usuario logueado: <strong>{$usuario.correo_electronico}</strong>
				</div>
			{:else}
				<div class="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded mb-4">
					⚠️ No hay usuario logueado - Las pruebas funcionarán de todos modos
				</div>
			{/if}
		</div>

		<!-- Botones de acción -->
		<div class="flex flex-col sm:flex-row gap-4 justify-center mb-8">
			<button 
				on:click={() => mostrarSelector = true}
				class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg transition duration-200"
			>
				🏷️ Probar Selector de Membresías
			</button>
			
			<button 
				on:click={verificarBaseDatos}
				disabled={testResults.loading}
				class="bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white font-semibold py-3 px-6 rounded-lg transition duration-200"
			>
				{#if testResults.loading}
					⏳ Verificando...
				{:else}
					🔍 Verificar Base de Datos
				{/if}
			</button>
		</div>

		<!-- Enlace a diagnóstico -->
		<div class="text-center mb-6">
			<a 
				href="/diagnostico-epayco"
				class="bg-orange-600 text-white px-6 py-3 rounded-lg hover:bg-orange-700 transition-colors font-medium inline-block"
			>
				🔍 Diagnóstico Completo ePayco
			</a>
		</div>

		<!-- Resultados de verificación -->
		{#if testResults.pagos.length > 0 || testResults.suscripciones.length > 0}
		<div class="bg-white rounded-lg shadow-lg p-6 mb-8">
			<h2 class="text-2xl font-bold mb-4">📊 Resultados de la Base de Datos</h2>
			
			<!-- Últimos pagos -->
			{#if testResults.pagos.length > 0}
			<div class="mb-6">
				<h3 class="text-lg font-semibold mb-3 text-blue-600">💰 Últimos Pagos</h3>
				<div class="overflow-x-auto">
					<table class="min-w-full bg-gray-50 rounded-lg">
						<thead>
							<tr class="bg-gray-200">
								<th class="px-4 py-2 text-left">Referencia</th>
								<th class="px-4 py-2 text-left">Estado</th>
								<th class="px-4 py-2 text-left">Monto</th>
								<th class="px-4 py-2 text-left">Membresía</th>
								<th class="px-4 py-2 text-left">Fecha</th>
							</tr>
						</thead>
						<tbody>
							{#each testResults.pagos as pago}
							<tr class="border-b">
								<td class="px-4 py-2 font-mono text-sm">{pago.referencia}</td>
								<td class="px-4 py-2">
									<span class="px-2 py-1 rounded text-xs {pago.estado === 'exitoso' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}">
										{pago.estado}
									</span>
								</td>
								<td class="px-4 py-2">${pago.monto}</td>
								<td class="px-4 py-2">{pago.membresia_nombre || 'N/A'}</td>
								<td class="px-4 py-2 text-sm">{new Date(pago.created_at).toLocaleString()}</td>
							</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</div>
			{/if}

			<!-- Suscripciones -->
			{#if testResults.suscripciones.length > 0}
			<div>
				<h3 class="text-lg font-semibold mb-3 text-purple-600">📝 Suscripciones</h3>
				<div class="overflow-x-auto">
					<table class="min-w-full bg-gray-50 rounded-lg">
						<thead>
							<tr class="bg-gray-200">
								<th class="px-4 py-2 text-left">Usuario</th>
								<th class="px-4 py-2 text-left">Membresía</th>
								<th class="px-4 py-2 text-left">Estado</th>
								<th class="px-4 py-2 text-left">Inicio</th>
								<th class="px-4 py-2 text-left">Fin</th>
							</tr>
						</thead>
						<tbody>
							{#each testResults.suscripciones as suscripcion}
							<tr class="border-b">
								<td class="px-4 py-2">{suscripcion.usuario_email || suscripcion.usuario_id}</td>
								<td class="px-4 py-2">{suscripcion.membresia_nombre}</td>
								<td class="px-4 py-2">
									<span class="px-2 py-1 rounded text-xs {suscripcion.estado === 'activa' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}">
										{suscripcion.estado}
									</span>
								</td>
								<td class="px-4 py-2 text-sm">{new Date(suscripcion.fecha_inicio).toLocaleDateString()}</td>
								<td class="px-4 py-2 text-sm">{new Date(suscripcion.fecha_fin).toLocaleDateString()}</td>
							</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</div>
			{/if}
		</div>
		{/if}

		<!-- Instrucciones -->
		<div class="bg-white rounded-lg shadow-lg p-6">
			<h2 class="text-2xl font-bold mb-4">📋 Instrucciones de Prueba</h2>
			
			<div class="space-y-4">
				<div class="border-l-4 border-blue-500 pl-4">
					<h3 class="font-semibold text-blue-700">1. Pagos Exitosos</h3>
					<p class="text-gray-600">Visa: <code class="bg-gray-100 px-2 py-1 rounded">4575623182290326</code></p>
					<p class="text-gray-600">Mastercard: <code class="bg-gray-100 px-2 py-1 rounded">5254133674403564</code></p>
				</div>
				
				<div class="border-l-4 border-red-500 pl-4">
					<h3 class="font-semibold text-red-700">2. Pagos Rechazados</h3>
					<p class="text-gray-600">Visa: <code class="bg-gray-100 px-2 py-1 rounded">4151611527583283</code></p>
				</div>
				
				<div class="border-l-4 border-green-500 pl-4">
					<h3 class="font-semibold text-green-700">3. Datos Adicionales</h3>
					<p class="text-gray-600">CVV: <code class="bg-gray-100 px-2 py-1 rounded">123</code></p>
					<p class="text-gray-600">Vencimiento: <code class="bg-gray-100 px-2 py-1 rounded">12/26</code> (cualquier fecha futura)</p>
				</div>
			</div>
		</div>

		<!-- Información de tarjetas de prueba -->
		<div class="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
			<h3 class="font-bold text-yellow-800 mb-4">🧪 Tarjetas de Prueba OFICIALES Bold (ex-ePayco)</h3>
			
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
				<!-- Tarjetas exitosas -->
				<div class="bg-green-50 border border-green-200 rounded p-4">
					<h4 class="font-semibold text-green-800 mb-2">✅ PAGOS EXITOSOS:</h4>
					<div class="space-y-2 text-sm">
						<div class="bg-white p-2 rounded border">
							<strong>VISA OFICIAL:</strong> 4111111111111111<br>
							<strong>CVV:</strong> 123 | <strong>Fecha:</strong> 12/29<br>
							<strong>Nombre:</strong> APPROVED
						</div>
						<div class="bg-white p-2 rounded border">
							<strong>MASTERCARD OFICIAL:</strong> 5100010000000015<br>
							<strong>CVV:</strong> 123 | <strong>Fecha:</strong> 12/29<br>
							<strong>Nombre:</strong> APPROVED
						</div>
					</div>
				</div>

				<!-- Tarjetas rechazadas -->
				<div class="bg-red-50 border border-red-200 rounded p-4">
					<h4 class="font-semibold text-red-800 mb-2">❌ PARA PROBAR RECHAZOS:</h4>
					<div class="space-y-2 text-sm">
						<div class="bg-white p-2 rounded border">
							<strong>RECHAZADA:</strong> 4970110000000062<br>
							<strong>CVV:</strong> 123 | <strong>Fecha:</strong> 12/29<br>
							<strong>Nombre:</strong> DECLINED
						</div>
						<div class="bg-white p-2 rounded border">
							<strong>FALLIDA:</strong> 5204730000008404<br>
							<strong>CVV:</strong> 123 | <strong>Fecha:</strong> 12/29<br>
							<strong>Nombre:</strong> FAILED
						</div>
					</div>
				</div>
			</div>

			<div class="mt-4 p-4 bg-blue-50 border border-blue-200 rounded">
				<h4 class="font-semibold text-blue-800 mb-2">⚠️ IMPORTANTE:</h4>
				<ul class="text-sm text-blue-700 space-y-1">
					<li>• Estas son las tarjetas OFICIALES de Bold (ex-ePayco)</li>
					<li>• DEBES estar en modo TEST (verificar variable VITE_EPAYCO_TEST_MODE=true)</li>
					<li>• Solo funcionan en el sandbox de ePayco/Bold</li>
					<li>• No usar tarjetas reales en modo prueba</li>
				</ul>
			</div>
		</div>
	</div>
</div>

<!-- Modal del selector -->
{#if mostrarSelector}
	<SelectorMembresias bind:mostrarModal={mostrarSelector} />
{/if} 