<script lang="ts">
	import ModalDeInicioDeSesion from '$lib/components/Autenticacion/ModalDeInicioDeSesion.svelte';
	
	// Componentes de la nueva Landing Page
	import HeroHome from '$lib/components/Inicio/HeroHome.svelte';
	import SeccionBeneficios from '$lib/components/ComponentesLanding/SeccionBeneficios.svelte';
	// TODO: Crear estos componentes cuando sea necesario
	// import SobreInstructor from '$lib/components/ComponentesLanding/SobreInstructor.svelte';
	// import TestimoniosEstudiantes from '$lib/components/ComponentesLanding/TestimoniosEstudiantes.svelte';
	// import PreguntasFrecuentes from '$lib/components/ComponentesLanding/PreguntasFrecuentes.svelte';
	// import CTAFinal from '$lib/components/ComponentesLanding/CTAFinal.svelte';
	// import FooterCompleto from '$lib/components/ComponentesLanding/FooterCompleto.svelte';

	let mostrarModal = false;

	// Función para hacer scroll suave a una sección
	function scrollToSection(sectionId: string) {
		const element = document.getElementById(sectionId);
		if (element) {
			element.scrollIntoView({ behavior: 'smooth' });
		}
	}
</script>

<svelte:head>
	<title>Academia Vallenata Online - Aprende Acordeón con Jesús González | Curso Completo</title>
	<meta name="description" content="🎵 Aprende acordeón vallenato desde cero con el maestro Jesús González. +5,000 estudiantes, método único, clases online 24/7. ¡Empieza GRATIS hoy!" />
	<meta name="keywords" content="acordeón vallenato, clases online, Jesús González, curso acordeón, vallenato Colombia, aprender acordeón" />
	<meta property="og:title" content="Academia Vallenata Online - Aprende Acordeón Vallenato" />
	<meta property="og:description" content="Únete a +5,000 estudiantes que ya tocan acordeón vallenato. Método único del maestro Jesús González." />
	<meta property="og:image" content="/images/og-image-academia.jpg" />
	<meta property="og:type" content="website" />
	<meta name="twitter:card" content="summary_large_image" />
</svelte:head>

<!-- Modal de inicio de sesión -->
<ModalDeInicioDeSesion bind:abierto={mostrarModal} />

<!-- Landing Page Completa -->
<main>
	<!-- 1. Hero Section -->
	<HeroHome 
		bind:mostrarModal 
		{scrollToSection} 
	/>

	<!-- 2. Beneficios de la Academia -->
	<SeccionBeneficios contenido={{}} tipo="curso" />

	<!-- TODO: Activar estas secciones cuando los componentes estén creados -->
	
	<!-- 4. Sobre el Instructor -->
	<!-- <SobreInstructor /> -->

	<!-- 5. Testimonios de Estudiantes -->
	<!-- <TestimoniosEstudiantes /> -->

	<!-- 6. Preguntas Frecuentes -->
	<!-- <PreguntasFrecuentes /> -->

	<!-- 7. Call to Action Final -->
	<!-- <CTAFinal /> -->

	<!-- 8. Footer Completo -->
	<!-- <FooterCompleto /> -->
</main>

<style>
	main {
		width: 100%;
		min-height: 100vh;
	}
	
	/* Asegurar que no haya espacios entre secciones */
	:global(section) {
		margin: 0;
		padding: 0;
	}
	
	/* Smooth scroll para toda la página */
	:global(html) {
		scroll-behavior: smooth;
	}
</style>
  