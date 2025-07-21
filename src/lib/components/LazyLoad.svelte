<script lang="ts">
	import { onMount } from 'svelte';
	import { browser } from '$app/environment';

	// Props
	export let component: any; // Componente a cargar
	export let threshold = 0.1; // Cuándo activar la carga (10% visible)
	export let rootMargin = '50px'; // Margen para activar antes
	export let placeholder = ''; // Texto mientras carga
	export let height = 'auto'; // Altura mínima para evitar layout shift
	export let fallback: any = null; // Componente de fallback si falla la carga

	// Estados
	let containerElement: HTMLElement;
	let componentLoaded = false;
	let loadedComponent: any = null;
	let isVisible = false;
	let isLoading = false;
	let loadError = false;

	// Intersection Observer
	let observer: IntersectionObserver;

	onMount(() => {
		if (!browser || !containerElement) return;

		// Crear Intersection Observer
		observer = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (entry.isIntersecting && !componentLoaded && !isLoading) {
						loadComponent();
					}
				});
			},
			{
				threshold,
				rootMargin
			}
		);

		// Observar el contenedor
		observer.observe(containerElement);

		// Cleanup
		return () => {
			if (observer) observer.disconnect();
		};
	});

	// Cargar componente dinámicamente
	async function loadComponent() {
		if (componentLoaded || isLoading) return;

		isLoading = true;
		isVisible = true;

		try {
			// Si es una función (import dinámico)
			if (typeof component === 'function') {
				const module = await component();
				loadedComponent = module.default || module;
			} else {
				// Si ya es un componente
				loadedComponent = component;
			}

			componentLoaded = true;
			loadError = false;
		} catch (error) {
			console.warn('Error cargando componente lazy:', error);
			loadError = true;
			
			// Usar fallback si está disponible
			if (fallback) {
				loadedComponent = fallback;
				componentLoaded = true;
			}
		} finally {
			isLoading = false;
		}
	}

	// Función para forzar carga (útil para testing)
	export function forceLoad() {
		if (!componentLoaded) {
			loadComponent();
		}
	}
</script>

<div 
	bind:this={containerElement}
	class="lazy-container"
	class:loading={isLoading}
	class:loaded={componentLoaded}
	class:error={loadError}
	style="min-height: {height}"
>
	{#if componentLoaded && loadedComponent && !loadError}
		<!-- Componente cargado exitosamente -->
		<svelte:component this={loadedComponent} {...$$props} />
	{:else if isLoading}
		<!-- Estado de carga -->
		<div class="lazy-loading">
			<div class="lazy-spinner">
				<div class="spinner"></div>
			</div>
			{#if placeholder}
				<p class="lazy-placeholder">{placeholder}</p>
			{:else}
				<p class="lazy-placeholder">Cargando componente...</p>
			{/if}
		</div>
	{:else if loadError && !fallback}
		<!-- Error sin fallback -->
		<div class="lazy-error">
			<p>⚠️ Error cargando contenido</p>
			<button on:click={loadComponent} class="retry-btn">
				🔄 Reintentar
			</button>
		</div>
	{:else}
		<!-- Placeholder inicial (antes de ser visible) -->
		<div class="lazy-placeholder-initial">
			{#if placeholder}
				<p>{placeholder}</p>
			{:else}
				<div class="placeholder-skeleton">
					<div class="skeleton-line"></div>
					<div class="skeleton-line short"></div>
					<div class="skeleton-line"></div>
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	.lazy-container {
		display: block;
		width: 100%;
		transition: opacity 0.3s ease-in-out;
	}

	.lazy-container.loading {
		opacity: 0.8;
	}

	.lazy-container.loaded {
		opacity: 1;
	}

	.lazy-container.error {
		opacity: 0.6;
	}

	/* Loading state */
	.lazy-loading {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 40px 20px;
		text-align: center;
	}

	.lazy-spinner {
		margin-bottom: 16px;
	}

	.spinner {
		width: 32px;
		height: 32px;
		border: 3px solid #e5e7eb;
		border-top: 3px solid #3b82f6;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	.lazy-placeholder {
		margin: 0;
		color: #6b7280;
		font-size: 14px;
	}

	/* Error state */
	.lazy-error {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 40px 20px;
		text-align: center;
		color: #ef4444;
	}

	.retry-btn {
		margin-top: 12px;
		padding: 8px 16px;
		background: #3b82f6;
		color: white;
		border: none;
		border-radius: 6px;
		cursor: pointer;
		font-size: 14px;
		transition: background-color 0.2s;
	}

	.retry-btn:hover {
		background: #2563eb;
	}

	/* Placeholder inicial */
	.lazy-placeholder-initial {
		padding: 20px;
	}

	.placeholder-skeleton {
		animation: pulse 2s infinite;
	}

	.skeleton-line {
		height: 16px;
		background: #e5e7eb;
		border-radius: 4px;
		margin-bottom: 12px;
	}

	.skeleton-line.short {
		width: 60%;
	}

	@keyframes pulse {
		0%, 100% {
			opacity: 1;
		}
		50% {
			opacity: 0.5;
		}
	}

	/* Responsive */
	@media (max-width: 640px) {
		.lazy-loading {
			padding: 20px 16px;
		}

		.spinner {
			width: 24px;
			height: 24px;
			border-width: 2px;
		}

		.lazy-placeholder {
			font-size: 12px;
		}
	}
</style> 