<script lang="ts">
	import { onMount } from 'svelte';
	import ModalPagoInteligente from '$lib/components/ComponentesLanding/ModalPagoInteligente.svelte';
	import { obtenerMembresias, obtenerMembresiasPorDefecto, type Membresia } from '$lib/services/membresiaService';

	// Estado del componente
	let cargando = true;
	let mostrarModalPago = false;
	let planSeleccionado: any = null;

	// Planes de membresía (se cargan dinámicamente)
	let planes: Membresia[] = [];

	let mostrarAnual = false;

	onMount(async () => {
		try {
			// 🎯 USAR SIEMPRE DATOS DE FALLBACK PARA MOSTRAR CARACTERÍSTICAS
			// Esto asegura que las características se vean correctamente
			planes = obtenerMembresiasPorDefecto();
			console.log('✅ Membresías cargadas con características:', planes);
			
			// Intentar cargar desde base de datos (opcional, para futuro)
			// const membresiasBD = await obtenerMembresias();
			// if (membresiasBD.length > 0 && membresiasBD[0].caracteristicas?.length > 0) {
			// 	planes = membresiasBD;
			// }
		} catch (error) {
			console.error('❌ Error cargando membresías:', error);
			// Fallback a datos estáticos
			planes = obtenerMembresiasPorDefecto();
		}
		cargando = false;
	});

	function seleccionarPlan(plan: any) {
		console.log('🎯 Plan seleccionado:', plan);
		planSeleccionado = plan;
		mostrarModalPago = true;
	}

	function togglePrecio() {
		mostrarAnual = !mostrarAnual;
	}

	function calcularAhorro(precio: number, ahorro: number) {
		return Math.round((ahorro / (precio * 12)) * 100);
	}
</script>

<svelte:head>
	<title>Planes de Membresía - Academia Vallenata Online</title>
	<meta name="description" content="Elige el plan perfecto para aprender acordeón vallenato. Acceso completo a cursos, tutoriales y mentoría personalizada." />
</svelte:head>

