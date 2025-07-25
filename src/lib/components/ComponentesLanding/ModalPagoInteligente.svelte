<script lang="ts">
	import { onMount } from 'svelte';
	import { usuario } from '$lib/UsuarioActivo/usuario';

	// Props
	export let mostrar = false;
	export let contenido: any = null; // Curso o tutorial
	export let tipoContenido: 'curso' | 'tutorial' = 'curso';

	// Estado del modal
	let pasoActual = 1;
	let cargando = false;
	let procesandoPago = false; // Nueva variable para evitar múltiples clics
	let error = '';
	let datosPago = {
		// Datos básicos
		nombre: '',
		apellido: '',
		email: '',
		telefono: '',
		whatsapp: '',
		
		// Datos de facturación/identificación
		tipo_documento: 'CC', // CC, CE, NIT, Pasaporte
		numero_documento: '',
		direccion: '',
		ciudad: '',
		pais: 'Colombia',
		codigo_postal: '',
		
		// Datos adicionales
		fecha_nacimiento: '',
		profesion: '',
		como_nos_conocio: 'Redes sociales',
		
		// Contraseña para usuarios nuevos
		password: '',
		confirmarPassword: ''
	};
	let pagoExitoso = false;
	let usuarioEstaRegistrado = false;
	
	// Variables para validación en tiempo real
	let erroresValidacion = {
		email: '',
		telefono: '',
		documento: '',
		password: ''
	};
	
	// Variables de seguridad adicionales
	let ultimoIntentoPago = 0;
	const TIEMPO_MINIMO_ENTRE_INTENTOS = 3000; // 3 segundos

	// --- LÓGICA DE EPAYCO ON-PAGE ---
	let handler: any;
	// Credenciales de ePayco (modo test)
	const EPAYCO_PUBLIC_KEY = 'a04d60e2e678d5bd89a58d26f3413fdb';
	const EPAYCO_CUSTOMER_ID = '37257';

	function loadEpaycoScript() {
		return new Promise((resolve, reject) => {
			if (document.querySelector('script[src="https://checkout.epayco.co/checkout.js"]')) {
				resolve(true);
				return;
			}
			const script = document.createElement('script');
			script.src = 'https://checkout.epayco.co/checkout.js';
			script.onload = () => resolve(true);
			script.onerror = () => reject(new Error('No se pudo cargar el script de ePayco.'));
			document.head.appendChild(script);
		});
	}

	function cerrarModal() {
		mostrar = false;
		// Reset estado
		pasoActual = 1;
		error = '';
		cargando = false;
		procesandoPago = false;
		pagoExitoso = false;
		usuarioEstaRegistrado = false;
		
		// Limpiar errores de validación
		erroresValidacion = {
			email: '',
			telefono: '',
			documento: '',
			password: ''
		};
		
		// Reset rate limiting
		ultimoIntentoPago = 0;
	}

	function validarDatosPago() {
		// Ejecutar validaciones en tiempo real para obtener errores actualizados
		validarEmail(datosPago.email);
		validarTelefono(datosPago.telefono);
		validarDocumento(datosPago.numero_documento, datosPago.tipo_documento);
		if (!usuarioEstaRegistrado) {
			validarPassword(datosPago.password);
		}
		
		// Verificar si hay errores de validación en tiempo real
		if (erroresValidacion.email || erroresValidacion.telefono || erroresValidacion.documento || erroresValidacion.password) {
			error = 'Por favor, corrige los errores marcados en rojo.';
			return false;
		}
		
		// Validaciones básicas
		if (!datosPago.nombre.trim() || !datosPago.email.trim() || !datosPago.telefono.trim()) {
			error = 'Por favor, completa tu nombre, email y teléfono.';
			return false;
		}
		
		// Validación de nombre (solo letras y espacios)
		if (!/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/.test(datosPago.nombre.trim())) {
			error = 'El nombre solo puede contener letras y espacios.';
			return false;
		}
		
		if (datosPago.apellido && !/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/.test(datosPago.apellido.trim())) {
			error = 'El apellido solo puede contener letras y espacios.';
			return false;
		}
		
		// Validación de email más robusta
		const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
		if (!emailRegex.test(datosPago.email.trim())) {
			error = 'Por favor, introduce un correo electrónico válido.';
			return false;
		}
		
		// Validación de teléfono (solo números, espacios, guiones y paréntesis)
		const telefonoLimpio = datosPago.telefono.replace(/[\s\-\(\)]/g, '');
		if (!/^\d{7,15}$/.test(telefonoLimpio)) {
			error = 'El teléfono debe tener entre 7 y 15 dígitos.';
			return false;
		}
		
		// Validaciones adicionales para facturación
		if (!datosPago.numero_documento.trim()) {
			error = 'El número de documento es requerido para la facturación.';
			return false;
		}
		
		// Validación de documento según tipo
		const docLimpio = datosPago.numero_documento.replace(/[\s\-\.]/g, '');
		if (datosPago.tipo_documento === 'CC' && (docLimpio.length < 6 || docLimpio.length > 10)) {
			error = 'La cédula debe tener entre 6 y 10 dígitos.';
			return false;
		}
		
		if (datosPago.tipo_documento === 'NIT' && (docLimpio.length < 9 || docLimpio.length > 12)) {
			error = 'El NIT debe tener entre 9 y 12 dígitos.';
			return false;
		}
		
		if (!datosPago.direccion.trim() || datosPago.direccion.trim().length < 10) {
			error = 'La dirección debe tener al menos 10 caracteres.';
			return false;
		}
		
		if (!datosPago.ciudad.trim() || datosPago.ciudad.trim().length < 2) {
			error = 'La ciudad es requerida.';
			return false;
		}
		
		// Validación de contraseña para usuarios nuevos
		if (!usuarioEstaRegistrado) {
			if (!datosPago.password.trim()) {
				error = 'Por favor, crea una contraseña para tu cuenta.';
				return false;
			}
			
			if (datosPago.password.length < 8) {
				error = 'La contraseña debe tener al menos 8 caracteres.';
				return false;
			}
			
			// Validar que la contraseña tenga al menos una letra y un número
			if (!/(?=.*[a-zA-Z])(?=.*\d)/.test(datosPago.password)) {
				error = 'La contraseña debe contener al menos una letra y un número.';
				return false;
			}
			
			if (datosPago.password !== datosPago.confirmarPassword) {
				error = 'Las contraseñas no coinciden.';
				return false;
			}
		}
		
		error = '';
		return true;
	}

	function handleSiguiente() {
		if (pasoActual === 1) {
			if (!usuarioEstaRegistrado) {
				// Si no está registrado, ir directo al formulario
				pasoActual = 2;
			} else {
				// Si está registrado, verificar si faltan datos críticos
				if (!datosPago.numero_documento || !datosPago.direccion) {
					// Faltan datos críticos, ir al formulario
					pasoActual = 2;
				} else {
					// Todos los datos están completos, procesar pago
					procesarPago();
				}
			}
		} else if (pasoActual === 2) {
			if (validarDatosPago()) {
				procesarPago();
			}
		}
	}

	function handleAtras() {
		if (pasoActual > 1) {
			pasoActual--;
		}
	}

	// Al abrir el modal, verificamos el estado del usuario
	$: if (mostrar) {
		verificarUsuario();
	}

	async function verificarUsuario() {
		if ($usuario) {
			usuarioEstaRegistrado = true;
			pasoActual = 1; // SIEMPRE mostrar el paso 1 primero
			
			// Llenar datos desde el perfil del usuario
			datosPago.nombre = $usuario.nombre || '';
			datosPago.apellido = $usuario.apellido || '';
			datosPago.email = $usuario.correo_electronico || '';
			// @ts-ignore - El campo whatsapp puede no existir en todos los perfiles
			datosPago.telefono = $usuario.whatsapp || '';
			datosPago.whatsapp = $usuario.whatsapp || '';
			// @ts-ignore - Los campos ciudad y pais pueden no existir en todos los perfiles
			datosPago.ciudad = $usuario.ciudad || '';
			// @ts-ignore - Los campos ciudad y pais pueden no existir en todos los perfiles
			datosPago.pais = $usuario.pais || 'Colombia';
			
		} else {
			usuarioEstaRegistrado = false;
			pasoActual = 1; // Mostrar opciones de registro/login
		}
	}

	async function procesarPago() {
		// --- 1. PREVENCIÓN DE MÚLTIPLES CLICS Y RATE LIMITING ---
		const ahora = Date.now();
		if (procesandoPago || ahora - ultimoIntentoPago < TIEMPO_MINIMO_ENTRE_INTENTOS) {
			console.warn('Intento de pago duplicado o demasiado rápido, ignorando.');
			return;
		}
		
		procesandoPago = true;
		ultimoIntentoPago = ahora;
		cargando = true;
		error = '';

		try {
			// --- 2. CARGAR EL SCRIPT DE EPAYCO ---
			await loadEpaycoScript();
			
			// --- 3. OBTENER PRECIO Y VERIFICAR SI ES GRATUITO ---
			const totalAPagar = obtenerPrecio(contenido);
			const tituloProducto = obtenerTitulo(contenido);
			
			if (totalAPagar <= 0) {
				console.log('Contenido gratuito, procesando inscripción...');
				pagoExitoso = true;
				// Aquí iría la lógica para inscribir al usuario directamente
				return;
			}
			
			// --- 4. PREPARAR Y ENVIAR DATOS AL BACKEND ---
			const datosSanitizados = sanitizarDatos({ ...datosPago });
			const dataParaApi = {
				usuarioId: $usuario?.id || null,
				esUsuarioNuevo: !usuarioEstaRegistrado,
				cursoId: tipoContenido === 'curso' ? contenido.id : undefined,
				tutorialId: tipoContenido === 'tutorial' ? contenido.id : undefined,
				email: datosSanitizados.email,
				nombre: datosSanitizados.nombre,
				telefono: datosSanitizados.telefono,
				datosAdicionales: {
					apellido: datosSanitizados.apellido,
					whatsapp: datosSanitizados.whatsapp,
					documento_tipo: datosSanitizados.tipo_documento,
					documento_numero: datosSanitizados.numero_documento,
					direccion_completa: datosSanitizados.direccion,
					ciudad: datosSanitizados.ciudad,
					pais: datosSanitizados.pais,
					codigo_postal: datosSanitizados.codigo_postal,
					fecha_nacimiento: datosSanitizados.fecha_nacimiento,
					profesion: datosSanitizados.profesion,
					como_nos_conocio: datosSanitizados.como_nos_conocio
				},
				password: usuarioEstaRegistrado ? undefined : datosSanitizados.password
			};
			
			const response = await fetch('/api/pagos/crear', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify(dataParaApi)
			});
			
			if (!response.ok) {
				const errorData = await response.json();
				throw new Error(errorData.message || `Error del servidor: ${response.status}`);
			}
			
			const { epaycoData } = await response.json();
			
			// --- 5. CONFIGURAR Y ABRIR EL CHECKOUT DE EPAYCO (EL MODO CORRECTO) ---
			if ((window as any).ePayco) {
				// Paso 1: Configurar el handler con la llave y el modo test
				const handler = (window as any).ePayco.checkout.configure({
					key: epaycoData.key,
					test: epaycoData.test
				});

				// Paso 2: Abrir el checkout con los datos de la transacción
				handler.open(epaycoData);

			} else {
				throw new Error('El objeto ePayco no se encontró en window.');
			}
			
		} catch (err: any) {
			console.error('Error en procesarPago:', err);
			error = err.message || 'Ocurrió un error inesperado al procesar el pago.';
		} finally {
			cargando = false;
			procesandoPago = false; // Liberar el bloqueo de pago
		}
	}

	// Función para manejar registro rápido
	function registroRapido() {
		usuarioEstaRegistrado = false;
		pasoActual = 2;
	}

	// Obtener precio seguro del contenido
	function obtenerPrecio(contenido: any): number {
		if (!contenido) return 0;
		// La lógica de precios es la misma para cursos y tutoriales.
		return contenido.precio_rebajado || contenido.precio_normal || 0;
	}

	// Obtener título seguro del contenido
	function obtenerTitulo(contenido: any): string {
		if (!contenido) return 'Contenido no disponible';
		return contenido.titulo || 'Sin título';
	}

	// Función para sanitizar datos con mayor seguridad
	function sanitizarDatos(datos: any) {
		const datosSanitizados: any = {};
		
		// Limpiar y normalizar campos de texto con validación de seguridad
		if (datos.nombre) {
			datosSanitizados.nombre = datos.nombre.trim()
				.replace(/\s+/g, ' ')
				.replace(/[<>'"&]/g, '') // Remover caracteres potencialmente peligrosos
				.substring(0, 50); // Limitar longitud
		}
		
		if (datos.apellido) {
			datosSanitizados.apellido = datos.apellido.trim()
				.replace(/\s+/g, ' ')
				.replace(/[<>'"&]/g, '')
				.substring(0, 50);
		}
		
		if (datos.email) {
			datosSanitizados.email = datos.email.trim()
				.toLowerCase()
				.replace(/[<>'"&]/g, '')
				.substring(0, 100);
		}
		
		if (datos.telefono) {
			datosSanitizados.telefono = datos.telefono.replace(/[^\d+\-\s()]/g, '').trim();
		}
		
		if (datos.whatsapp) {
			datosSanitizados.whatsapp = datos.whatsapp.replace(/[^\d+\-\s()]/g, '').trim();
		}
		
		if (datos.direccion) {
			datosSanitizados.direccion = datos.direccion.trim()
				.replace(/\s+/g, ' ')
				.replace(/[<>'"&]/g, '')
				.substring(0, 200);
		}
		
		if (datos.ciudad) {
			datosSanitizados.ciudad = datos.ciudad.trim()
				.replace(/\s+/g, ' ')
				.replace(/[<>'"&]/g, '')
				.substring(0, 50);
		}
		
		if (datos.pais) {
			datosSanitizados.pais = datos.pais.trim()
				.replace(/[<>'"&]/g, '')
				.substring(0, 50);
		}
		
		if (datos.profesion) {
			datosSanitizados.profesion = datos.profesion.trim()
				.replace(/[<>'"&]/g, '')
				.substring(0, 100);
		}
		
		// Limpiar número de documento (solo números y guiones)
		if (datos.numero_documento) {
			datosSanitizados.numero_documento = datos.numero_documento.replace(/[^\d\-]/g, '');
		}
		
		// Limpiar teléfonos (mantener solo números y caracteres válidos)
		if (datos.telefono) {
			const telefonoLimpio = datos.telefono.replace(/[^\d]/g, '');
			datosSanitizados.telefono = telefonoLimpio.substring(0, 15);
		}
		
		if (datos.whatsapp) {
			const whatsappLimpio = datos.whatsapp.replace(/[^\d]/g, '');
			datosSanitizados.whatsapp = whatsappLimpio.substring(0, 15);
		}
		
		// Limpiar código postal
		if (datos.codigo_postal) {
			datosSanitizados.codigo_postal = datos.codigo_postal.trim()
				.replace(/[^\w\-]/g, '')
				.substring(0, 10);
		}
		
		return datosSanitizados;
	}

	// Validaciones en tiempo real con mayor seguridad
	function validarEmail(email: string) {
		const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
		const caracteresProhibidos = /[<>'"&]/;
		
		if (!email) {
			erroresValidacion.email = '';
		} else if (caracteresProhibidos.test(email)) {
			erroresValidacion.email = 'Caracteres no permitidos en email';
		} else if (email.length > 100) {
			erroresValidacion.email = 'Email demasiado largo';
		} else if (!emailRegex.test(email.trim())) {
			erroresValidacion.email = 'Email inválido';
		} else {
			erroresValidacion.email = '';
		}
	}

	function validarTelefono(telefono: string) {
		const telefonoLimpio = telefono.replace(/[\s\-\(\)]/g, '');
		const caracteresProhibidos = /[<>'"&]/;
		
		if (!telefono) {
			erroresValidacion.telefono = '';
		} else if (caracteresProhibidos.test(telefono)) {
			erroresValidacion.telefono = 'Caracteres no permitidos';
		} else if (!/^\d{7,15}$/.test(telefonoLimpio)) {
			erroresValidacion.telefono = 'Teléfono debe tener 7-15 dígitos';
		} else {
			erroresValidacion.telefono = '';
		}
	}

	function validarDocumento(documento: string, tipo: string) {
		const docLimpio = documento.replace(/[\s\-\.]/g, '');
		const caracteresProhibidos = /[<>'"&]/;
		
		if (!documento) {
			erroresValidacion.documento = '';
		} else if (caracteresProhibidos.test(documento)) {
			erroresValidacion.documento = 'Caracteres no permitidos';
		} else if (tipo === 'CC' && (docLimpio.length < 6 || docLimpio.length > 10)) {
			erroresValidacion.documento = 'Cédula: 6-10 dígitos';
		} else if (tipo === 'NIT' && (docLimpio.length < 9 || docLimpio.length > 12)) {
			erroresValidacion.documento = 'NIT: 9-12 dígitos';
		} else if (tipo === 'CE' && (docLimpio.length < 6 || docLimpio.length > 12)) {
			erroresValidacion.documento = 'CE: 6-12 dígitos';
		} else if (tipo === 'Pasaporte' && (documento.length < 6 || documento.length > 20)) {
			erroresValidacion.documento = 'Pasaporte: 6-20 caracteres';
		} else {
			erroresValidacion.documento = '';
		}
	}

	function validarPassword(password: string) {
		const caracteresProhibidos = /[<>'"&]/;
		
		if (!password) {
			erroresValidacion.password = '';
		} else if (caracteresProhibidos.test(password)) {
			erroresValidacion.password = 'Caracteres no permitidos';
		} else if (password.length < 8) {
			erroresValidacion.password = 'Mínimo 8 caracteres';
		} else if (password.length > 128) {
			erroresValidacion.password = 'Máximo 128 caracteres';
		} else if (!/(?=.*[a-zA-Z])(?=.*\d)/.test(password)) {
			erroresValidacion.password = 'Debe tener letra y número';
		} else {
			erroresValidacion.password = '';
		}
	}
</script>

<svelte:head>
	<!-- El script se carga dinámicamente en onMount -->
</svelte:head>

{#if mostrar}
	<div
		class="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4"
		on:click={cerrarModal}
		role="dialog"
		aria-modal="true"
		aria-labelledby="modal-title"
	>
		<div
			class="bg-gray-800 rounded-lg shadow-xl w-full max-w-2xl mx-auto text-white border border-gray-700 relative transition-all duration-300 modal-content max-h-[90vh] overflow-y-auto"
			on:click|stopPropagation
		>
			<!-- Botón de cerrar -->
			<button
				on:click={cerrarModal}
				class="absolute top-3 right-3 text-gray-400 hover:text-white transition-colors z-10"
				aria-label="Cerrar modal"
			>
				<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
				</svg>
			</button>

			<div class="p-6 md:p-8">
				{#if pasoActual !== 4 && pasoActual !== 5}
					<h2 id="modal-title" class="text-2xl font-bold mb-4 text-center">
						{#if pasoActual === 1}
							{#if usuarioEstaRegistrado}
								Confirmar Compra
							{:else}
								Completar Compra
							{/if}
						{:else}
							Datos de Facturación
						{/if}
					</h2>
				{/if}

				<!-- Resumen del Producto -->
				{#if contenido && pasoActual !== 4}
					<div class="bg-gradient-to-r from-purple-600/20 to-blue-600/20 border border-purple-500/50 p-4 rounded-lg mb-4">
						<div class="flex justify-between items-center">
							<div>
								<h3 class="font-semibold text-lg text-white">{obtenerTitulo(contenido)}</h3>
								<p class="text-gray-300 text-sm">
									{tipoContenido === 'curso' ? '🎓 Curso completo' : '🎵 Tutorial individual'}
								</p>
							</div>
							<div class="text-right">
								<p class="text-2xl font-bold text-green-400">
									${obtenerPrecio(contenido).toLocaleString('es-CO')}
								</p>
								<p class="text-xs text-gray-400">COP</p>
							</div>
						</div>
					</div>
				{:else if !contenido}
					<div class="bg-red-500/20 border border-red-500 text-red-300 px-4 py-3 rounded-md mb-4 text-sm" role="alert">
						<p>⚠️ No se ha seleccionado contenido para comprar</p>
					</div>
				{/if}
				
				{#if error}
					<div class="bg-red-500/20 border border-red-500 text-red-300 px-4 py-3 rounded-md mb-4 text-sm" role="alert">
						<p>{error}</p>
					</div>
				{/if}

				<!-- Paso 1: Estado inicial -->
				{#if pasoActual === 1}
					{#if usuarioEstaRegistrado}
						<!-- Usuario registrado - mostrar resumen y botón directo -->
						<div class="text-center">
							<div class="bg-green-500/20 border border-green-500 text-green-300 px-4 py-3 rounded-md mb-4 text-sm">
								<p>✅ Sesión activa como: <strong>{$usuario?.nombre}</strong></p>
								<p class="text-xs text-green-200 mt-1">{$usuario?.correo_electronico}</p>
							</div>
							<p class="mb-4">Puedes proceder directamente con tu compra.</p>
						</div>
					{:else}
						<!-- Usuario no registrado - ir directo al formulario -->
						<div class="text-center space-y-4">
							<div class="bg-blue-500/20 border border-blue-500 text-blue-300 px-4 py-3 rounded-md text-sm">
								<p class="font-semibold">🆕 Crear tu cuenta es fácil y rápido</p>
								<p class="text-xs mt-1">Completa tus datos y tendrás acceso inmediato</p>
							</div>
							
							<p class="text-gray-300 mb-4">
								Al completar tu compra, crearemos automáticamente tu cuenta con acceso completo a la plataforma.
							</p>
						</div>
					{/if}
				{/if}

				<!-- Paso 2: Formulario de Datos (solo para usuarios no registrados o datos faltantes) -->
				{#if pasoActual === 2}
					<form on:submit|preventDefault={handleSiguiente} class="space-y-3">
						
						<!-- Datos Personales -->
						<div class="bg-gray-700/30 p-3 rounded-lg">
							<h4 class="font-semibold text-purple-300 mb-2 text-sm">👤 Datos Personales</h4>
							
							<div class="grid grid-cols-2 gap-2">
								<div>
									<input 
										type="text" 
										id="nombre" 
										bind:value={datosPago.nombre} 
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition" 
										required 
										placeholder="Nombres"
									/>
								</div>
								<div>
									<input 
										type="text" 
										id="apellido" 
										bind:value={datosPago.apellido} 
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition" 
										required 
										placeholder="Apellidos"
									/>
								</div>
							</div>
							
							<div class="grid grid-cols-2 gap-2 mt-2">
								<div>
									<input 
										type="email" 
										id="email" 
										bind:value={datosPago.email} 
										on:input={() => validarEmail(datosPago.email)}
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition {erroresValidacion.email ? 'border-red-500' : ''}" 
										required 
										placeholder="tu@email.com"
									/>
									{#if erroresValidacion.email}
										<p class="text-red-400 text-xs mt-1">{erroresValidacion.email}</p>
									{/if}
								</div>
								<div>
									<input 
										type="tel" 
										id="telefono" 
										bind:value={datosPago.telefono} 
										on:input={() => validarTelefono(datosPago.telefono)}
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition {erroresValidacion.telefono ? 'border-red-500' : ''}" 
										required 
										placeholder="+57 300 123 4567"
									/>
									{#if erroresValidacion.telefono}
										<p class="text-red-400 text-xs mt-1">{erroresValidacion.telefono}</p>
									{/if}
								</div>
							</div>
						</div>

						<!-- Datos de Identificación y Facturación -->
						<div class="bg-gray-700/30 p-3 rounded-lg">
							<h4 class="font-semibold text-purple-300 mb-2 text-sm">📄 Identificación y Facturación</h4>
							
							<div class="grid grid-cols-3 gap-2">
								<div>
									<select 
										id="tipo_documento" 
										bind:value={datosPago.tipo_documento} 
										on:change={() => validarDocumento(datosPago.numero_documento, datosPago.tipo_documento)}
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition"
									>
										<option value="CC">CC</option>
										<option value="CE">CE</option>
										<option value="Pasaporte">Pasaporte</option>
										<option value="NIT">NIT</option>
									</select>
								</div>
								<div class="col-span-2">
									<input 
										type="text" 
										id="numero_documento" 
										bind:value={datosPago.numero_documento} 
										on:input={() => validarDocumento(datosPago.numero_documento, datosPago.tipo_documento)}
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition {erroresValidacion.documento ? 'border-red-500' : ''}" 
										required 
										placeholder="Número de documento"
									/>
									{#if erroresValidacion.documento}
										<p class="text-red-400 text-xs mt-1 col-span-2">{erroresValidacion.documento}</p>
									{/if}
								</div>
							</div>
							
							<div class="mt-2">
								<input 
									type="text" 
									id="direccion" 
									bind:value={datosPago.direccion} 
									class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition" 
									required 
									placeholder="Dirección completa"
								/>
							</div>
							
							<div class="grid grid-cols-3 gap-2 mt-2">
								<div>
									<input 
										type="text" 
										id="ciudad" 
										bind:value={datosPago.ciudad} 
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition" 
										required 
										placeholder="Ciudad"
									/>
								</div>
								<div>
									<select 
										id="pais" 
										bind:value={datosPago.pais} 
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition"
									>
										<option value="Colombia">Colombia</option>
										<option value="Venezuela">Venezuela</option>
										<option value="Ecuador">Ecuador</option>
										<option value="Perú">Perú</option>
										<option value="Estados Unidos">Estados Unidos</option>
										<option value="España">España</option>
										<option value="Otro">Otro</option>
									</select>
								</div>
								<div>
									<input 
										type="text" 
										id="codigo_postal" 
										bind:value={datosPago.codigo_postal} 
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition" 
										placeholder="Código postal"
									/>
								</div>
							</div>
						</div>

						<!-- Datos Adicionales (Opcionales) -->
						<div class="bg-gray-700/30 p-3 rounded-lg">
							<h4 class="font-semibold text-purple-300 mb-2 text-sm">➕ Información Adicional (Opcional)</h4>
							
							<div class="grid grid-cols-2 gap-2">
								<div>
									<input 
										type="date" 
										id="fecha_nacimiento" 
										bind:value={datosPago.fecha_nacimiento} 
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition"
										title="Fecha de nacimiento"
									/>
								</div>
								<div>
									<input 
										type="text" 
										id="profesion" 
										bind:value={datosPago.profesion} 
										class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition" 
										placeholder="Profesión"
									/>
								</div>
							</div>
							
							<div class="mt-2">
								<select 
									id="como_nos_conocio" 
									bind:value={datosPago.como_nos_conocio} 
									class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-purple-500 focus:border-purple-500 transition"
								>
									<option value="Facebook">Facebook</option>
									<option value="Instagram">Instagram</option>
									<option value="YouTube">YouTube</option>
									<option value="TikTok">TikTok</option>
									<option value="Google">Google</option>
									<option value="Recomendación">Recomendación</option>
									<option value="WhatsApp">WhatsApp</option>
									<option value="Otro">Otro</option>
								</select>
							</div>
						</div>

						<!-- Contraseña para usuarios nuevos -->
						{#if !usuarioEstaRegistrado}
							<div class="bg-green-500/20 border border-green-500 p-3 rounded-lg">
								<h4 class="font-semibold text-green-300 mb-2 text-sm">🔐 Crear tu Cuenta</h4>
								
								<div class="grid grid-cols-2 gap-2">
									<div>
										<input 
											type="password" 
											id="password" 
											bind:value={datosPago.password} 
											on:input={() => validarPassword(datosPago.password)}
											class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-green-500 focus:border-green-500 transition {erroresValidacion.password ? 'border-red-500' : ''}" 
											required 
											placeholder="Contraseña (min. 8 caracteres)"
											minlength="8"
										/>
										{#if erroresValidacion.password}
											<p class="text-red-400 text-xs mt-1">{erroresValidacion.password}</p>
										{/if}
									</div>
									<div>
										<input 
											type="password" 
											id="confirmarPassword" 
											bind:value={datosPago.confirmarPassword} 
											class="w-full bg-gray-900 border border-gray-600 rounded-md px-3 py-2 text-sm focus:ring-green-500 focus:border-green-500 transition {datosPago.password !== datosPago.confirmarPassword && datosPago.confirmarPassword ? 'border-red-500' : ''}" 
											required 
											placeholder="Confirmar contraseña"
											minlength="8"
										/>
										{#if datosPago.password !== datosPago.confirmarPassword && datosPago.confirmarPassword}
											<p class="text-red-400 text-xs mt-1">Las contraseñas no coinciden</p>
										{/if}
									</div>
								</div>
								
								<p class="text-green-200 text-xs mt-2">
									✅ Tu cuenta se creará automáticamente al completar el pago
								</p>
							</div>
						{/if}
						
						<div class="bg-blue-500/20 border border-blue-500 text-blue-300 px-3 py-2 rounded-md text-xs">
							<p>✅ Datos seguros • Procesamiento automático • Acceso inmediato</p>
						</div>
					</form>
				{/if}

				<!-- Paso 4: Loading -->
				{#if pasoActual === 4}
					<div class="text-center py-8">
						<svg class="animate-spin h-8 w-8 text-purple-400 mx-auto mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
							<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
							<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
						</svg>
						<p class="text-lg font-semibold">Conectando con la pasarela de pago...</p>
						<p class="text-gray-400">Por favor, espera un momento.</p>
					</div>
				{/if}

				<!-- Paso 5: Éxito -->
				{#if pagoExitoso}
					<div class="text-center py-8">
						<svg class="w-16 h-16 text-green-500 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
						</svg>
						<h2 class="text-2xl font-bold mb-2">¡Pago Exitoso!</h2>
						<p class="text-gray-300">Gracias por tu compra. Revisa tu correo para más detalles.</p>
						<button 
							on:click={cerrarModal} 
							class="mt-6 bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-6 rounded-md transition-colors"
						>
							Cerrar
						</button>
					</div>
				{/if}
			</div>

			<!-- Footer con botones de navegación -->
			{#if pasoActual === 1 || pasoActual === 2}
				<div class="bg-gray-700/50 px-6 py-4 flex justify-between items-center rounded-b-lg">
					{#if pasoActual === 2}
						<button 
							on:click={handleAtras} 
							class="text-gray-300 hover:text-white transition-colors"
							disabled={cargando}
						>
							&larr; Atrás
						</button>
					{:else}
						<div></div>
					{/if}
					
					<button
						on:click={handleSiguiente}
						disabled={cargando || procesandoPago || !contenido}
						class="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold py-2 px-6 rounded-md transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
					>
						{#if cargando || procesandoPago}
							<svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
								<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
								<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
							</svg>
							<span>Procesando...</span>
						{:else if pasoActual === 1}
							💳 Pagar ${obtenerPrecio(contenido).toLocaleString('es-CO')}
						{:else}
							💳 Procesar Pago
						{/if}
					</button>
				</div>
			{/if}
		</div>
	</div>
{/if}

<style>
	/* Animaciones y responsive */
	.modal-content {
		animation: modalFadeIn 0.3s ease-out;
	}

	@keyframes modalFadeIn {
		from {
			opacity: 0;
			transform: scale(0.9) translateY(-20px);
		}
		to {
			opacity: 1;
			transform: scale(1) translateY(0);
		}
	}

	/* Responsive */
	@media (max-width: 768px) {
		.modal-content {
			margin: 0.5rem;
			max-width: calc(100% - 1rem);
			max-height: calc(100vh - 1rem);
		}
		
		:global(.grid-cols-2) {
			grid-template-columns: 1fr;
		}
		
		:global(.grid-cols-3) {
			grid-template-columns: 1fr 2fr;
		}
	}

	@media (max-width: 480px) {
		.modal-content {
			margin: 0.25rem;
			max-width: calc(100% - 0.5rem);
			max-height: calc(100vh - 0.5rem);
		}
		
		:global(.grid-cols-3) {
			grid-template-columns: 1fr;
		}
	}
</style> 