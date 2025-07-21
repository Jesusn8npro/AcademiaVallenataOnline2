<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase/clienteSupabase';
	import HeroCursos from '$lib/components/Cursos/HeroCursos.svelte';
	import FiltrosCursos from '$lib/components/Cursos/FiltrosCursos.svelte';
	import GridCursos from '$lib/components/Cursos/GridCursos.svelte';

	let todosLosItems: any[] = [];
	let itemsFiltrados: any[] = [];
	let cargando = true;
	let error = '';

	let filtros = {
		texto: '',
		tipo: '',
		nivel: '',
		precio: ''
	};

	const itemsPorPagina = 12;
	let paginaActual = 1;

	let estadisticas = {
		totalCursos: 0,
		totalTutoriales: 0
	};

	onMount(async () => {
		await cargarContenido();
	});

	async function cargarContenido() {
		cargando = true;
		error = '';
		
		try {
			const [cursosResponse, tutorialesResponse] = await Promise.all([
				supabase
					.from('cursos')
					.select('*')
					.order('created_at', { ascending: false }),
				supabase
					.from('tutoriales')
					.select('*')
					.order('created_at', { ascending: false })
			]);

			if (cursosResponse.error) throw cursosResponse.error;
			if (tutorialesResponse.error) throw tutorialesResponse.error;

			const cursos = (cursosResponse.data || []).map((curso: any) => ({
				...curso,
				tipo: 'curso',
				estudiantes: generateEstudiantes(),
				rating: generateRating()
			}));

			const tutoriales = (tutorialesResponse.data || []).map((tutorial: any) => ({
				...tutorial,
				tipo: 'tutorial',
				estudiantes: generateEstudiantes(),
				rating: generateRating()
			}));

			todosLosItems = [...cursos, ...tutoriales]
				.filter(item => item.titulo && item.imagen_url)
				.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

			calcularEstadisticas();
			aplicarFiltros();

		} catch (err: any) {
			console.error('Error cargando contenido:', err);
			error = 'Error al cargar el contenido. Por favor, intenta de nuevo.';
		} finally {
			cargando = false;
		}
	}

	function generateEstudiantes() {
		const base = Math.floor(Math.random() * 2000) + 100;
		return `${base.toLocaleString()}+`;
	}

	function generateRating() {
		return (4.2 + Math.random() * 0.8).toFixed(1);
	}

	function calcularEstadisticas() {
		const cursos = todosLosItems.filter(item => item.tipo === 'curso');
		const tutoriales = todosLosItems.filter(item => item.tipo === 'tutorial');

		estadisticas = {
			totalCursos: cursos.length,
			totalTutoriales: tutoriales.length
		};
	}

	function aplicarFiltros() {
		itemsFiltrados = todosLosItems.filter(item => {
			if (filtros.texto) {
				const texto = filtros.texto.toLowerCase();
				const coincide = 
					item.titulo?.toLowerCase().includes(texto) ||
					item.descripcion?.toLowerCase().includes(texto);
				if (!coincide) return false;
			}

			if (filtros.tipo && item.tipo !== filtros.tipo) {
				return false;
			}

			if (filtros.nivel && item.nivel !== filtros.nivel) {
				return false;
			}

			if (filtros.precio === 'gratis' && (item.precio_normal > 0)) {
				return false;
			}
			if (filtros.precio === 'pago' && (!item.precio_normal || item.precio_normal === 0)) {
				return false;
			}

			return true;
		});

		paginaActual = 1;
	}

	function manejarFiltros(event: CustomEvent) {
		filtros = event.detail;
		aplicarFiltros();
	}

	$: itemsPaginados = itemsFiltrados.slice(
		(paginaActual - 1) * itemsPorPagina,
		paginaActual * itemsPorPagina
	);

	$: estadisticasActuales = {
		...estadisticas,
		totalCursos: itemsFiltrados.filter(item => item.tipo === 'curso').length,
		totalTutoriales: itemsFiltrados.filter(item => item.tipo === 'tutorial').length
	};
</script>

<svelte:head>
	<title>Cursos de Acordeón Vallenato - Academia Vallenata Online</title>
	<meta 
		name="description" 
		content="Descubre nuestros cursos premium de acordeón vallenato. Aprende desde principiante hasta nivel profesional con los mejores maestros." 
	/>
	<meta name="keywords" content="cursos acordeón vallenato, clases música, tutoriales acordeón, academia vallenata" />
</svelte:head>

<HeroCursos />

<section id="catalogo-section" class="catalogo-section">
	<div class="container">
		<div class="seccion-header">
			<h2 class="seccion-titulo">
				Explora Nuestro <span class="titulo-highlight">Catálogo Completo</span>
			</h2>
			<p class="seccion-subtitulo">
				Encuentra el curso o tutorial perfecto para tu nivel y objetivos musicales
			</p>
		</div>

		<FiltrosCursos 
			bind:filtros={filtros}
			estadisticas={estadisticasActuales}
			on:filtrar={manejarFiltros}
		/>

		<GridCursos 
			items={itemsPaginados}
			{cargando}
			{error}
			bind:paginaActual={paginaActual}
			{itemsPorPagina}
			totalItems={itemsFiltrados.length}
		/>
	</div>
</section>

<style>
	.catalogo-section {
		background: linear-gradient(180deg, #f8fafc 0%, #ffffff 100%);
		padding: 4rem 0;
    	width: 100%;
	}

	.container {
		margin: 0 auto;
		padding: 0 2rem;
	}

	.seccion-header {
		text-align: center;
		margin-bottom: 3rem;
	}

	.seccion-titulo {
		font-size: clamp(2rem, 4vw, 3rem);
		font-weight: 800;
		color: #1f2937;
		margin-bottom: 1rem;
		line-height: 1.2;
	}

	.titulo-highlight {
		background: linear-gradient(45deg, #667eea, #764ba2);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
	}

	.seccion-subtitulo {
		font-size: 1.25rem;
		color: #6b7280;
		max-width: 600px;
		margin: 0 auto;
		line-height: 1.6;
	}

	@media (max-width: 768px) {
		.catalogo-section {
			padding: 2rem 0;
		}

		.container {
			padding: 0 1rem;
		}

		.seccion-header {
			margin-bottom: 2rem;
		}

		.seccion-subtitulo {
			font-size: 1.1rem;
		}
	}
</style>

