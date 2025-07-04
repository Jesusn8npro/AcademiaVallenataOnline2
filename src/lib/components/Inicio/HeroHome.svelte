<script lang="ts">
	import { onMount } from 'svelte';
	import { fly, scale } from 'svelte/transition';
	import { quintOut } from 'svelte/easing';

	export let mostrarModal: boolean;
	export let scrollToSection: (id: string) => void;

	let visible = false;

	onMount(() => {
		visible = true;
	});
</script>

<section class="hero-section">
	<!-- Fondo animado con partículas -->
	<div class="hero-particles">
		<div class="particles"></div>
	</div>
	
	<!-- Imagen de fondo con overlay -->
	<div class="hero-background">
		<img 
			src="/images/Home/Banner- Academia vallenata ONLINE.jpg" 
			alt="Academia Vallenata Background"
			class="hero-bg-image"
		/>
	</div>
	
	<!-- Contenido principal -->
	<div class="hero-content">
		{#if visible}
			<div in:fly="{{ y: 50, duration: 1000, easing: quintOut }}">
				<h1 class="hero-title">
					Domina el Acordeón<br>
					<span class="hero-subtitle">Como Un Profesional</span>
				</h1>
			</div>
			
			<div in:fly="{{ y: 50, duration: 1000, delay: 200, easing: quintOut }}">
				<p class="hero-description">
					🎵 Aprende con <strong>Jesús González</strong>, el maestro más reconocido de Colombia. 
					<br>Más de <strong>5,000 estudiantes</strong> ya transformaron su vida musical.
				</p>
			</div>
			
			<div in:fly="{{ y: 50, duration: 1000, delay: 400, easing: quintOut }}" class="hero-buttons">
				<button 
					on:click={() => scrollToSection('cursos')}
					class="hero-btn-primary"
				>
					🚀 Empezar Ahora GRATIS
				</button>
				
				<button 
					on:click={() => mostrarModal = true}
					class="hero-btn-secondary"
				>
					👤 Iniciar Sesión
				</button>
			</div>
			
			<div in:scale="{{ start: 0, duration: 1000, delay: 600, easing: quintOut }}">
				<div class="hero-rating">
					<span class="rating-stars">⭐⭐⭐⭐⭐</span>
					<span class="rating-text">4.9/5 - Más de 1,200 reseñas</span>
				</div>
			</div>
		{/if}
	</div>
	
	<!-- Scroll indicator -->
	<div class="scroll-indicator">
		<div class="scroll-mouse">
			<div class="scroll-dot"></div>
		</div>
	</div>
</section>

<style>
	.hero-section {
		position: relative;
		min-height: 100vh;
		display: flex;
		align-items: center;
		justify-content: center;
		overflow: hidden;
		background: linear-gradient(135deg, #1e3a8a 0%, #7c3aed 50%, #3730a3 100%);
	}

	.hero-particles {
		position: absolute;
		inset: 0;
		opacity: 0.2;
	}

	.particles {
		background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.1'%3E%3Ccircle cx='30' cy='30' r='2'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
		animation: particleMove 20s linear infinite;
	}

	@keyframes particleMove {
		0% { transform: translateX(0) translateY(0); }
		25% { transform: translateX(20px) translateY(-20px); }
		50% { transform: translateX(-20px) translateY(-40px); }
		75% { transform: translateX(40px) translateY(-20px); }
		100% { transform: translateX(0) translateY(0); }
	}

	.hero-background {
		position: absolute;
		inset: 0;
		background: rgba(0, 0, 0, 0.4);
	}

	.hero-bg-image {
		width: 100%;
		height: 100%;
		object-fit: cover;
		opacity: 0.3;
	}

	.hero-content {
		position: relative;
		z-index: 10;
		text-align: center;
		color: white;
		padding: 0 1rem;
		max-width: 1200px;
		margin: 0 auto;
	}

	.hero-title {
		font-size: clamp(2.5rem, 8vw, 7rem);
		font-weight: 700;
		margin-bottom: 1.5rem;
		background: linear-gradient(90deg, #fbbf24 0%, #ea580c 50%, #dc2626 100%);
		background-clip: text;
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		line-height: 1.1;
	}

	.hero-subtitle {
		color: white;
		-webkit-text-fill-color: white;
	}

	.hero-description {
		font-size: clamp(1.1rem, 3vw, 2rem);
		margin-bottom: 2rem;
		color: #e5e7eb;
		max-width: 768px;
		margin-left: auto;
		margin-right: auto;
		line-height: 1.6;
	}

	.hero-buttons {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		justify-content: center;
		align-items: center;
		margin-bottom: 3rem;
	}

	.hero-btn-primary {
		padding: 1rem 2rem;
		background: linear-gradient(90deg, #fbbf24 0%, #ea580c 100%);
		color: black;
		font-weight: 700;
		font-size: 1.125rem;
		border-radius: 9999px;
		border: none;
		cursor: pointer;
		transition: all 0.3s ease;
		box-shadow: 0 10px 30px rgba(251, 191, 36, 0.3);
		animation: float 3s ease-in-out infinite;
	}

	.hero-btn-primary:hover {
		transform: scale(1.05);
		box-shadow: 0 15px 40px rgba(251, 191, 36, 0.5);
	}

	@keyframes float {
		0%, 100% { transform: translateY(0px); }
		50% { transform: translateY(-20px); }
	}

	.hero-btn-secondary {
		padding: 1rem 2rem;
		border: 2px solid white;
		color: white;
		background: transparent;
		font-weight: 700;
		font-size: 1.125rem;
		border-radius: 9999px;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.hero-btn-secondary:hover {
		background: white;
		color: black;
	}

	.hero-rating {
		display: flex;
		justify-content: center;
		align-items: center;
		gap: 0.5rem;
		color: #fbbf24;
	}

	.rating-stars {
		font-size: 2rem;
	}

	.rating-text {
		font-size: 1.125rem;
		font-weight: 600;
	}

	.scroll-indicator {
		position: absolute;
		bottom: 2rem;
		left: 50%;
		transform: translateX(-50%);
		animation: bounce 2s infinite;
	}

	.scroll-mouse {
		width: 1.5rem;
		height: 2.5rem;
		border: 2px solid white;
		border-radius: 9999px;
		display: flex;
		justify-content: center;
	}

	.scroll-dot {
		width: 0.25rem;
		height: 0.75rem;
		background: white;
		border-radius: 9999px;
		margin-top: 0.5rem;
		animation: pulse 2s infinite;
	}

	@keyframes bounce {
		0%, 20%, 50%, 80%, 100% { transform: translateX(-50%) translateY(0); }
		40% { transform: translateX(-50%) translateY(-10px); }
		60% { transform: translateX(-50%) translateY(-5px); }
	}

	@media (min-width: 640px) {
		.hero-buttons {
			flex-direction: row;
		}
	}
</style> 