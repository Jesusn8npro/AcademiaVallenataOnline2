<script lang="ts">
	import SelectorMembresias from '$lib/components/Membresias/SelectorMembresias.svelte';
	import { usuario } from '$lib/UsuarioActivo/usuario';
	import { onMount } from 'svelte';

	let cargando = true;

	onMount(() => {
		cargando = false;
	});
</script>

<svelte:head>
	<title>Planes de Membresía - Academia Vallenata Online</title>
	<meta name="description" content="Elige el plan de membresía que mejor se adapte a tu aprendizaje del acordeón vallenato. Acceso completo a cursos, tutoriales y contenido exclusivo." />
	<meta name="keywords" content="membresía, planes, acordeón, vallenato, academia, cursos, tutoriales" />
</svelte:head>

{#if cargando}
	<div class="flex justify-center items-center min-h-screen">
		<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
	</div>
{:else}
	<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
		<!-- Hero Section -->
		<div class="bg-gradient-to-r from-blue-600 to-indigo-700 text-white">
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
				<div class="text-center">
					<h1 class="text-4xl md:text-5xl font-bold mb-6">
						Desbloquea Todo Tu Potencial Musical
					</h1>
					<p class="text-xl md:text-2xl mb-8 max-w-3xl mx-auto opacity-90">
						Accede a todos nuestros cursos, tutoriales exclusivos y contenido premium 
						para dominar el acordeón vallenato como un profesional.
					</p>
					
					{#if $usuario?.id}
						<div class="bg-white/10 backdrop-blur-sm rounded-lg p-4 max-w-md mx-auto">
							<div class="flex items-center justify-center">
								<svg class="w-6 h-6 mr-2" fill="currentColor" viewBox="0 0 20 20">
									<path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
								</svg>
								<span class="font-medium">
									¡Hola, {$usuario.nombre || $usuario.correo_electronico}!
								</span>
							</div>
							<p class="text-sm mt-2 opacity-80">
								Encuentra el plan perfecto para ti
							</p>
						</div>
					{:else}
						<div class="bg-yellow-500/20 backdrop-blur-sm rounded-lg p-4 max-w-md mx-auto">
							<div class="flex items-center justify-center">
								<svg class="w-6 h-6 mr-2" fill="currentColor" viewBox="0 0 20 20">
									<path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
								</svg>
								<span class="font-medium">
									Inicia sesión para ver precios personalizados
								</span>
							</div>
						</div>
					{/if}
				</div>
			</div>
		</div>

		<!-- Selector de Membresías -->
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
			<SelectorMembresias />
		</div>

		<!-- Sección de Testimonios -->
		<div class="bg-white py-16">
			<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
				<div class="text-center mb-12">
					<h2 class="text-3xl font-bold text-gray-900 mb-4">
						Lo que dicen nuestros estudiantes
					</h2>
					<p class="text-gray-600 max-w-2xl mx-auto">
						Miles de estudiantes ya han transformado su forma de tocar el acordeón 
						con nuestros planes de membresía.
					</p>
				</div>

				<div class="grid grid-cols-1 md:grid-cols-3 gap-8">
					<!-- Testimonio 1 -->
					<div class="bg-gray-50 rounded-lg p-6">
						<div class="flex items-center mb-4">
							<div class="flex text-yellow-400">
								{#each Array(5) as _}
									<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
										<path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
									</svg>
								{/each}
							</div>
						</div>
						<p class="text-gray-700 mb-4">
							"Con el plan Premium he aprendido más en 3 meses que en años de práctica por mi cuenta. 
							Los tutoriales son increíbles."
						</p>
						<div class="flex items-center">
							<div class="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold">
								JM
							</div>
							<div class="ml-3">
								<p class="font-medium text-gray-900">Juan Manuel</p>
								<p class="text-sm text-gray-600">Estudiante Premium</p>
							</div>
						</div>
					</div>

					<!-- Testimonio 2 -->
					<div class="bg-gray-50 rounded-lg p-6">
						<div class="flex items-center mb-4">
							<div class="flex text-yellow-400">
								{#each Array(5) as _}
									<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
										<path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
									</svg>
								{/each}
							</div>
						</div>
						<p class="text-gray-700 mb-4">
							"El plan Intermedio es perfecto para mi nivel. El acceso a la comunidad 
							y las clases personalizadas han marcado la diferencia."
						</p>
						<div class="flex items-center">
							<div class="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center text-white font-bold">
								MC
							</div>
							<div class="ml-3">
								<p class="font-medium text-gray-900">María Carmen</p>
								<p class="text-sm text-gray-600">Estudiante Intermedia</p>
							</div>
						</div>
					</div>

					<!-- Testimonio 3 -->
					<div class="bg-gray-50 rounded-lg p-6">
						<div class="flex items-center mb-4">
							<div class="flex text-yellow-400">
								{#each Array(5) as _}
									<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
										<path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
									</svg>
								{/each}
							</div>
						</div>
						<p class="text-gray-700 mb-4">
							"Empecé con el plan Básico y he ido progresando. La calidad de la enseñanza 
							es excelente y el precio muy justo."
						</p>
						<div class="flex items-center">
							<div class="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center text-white font-bold">
								AR
							</div>
							<div class="ml-3">
								<p class="font-medium text-gray-900">Andrés Ramírez</p>
								<p class="text-sm text-gray-600">Estudiante Básico</p>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

		<!-- Sección de FAQ -->
		<div class="bg-gray-50 py-16">
			<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
				<div class="text-center mb-12">
					<h2 class="text-3xl font-bold text-gray-900 mb-4">
						Preguntas Frecuentes
					</h2>
					<p class="text-gray-600">
						Resolvemos tus dudas sobre nuestros planes de membresía
					</p>
				</div>

				<div class="space-y-6">
					<details class="bg-white rounded-lg shadow-sm">
						<summary class="px-6 py-4 cursor-pointer font-medium text-gray-900 hover:bg-gray-50">
							¿Puedo cancelar mi membresía en cualquier momento?
						</summary>
						<div class="px-6 pb-4 text-gray-600">
							Sí, puedes cancelar tu membresía en cualquier momento desde tu panel de usuario. 
							Tu acceso continuará hasta el final del período pagado.
						</div>
					</details>

					<details class="bg-white rounded-lg shadow-sm">
						<summary class="px-6 py-4 cursor-pointer font-medium text-gray-900 hover:bg-gray-50">
							¿Hay algún descuento por pago anual?
						</summary>
						<div class="px-6 pb-4 text-gray-600">
							¡Sí! Ofrecemos hasta un 20% de descuento en todos los planes cuando eliges 
							la opción de pago anual. Es una excelente manera de ahorrar.
						</div>
					</details>

					<details class="bg-white rounded-lg shadow-sm">
						<summary class="px-6 py-4 cursor-pointer font-medium text-gray-900 hover:bg-gray-50">
							¿Puedo cambiar de plan en cualquier momento?
						</summary>
						<div class="px-6 pb-4 text-gray-600">
							Por supuesto. Puedes actualizar tu plan en cualquier momento. Si cambias a un plan superior, 
							solo pagarás la diferencia prorrateada. Los downgrades se aplicarán en tu próximo ciclo de facturación.
						</div>
					</details>

					<details class="bg-white rounded-lg shadow-sm">
						<summary class="px-6 py-4 cursor-pointer font-medium text-gray-900 hover:bg-gray-50">
							¿Qué métodos de pago aceptan?
						</summary>
						<div class="px-6 pb-4 text-gray-600">
							Aceptamos tarjetas de crédito, débito, PSE y otros métodos de pago populares en Colombia 
							a través de nuestra plataforma segura de pagos ePayco.
						</div>
					</details>

					<details class="bg-white rounded-lg shadow-sm">
						<summary class="px-6 py-4 cursor-pointer font-medium text-gray-900 hover:bg-gray-50">
							¿Hay garantía de devolución de dinero?
						</summary>
						<div class="px-6 pb-4 text-gray-600">
							Ofrecemos una garantía de devolución de dinero de 7 días en todos nuestros planes. 
							Si no estás satisfecho, te devolvemos el 100% de tu dinero.
						</div>
					</details>
				</div>
			</div>
		</div>

		<!-- Call to Action Final -->
		<div class="bg-gradient-to-r from-blue-600 to-indigo-700 text-white py-16">
			<div class="max-w-4xl mx-auto text-center px-4 sm:px-6 lg:px-8">
				<h2 class="text-3xl font-bold mb-4">
					¿Listo para comenzar tu journey musical?
				</h2>
				<p class="text-xl mb-8 opacity-90">
					Únete a miles de estudiantes que ya están dominando el acordeón vallenato
				</p>
				<button 
					on:click={() => document.querySelector('.grid.grid-cols-1.md\\:grid-cols-2')?.scrollIntoView({ behavior: 'smooth' })}
					class="bg-white text-blue-600 px-8 py-3 rounded-lg font-bold text-lg hover:bg-gray-100 transition-colors"
				>
					Ver Planes de Membresía
				</button>
			</div>
		</div>
	</div>
{/if} 