{#if cargando}
	<div class="cargando">
		<div class="spinner"></div>
		<p>Cargando planes...</p>
	</div>
{:else}
	<div class="pagina-membresias">
		<!-- Hero Section -->
		<section class="hero">
			<div class="contenedor">
				<div class="hero-contenido">
					<div class="badge-hero">🎵 MEMBRESÍAS</div>
					<h1 class="titulo-principal">
						Desbloquea Todo Tu <span class="gradiente">Potencial Musical</span> 🎵
					</h1>
					<p class="subtitulo">
						Únete a <strong>+5,000 estudiantes</strong> que ya dominan el acordeón vallenato como profesionales
					</p>
					
					<!-- Toggle Mensual/Anual -->
					<div class="toggle-container">
						<span class="toggle-label" class:activo={!mostrarAnual}>Mensual</span>
						<button class="toggle-switch" class:anual={mostrarAnual} on:click={togglePrecio}>
							<div class="toggle-slider"></div>
						</button>
						<span class="toggle-label" class:activo={mostrarAnual}>
							Anual 
							<span class="descuento-badge">¡Ahorra hasta 30%!</span>
								</span>
					</div>
				</div>
			</div>
		</section>

		<!-- Planes de Membresía -->
		<section class="planes-seccion">
			<div class="contenedor">
				<div class="planes-wrapper">
					{#each planes as plan, index}
						<div class="plan-tarjeta" class:destacada={plan.popular} class:elite={plan.id === 'elite'}>
							<!-- Badge de plan popular/elite -->
							{#if plan.popular}
								<div class="badge-plan popular">🔥 MÁS POPULAR</div>
							{:else if plan.id === 'elite'}
								<div class="badge-plan elite">💎 PLAN ÉLITE</div>
							{/if}

							<!-- Header del plan -->
							<div class="plan-header">
								<div class="plan-info">
									<h3 class="plan-titulo">{plan.nombre}</h3>
									<p class="plan-descripcion">{plan.descripcion}</p>
								</div>
								
								<div class="precio-seccion">
									{#if mostrarAnual}
										<div class="precio-container">
											<span class="precio-simbolo">$</span>
											<span class="precio-numero">{Math.round((plan.precio_anual || 0) / 12).toLocaleString()}</span>
											<span class="precio-periodo">/mes</span>
										</div>
										<div class="precio-detalle">
											Facturado ${(plan.precio_anual || 0).toLocaleString()} anualmente
										</div>
										<div class="ahorro-badge">
											💰 Ahorras ${(plan.ahorro_anual || 0).toLocaleString()}
										</div>
									{:else}
										<div class="precio-container">
											<span class="precio-simbolo">$</span>
											<span class="precio-numero">{plan.precio.toLocaleString()}</span>
											<span class="precio-periodo">/mes</span>
										</div>
										<div class="precio-detalle">
											Sin compromisos anuales
										</div>
									{/if}
								</div>
							</div>

							<!-- Lista de características -->
							<div class="caracteristicas-lista">
								<div class="caracteristicas-titulo">
									<h4>¿Qué incluye este plan?</h4>
						</div>
								<div class="caracteristicas-contenido">
									{#each plan.caracteristicas as caracteristica}
										<div class="caracteristica-item" class:incluida={caracteristica.startsWith('✅')} class:no-incluida={caracteristica.startsWith('❌')}>
											<div class="caracteristica-icono">
												{#if caracteristica.startsWith('✅')}
													<svg viewBox="0 0 20 20" fill="currentColor" class="check-icon">
														<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
													</svg>
					{:else}
													<svg viewBox="0 0 20 20" fill="currentColor" class="x-icon">
														<path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
								</svg>
												{/if}
											</div>
											<span class="caracteristica-texto">
												{caracteristica.replace('✅ ', '').replace('❌ ', '')}
								</span>
										</div>
									{/each}
								</div>
							</div>

							<!-- Botón de acción -->
							<div class="plan-footer">
								<button 
									class="boton-plan" 
									class:destacado={plan.popular}
									class:elite={plan.id === 'elite'}
									on:click={() => seleccionarPlan(plan)}
								>
									{#if plan.popular}
										🚀 ¡Comenzar Ahora!
									{:else if plan.id === 'elite'}
										💎 Acceso Exclusivo
									{:else}
										Seleccionar Plan
									{/if}
								</button>
							</div>
						</div>
					{/each}
				</div>
			</div>
		</section>

		<!-- Garantía y Beneficios -->
		<section class="beneficios-seccion">
			<div class="contenedor">
				<h2 class="titulo-seccion">¿Por qué elegir Academia Vallenata?</h2>
				<div class="beneficios-grid">
					<div class="beneficio-item">
						<div class="beneficio-icono">🛡️</div>
						<h4>Garantía de 30 Días</h4>
						<p>Si no estás satisfecho, te devolvemos el 100% de tu dinero</p>
					</div>
					<div class="beneficio-item">
						<div class="beneficio-icono">⚡</div>
						<h4>Acceso Inmediato</h4>
						<p>Empieza a aprender desde el primer minuto después del pago</p>
					</div>
					<div class="beneficio-item">
						<div class="beneficio-icono">📱</div>
						<h4>Disponible 24/7</h4>
						<p>Aprende cuando quieras, desde cualquier dispositivo</p>
		</div>
					<div class="beneficio-item">
						<div class="beneficio-icono">🎓</div>
						<h4>Certificados Oficiales</h4>
						<p>Obtén certificados que avalan tu progreso musical</p>
		</div>
				</div>
							</div>
		</section>

		<!-- Testimonios -->
		<section class="testimonios-seccion">
			<div class="contenedor">
				<h2 class="titulo-seccion">Lo que dicen nuestros estudiantes VIP</h2>
				<div class="testimonios-grid">
					<div class="testimonio-card">
						<div class="testimonio-avatar">
							<img src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=60&h=60&fit=crop&crop=face" alt="Carlos" />
						</div>
						<div class="testimonio-contenido">
							<div class="estrellas">⭐⭐⭐⭐⭐</div>
							<p>"El Plan Intermedio cambió mi vida. En 3 meses pasé de no saber nada a tocar en fiestas familiares. ¡Increíble!"</p>
							<div class="testimonio-autor">
								<strong>Carlos Mendoza</strong>
								<span>Plan Intermedio - Barranquilla</span>
							</div>
						</div>
					</div>
					<div class="testimonio-card">
						<div class="testimonio-avatar">
							<img src="https://images.unsplash.com/photo-1494790108755-2616b612b786?w=60&h=60&fit=crop&crop=face" alt="María" />
						</div>
						<div class="testimonio-contenido">
							<div class="estrellas">⭐⭐⭐⭐⭐</div>
							<p>"La mentoría 1:1 del Plan Premium es oro puro. Jesús me ayudó a corregir errores que tenía hace años."</p>
							<div class="testimonio-autor">
								<strong>María González</strong>
								<span>Plan Premium - Medellín</span>
							</div>
						</div>
					</div>
					<div class="testimonio-card">
						<div class="testimonio-avatar">
							<img src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=60&h=60&fit=crop&crop=face" alt="Roberto" />
						</div>
						<div class="testimonio-contenido">
							<div class="estrellas">⭐⭐⭐⭐⭐</div>
							<p>"Perfecto para principiantes. El Plan Básico tiene todo lo que necesitas para empezar bien."</p>
							<div class="testimonio-autor">
								<strong>Roberto Silva</strong>
								<span>Plan Básico - Cali</span>
							</div>
						</div>
					</div>
				</div>
			</div>
		</section>
	</div>
{/if} 

<!-- Modal de Pago Inteligente -->
{#if planSeleccionado}
	<ModalPagoInteligente 
		bind:mostrar={mostrarModalPago} 
		contenido={planSeleccionado}
		tipoContenido="membresia"
	/>
{/if}

<style>
	/* Variables CSS mejoradas */
	:global(:root) {
		--primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		--success-color: #10b981;
		--warning-color: #f59e0b;
		--error-color: #ef4444;
		--text-primary: #1f2937;
		--text-secondary: #6b7280;
		--bg-primary: #ffffff;
		--bg-secondary: #f8fafc;
		--border-color: #e5e7eb;
		--shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
		--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
		--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
		--shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
	}

	* {
		margin: 0;
		padding: 0;
		box-sizing: border-box;
	}

	.pagina-membresias {
		font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
		line-height: 1.6;
		color: var(--text-primary);
		background: linear-gradient(180deg, #f8fafc 0%, #ffffff 100%);
	}

	.contenedor {
		max-width: 1800px;
		margin: 0 auto;
		padding: 0 1.5rem;
	}

	/* CARGANDO */
	.cargando {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		min-height: 60vh;
		gap: 1rem;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 4px solid var(--border-color);
		border-top: 4px solid #667eea;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		0% { transform: rotate(0deg); }
		100% { transform: rotate(360deg); }
	}

	/* HERO SECTION */
	.hero {
		background: var(--primary-gradient);
		color: white;
		padding: 4rem 0 6rem 0;
		position: relative;
		overflow: hidden;
	}

	.hero::before {
		content: '';
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.05'%3E%3Cpath d='m36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E") repeat;
		opacity: 0.3;
	}

	.hero-contenido {
		position: relative;
		z-index: 2;
		text-align: center;
		max-width: 800px;
		margin: 0 auto;
	}

	.badge-hero {
		display: inline-block;
		background: rgba(255, 255, 255, 0.2);
		color: white;
		padding: 0.5rem 1.5rem;
		border-radius: 50px;
		font-size: 0.9rem;
		font-weight: 600;
		margin-bottom: 2rem;
		backdrop-filter: blur(10px);
		border: 1px solid rgba(255, 255, 255, 0.3);
	}

	.titulo-principal {
		font-size: clamp(2.5rem, 5vw, 4rem);
		font-weight: 900;
		margin-bottom: 1.5rem;
		line-height: 1.1;
	}

	.gradiente {
		background: linear-gradient(45deg, #fbbf24, #f59e0b, #d97706);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	.subtitulo {
		font-size: 1.25rem;
		margin-bottom: 3rem;
		opacity: 0.95;
		line-height: 1.6;
	}

	/* TOGGLE PRECIO */
	.toggle-container {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 1.5rem;
		margin-top: 2rem;
		background: rgba(255, 255, 255, 0.1);
		padding: 1rem 2rem;
		border-radius: 50px;
		backdrop-filter: blur(10px);
		border: 1px solid rgba(255, 255, 255, 0.2);
		display: inline-flex;
	}

	.toggle-label {
		font-weight: 600;
		opacity: 0.7;
		transition: all 0.3s ease;
		font-size: 1rem;
	}

	.toggle-label.activo {
		opacity: 1;
		color: #fbbf24;
	}

	.toggle-switch {
		position: relative;
		width: 60px;
		height: 30px;
		background: rgba(255, 255, 255, 0.2);
		border: none;
		border-radius: 15px;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.toggle-switch.anual {
		background: #fbbf24;
	}

	.toggle-slider {
		position: absolute;
		top: 3px;
		left: 3px;
		width: 24px;
		height: 24px;
		background: white;
		border-radius: 50%;
		transition: all 0.3s ease;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
	}

	.toggle-switch.anual .toggle-slider {
		transform: translateX(30px);
	}

	.descuento-badge {
		display: inline-block;
		background: #fbbf24;
		color: #000;
		padding: 0.25rem 0.75rem;
		border-radius: 12px;
		font-size: 0.75rem;
		margin-left: 0.5rem;
		font-weight: 700;
		animation: pulse 2s infinite;
	}

	@keyframes pulse {
		0%, 100% { transform: scale(1); }
		50% { transform: scale(1.05); }
	}

	/* PLANES SECTION */
	.planes-seccion {
		padding: 4rem 0;
		background: #ffffff;
		position: relative;
		margin-top: -3rem;
		z-index: 3;
	}

	.planes-wrapper {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: 2rem;
		max-width: 95%;
		margin: 0 auto;
		padding: 0 2rem;
		align-items: stretch; /* 🔧 MISMO ALTO PARA TODAS */
	}

	/* 4 columnas en pantallas grandes - USAR TODO EL ESPACIO */
	@media (min-width: 1200px) {
		.planes-wrapper {
			grid-template-columns: repeat(4, 1fr);
			gap: 2rem;
			max-width: 98%;
			padding: 0 3rem;
		}
	}

	/* 2 columnas en tablets */
	@media (min-width: 768px) and (max-width: 1199px) {
		.planes-wrapper {
			grid-template-columns: repeat(2, 1fr);
			max-width: 90%;
			gap: 2rem;
			padding: 0 2rem;
		}
	}

	/* 1 columna en móviles */
	@media (max-width: 767px) {
		.planes-wrapper {
			grid-template-columns: 1fr;
			gap: 2rem;
			padding: 0 1rem;
			max-width: 100%;
		}
	}

	/* TARJETAS DE PLANES */
	.plan-tarjeta {
		background: var(--bg-primary);
		border-radius: 24px;
		border: 2px solid var(--border-color);
		overflow: hidden;
		transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
		position: relative;
		box-shadow: var(--shadow-lg);
		display: flex;
		flex-direction: column;
		height: 100%; /* 🔧 MISMO ALTO PARA TODAS */
	}

	.plan-tarjeta:hover {
		transform: translateY(-8px);
		box-shadow: var(--shadow-xl);
		border-color: #667eea;
	}

	.plan-tarjeta.destacada {
		border-color: #667eea;
		transform: scale(1.05);
		box-shadow: 
			var(--shadow-xl),
			0 0 0 1px rgba(102, 126, 234, 0.1);
	}

	.plan-tarjeta.destacada:hover {
		transform: scale(1.05) translateY(-8px);
	}

	.plan-tarjeta.elite {
		background: linear-gradient(145deg, #1f2937 0%, #111827 100%);
		border-color: #fbbf24;
		color: white;
	}

	/* BADGES */
	.badge-plan {
		position: absolute;
		top: -12px;
		left: 50%;
		transform: translateX(-50%);
		padding: 0.5rem 1.5rem;
		border-radius: 20px;
		font-size: 0.75rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.5px;
		z-index: 2;
	}

	.badge-plan.popular {
		background: linear-gradient(135deg, #ef4444, #dc2626);
		color: white;
		box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
	}

	.badge-plan.elite {
		background: linear-gradient(135deg, #fbbf24, #f59e0b);
		color: #000;
		box-shadow: 0 4px 12px rgba(251, 191, 36, 0.3);
	}

	/* HEADER DEL PLAN */
	.plan-header {
		padding: 1.5rem 1.5rem 1.25rem 1.5rem;
		text-align: center;
		border-bottom: 1px solid var(--border-color);
	}

	.plan-tarjeta.elite .plan-header {
		border-bottom-color: rgba(255, 255, 255, 0.1);
	}

	.plan-titulo {
		font-size: 1.5rem;
		font-weight: 700;
		margin-bottom: 0.5rem;
		color: var(--text-primary);
	}

	.plan-tarjeta.elite .plan-titulo {
		color: white;
	}

	.plan-descripcion {
		color: var(--text-secondary);
		font-size: 0.95rem;
		margin-bottom: 2rem;
		line-height: 1.5;
	}

	.plan-tarjeta.elite .plan-descripcion {
		color: rgba(255, 255, 255, 0.8);
	}

	/* PRECIOS */
	.precio-seccion {
		text-align: center;
	}

	.precio-container {
		display: flex;
		align-items: baseline;
		justify-content: center;
		margin-bottom: 0.5rem;
	}

	.precio-simbolo {
		font-size: 1.5rem;
		font-weight: 600;
		color: var(--text-secondary);
	}

	.precio-numero {
		font-size: 3rem;
		font-weight: 900;
		color: #667eea;
		margin: 0 0.25rem;
	}

	.plan-tarjeta.elite .precio-numero {
		color: #fbbf24;
	}

	.precio-periodo {
		font-size: 1rem;
		color: var(--text-secondary);
	}

	.precio-detalle {
		font-size: 0.9rem;
		color: var(--text-secondary);
		margin-bottom: 1rem;
	}

	.plan-tarjeta.elite .precio-detalle {
		color: rgba(255, 255, 255, 0.7);
	}

	.ahorro-badge {
		display: inline-block;
		background: linear-gradient(135deg, #10b981, #059669);
		color: white;
		padding: 0.5rem 1rem;
		border-radius: 20px;
		font-size: 0.8rem;
		font-weight: 600;
	}

	/* CARACTERÍSTICAS */
	.caracteristicas-lista {
		padding: 1.5rem 1.5rem 1.5rem 1.5rem;
		flex-grow: 1; /* 🔧 OCUPA EL ESPACIO RESTANTE */
		display: flex;
		flex-direction: column;
	}

	.caracteristicas-titulo {
		margin-bottom: 1rem;
		padding-bottom: 0.75rem;
		border-bottom: 1px solid var(--border-color);
	}

	.plan-tarjeta.elite .caracteristicas-titulo {
		border-bottom-color: rgba(255, 255, 255, 0.2);
	}

	.caracteristicas-titulo h4 {
		font-size: 1rem;
		font-weight: 700;
		color: var(--text-primary);
		margin: 0;
	}

	.plan-tarjeta.elite .caracteristicas-titulo h4 {
		color: white;
	}

	.caracteristicas-contenido {
		flex-grow: 1;
		display: flex;
		flex-direction: column;
		justify-content: flex-start;
	}

	.caracteristica-item {
		display: flex;
		align-items: flex-start;
		margin-bottom: 0.5rem;
		padding: 0.75rem 1rem;
		border-radius: 8px;
		transition: all 0.2s ease;
		border-left: 3px solid transparent;
	}

	.caracteristica-item:hover {
		background: rgba(102, 126, 234, 0.08);
		transform: translateX(4px);
	}

	.caracteristica-item.incluida {
		border-left-color: var(--success-color);
		background: rgba(16, 185, 129, 0.05);
	}

	.caracteristica-item.no-incluida {
		border-left-color: #d1d5db;
		background: rgba(107, 114, 128, 0.03);
	}

	.plan-tarjeta.elite .caracteristica-item:hover {
		background: rgba(255, 255, 255, 0.08);
	}

	.plan-tarjeta.elite .caracteristica-item.incluida {
		border-left-color: #fbbf24;
		background: rgba(251, 191, 36, 0.1);
	}

	.plan-tarjeta.elite .caracteristica-item.no-incluida {
		border-left-color: rgba(255, 255, 255, 0.3);
		background: rgba(255, 255, 255, 0.05);
	}

	.caracteristica-icono {
		flex-shrink: 0;
		width: 18px;
		height: 18px;
		margin-right: 0.75rem;
		margin-top: 0.1rem;
	}

	.check-icon {
		color: var(--success-color);
	}

	.x-icon {
		color: var(--text-secondary);
		opacity: 0.6;
	}

	.plan-tarjeta.elite .check-icon {
		color: #fbbf24;
	}

	.plan-tarjeta.elite .x-icon {
		color: rgba(255, 255, 255, 0.4);
	}

	.caracteristica-texto {
		font-size: 0.9rem;
		line-height: 1.4;
		font-weight: 500;
	}

	.caracteristica-item.incluida .caracteristica-texto {
		color: var(--text-primary);
		font-weight: 600;
	}

	.caracteristica-item.no-incluida .caracteristica-texto {
		color: var(--text-secondary);
		opacity: 0.8;
		font-weight: 400;
		text-decoration: line-through;
	}

	.plan-tarjeta.elite .caracteristica-item.incluida .caracteristica-texto {
		color: white;
		font-weight: 600;
	}

	.plan-tarjeta.elite .caracteristica-item.no-incluida .caracteristica-texto {
		color: rgba(255, 255, 255, 0.6);
		opacity: 0.8;
	}

	/* FOOTER DEL PLAN */
	.plan-footer {
		padding: 1.5rem;
		border-top: 1px solid var(--border-color);
		margin-top: auto; /* 🔧 BOTÓN SIEMPRE AL FINAL */
	}

	.plan-tarjeta.elite .plan-footer {
		border-top-color: rgba(255, 255, 255, 0.1);
	}

	.boton-plan {
		width: 100%;
		padding: 1rem 2rem;
		background: var(--primary-gradient);
		color: white;
		border: none;
		border-radius: 12px;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s ease;
		text-transform: none;
		position: relative;
		overflow: hidden;
	}

	.boton-plan::before {
		content: '';
		position: absolute;
		top: 0;
		left: -100%;
		width: 100%;
		height: 100%;
		background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
		transition: left 0.5s;
	}

	.boton-plan:hover::before {
		left: 100%;
	}

	.boton-plan:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 25px rgba(102, 126, 234, 0.3);
	}

	.boton-plan.destacado {
		background: linear-gradient(135deg, #ef4444, #dc2626);
		font-size: 1.1rem;
		padding: 1.25rem 2rem;
	}

	.boton-plan.destacado:hover {
		box-shadow: 0 8px 25px rgba(239, 68, 68, 0.3);
	}

	.boton-plan.elite {
		background: linear-gradient(135deg, #fbbf24, #f59e0b);
		color: #000;
		font-weight: 700;
	}

	.boton-plan.elite:hover {
		box-shadow: 0 8px 25px rgba(251, 191, 36, 0.3);
	}

	/* BENEFICIOS SECTION */
	.beneficios-seccion {
		padding: 4rem 0;
		background: var(--bg-secondary);
	}

	.titulo-seccion {
		text-align: center;
		font-size: 2.5rem;
		font-weight: 800;
		margin-bottom: 3rem;
		color: var(--text-primary);
	}

	.beneficios-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 2rem;
	}

	.beneficio-item {
		text-align: center;
		padding: 2rem;
		background: white;
		border-radius: 16px;
		box-shadow: var(--shadow-md);
		transition: all 0.3s ease;
	}

	.beneficio-item:hover {
		transform: translateY(-4px);
		box-shadow: var(--shadow-lg);
	}

	.beneficio-icono {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.beneficio-item h4 {
		font-size: 1.25rem;
		font-weight: 700;
		margin-bottom: 0.75rem;
		color: var(--text-primary);
	}

	.beneficio-item p {
		color: var(--text-secondary);
		line-height: 1.6;
	}

	/* TESTIMONIOS */
	.testimonios-seccion {
		padding: 4rem 0;
		background: white;
	}

	.testimonios-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
		gap: 2rem;
	}

	.testimonio-card {
		background: white;
		padding: 2rem;
		border-radius: 16px;
		box-shadow: var(--shadow-lg);
		border: 1px solid var(--border-color);
		transition: all 0.3s ease;
	}

	.testimonio-card:hover {
		transform: translateY(-4px);
		box-shadow: var(--shadow-xl);
	}

	.testimonio-avatar {
		width: 60px;
		height: 60px;
		border-radius: 50%;
		overflow: hidden;
		margin-bottom: 1rem;
	}

	.testimonio-avatar img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.estrellas {
		font-size: 1.1rem;
		margin-bottom: 1rem;
	}

	.testimonio-contenido p {
		font-style: italic;
		margin-bottom: 1.5rem;
		line-height: 1.6;
		color: var(--text-primary);
	}

	.testimonio-autor strong {
		color: var(--text-primary);
		font-weight: 600;
	}

	.testimonio-autor span {
		color: var(--text-secondary);
		font-size: 0.9rem;
		display: block;
		margin-top: 0.25rem;
	}

	/* RESPONSIVE */
	@media (max-width: 1024px) {
		.planes-wrapper {
			grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		}
		
		.plan-tarjeta.destacada,
		.plan-tarjeta.elite {
			transform: none;
		}
		
		.plan-tarjeta.destacada:hover,
		.plan-tarjeta.elite:hover {
			transform: translateY(-8px);
		}
	}

	@media (max-width: 768px) {
		.planes-wrapper {
			grid-template-columns: 1fr;
		}
		
		.plan-header {
			padding: 1.5rem;
		}

		.caracteristicas-lista {
			padding: 1.5rem;
		}

		.plan-footer {
			padding: 1.5rem;
		}

		.titulo-principal {
			font-size: 2.5rem;
		}

		.toggle-container {
			flex-direction: column;
			gap: 1rem;
			padding: 1.5rem;
		}

		.testimonios-grid {
			grid-template-columns: 1fr;
		}

		.beneficios-grid {
			grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		}
	}
</style> 