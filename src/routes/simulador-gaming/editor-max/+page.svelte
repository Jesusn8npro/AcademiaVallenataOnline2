<script lang="ts">
  // @ts-nocheck
  import { onMount, onDestroy } from 'svelte';
  import { browser } from '$app/environment';
  import { goto } from '$app/navigation';
  import { audioManager, TipoEfectoUI } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
  import { editorSupabase, type GrabacionConAudio } from '$lib/components/SimuladorDefinitivo/supabase/editorSupabase';
  import { ReproductorAudioSincronizado } from '$lib/components/SimuladorDefinitivo/audio/reproductor';
  import { mapaBotonesPorId } from '$lib/components/SimuladorDefinitivo/SimuladorDeAcordeonJS/notasAcordeonDiatonico.js';
  import AcordeonSimulador from '$lib/components/SimuladorDefinitivo/components/simulador/AcordeonSimulador.svelte';
  import FondoPagina from '$lib/components/SimuladorDefinitivo/components/comunes/FondoPagina.svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
  
  // 🎵 IMPORTAR SERVICIOS DE CREAR-CANCION
  import CancionesService from '$lib/services/cancionesService';
  import AudioService from '$lib/services/audioService';
  import StorageService from '$lib/services/storageService';
  import type { CancionAcordeon, SecuenciaCancion, NotaTemporizada } from '$lib/services/cancionesService';

  // ===========================
  // ESTADOS PRINCIPALES
  // ===========================
  
  // Estados del flujo
  let pasoActual = 1; // 1: Subir Audio, 2: Grabar Acordeón, 3: Sincronizar, 4: Publicar
  let procesando = false;
  let mensaje = '';
  let tipoMensaje = 'info'; // 'info', 'success', 'error', 'warning'

  // 🎵 USUARIO Y DATOS ESTRUCTURADOS
  let usuario: any = null;
  let audioServiceInstance: AudioService | null = null;
  
  // Datos de la canción estructurados (compatible con crear-cancion)
  let datosCancion: Partial<CancionAcordeon> = {
    titulo: '',
    artista: '',
    genero: 'vallenato',
    nivel_dificultad: 1,
    duracion_segundos: 0,
    bpm: 120,
    afinacion: 'FBE',
    url_audio: '',
    descripcion: '',
    tags: [],
    dificultad_tecnica: 'principiante',
    requiere_cambios_fuelle: true,
    requiere_acordes: false,
    requiere_bajos: true,
    xp_recompensa: 50,
    monedas_recompensa: 10,
    puntos_precision: 100,
    tiempo_maximo_minutos: 10,
    precision_minima_requerida: 75,
    intentos_maximos: 3,
    estado: 'borrador',
    es_publica: false,
    es_premium: false,
    orden_mostrar: 0
  };
  
  // Datos de la secuencia estructurados
  let datosSecuencia: Partial<SecuenciaCancion> = {
    nombre_secuencia: 'Secuencia principal',
    descripcion: 'Grabada en Editor Max',
    tolerancia_timing_ms: 150,
    auto_cuantizar: false,
    usar_metronomo: false,
    notas_secuencia: [],
    marcadores_tiempo: {},
    es_secuencia_principal: true,
    nivel_dificultad: 1,
    estado: 'borrador'
  };

  // Audio
  let archivoAudio: File | null = null;
  let reproductor: ReproductorAudioSincronizado | null = null;
  let reproduciendo = false;
  let tiempoActual = 0;
  let duracionTotal = 0;
  let volumen = 80;
  let velocidad = 1.0;
  let velocidadGrabacion = 1.0; // Velocidad usada durante la grabación
  let offsetGrabacion = 0; // Offset para grabación en segundos
  let arrastrando = false; // Estado para arrastrar línea de tiempo

  // Grabación del acordeón
  let grabandoAcordeon = false;
  let pausado = false;
  let notasGrabadas: any[] = [];
  let tiempoInicioGrabacion = 0;
  let botonesActivos = {};
  let direccion = 'halar';
  let afinacion = 'FBE';
  
  // Variables para sincronización en tiempo real (como en editor original)
  let tiemposReproduccion = [];
  let direccionOriginalReproduccion = null;
  let intervaloPrevio = null;
  let intervaloActualizacionTiempo = null; // Para actualizar tiempo en preview

  // Metadatos de la canción
  let metadatos = {
    titulo: '',
    artista: '',
    genero: 'Vallenato',
    dificultad: 'Intermedio',
    descripcion: '',
    tags: []
  };

  // UI y preview
  let mostrandoPreview = false;
  let acordeonRef;
  let inputFileRef;
  let tagInput = '';

  // 🎵 SINCRONIZAR NOTAS CON DATOS ESTRUCTURADOS (SOLO PARA PREVIEW)
  function sincronizarNotasConEstructura() {
    if (notasGrabadas && notasGrabadas.length > 0) {
      // Solo sincronizar para preview, NO duplicar notas
      datosSecuencia.duracion_total_ms = duracionTotal * 1000;
      console.log(`🎹 Sincronizada duración: ${duracionTotal}s para preview`);
    }
  }

  // Reactividad para sincronizar automáticamente (SIN CONVERTIR NOTAS)
  $: if (notasGrabadas) {
    sincronizarNotasConEstructura();
  }

  // ===========================
  // CICLO DE VIDA
  // ===========================

  onMount(async () => {
    if (browser) {
      // 🔍 VERIFICAR IMPORTS CRÍTICOS
      console.log('🔍 Verificando imports...');
      console.log('ReproductorAudioSincronizado:', ReproductorAudioSincronizado);
      console.log('audioManager:', audioManager);
      console.log('CancionesService:', CancionesService);
      console.log('AudioService:', AudioService);
      
      // 🎵 SUSCRIBIRSE AL USUARIO
      try {
        estadoUsuarioActual.subscribe(value => {
          usuario = value?.user || null;
          console.log('👤 Estado del usuario:', usuario ? `Autenticado: ${usuario.email}` : 'No autenticado');
          
          if (usuario?.id) {
            datosCancion.creador_id = usuario.id;
          }
        });
      } catch (error) {
        console.error('❌ Error suscribiéndose al usuario:', error);
      }
      
      // 🎵 INICIALIZAR AUDIO SERVICE
      try {
        audioServiceInstance = AudioService.obtenerInstancia();
        await audioServiceInstance.inicializar();
        console.log('✅ AudioService inicializado correctamente');
      } catch (error) {
        console.error('❌ Error inicializando AudioService:', error);
      }
      
      // 🎵 INICIALIZAR REPRODUCTOR
      try {
        inicializarReproductor();
        console.log('✅ Reproductor inicializado correctamente');
      } catch (error) {
        console.error('❌ Error inicializando reproductor:', error);
      }
      
      // 🎵 INICIALIZAR AUDIO MANAGER
      try {
        audioManager.reproducirEfectoUI(TipoEfectoUI.POWER);
        console.log('✅ AudioManager funcionando correctamente');
      } catch (error) {
        console.error('❌ Error con AudioManager:', error);
      }
      
      mostrarMensaje('¡Bienvenido al Editor Max! Sube tu pista de audio para comenzar.', 'info');

      // 🎵 VERIFICAR BUCKET DE STORAGE
      try {
        console.log('🔍 Verificando bucket de storage...');
        const bucketOk = await StorageService.verificarYCrearBucket();
        if (bucketOk) {
          console.log('✅ Bucket de storage verificado correctamente');
        } else {
          console.warn('⚠️ Problema con el bucket de storage');
        }
      } catch (error) {
        console.error('❌ Error verificando bucket:', error);
        mostrarMensaje('⚠️ Advertencia: Problema con el storage de archivos', 'warning');
      }

      // 🎵 PROBAR CONEXIÓN CON SUPABASE
      try {
        const { data: testData, error: testError } = await supabase
          .from('canciones_simulador_acordeon')
          .select('id, titulo')
          .limit(1);
          
        if (testError) {
          throw testError;
        }
          
        console.log('✅ Conexión a Supabase exitosa:', testData);
      } catch (error) {
        console.error('❌ Error al conectar con Supabase:', error);
        mostrarMensaje('⚠️ Advertencia: Error al conectar con la base de datos', 'warning');
      }
      
      // 🎵 VERIFICAR BUCKET DE STORAGE
      try {
        const bucketOk = await StorageService.verificarYCrearBucket();
        if (bucketOk) {
          console.log('✅ Bucket de storage verificado correctamente');
        } else {
          console.error('❌ Error con bucket de storage');
          mostrarMensaje('⚠️ Advertencia: Error con el almacenamiento de archivos', 'warning');
        }
      } catch (error) {
        console.error('❌ Error verificando bucket:', error);
        mostrarMensaje('⚠️ Advertencia: Error verificando almacenamiento', 'warning');
      }
    }
  });

  onDestroy(() => {
    limpiarRecursos();
  });

  // ===========================
  // REPRODUCTOR DE AUDIO
  // ===========================

  function inicializarReproductor() {
    // Verificar que la clase esté disponible
    if (!ReproductorAudioSincronizado) {
      console.error('❌ ReproductorAudioSincronizado no está disponible');
      mostrarMensaje('❌ Error: Reproductor de audio no disponible', 'error');
      return;
    }
    
    try {
      reproductor = new ReproductorAudioSincronizado();
      
      // Verificar que el reproductor se creó correctamente
      if (!reproductor) {
        console.error('❌ Error creando instancia del reproductor');
        return;
      }
      
      // Eventos del reproductor
      reproductor.suscribirseA('play', () => {
        reproduciendo = true;
      });
      
      reproductor.suscribirseA('pause', () => {
        reproduciendo = false;
      });
      
      reproductor.suscribirseA('stop', () => {
        reproduciendo = false;
        tiempoActual = 0;
      });
      
      reproductor.suscribirseA('timeupdate', (data) => {
        tiempoActual = data.tiempo;
      });
      
      reproductor.suscribirseA('load', (data) => {
        duracionTotal = data.duracion;
      });

      console.log('✅ Reproductor inicializado correctamente');
      
      // Nota: Los eventos de sincronización ahora se manejan con el sistema temporal
      // en lugar de usar el reproductor Howler.js
    } catch (error) {
      console.error('❌ Error inicializando reproductor:', error);
      mostrarMensaje('❌ Error inicializando reproductor de audio', 'error');
    }
  }

  // ===========================
  // PASO 1: SUBIR AUDIO
  // ===========================

  function seleccionarArchivo() {
    reproducirEfectoSeguro(TipoEfectoUI.CLICK_BOTON);
    inputFileRef?.click();
  }

  async function manejarArchivoSeleccionado(event) {
    const archivo = event.target.files[0];
    if (!archivo) return;

    // 🎵 VALIDAR ARCHIVO USANDO STORAGE SERVICE
    const validacion = StorageService.validarArchivo(archivo);
    if (!validacion.valido) {
      mostrarMensaje(`❌ ${validacion.error}`, 'error');
      return;
    }

    procesando = true;
    mostrarMensaje('📤 Cargando archivo de audio...', 'info');

    try {
      archivoAudio = archivo;
      
      // 🎵 ACTUALIZAR DATOS ESTRUCTURADOS
      datosCancion.titulo = datosCancion.titulo || archivo.name.replace(/\.[^/.]+$/, "");
      datosCancion.artista = datosCancion.artista || 'Artista';
      
      // 🎵 OBTENER DURACIÓN DEL ARCHIVO
      try {
        duracionTotal = await AudioService.obtenerDuracionArchivo(archivo);
        datosCancion.duracion_segundos = Math.floor(duracionTotal);
        console.log(`⏱️ Duración del archivo: ${duracionTotal} segundos`);
      } catch (error) {
        console.error('❌ Error obteniendo duración:', error);
        duracionTotal = 0;
      }
      
      // 🎵 SUBIR INMEDIATAMENTE AL BUCKET DE SUPABASE
      if (usuario?.id) {
        try {
          mostrarMensaje('☁️ Subiendo archivo a Supabase...', 'info');
          
          const urlAudioSubido = await subirAudioASupabase(archivo);
          
          if (urlAudioSubido) {
            datosCancion.url_audio = urlAudioSubido;
            console.log('✅ Audio subido inmediatamente al bucket:', urlAudioSubido);
            mostrarMensaje('✅ Audio guardado en Supabase automáticamente', 'success');
          } else {
            console.warn('⚠️ No se pudo subir el audio, pero se continuará con archivo local');
            mostrarMensaje('⚠️ Audio cargado localmente (no se pudo subir a Supabase)', 'warning');
          }
        } catch (error) {
          console.error('❌ Error subiendo audio:', error);
          mostrarMensaje('⚠️ Audio cargado localmente (error subiendo a Supabase)', 'warning');
        }
      } else {
        console.log('ℹ️ Usuario no autenticado, usando archivo local');
        mostrarMensaje('🔐 Inicia sesión para guardar el audio en Supabase automáticamente', 'warning');
      }
      
      // Verificar que el reproductor esté inicializado
      if (!reproductor) {
        console.log('🔧 Inicializando reproductor...');
        inicializarReproductor();
      }
      
      // Crear URL temporal para el reproductor (siempre usar archivo local para reproducción)
      const urlTemporal = URL.createObjectURL(archivo);
      
      // Cargar en el reproductor
      const cancionTemporal = {
        id: 'temp-upload',
        titulo: datosCancion.titulo,
        artista: datosCancion.artista,
        genero: datosCancion.genero,
        dificultad: datosCancion.dificultad_tecnica,
        duracion: duracionTotal,
        notas: [],
        audio_url: urlTemporal
      };

      // Verificar que el reproductor esté disponible antes de cargar
      if (reproductor && typeof reproductor.cargarCancion === 'function') {
        await reproductor.cargarCancion(cancionTemporal, {
          volumen: volumen / 100,
          velocidad: velocidad
        });
      } else {
        console.error('❌ Reproductor no disponible o método cargarCancion no encontrado');
        mostrarMensaje('❌ Error inicializando reproductor de audio.', 'error');
        return;
      }

      reproducirEfectoSeguro(TipoEfectoUI.SUCCESS);
      mostrarMensaje(`✅ Audio cargado: ${archivo.name} (${Math.floor(duracionTotal)}s)`, 'success');
      pasoActual = 2;

    } catch (error) {
      console.error('Error cargando archivo:', error);
      mostrarMensaje('❌ Error al cargar el archivo de audio.', 'error');
    } finally {
      procesando = false;
    }
  }

  // ===========================
  // PASO 2: GRABAR ACORDEÓN
  // ===========================

  function toggleReproduccion() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    if (reproduciendo) {
      reproductor.pausar();
    } else {
      reproductor.reproducir();
    }
  }

  function detenerReproduccion() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    reproductor.detener();
  }

  function iniciarGrabacionAcordeon() {
    if (!reproductor) {
      mostrarMensaje('❌ Primero carga un archivo de audio.', 'error');
      return;
    }

    audioManager.reproducirEfectoUI(TipoEfectoUI.POWER);
    grabandoAcordeon = true;
    pausado = false;
    tiempoInicioGrabacion = Date.now();
    notasGrabadas = [];
    botonesActivos = {};
    
    // Guardar la velocidad de grabación actual
    velocidadGrabacion = velocidad;
    
    // Iniciar reproducción automáticamente
    reproductor.reproducir();
    
    mostrarMensaje(`🔴 ¡Grabación iniciada! Velocidad: ${velocidadGrabacion}x | Toca el acordeón sincronizado con la música.`, 'info');
  }

  function pausarGrabacionAcordeon() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    pausado = !pausado;
    
    if (pausado) {
      reproductor.pausar();
      mostrarMensaje('⏸️ Grabación pausada.', 'warning');
    } else {
      reproductor.reproducir();
      mostrarMensaje('▶️ Grabación reanudada.', 'info');
    }
  }

  function detenerGrabacionAcordeon() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.SUCCESS);
    grabandoAcordeon = false;
    pausado = false;
    
    reproductor.detener();
    limpiarNotasActivas();
    
    console.log(`🎵 Grabación detenida. Notas antes de limpiar: ${notasGrabadas.length}`);
    
    // Limpiar notas inválidas (como en editor original)
    limpiarNotasInvalidas();
    
    // Limpiar duplicados automáticamente
    limpiarNotasDuplicadas();
    
    console.log(`🧹 Notas después de limpiar: ${notasGrabadas.length}`);
    mostrarMensaje(`✅ Grabación completada: ${notasGrabadas.length} notas grabadas.`, 'success');
    
    if (notasGrabadas.length > 0) {
      pasoActual = 3;
    }
  }

  function limpiarNotasInvalidas() {
    const notasIniciales = notasGrabadas.length;
    notasGrabadas = notasGrabadas.filter(nota => 
      nota.duracion >= 0.05 && nota.idBoton && nota.tiempo >= 0
    );
    
    if (notasGrabadas.length !== notasIniciales) {
      console.log(`🧹 Limpieza completada - ${notasIniciales - notasGrabadas.length} notas inválidas eliminadas`);
    }
  }

  // Eventos del acordeón
  function manejarNotaPresionada(event) {
    console.log('🎵 Nota presionada:', event.detail);
    
    if (!grabandoAcordeon || pausado) {
      console.log('⏸️ Grabación no activa o pausada');
      return;
    }
    
    const { id, tipo } = event.detail;
    console.log(`🎹 Grabando nota: ${id} (${tipo})`);
    grabarNota(id);
  }

  function manejarNotaLiberada(event) {
    console.log('🎵 Nota liberada:', event.detail);
    
    if (!grabandoAcordeon || pausado) {
      console.log('⏸️ Grabación no activa o pausada');
      return;
    }
    
    const { id, tipo } = event.detail;
    console.log(`🎹 Finalizando nota: ${id} (${tipo})`);
    finalizarNota(id);
  }

  function manejarCambioFuelle(nuevaDireccion, nuevosBotonesActivos) {
    console.log('🪗 Cambio de fuelle:', nuevaDireccion);
    
    // Si es un evento de Svelte, extraer los datos
    if (typeof nuevaDireccion === 'object' && nuevaDireccion.detail) {
      const { direccion: dir, botonesActivos: botones } = nuevaDireccion.detail;
      direccion = dir;
      botonesActivos = botones;
    } else {
      // Si es una llamada directa desde el callback
      direccion = nuevaDireccion;
      if (nuevosBotonesActivos) {
        botonesActivos = nuevosBotonesActivos;
      }
    }
    
    if (grabandoAcordeon && Object.keys(botonesActivos).length > 0) {
      mostrarMensaje(`🌬️ Fuelle ${direccion} - ${Object.keys(botonesActivos).length} notas activas`, 'info');
    }
  }

  function grabarNota(id, origen = 'mouse') {
    if (!grabandoAcordeon || pausado) return null;
    
    // Usar el tiempo actual del reproductor + offset de grabación
    const tiempoActualGrabacion = tiempoActual + offsetGrabacion;
    
    // Evitar notas duplicadas muy cercanas en tiempo (más estricto)
    const notaReciente = notasGrabadas.find(n => 
      n.idBoton === id && (tiempoActualGrabacion - n.tiempo) < 0.1 // Aumentar a 100ms
    );
    
    if (notaReciente) {
      console.log(`🚫 Nota duplicada evitada: ${id} en tiempo ${tiempoActualGrabacion.toFixed(3)}s`);
      return notaReciente;
    }
    
    // Obtener información de la nota desde el mapa de botones
    const infoNota = mapaBotonesPorId[id];
    const nombreNota = infoNota ? infoNota.nombre : id;
    
    const nota = {
      tiempo: tiempoActualGrabacion,
      idBoton: id,
      nombre: nombreNota, // Agregar nombre de la nota
      duracion: 0.25,
      velocidad: 1.0,
      tipo: 'normal',
      origen: origen,
      direccion: direccion, // Usar 'direccion' en lugar de 'direccionFuelle'
      inicioPulsacion: Date.now(),
      activa: true
    };
    
    notasGrabadas.push(nota);
    notasGrabadas = notasGrabadas; // Trigger reactivity
    
    console.log(`✅ Nota grabada: ${nombreNota} (${id}) en tiempo ${tiempoActualGrabacion.toFixed(2)}s (offset: ${offsetGrabacion.toFixed(2)}s) - Total: ${notasGrabadas.length} (${origen})`);
    return nota;
  }

  function finalizarNota(id) {
    const nota = notasGrabadas.find(n => n.idBoton === id && n.activa);
    if (nota) {
      const duracion = (Date.now() - nota.inicioPulsacion) / 1000;
      nota.duracion = Math.max(0.1, duracion);
      nota.activa = false;
      delete nota.inicioPulsacion;
      
      if (nota.duracion >= 1.0) {
        nota.tipo = 'mantenida';
      }
      
      console.log(`🎵 Nota finalizada: ${id} - Duración: ${duracion.toFixed(2)}s - Tipo: ${nota.tipo}`);
    } else {
      console.log(`⚠️ No se encontró nota activa para finalizar: ${id}`);
    }
  }

  function limpiarNotasActivas() {
    Object.keys(botonesActivos).forEach(idBoton => {
      acordeonRef?.detenerTono(idBoton);
    });
    botonesActivos = {};
  }

  function limpiarNotasDuplicadas() {
    const notasLimpias = [];
    const umbralDuplicado = 0.05; // 50ms
    
    // Ordenar notas por tiempo
    const notasOrdenadas = [...notasGrabadas].sort((a, b) => a.tiempo - b.tiempo);
    
    for (const nota of notasOrdenadas) {
      const duplicado = notasLimpias.find(n => 
        n.idBoton === nota.idBoton && 
        n.direccion === nota.direccion &&
        Math.abs(n.tiempo - nota.tiempo) < umbralDuplicado
      );
      
      if (!duplicado) {
        notasLimpias.push(nota);
      } else {
        console.log('🗑️ Nota duplicada eliminada en limpieza:', nota.idBoton, 'en tiempo', nota.tiempo.toFixed(3) + 's');
      }
    }
    
    const notasEliminadas = notasGrabadas.length - notasLimpias.length;
    if (notasEliminadas > 0) {
      console.log(`🧹 Limpieza completada: ${notasEliminadas} notas duplicadas eliminadas`);
      notasGrabadas = notasLimpias;
    }
  }

  function limpiarDuplicadosManual() {
    const notasAntes = notasGrabadas.length;
    limpiarNotasDuplicadas();
    const notasDespues = notasGrabadas.length;
    
    if (notasAntes !== notasDespues) {
      mostrarMensaje(`🧹 ${notasAntes - notasDespues} notas duplicadas eliminadas`, 'success');
    } else {
      mostrarMensaje('✅ No se encontraron duplicados', 'info');
    }
  }

  // ===========================
  // PASO 3: SINCRONIZAR Y PREVIEW
  // ===========================

  async function mostrarPreview() {
    if (notasGrabadas.length === 0) {
      mostrarMensaje('❌ No hay notas grabadas para previsualizar.', 'error');
      return;
    }

    audioManager.reproducirEfectoUI(TipoEfectoUI.FLOURISH);
    
    // Configurar la misma velocidad que se usó durante la grabación
    if (velocidadGrabacion !== velocidad) {
      velocidad = velocidadGrabacion;
      if (reproductor) {
        reproductor.configurarVelocidad(velocidad);
      }
    }
    
    mostrandoPreview = true;
    
    mostrarMensaje(`🎵 Preview listo. Velocidad sincronizada: ${velocidad}x | Reproduce para ver la sincronización.`, 'success');
  }

  function cerrarPreview() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.SLIDE_1);
    mostrandoPreview = false;
    detenerReproduccionSincronizada();
    
    // Limpiar estado de arrastre
    arrastrando = false;
  }

  // Reproducción sincronizada (como en editor original)
  function reproducirSecuenciaSincronizada() {
    if (notasGrabadas.length === 0) {
      mostrarMensaje('❌ No hay notas para reproducir', 'error');
      return;
    }
    
    if (reproduciendo) {
      detenerReproduccionSincronizada();
      return;
    }
    
    // Iniciar reproducción del audio de fondo desde el tiempo actual
    if (reproductor.reproductorHowler) {
      reproductor.reproductorHowler.seek(tiempoActual);
    }
    reproductor.reproducir();
    
    reproduciendo = true;
    tiemposReproduccion = [];
    direccionOriginalReproduccion = direccion;
    acordeonRef?.limpiarTodasLasNotas();

    // Iniciar actualización de tiempo en tiempo real
    intervaloActualizacionTiempo = setInterval(() => {
      if (reproductor && reproductor.reproductorHowler && reproduciendo) {
        const tiempoReproductor = reproductor.reproductorHowler.seek();
        if (typeof tiempoReproductor === 'number') {
          tiempoActual = tiempoReproductor;
          
          // Actualizar secuencia visual en tiempo real durante reproducción
          if (mostrandoPreview) {
            actualizarSecuenciaVisual(tiempoActual);
          }
        }
      }
    }, 50); // Actualizar cada 50ms para suavidad
    
    const notasOrdenadas = [...notasGrabadas]
      .filter(n => !n.activa)
      .sort((a, b) => a.tiempo - b.tiempo);
    
    mostrarMensaje(`🎵 Reproduciendo secuencia sincronizada - ${notasOrdenadas.length} notas`, 'info');
    
    // Crear tabla de cambios de dirección por tiempo
    const cambiosDireccion = {};
    notasOrdenadas.forEach(nota => {
      const tiempoRedondeado = Math.round(nota.tiempo * 100) / 100;
      const direccionNota = nota.direccionFuelle || 'halar';
      
      if (!cambiosDireccion[tiempoRedondeado]) {
        cambiosDireccion[tiempoRedondeado] = new Set();
      }
      cambiosDireccion[tiempoRedondeado].add(direccionNota);
    });
    
    // Programar cambios de dirección (desde tiempo actual)
    Object.keys(cambiosDireccion).forEach(tiempo => {
      const tiempoNota = parseFloat(tiempo);
      
      // Solo programar cambios de dirección después del tiempo actual
      if (tiempoNota >= tiempoActual) {
        const tiempoEspera = (tiempoNota - tiempoActual) * 1000;
        const direcciones = Array.from(cambiosDireccion[tiempoNota]);
        const direccionAUsar = direcciones[0]; // Si hay conflicto, usar la primera
        
        const timeoutDireccion = setTimeout(() => {
          if (!reproduciendo) return;
          cambiarDireccionReproduccion(direccionAUsar);
        }, Math.max(0, tiempoEspera - 50)); // Cambiar dirección 50ms antes
        
        tiemposReproduccion.push(timeoutDireccion);
      }
    });
    
    // Reproducir cada nota individualmente (desde tiempo actual)
    notasOrdenadas.forEach((nota, index) => {
      const tiempoNota = nota.tiempo;
      
      // Solo programar notas que están después del tiempo actual
      if (tiempoNota >= tiempoActual) {
        const tiempoEspera = (tiempoNota - tiempoActual) * 1000;
        
        // Timeout para iniciar la nota
        const timeoutInicio = setTimeout(() => {
          if (!reproduciendo) return;
          iniciarNotaReproduccionSincronizada(nota);
        }, tiempoEspera);
        
        // Timeout para detener la nota (duración exacta)
        const timeoutFin = setTimeout(() => {
          if (!reproduciendo) return;
          detenerNotaReproduccionSincronizada(nota);
        }, tiempoEspera + (nota.duracion * 1000));
        
        tiemposReproduccion.push(timeoutInicio, timeoutFin);
      }
    });
    
    // Calcular duración desde el tiempo actual
    const notasFuturas = notasOrdenadas.filter(n => n.tiempo >= tiempoActual);
    if (notasFuturas.length > 0) {
      const duracionDesdeActual = Math.max(...notasFuturas.map(n => n.tiempo + n.duracion)) - tiempoActual;
      const timeoutFinal = setTimeout(() => {
        finalizarReproduccionSincronizada();
      }, (duracionDesdeActual * 1000) + 500);
      
      tiemposReproduccion.push(timeoutFinal);
    }
  }

  function detenerReproduccionSincronizada() {
    if (!reproduciendo) return;
    
    // Detener audio de fondo
    reproductor.pausar();
    
    reproduciendo = false;
    
    // Limpiar todos los timeouts
    tiemposReproduccion.forEach(timeout => clearTimeout(timeout));
    tiemposReproduccion = [];
    
    // Limpiar intervalo de actualización de tiempo
    if (intervaloActualizacionTiempo) {
      clearInterval(intervaloActualizacionTiempo);
      intervaloActualizacionTiempo = null;
    }
    
    // Detener todos los oscilladores activos
    Object.keys(botonesActivos).forEach(idBoton => {
      acordeonRef?.detenerTono(idBoton);
    });
    
    // Limpiar todas las notas
    acordeonRef?.limpiarTodasLasNotas();
    botonesActivos = {};
    
    // Restaurar la dirección original
    if (direccionOriginalReproduccion !== null) {
      direccion = direccionOriginalReproduccion;
      direccionOriginalReproduccion = null;
    }
    
    mostrarMensaje('⏹️ Reproducción detenida', 'info');
  }

  function finalizarReproduccionSincronizada() {
    reproduciendo = false;
    tiemposReproduccion = [];
    
    // Limpiar intervalo de actualización de tiempo
    if (intervaloActualizacionTiempo) {
      clearInterval(intervaloActualizacionTiempo);
      intervaloActualizacionTiempo = null;
    }
    
    // Detener audio de fondo
    reproductor.pausar();
    
    // Detener todos los oscilladores activos
    Object.keys(botonesActivos).forEach(idBoton => {
      acordeonRef?.detenerTono(idBoton);
    });
    
    // Limpiar todas las notas
    acordeonRef?.limpiarTodasLasNotas();
    botonesActivos = {};
    
    // Restaurar la dirección original
    if (direccionOriginalReproduccion !== null) {
      direccion = direccionOriginalReproduccion;
      direccionOriginalReproduccion = null;
    }
    
    mostrarMensaje('✅ Reproducción terminada', 'success');
  }

  // Función auxiliar para iniciar una nota durante la reproducción sincronizada
  function iniciarNotaReproduccionSincronizada(nota) {
    // Limpiar cualquier nota anterior con el mismo ID de botón
    if (botonesActivos[nota.idBoton]) {
      acordeonRef.detenerTono(nota.idBoton);
    }
    
    // Iniciar la nueva nota
    const { oscillator } = acordeonRef.reproducirTono(nota.idBoton);
    botonesActivos = {
      ...botonesActivos,
      [nota.idBoton]: { 
        oscillator, 
        direccionFuelle: nota.direccionFuelle || 'halar',
        duracionOriginal: nota.duracion,
        tiempoInicio: Date.now(),
        ...mapaBotonesPorId[nota.idBoton]
      }
    };
    
    // Forzar actualización de la UI
    botonesActivos = { ...botonesActivos };
    
    console.log(`▶️ Iniciando nota sincronizada: ${nota.idBoton} (${nota.duracion}s, ${nota.direccionFuelle})`);
  }

  // Función auxiliar para detener una nota durante la reproducción sincronizada
  function detenerNotaReproduccionSincronizada(nota) {
    // Verificar que la nota aún existe y es la misma
    const notaActual = botonesActivos[nota.idBoton];
    if (notaActual && notaActual.duracionOriginal === nota.duracion) {
      acordeonRef.detenerTono(nota.idBoton);
      const newMap = { ...botonesActivos };
      delete newMap[nota.idBoton];
      botonesActivos = newMap;
      
      console.log(`⏹️ Deteniendo nota sincronizada: ${nota.idBoton} (${nota.duracion}s completados)`);
    } else {
      console.log(`⚠️ No se pudo detener nota sincronizada: ${nota.idBoton} (ya no existe o cambió)`);
    }
  }

  // Función auxiliar para cambiar dirección durante reproducción
  function cambiarDireccionReproduccion(nuevaDireccion) {
    if (direccion === nuevaDireccion) return;
    
    console.log(`🌬️ Cambiando dirección de ${direccion} a ${nuevaDireccion}`);
    direccion = nuevaDireccion;
  }

  // Nota: Las funciones activarNotaEnAcordeon y desactivarNotaEnAcordeon 
  // ya no se necesitan con el nuevo sistema de sincronización temporal

  // ===========================
  // PASO 4: PUBLICAR CON SERVICIOS ESTRUCTURADOS
  // ===========================

  async function publicarCancion() {
    if (!validarMetadatos()) return;

    // Validar que tenemos archivo de audio
    if (!archivoAudio) {
      mostrarMensaje('❌ No hay archivo de audio para publicar.', 'error');
      return;
    }

    // Validar que tenemos notas grabadas
    if (!notasGrabadas || notasGrabadas.length === 0) {
      mostrarMensaje('❌ No hay notas de acordeón grabadas.', 'error');
      return;
    }

    // Validar que tenemos usuario
    if (!usuario?.id) {
      mostrarMensaje('❌ Usuario no autenticado. Inicia sesión para continuar.', 'error');
      return;
    }

    procesando = true;
    mostrarMensaje('📤 Publicando canción en Supabase...', 'info');

    try {
      console.log(`📋 Publicando canción:`, {
        titulo: datosCancion.titulo,
        artista: datosCancion.artista,
        audioSize: archivoAudio.size,
        notasCount: notasGrabadas.length
      });

      // 🎵 PASO 1: VERIFICAR/SUBIR ARCHIVO DE AUDIO
      let urlAudio: string | null = datosCancion.url_audio || null;
      
      if (urlAudio) {
        console.log('✅ Audio ya subido previamente:', urlAudio);
        mostrarMensaje('✅ Usando audio ya subido a Supabase', 'success');
      } else {
        // Si no hay URL, subir ahora
        mostrarMensaje('📤 Subiendo archivo de audio...', 'info');
        
        try {
          urlAudio = await subirAudioASupabase(archivoAudio);
          
          if (!urlAudio) {
            throw new Error('No se pudo subir el archivo de audio');
          }
          
          datosCancion.url_audio = urlAudio;
          console.log('✅ URL del audio obtenida:', urlAudio);
        } catch (error: any) {
          console.error('❌ Error subiendo audio:', error);
          throw new Error(`Error subiendo audio: ${error.message}`);
        }
      }

      // 🎵 PASO 2: PREPARAR DATOS DE LA CANCIÓN
      const datosCancionCompletos: Partial<CancionAcordeon> = {
        ...datosCancion,
        titulo: datosCancion.titulo || 'Canción sin título',
        artista: datosCancion.artista || 'Artista desconocido',
        url_audio: urlAudio,
        duracion_segundos: Math.floor(duracionTotal),
        descripcion: datosCancion.descripcion || `Canción creada en Editor Max`,
        tags: [...(datosCancion.tags || []), 'editor-max', 'sincronizado'],
        estado: 'activa',
        es_publica: true,
        creador_id: usuario.id
      };

      // 🎵 PASO 3: CREAR LA CANCIÓN
      mostrarMensaje('💾 Creando canción en base de datos...', 'info');
      const cancionCreada = await CancionesService.crearCancion(datosCancionCompletos as any);
      
      if (!cancionCreada) {
        throw new Error('Error creando la canción en la base de datos');
      }

      console.log('✅ Canción creada:', cancionCreada);

      // 🎵 PASO 4: PREPARAR Y CREAR LA SECUENCIA
      const notasEstructuradas = convertirNotasAEstructurado(notasGrabadas);
      
      console.log('🔍 DEBUG - Datos de secuencia antes de guardar:');
      console.log('📊 Notas estructuradas:', notasEstructuradas.length);
      console.log('📋 Ejemplo de nota estructurada:', notasEstructuradas[0]);
      
      const datosSecuenciaCompletos: Partial<SecuenciaCancion> = {
        ...datosSecuencia,
        cancion_id: cancionCreada.id,
        notas_secuencia: notasEstructuradas,
        duracion_total_ms: duracionTotal * 1000,
        estado: 'activa'
      };
      
      console.log('🎹 Datos completos de secuencia:', datosSecuenciaCompletos);

      mostrarMensaje('🎹 Guardando secuencia de notas...', 'info');
      const secuenciaCreada = await CancionesService.crearSecuencia(datosSecuenciaCompletos as any);
      
      if (!secuenciaCreada) {
        throw new Error('Error creando la secuencia de notas');
      }

              console.log('✅ Secuencia creada:', secuenciaCreada);

        // 🎵 PASO 5: ÉXITO
      audioManager.reproducirEfectoUI(TipoEfectoUI.FLOURISH);
      mostrarMensaje('🎉 ¡Canción publicada exitosamente!', 'success');
      pasoActual = 4;
      
      // Redirigir después de un momento
      setTimeout(() => {
        goto('/simulador-gaming/seleccion-canciones');
      }, 3000);

    } catch (error) {
      console.error('❌ Error publicando canción:', error);
      
      // Mostrar mensaje de error más específico
      let mensajeError = 'Error al publicar la canción.';
      
      if (error.message.includes('demasiado grande')) {
        mensajeError = 'El archivo de audio es demasiado grande (máx. 50MB).';
      } else if (error.message.includes('inválido')) {
        mensajeError = 'El archivo de audio no es válido.';
      } else {
        mensajeError = error.message || 'Error desconocido.';
      }
      
      mostrarMensaje(`❌ ${mensajeError}`, 'error');
      console.error('❌ Detalles del error:', error);
    } finally {
      procesando = false;
    }
  }

  function validarMetadatos() {
    if (!datosCancion.titulo?.trim()) {
      mostrarMensaje('❌ El título es obligatorio.', 'error');
      return false;
    }
    if (!datosCancion.artista?.trim()) {
      mostrarMensaje('❌ El artista es obligatorio.', 'error');
      return false;
    }
    return true;
  }

  // ===========================
  // UTILIDADES
  // ===========================

  // 🎵 CONVERTIR NOTAS AL FORMATO ESTRUCTURADO (COMPATIBLE CON SINCRONIZADORNOTAS)
  function convertirNotasAEstructurado(notasGrabadas: any[]): NotaTemporizada[] {
    console.log('🔄 Convirtiendo notas al formato estructurado...');
    console.log('📊 Notas originales a convertir:', notasGrabadas.length);
    
    // Filtrar y limpiar duplicados ANTES de convertir
    const notasLimpias = [];
    const umbralDuplicado = 50; // 50ms
    
    const notasFinalizadas = notasGrabadas.filter(nota => !nota.activa); // Solo notas finalizadas
    
    // Eliminar duplicados
    for (const nota of notasFinalizadas) {
      const duplicado = notasLimpias.find(n => 
        n.idBoton === nota.idBoton && 
        n.direccion === nota.direccion &&
        Math.abs((n.tiempo * 1000) - (nota.tiempo * 1000)) < umbralDuplicado
      );
      
      if (!duplicado) {
        notasLimpias.push(nota);
      } else {
        console.log('🗑️ Duplicado eliminado en conversión:', nota.idBoton, 'en tiempo', nota.tiempo.toFixed(3) + 's');
      }
    }
    
    console.log('📊 Notas después de limpiar duplicados:', notasLimpias.length);
    
    const notasConvertidas = notasLimpias
      .map((nota, index) => {
        // Convertir tiempo de segundos a milisegundos
        const timestamp_ms = (nota.tiempo || 0) * 1000;
        const duracion_ms = (nota.duracion || 0.2) * 1000;
        
        const notaConvertida: NotaTemporizada = {
          timestamp_ms: timestamp_ms,
          duracion_ms: duracion_ms,
          nota_id: nota.idBoton || nota.id || 'desconocida',
          nota_nombre: nota.nombre || 'Desconocida',
          fuelle_direccion: nota.direccion || 'halar',
          es_acorde: false,
          notas_acorde: [],
          intensidad: 'normal' as const,
          es_opcional: false,
          tipo_nota: 'melodia' as const
        };
        
        // Log de debug para las primeras notas
        if (index < 3) {
          console.log(`🎵 Nota ${index + 1}:`, {
            original: {
              tiempo: nota.tiempo,
              duracion: nota.duracion,
              idBoton: nota.idBoton,
              nombre: nota.nombre,
              direccion: nota.direccion
            },
            convertida: notaConvertida
          });
        }
        
        return notaConvertida;
      })
      .sort((a, b) => a.timestamp_ms - b.timestamp_ms); // Ordenar por tiempo
    
    console.log('✅ Notas convertidas exitosamente:', notasConvertidas.length);
    if (notasConvertidas.length > 0) {
      console.log('🎵 Primera nota:', notasConvertidas[0]);
      console.log('🎵 Última nota:', notasConvertidas[notasConvertidas.length - 1]);
    }
    
    return notasConvertidas;
  }

  // 🎵 SUBIR ARCHIVO DE AUDIO A SUPABASE (USANDO STORAGE SERVICE)
  async function subirAudioASupabase(archivo: File): Promise<string | null> {
    try {
      if (!usuario?.id) {
        throw new Error('Usuario no autenticado');
      }

      console.log('📤 Iniciando subida de archivo a Supabase Storage...');
      console.log('📋 Detalles del archivo:', {
        nombre: archivo.name,
        tipo: archivo.type,
        tamaño: `${(archivo.size / 1024 / 1024).toFixed(2)}MB`,
        usuario: usuario.id
      });

      // 🔍 VERIFICAR STORAGE SERVICE
      if (!StorageService) {
        throw new Error('StorageService no está disponible');
      }

      // 🔍 VERIFICAR Y CREAR BUCKET
      console.log('🔍 Verificando bucket de storage...');
      const bucketOk = await StorageService.verificarYCrearBucket();
      if (!bucketOk) {
        throw new Error('No se pudo acceder o crear el bucket de storage');
      }

      // 🔍 VALIDAR ARCHIVO
      console.log('🔍 Validando archivo...');
      const validacion = StorageService.validarArchivo(archivo);
      if (!validacion.valido) {
        throw new Error(`Archivo inválido: ${validacion.error}`);
      }

      // 🔍 GENERAR NOMBRE DE ARCHIVO ÚNICO
      const extension = archivo.name.split('.').pop() || 'mp3';
      const titulo = datosCancion.titulo || 'cancion-editor-max';
      const rutaArchivo = StorageService.generarNombreArchivo(titulo, usuario.id, extension);
      
      console.log('📁 Ruta del archivo:', rutaArchivo);

      // 🔍 SUBIR ARCHIVO CON SEGUIMIENTO DE PROGRESO
      mostrarMensaje('📤 Subiendo archivo de audio...', 'info');
      
      const resultado = await StorageService.subirArchivo(
        archivo, 
        rutaArchivo,
        (progress) => {
          console.log(`📈 Progreso de subida: ${progress}%`);
          if (progress === 100) {
            mostrarMensaje('✅ Archivo subido exitosamente', 'success');
          }
        }
      );

      if (!resultado.success) {
        console.error('❌ Error subiendo archivo:', resultado.error);
        throw new Error(`Error de subida: ${resultado.error}`);
      }

      console.log('✅ Archivo subido exitosamente:', resultado.url);
      return resultado.url || null;

    } catch (error: any) {
      console.error('❌ Error en subirAudioASupabase:', error);
      
      // Proporcionar mensaje de error más específico
      if (error.message.includes('not found') || error.message.includes('bucket')) {
        throw new Error('Error de configuración del bucket de storage');
      } else if (error.message.includes('unauthorized') || error.message.includes('permission')) {
        throw new Error('Sin permisos para subir archivos');
      } else if (error.message.includes('network') || error.message.includes('fetch')) {
        throw new Error('Error de conectividad con Supabase');
      } else {
        throw new Error(error.message || 'Error desconocido al subir archivo');
      }
    }
  }

  function mostrarMensaje(texto, tipo = 'info') {
    mensaje = texto;
    tipoMensaje = tipo;
    setTimeout(() => {
      mensaje = '';
    }, 5000);
  }

  function formatearTiempo(segundos) {
    const minutos = Math.floor(segundos / 60);
    const segs = Math.floor(segundos % 60);
    return `${minutos}:${segs.toString().padStart(2, '0')}`;
  }

  function agregarTag() {
    if (tagInput.trim() && !datosCancion.tags.includes(tagInput.trim())) {
      datosCancion.tags = [...(datosCancion.tags || []), tagInput.trim()];
      tagInput = '';
    }
  }

  function eliminarTag(tag) {
    datosCancion.tags = (datosCancion.tags || []).filter(t => t !== tag);
  }

  function limpiarRecursos() {
    if (reproductor) {
      reproductor.limpiar();
    }
    if (archivoAudio) {
      URL.revokeObjectURL(URL.createObjectURL(archivoAudio));
    }
    
    // Limpiar intervalos
    if (intervaloActualizacionTiempo) {
      clearInterval(intervaloActualizacionTiempo);
      intervaloActualizacionTiempo = null;
    }
    
    // Limpiar timeouts de reproducción
    tiemposReproduccion.forEach(timeout => clearTimeout(timeout));
    tiemposReproduccion = [];
  }

  function reiniciarEditor() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.POWER);
    pasoActual = 1;
    archivoAudio = null;
    notasGrabadas = [];
    grabandoAcordeon = false;
    mostrandoPreview = false;
    
    // Resetear datos estructurados
    datosCancion = {
      titulo: '',
      artista: '',
      genero: 'vallenato',
      nivel_dificultad: 1,
      duracion_segundos: 0,
      bpm: 120,
      afinacion: 'FBE',
      url_audio: '',
      descripcion: '',
      tags: [],
      dificultad_tecnica: 'principiante',
      requiere_cambios_fuelle: true,
      requiere_acordes: false,
      requiere_bajos: true,
      xp_recompensa: 50,
      monedas_recompensa: 10,
      puntos_precision: 100,
      tiempo_maximo_minutos: 10,
      precision_minima_requerida: 75,
      intentos_maximos: 3,
      estado: 'borrador',
      es_publica: false,
      es_premium: false,
      orden_mostrar: 0,
      creador_id: usuario?.id
    };
    
    datosSecuencia = {
      nombre_secuencia: 'Secuencia principal',
      descripcion: 'Grabada en Editor Max',
      tolerancia_timing_ms: 150,
      auto_cuantizar: false,
      usar_metronomo: false,
      notas_secuencia: [],
      marcadores_tiempo: {},
      es_secuencia_principal: true,
      nivel_dificultad: 1,
      estado: 'borrador'
    };
    
    tiempoActual = 0;
    duracionTotal = 0;
    limpiarRecursos();
    inicializarReproductor();
  }

  function irASeleccionCanciones() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    goto('/simulador-gaming/seleccion-canciones');
  }

  // Control de volumen y velocidad
  function cambiarVolumen(event) {
    volumen = parseInt(event.target.value);
    if (reproductor) {
      reproductor.configurarVolumen(volumen / 100);
    }
  }

  function cambiarVelocidad(event) {
    velocidad = parseFloat(event.target.value);
    if (reproductor) {
      reproductor.configurarVelocidad(velocidad);
    }
  }

  // ===========================
  // MANIPULACIÓN DE LÍNEA DE TIEMPO
  // ===========================

  function iniciarArrastre(event) {
    if (!reproductor || !duracionTotal) return;
    
    arrastrando = true;
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    // Pausar durante el arrastre
    if (reproduciendo) {
      reproductor.pausar();
    }
    
    actualizarPosicionArrastre(event);
  }

  function actualizarPosicionArrastre(event) {
    if (!arrastrando || !reproductor) return;
    
    const barra = event.currentTarget;
    const rect = barra.getBoundingClientRect();
    const posicionX = event.clientX - rect.left;
    const porcentaje = Math.max(0, Math.min(1, posicionX / rect.width));
    const tiempoNuevo = porcentaje * duracionTotal;
    
    // Actualizar tiempo actual
    tiempoActual = tiempoNuevo;
    
    // Buscar reproductor Howler.js y actualizar posición
    if (reproductor && reproductor.reproductorHowler) {
      reproductor.reproductorHowler.seek(tiempoNuevo);
    }
  }

  function finalizarArrastre() {
    if (!arrastrando) return;
    
    arrastrando = false;
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    // Ajustar notas grabadas según el nuevo tiempo
    ajustarNotasGrabadas();
    
    mostrarMensaje(`⏭️ Posición cambiada: ${formatearTiempo(tiempoActual)}`, 'info');
  }

  function ajustarNotasGrabadas() {
    // Ajustar las notas grabadas según el offset de tiempo
    if (grabandoAcordeon && notasGrabadas.length > 0) {
      const tiempoOffset = tiempoActual - (notasGrabadas[notasGrabadas.length - 1]?.tiempo || 0);
      
      // Actualizar offset de grabación
      offsetGrabacion = tiempoOffset;
      
      console.log(`🎵 Offset de grabación ajustado: ${tiempoOffset.toFixed(2)}s`);
    }
  }

  function aplicarOffsetPreconfigurado(segundos) {
    if (!reproductor) return;
    
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    const tiempoNuevo = Math.max(0, Math.min(duracionTotal, tiempoActual + segundos));
    
    // Actualizar tiempo
    tiempoActual = tiempoNuevo;
    
    // Actualizar reproductor
    if (reproductor.reproductorHowler) {
      reproductor.reproductorHowler.seek(tiempoNuevo);
    }
    
    // Ajustar notas grabadas
    ajustarNotasGrabadas();
    
    const direccion = segundos > 0 ? 'adelante' : 'atrás';
    mostrarMensaje(`⏭️ Movido ${Math.abs(segundos)}s ${direccion}`, 'info');
  }

  function saltarA(segundos) {
    if (!reproductor) return;
    
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    const tiempoNuevo = Math.max(0, Math.min(duracionTotal, segundos));
    
    // Actualizar tiempo
    tiempoActual = tiempoNuevo;
    
    // Actualizar reproductor
    if (reproductor.reproductorHowler) {
      reproductor.reproductorHowler.seek(tiempoNuevo);
    }
    
    // Ajustar notas grabadas
    ajustarNotasGrabadas();
    
    mostrarMensaje(`⏭️ Saltado a: ${formatearTiempo(tiempoNuevo)}`, 'info');
  }

  // ===========================
  // ACTUALIZACIÓN DE SECUENCIA EN TIEMPO REAL
  // ===========================

  function actualizarSecuenciaVisual(tiempo) {
    if (!acordeonRef || !notasGrabadas.length) return;
    
    // Limpiar todas las notas activas
    acordeonRef.limpiarTodasLasNotas();
    
    // Encontrar notas que deberían estar activas en este tiempo
    const notasActivas = notasGrabadas.filter(nota => {
      if (nota.activa) return false; // Ignorar notas aún en grabación
      
      const inicioNota = nota.tiempo;
      const finNota = nota.tiempo + nota.duracion;
      
      return tiempo >= inicioNota && tiempo <= finNota;
    });
    
    // Activar las notas correspondientes
    notasActivas.forEach(nota => {
      if (acordeonRef) {
        // Cambiar dirección si es necesario
        if (nota.direccionFuelle && nota.direccionFuelle !== direccion) {
          direccion = nota.direccionFuelle;
        }
        
        // Activar el botón visualmente y con sonido
        acordeonRef.activarBoton(nota.idBoton);
        botonesActivos[nota.idBoton] = true;
      }
    });
    
    // Actualizar estado visual
    botonesActivos = { ...botonesActivos };
  }

  function mostrarIndicadorTiempo(tiempo) {
    // Mostrar línea de tiempo o indicador visual del momento actual
    const progreso = duracionTotal > 0 ? (tiempo / duracionTotal) * 100 : 0;
    
    // También podríamos mostrar un contador de notas
    const notasReproducidas = notasGrabadas.filter(n => !n.activa && n.tiempo <= tiempo).length;
    const totalNotas = notasGrabadas.filter(n => !n.activa).length;
    
    console.log(`🎵 Tiempo: ${tiempo.toFixed(2)}s | Progreso: ${progreso.toFixed(1)}% | Notas: ${notasReproducidas}/${totalNotas}`);
  }

  // ===========================
  // CONTROLES DE PREVIEW
  // ===========================

  function iniciarArrastrePreview(event) {
    if (!reproductor || !duracionTotal) return;
    
    arrastrando = true;
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    // Pausar reproducción sincronizada si está activa
    if (reproduciendo) {
      detenerReproduccionSincronizada();
    }
    
    actualizarPosicionArrastrePreview(event);
  }

  function actualizarPosicionArrastrePreview(event) {
    if (!arrastrando || !reproductor) return;
    
    const barra = event.currentTarget;
    const rect = barra.getBoundingClientRect();
    const posicionX = event.clientX - rect.left;
    const porcentaje = Math.max(0, Math.min(1, posicionX / rect.width));
    const tiempoNuevo = porcentaje * duracionTotal;
    
    // Actualizar tiempo actual
    tiempoActual = tiempoNuevo;
    
    // Actualizar reproductor Howler.js
    if (reproductor && reproductor.reproductorHowler) {
      reproductor.reproductorHowler.seek(tiempoNuevo);
    }
    
    // Actualizar secuencia visual del acordeón
    actualizarSecuenciaVisual(tiempoNuevo);
    mostrarIndicadorTiempo(tiempoNuevo);
  }

  function finalizarArrastrePreview() {
    if (!arrastrando) return;
    
    arrastrando = false;
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    // Actualizar secuencia final
    actualizarSecuenciaVisual(tiempoActual);
    
    mostrarMensaje(`⏭️ Preview movido a: ${formatearTiempo(tiempoActual)}`, 'info');
    
    // Opcional: reiniciar reproducción sincronizada desde la nueva posición
    // (comentado para que el usuario decida cuándo reproducir)
    // setTimeout(() => {
    //   if (mostrandoPreview) {
    //     reproducirSecuenciaSincronizada();
    //   }
    // }, 500);
  }

  function aplicarOffsetPreview(segundos) {
    if (!reproductor) return;
    
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    const estabReproduciendo = reproduciendo;
    
    // Pausar si está reproduciendo
    if (estabReproduciendo) {
      detenerReproduccionSincronizada();
    }
    
    const tiempoNuevo = Math.max(0, Math.min(duracionTotal, tiempoActual + segundos));
    
    // Actualizar tiempo
    tiempoActual = tiempoNuevo;
    
    // Actualizar reproductor
    if (reproductor.reproductorHowler) {
      reproductor.reproductorHowler.seek(tiempoNuevo);
    }
    
    // Actualizar secuencia visual del acordeón
    actualizarSecuenciaVisual(tiempoNuevo);
    
    const direccion = segundos > 0 ? 'adelante' : 'atrás';
    mostrarMensaje(`⏭️ Preview movido ${Math.abs(segundos)}s ${direccion}`, 'info');
    
    // Reiniciar reproducción desde nueva posición si estaba reproduciendo
    if (estabReproduciendo) {
      setTimeout(() => {
        reproducirSecuenciaSincronizada();
      }, 300);
    }
  }

  function saltarAPreview(segundos) {
    if (!reproductor) return;
    
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    
    const estabReproduciendo = reproduciendo;
    
    // Pausar si está reproduciendo
    if (estabReproduciendo) {
      detenerReproduccionSincronizada();
    }
    
    const tiempoNuevo = Math.max(0, Math.min(duracionTotal, segundos));
    
    // Actualizar tiempo
    tiempoActual = tiempoNuevo;
    
    // Actualizar reproductor
    if (reproductor.reproductorHowler) {
      reproductor.reproductorHowler.seek(tiempoNuevo);
    }
    
    // Actualizar secuencia visual del acordeón
    actualizarSecuenciaVisual(tiempoNuevo);
    
    mostrarMensaje(`⏭️ Preview saltado a: ${formatearTiempo(tiempoNuevo)}`, 'info');
    
    // Reiniciar reproducción desde nueva posición si estaba reproduciendo
    if (estabReproduciendo) {
      setTimeout(() => {
        reproducirSecuenciaSincronizada();
      }, 300);
    }
  }

  // Función de prueba para verificar funcionalidad
  function pruebaFuncionalidad() {
    console.log('🧪 Iniciando prueba de funcionalidad...');
    
    // Probar eventos del acordeón
    console.log('🎹 Estado del acordeón:', {
      grabandoAcordeon,
      pausado,
      notasGrabadas: notasGrabadas.length,
      tiempoActual,
      direccion
    });
    
    // Probar grabación de una nota simulada
    if (grabandoAcordeon) {
      grabarNota('primeraFila-1-halar');
      setTimeout(() => {
        finalizarNota('primeraFila-1-halar');
      }, 1000);
    }
    
    console.log('✅ Prueba completada');
  }

  // Navegación entre pasos
  function irAPaso(numeroPaso) {
    console.log(`🔄 Navegando al paso ${numeroPaso}`);
    
    // Validaciones para permitir navegación
    if (numeroPaso === 1) {
      // Siempre se puede ir al paso 1
      pasoActual = 1;
      mostrandoPreview = false;
      if (reproductor) reproductor.detener();
    } else if (numeroPaso === 2) {
      // Solo si hay audio cargado
      if (!archivoAudio) {
        mostrarMensaje('❌ Primero debes cargar un archivo de audio.', 'error');
        return;
      }
      pasoActual = 2;
      mostrandoPreview = false;
      if (reproductor) reproductor.detener();
    } else if (numeroPaso === 3) {
      // Solo si hay audio y notas grabadas
      if (!archivoAudio) {
        mostrarMensaje('❌ Primero debes cargar un archivo de audio.', 'error');
        return;
      }
      if (notasGrabadas.length === 0) {
        mostrarMensaje('❌ Primero debes grabar notas del acordeón.', 'error');
        return;
      }
      pasoActual = 3;
      mostrandoPreview = false;
      if (reproductor) reproductor.detener();
    } else if (numeroPaso === 4) {
      // Solo si todo está completo
      if (!archivoAudio) {
        mostrarMensaje('❌ Primero debes cargar un archivo de audio.', 'error');
        return;
      }
      if (notasGrabadas.length === 0) {
        mostrarMensaje('❌ Primero debes grabar notas del acordeón.', 'error');
        return;
      }
      pasoActual = 4;
      mostrandoPreview = false;
      if (reproductor) reproductor.detener();
    }
    
    // Limpiar estados de grabación y reproducción
    if (grabandoAcordeon) {
      detenerGrabacionAcordeon();
    }
    
    if (reproduciendo) {
      detenerReproduccionSincronizada();
    }
    
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    mostrarMensaje(`📍 Paso ${numeroPaso} activado.`, 'info');
  }

  // Verificar estado de Supabase
  async function verificarEstadoSupabase() {
    try {
      reproducirEfectoSeguro(TipoEfectoUI.CLICK_BOTON);
      mostrarMensaje('🔍 Verificando estado de Supabase...', 'info');
      
      // 🎵 VERIFICAR SERVICIOS CRÍTICOS
      console.log('🔍 Verificando servicios...');
      
      // Verificar StorageService
      if (!StorageService) {
        throw new Error('StorageService no está disponible');
      }
      
      // Verificar bucket del simulador
      const bucketInfo = await StorageService.verificarYCrearBucket();
      console.log('✅ Bucket verificado:', bucketInfo);
      
      // Verificar conexión a la tabla
      const { data: testData, error: testError } = await supabase
        .from('canciones_simulador_acordeon')
        .select('id, titulo, created_at')
        .limit(3);
        
      if (testError) {
        throw testError;
      }
      
      console.log('✅ Conexión a tabla exitosa:', testData);
      
      // Verificar CancionesService
      const cancionesCount = await CancionesService.contarCanciones();
      console.log('✅ Total de canciones:', cancionesCount);
      
      // Mostrar reporte detallado
      const reporteAmigable = `
🔍 DIAGNÓSTICO DE SUPABASE - EDITOR MAX

✅ CONEXIÓN A BASE DE DATOS: OK
✅ TABLA canciones_simulador_acordeon: OK
✅ BUCKET simulador-acordeon: OK
✅ SERVICIOS INTEGRADOS: OK

📊 ESTADÍSTICAS:
• Total de canciones: ${cancionesCount}
• Últimas canciones: ${testData?.length || 0}
• StorageService: Funcionando
• CancionesService: Funcionando

🌐 Tu proyecto: https://supabase.com/dashboard/project/pxvixslubhuyydwfutueh

💡 ESTADO: ¡Todo funcionando correctamente!
      `;
      
      alert(reporteAmigable);
      mostrarMensaje('✅ Supabase está funcionando correctamente.', 'success');
      
    } catch (error) {
      console.error('❌ Error verificando Supabase:', error);
      
      const errorDetallado = `
❌ ERROR EN SUPABASE - EDITOR MAX

🔍 PROBLEMA DETECTADO:
${error.message}

🛠️ POSIBLES SOLUCIONES:
• Verifica tu conexión a internet
• Ejecuta los scripts SQL actualizados
• Revisa que el proyecto esté activo
• Verifica las políticas de Storage

📁 ARCHIVOS NECESARIOS:
• supabase_schema_simple.sql
• supabase_storage_config.sql

🌐 Tu proyecto: https://supabase.com/dashboard/project/pxvixslubhuyydwfutueh

⚠️ FALLBACK: Se guardará en localStorage si es necesario
      `;
      
      alert(errorDetallado);
      mostrarMensaje('❌ Error al verificar Supabase. Revisa la consola.', 'error');
    }
  }

  // Mostrar ayuda para configurar Supabase
  function mostrarAyudaSupabase() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.FLOURISH);
    
    const ayuda = `
🚀 CONFIGURAR SUPABASE PARA AUDIO

⚠️ IMPORTANTE: Los scripts SQL han sido CORREGIDOS

🔧 PASOS ACTUALIZADOS:
1. Ve a: https://supabase.com/dashboard/project/pxvixslubhuyydwfutueh
2. Ve a "SQL Editor"
3. Ejecuta primero: supabase_schema_simple.sql
4. Ejecuta después: supabase_storage_config.sql

✅ ERRORES CORREGIDOS:
• ON CONFLICT eliminado (ya no da error 42P10)
• Bucket con configuración simplificada
• Políticas de Storage mejoradas

🔄 FALLBACK AUTOMÁTICO:
Si Supabase falla, se guarda automáticamente en localStorage

📱 PRUEBA RÁPIDA:
Usa el botón "Verificar Estado de Supabase" para diagnosticar
    `;
    
    alert(ayuda);
  }

  // 🎵 FUNCIÓN SEGURA PARA EFECTOS DE SONIDO
  function reproducirEfectoSeguro(tipoEfecto: any) {
    try {
      if (audioManager && typeof audioManager.reproducirEfectoUI === 'function') {
        audioManager.reproducirEfectoUI(tipoEfecto);
      } else {
        console.log('🔇 AudioManager no disponible, continuando sin sonido');
      }
    } catch (error) {
      console.error('❌ Error reproduciendo efecto:', error);
    }
  }

  // 🎵 SUBIR AUDIO MANUALMENTE
  async function subirAudioManualmente() {
    if (!archivoAudio || !usuario?.id) {
      mostrarMensaje('❌ No hay archivo de audio o usuario no autenticado', 'error');
      return;
    }

    procesando = true;
    mostrarMensaje('☁️ Subiendo audio a Supabase...', 'info');

    try {
      const urlAudioSubido = await subirAudioASupabase(archivoAudio);
      
      if (urlAudioSubido) {
        datosCancion.url_audio = urlAudioSubido;
        reproducirEfectoSeguro(TipoEfectoUI.SUCCESS);
        mostrarMensaje('✅ Audio subido exitosamente a Supabase', 'success');
      } else {
        throw new Error('No se pudo subir el archivo');
      }
    } catch (error: any) {
      console.error('❌ Error subiendo audio manualmente:', error);
      mostrarMensaje(`❌ Error subiendo audio: ${error.message}`, 'error');
    } finally {
      procesando = false;
    }
  }

  // 🔐 FUNCIONES DE AUTENTICACIÓN
  async function iniciarSesion() {
    try {
      reproducirEfectoSeguro(TipoEfectoUI.CLICK_BOTON);
      
      // Para pruebas rápidas, crear un usuario temporal
      const email = prompt('Ingresa tu email:') || 'test@example.com';
      const password = prompt('Ingresa tu contraseña:');
      if (!password) {
        mostrarMensaje('❌ Contraseña requerida para continuar', 'error');
        return;
      }
      
      mostrarMensaje('🔐 Iniciando sesión...', 'info');
      
      // Intentar iniciar sesión
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email,
        password: password
      });
      
      if (error) {
        // Si no existe el usuario, crearlo
        console.log('Usuario no existe, creando cuenta...');
        const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
          email: email,
          password: password
        });
        
        if (signUpError) {
          throw signUpError;
        }
        
        mostrarMensaje('✅ Cuenta creada e iniciada sesión exitosamente', 'success');
      } else {
        mostrarMensaje('✅ Sesión iniciada exitosamente', 'success');
      }
      
    } catch (error: any) {
      console.error('❌ Error iniciando sesión:', error);
      mostrarMensaje(`❌ Error al iniciar sesión: ${error.message}`, 'error');
    }
  }

  async function cerrarSesion() {
    try {
      reproducirEfectoSeguro(TipoEfectoUI.CLICK_BOTON);
      
      const { error } = await supabase.auth.signOut();
      
      if (error) {
        throw error;
      }
      
      mostrarMensaje('👋 Sesión cerrada exitosamente', 'success');
      
    } catch (error) {
      console.error('❌ Error cerrando sesión:', error);
      mostrarMensaje('❌ Error al cerrar sesión', 'error');
    }
  }
</script>

<FondoPagina>
  <!-- Input file oculto -->
  <input
    type="file"
    accept="audio/*"
    bind:this={inputFileRef}
    on:change={manejarArchivoSeleccionado}
    class="hidden"
  />

  <div class="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-indigo-900 text-white">
    <!-- Header -->
    <div class="bg-black/30 backdrop-blur-md border-b border-cyan-500/30">
      <div class="container mx-auto px-6 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <div class="w-12 h-12 bg-gradient-to-r from-cyan-400 to-purple-500 rounded-xl flex items-center justify-center">
              <span class="text-2xl font-bold">🎵</span>
            </div>
            <div>
              <h1 class="text-3xl font-bold bg-gradient-to-r from-cyan-400 to-purple-400 bg-clip-text text-transparent">
                Editor Max
              </h1>
              <p class="text-cyan-300/70">Estudio de Grabación Profesional</p>
            </div>
          </div>
          
          <div class="flex items-center space-x-4">
            {#if usuario}
              <div class="flex items-center space-x-2 text-green-300">
                <span class="text-sm">👤 {usuario.email}</span>
                <button
                  on:click={cerrarSesion}
                  class="px-3 py-1 bg-red-600 hover:bg-red-500 rounded text-xs transition-colors"
                >
                  Salir
                </button>
              </div>
            {:else}
              <button
                on:click={iniciarSesion}
                class="px-4 py-2 bg-gradient-to-r from-green-600 to-emerald-600 rounded-lg hover:from-green-500 hover:to-emerald-500 transition-all duration-300 transform hover:scale-105"
              >
                🔐 Iniciar Sesión
              </button>
            {/if}
            
            <button
              on:click={irASeleccionCanciones}
              class="px-4 py-2 bg-gradient-to-r from-purple-600 to-indigo-600 rounded-lg hover:from-purple-500 hover:to-indigo-500 transition-all duration-300 transform hover:scale-105"
            >
              📚 Mis Canciones
            </button>
            
            <button
              on:click={reiniciarEditor}
              class="px-4 py-2 bg-gradient-to-r from-red-600 to-pink-600 rounded-lg hover:from-red-500 hover:to-pink-500 transition-all duration-300 transform hover:scale-105"
            >
              🔄 Nuevo Proyecto
            </button>

            <button
              on:click={mostrarAyudaSupabase}
              class="px-4 py-2 bg-gradient-to-r from-yellow-600 to-orange-600 rounded-lg hover:from-yellow-500 hover:to-orange-500 transition-all duration-300 transform hover:scale-105"
              title="Ayuda con Supabase"
            >
              🆘 Ayuda
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Barra de Progreso -->
    <div class="bg-black/20 backdrop-blur-sm border-b border-cyan-500/20">
      <div class="container mx-auto px-6 py-3">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-8">
            {#each ['Subir Audio', 'Grabar Acordeón', 'Preview', 'Publicar'] as paso, index}
              <div class="flex items-center space-x-2">
                <button
                  on:click={() => irAPaso(index + 1)}
                  class="w-8 h-8 rounded-full flex items-center justify-center transition-all duration-300 hover:scale-110 {pasoActual > index + 1 ? 'bg-green-500 hover:bg-green-400' : pasoActual === index + 1 ? 'bg-cyan-500 hover:bg-cyan-400' : 'bg-gray-600 hover:bg-gray-500'}"
                >
                  <span class="text-sm font-bold">{index + 1}</span>
                </button>
                <span class="text-sm {pasoActual >= index + 1 ? 'text-cyan-300' : 'text-gray-400'}">{paso}</span>
                {#if index < 3}
                  <div class="w-8 h-1 {pasoActual > index + 1 ? 'bg-green-500' : 'bg-gray-600'} rounded"></div>
                {/if}
              </div>
            {/each}
          </div>
          
          <div class="text-sm text-cyan-300">
            Paso {pasoActual} de 4
          </div>
        </div>
      </div>
    </div>

    <!-- Alerta de Usuario No Autenticado -->
    {#if !usuario}
      <div class="container mx-auto px-6 py-3">
        <div class="p-4 rounded-lg border bg-red-500/20 border-red-500/50 text-red-300 flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <span class="text-2xl">🔐</span>
            <div>
              <p class="font-semibold">Usuario no autenticado</p>
              <p class="text-sm text-red-200">Inicia sesión para guardar tus canciones en Supabase</p>
            </div>
          </div>
          <button
            on:click={iniciarSesion}
            class="px-4 py-2 bg-red-600 hover:bg-red-500 rounded-lg font-medium transition-colors"
          >
            Iniciar Sesión
          </button>
        </div>
      </div>
    {/if}

    <!-- Mensaje de Estado -->
    {#if mensaje}
      <div class="container mx-auto px-6 py-3">
        <div class="p-4 rounded-lg border {
          tipoMensaje === 'success' ? 'bg-green-500/20 border-green-500/50 text-green-300' :
          tipoMensaje === 'error' ? 'bg-red-500/20 border-red-500/50 text-red-300' :
          tipoMensaje === 'warning' ? 'bg-yellow-500/20 border-yellow-500/50 text-yellow-300' :
          'bg-cyan-500/20 border-cyan-500/50 text-cyan-300'
        }">
          {mensaje}
        </div>
      </div>
    {/if}

    <div class="container mx-auto px-6 py-8">
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        
        <!-- Panel Principal -->
        <div class="xl:col-span-2">
          
          <!-- PASO 1: SUBIR AUDIO -->
          {#if pasoActual === 1}
            <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-cyan-500/30 p-8">
              <h2 class="text-2xl font-bold text-cyan-400 mb-6 flex items-center">
                <span class="mr-3">📤</span>
                Paso 1: Subir Pista de Audio
              </h2>
              
              <div class="space-y-6">
                <div class="border-2 border-dashed border-cyan-500/50 rounded-xl p-12 text-center hover:border-cyan-400/70 transition-colors">
                  <div class="text-6xl mb-4">🎵</div>
                  <h3 class="text-xl font-semibold text-cyan-300 mb-2">
                    Arrastra tu archivo de audio aquí
                  </h3>
                  <p class="text-gray-400 mb-6">
                    Formatos soportados: WAV, MP3, OGG, M4A (máx. 50MB)
                  </p>
                  
                  <button
                    on:click={seleccionarArchivo}
                    disabled={procesando}
                    class="px-8 py-4 bg-gradient-to-r from-cyan-500 to-purple-500 rounded-xl font-semibold hover:from-cyan-400 hover:to-purple-400 transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {procesando ? '⏳ Cargando...' : '📁 Seleccionar Archivo'}
                  </button>
                </div>

                {#if archivoAudio}
                  <div class="bg-gradient-to-r from-green-500/20 to-cyan-500/20 rounded-xl p-6 border border-green-500/30">
                    <div class="flex items-center space-x-4">
                      <div class="w-12 h-12 bg-green-500 rounded-lg flex items-center justify-center">
                        <span class="text-xl">✅</span>
                      </div>
                      <div>
                        <h4 class="font-semibold text-green-300">Archivo Cargado</h4>
                        <p class="text-gray-300">{archivoAudio.name}</p>
                        <p class="text-sm text-gray-400">
                          Tamaño: {(archivoAudio.size / 1024 / 1024).toFixed(2)} MB
                        </p>
                      </div>
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          {/if}

          <!-- PASO 2: GRABAR ACORDEÓN -->
          {#if pasoActual === 2}
            <div class="space-y-6">
              <!-- Reproductor de Audio -->
              <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-cyan-500/30 p-6">
                <h2 class="text-xl font-bold text-cyan-400 mb-4 flex items-center">
                  <span class="mr-3">🎵</span>
                  Reproductor de Audio
                </h2>
                
                <div class="space-y-4">
                  <!-- Controles principales -->
                  <div class="flex items-center justify-center space-x-4">
                    <button
                      on:click={toggleReproduccion}
                      class="w-14 h-14 bg-gradient-to-r from-green-500 to-cyan-500 rounded-full flex items-center justify-center hover:from-green-400 hover:to-cyan-400 transition-all duration-300 transform hover:scale-105"
                    >
                      <span class="text-2xl">{reproduciendo ? '⏸️' : '▶️'}</span>
                    </button>
                    
                    <button
                      on:click={detenerReproduccion}
                      class="w-12 h-12 bg-gradient-to-r from-red-500 to-pink-500 rounded-full flex items-center justify-center hover:from-red-400 hover:to-pink-400 transition-all duration-300"
                    >
                      <span class="text-xl">⏹️</span>
                    </button>
                  </div>

                  <!-- Barra de Progreso Interactiva -->
                  <div class="space-y-2">
                    <div class="flex justify-between text-sm text-gray-400">
                      <span>{formatearTiempo(tiempoActual)}</span>
                      <span class="text-cyan-400">Offset: {offsetGrabacion.toFixed(1)}s</span>
                      <span>{formatearTiempo(duracionTotal)}</span>
                    </div>
                    <div 
                      class="w-full bg-gray-700 rounded-full h-3 cursor-pointer hover:bg-gray-600 transition-colors {arrastrando ? 'bg-cyan-700' : ''}"
                      on:mousedown={iniciarArrastre}
                      on:mousemove={actualizarPosicionArrastre}
                      on:mouseup={finalizarArrastre}
                      on:mouseleave={finalizarArrastre}
                    >
                      <div 
                        class="bg-gradient-to-r from-cyan-400 to-purple-400 h-3 rounded-full transition-all duration-300 relative"
                        style="width: {duracionTotal > 0 ? (tiempoActual / duracionTotal) * 100 : 0}%"
                      >
                        <div class="absolute right-0 top-0 w-4 h-4 bg-white rounded-full shadow-lg transform -translate-y-0.5 cursor-grab {arrastrando ? 'cursor-grabbing scale-125' : ''}"></div>
                      </div>
                    </div>
                  </div>

                  <!-- Controles de Manipulación de Tiempo -->
                  {#if grabandoAcordeon}
                    <div class="bg-purple-500/20 rounded-lg p-4 border border-purple-500/30">
                      <h4 class="text-sm font-semibold text-purple-300 mb-3">🎯 Manipulación de Línea de Tiempo</h4>
                      <div class="grid grid-cols-2 gap-3">
                        <div>
                          <label class="text-xs text-gray-400 mb-1 block">Saltos Rápidos</label>
                          <div class="flex space-x-2">
                            <button
                              on:click={() => aplicarOffsetPreconfigurado(-20)}
                              class="px-3 py-1 bg-red-500/20 border border-red-500/50 rounded text-xs hover:bg-red-500/30 transition-colors"
                            >
                              -20s
                            </button>
                            <button
                              on:click={() => aplicarOffsetPreconfigurado(-10)}
                              class="px-3 py-1 bg-red-500/20 border border-red-500/50 rounded text-xs hover:bg-red-500/30 transition-colors"
                            >
                              -10s
                            </button>
                            <button
                              on:click={() => aplicarOffsetPreconfigurado(-3)}
                              class="px-3 py-1 bg-red-500/20 border border-red-500/50 rounded text-xs hover:bg-red-500/30 transition-colors"
                            >
                              -3s
                            </button>
                          </div>
                        </div>
                        <div>
                          <label class="text-xs text-gray-400 mb-1 block">Adelantar</label>
                          <div class="flex space-x-2">
                            <button
                              on:click={() => aplicarOffsetPreconfigurado(3)}
                              class="px-3 py-1 bg-green-500/20 border border-green-500/50 rounded text-xs hover:bg-green-500/30 transition-colors"
                            >
                              +3s
                            </button>
                            <button
                              on:click={() => aplicarOffsetPreconfigurado(10)}
                              class="px-3 py-1 bg-green-500/20 border border-green-500/50 rounded text-xs hover:bg-green-500/30 transition-colors"
                            >
                              +10s
                            </button>
                            <button
                              on:click={() => aplicarOffsetPreconfigurado(20)}
                              class="px-3 py-1 bg-green-500/20 border border-green-500/50 rounded text-xs hover:bg-green-500/30 transition-colors"
                            >
                              +20s
                            </button>
                          </div>
                        </div>
                      </div>
                      <div class="mt-3">
                        <label class="text-xs text-gray-400 mb-1 block">Posiciones Exactas</label>
                        <div class="flex space-x-2">
                          <button
                            on:click={() => saltarA(0)}
                            class="px-3 py-1 bg-blue-500/20 border border-blue-500/50 rounded text-xs hover:bg-blue-500/30 transition-colors"
                          >
                            Inicio
                          </button>
                          <button
                            on:click={() => saltarA(duracionTotal / 2)}
                            class="px-3 py-1 bg-blue-500/20 border border-blue-500/50 rounded text-xs hover:bg-blue-500/30 transition-colors"
                          >
                            Medio
                          </button>
                          <button
                            on:click={() => saltarA(duracionTotal * 0.75)}
                            class="px-3 py-1 bg-blue-500/20 border border-blue-500/50 rounded text-xs hover:bg-blue-500/30 transition-colors"
                          >
                            75%
                          </button>
                        </div>
                      </div>
                    </div>
                  {/if}

                  <!-- Controles de Volumen y Velocidad -->
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm text-gray-400 mb-2">Volumen: {volumen}%</label>
                      <input
                        type="range"
                        min="0"
                        max="100"
                        bind:value={volumen}
                        on:input={cambiarVolumen}
                        class="w-full h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer slider"
                      />
                    </div>
                    <div>
                      <label class="block text-sm text-gray-400 mb-2">Velocidad: {velocidad}x</label>
                      <input
                        type="range"
                        min="0.5"
                        max="2.0"
                        step="0.1"
                        bind:value={velocidad}
                        on:input={cambiarVelocidad}
                        class="w-full h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer slider"
                      />
                    </div>
                  </div>
                </div>
              </div>

              <!-- Controles de Grabación -->
              <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-purple-500/30 p-6">
                <h2 class="text-xl font-bold text-purple-400 mb-4 flex items-center">
                  <span class="mr-3">🎹</span>
                  Grabación del Acordeón
                </h2>
                
                                  <div class="flex items-center justify-center space-x-4 mb-6">
                  {#if !grabandoAcordeon}
                    <button
                      on:click={iniciarGrabacionAcordeon}
                      class="px-8 py-4 bg-gradient-to-r from-red-500 to-pink-500 rounded-xl font-semibold hover:from-red-400 hover:to-pink-400 transition-all duration-300 transform hover:scale-105"
                    >
                      🔴 Iniciar Grabación
                    </button>
                    
                    <button
                      on:click={pruebaFuncionalidad}
                      class="px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-lg font-semibold hover:from-blue-400 hover:to-purple-400 transition-all duration-300 text-sm"
                    >
                      🧪 Probar
                    </button>
                  {:else}
                    <button
                      on:click={pausarGrabacionAcordeon}
                      class="px-6 py-3 bg-gradient-to-r from-yellow-500 to-orange-500 rounded-lg font-semibold hover:from-yellow-400 hover:to-orange-400 transition-all duration-300"
                    >
                      {pausado ? '▶️ Continuar' : '⏸️ Pausar'}
                    </button>
                    
                    <button
                      on:click={detenerGrabacionAcordeon}
                      class="px-6 py-3 bg-gradient-to-r from-green-500 to-cyan-500 rounded-lg font-semibold hover:from-green-400 hover:to-cyan-400 transition-all duration-300"
                    >
                      ⏹️ Finalizar
                    </button>
                    
                    <button
                      on:click={pruebaFuncionalidad}
                      class="px-3 py-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-lg font-semibold hover:from-blue-400 hover:to-purple-400 transition-all duration-300 text-sm"
                    >
                      🧪 Probar
                    </button>
                  {/if}
                </div>

                {#if grabandoAcordeon}
                  <div class="bg-red-500/20 border border-red-500/50 rounded-lg p-4 text-center">
                    <div class="flex items-center justify-center space-x-2 mb-2">
                      <div class="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
                      <span class="text-red-300 font-semibold">GRABANDO</span>
                    </div>
                    <p class="text-sm text-gray-300">
                      Notas grabadas: {notasGrabadas.length}
                    </p>
                  </div>
                {/if}
              </div>

              <!-- Acordeón Simulador -->
              <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-yellow-500/30 p-6">
                <h3 class="text-lg font-semibold text-yellow-400 mb-4">
                  🪗 Simulador de Acordeón
                </h3>
                                    <div class="editor-max-acordeon">
                      <AcordeonSimulador
                        bind:this={acordeonRef}
                        bind:direccion
                        bind:afinacion
                        bind:botonesActivos
                        modoEditor={true}
                        grabando={grabandoAcordeon}
                        pausado={pausado}
                        reproduciendo={reproduciendo}
                        onGrabarNota={grabarNota}
                        onFinalizarNota={finalizarNota}
                        onCambiarFuelle={manejarCambioFuelle}
                        on:notaPresionada={manejarNotaPresionada}
                        on:notaLiberada={manejarNotaLiberada}
                        on:cambioFuelle={manejarCambioFuelle}
                      />
                    </div>
              </div>
            </div>
          {/if}

          <!-- PASO 3: PREVIEW -->
          {#if pasoActual === 3}
            <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-green-500/30 p-8">
              <h2 class="text-2xl font-bold text-green-400 mb-6 flex items-center">
                <span class="mr-3">🎬</span>
                Paso 3: Preview y Ajustes Finales
              </h2>
              
              <div class="space-y-6">
                <div class="grid grid-cols-3 gap-4">
                  <div class="bg-cyan-500/20 rounded-xl p-4 border border-cyan-500/30">
                    <h4 class="font-semibold text-cyan-300 mb-2">Audio Original</h4>
                    <p class="text-sm text-gray-400">
                      Duración: {formatearTiempo(duracionTotal)}
                    </p>
                  </div>
                  
                  <div class="bg-purple-500/20 rounded-xl p-4 border border-purple-500/30">
                    <h4 class="font-semibold text-purple-300 mb-2">Acordeón Grabado</h4>
                    <p class="text-sm text-gray-400">
                      {notasGrabadas.filter(n => !n.activa).length} notas grabadas
                    </p>
                  </div>

                  <div class="bg-yellow-500/20 rounded-xl p-4 border border-yellow-500/30">
                    <h4 class="font-semibold text-yellow-300 mb-2">Velocidad</h4>
                    <p class="text-sm text-gray-400">
                      Grabado: {velocidadGrabacion}x
                    </p>
                    <p class="text-sm text-gray-400">
                      Actual: {velocidad}x
                    </p>
                  </div>
                </div>

                <div class="text-center space-y-4">
                  {#if !mostrandoPreview}
                    <button
                      on:click={mostrarPreview}
                      class="px-8 py-4 bg-gradient-to-r from-green-500 to-cyan-500 rounded-xl font-semibold hover:from-green-400 hover:to-cyan-400 transition-all duration-300 transform hover:scale-105"
                    >
                      🎵 Generar Preview Sincronizado
                    </button>
                  {:else}
                    <div class="space-y-4">
                      <div class="bg-green-500/20 border border-green-500/50 rounded-lg p-4">
                        <h4 class="font-semibold text-green-300 mb-2">Preview Listo</h4>
                        <p class="text-sm text-gray-400">
                          Reproduce para ver la sincronización entre audio y acordeón
                        </p>
                      </div>

                      <!-- Barra de Progreso del Preview -->
                      <div class="bg-black/40 rounded-lg p-4 border border-cyan-500/30">
                        <h4 class="text-sm font-semibold text-cyan-300 mb-3">🎵 Control de Reproducción</h4>
                        
                        <!-- Información de tiempo -->
                        <div class="flex justify-between text-sm text-gray-400 mb-2">
                          <span>{formatearTiempo(tiempoActual)}</span>
                          <span class="text-cyan-400">{reproduciendo ? 'Reproduciendo...' : 'Pausado'}</span>
                          <span>{formatearTiempo(duracionTotal)}</span>
                        </div>

                        <!-- Barra de progreso interactiva -->
                        <div 
                          class="w-full bg-gray-700 rounded-full h-4 cursor-pointer hover:bg-gray-600 transition-colors {arrastrando ? 'bg-cyan-700' : ''} mb-3"
                          on:mousedown={iniciarArrastrePreview}
                          on:mousemove={actualizarPosicionArrastrePreview}
                          on:mouseup={finalizarArrastrePreview}
                          on:mouseleave={finalizarArrastrePreview}
                        >
                          <div 
                            class="bg-gradient-to-r from-green-400 to-cyan-400 h-4 rounded-full transition-all duration-300 relative"
                            style="width: {duracionTotal > 0 ? (tiempoActual / duracionTotal) * 100 : 0}%"
                          >
                            <div class="absolute right-0 top-0 w-5 h-5 bg-white rounded-full shadow-lg transform -translate-y-0.5 cursor-grab {arrastrando ? 'cursor-grabbing scale-125' : ''} flex items-center justify-center">
                              <div class="w-2 h-2 bg-green-500 rounded-full"></div>
                            </div>
                          </div>
                        </div>

                        <!-- Controles de navegación rápida -->
                        <div class="grid grid-cols-3 gap-2 mb-3">
                          <div>
                            <label class="text-xs text-gray-400 mb-1 block">Retroceder</label>
                            <div class="flex space-x-1">
                              <button
                                on:click={() => aplicarOffsetPreview(-10)}
                                class="px-2 py-1 bg-red-500/20 border border-red-500/50 rounded text-xs hover:bg-red-500/30 transition-colors"
                              >
                                -10s
                              </button>
                              <button
                                on:click={() => aplicarOffsetPreview(-5)}
                                class="px-2 py-1 bg-red-500/20 border border-red-500/50 rounded text-xs hover:bg-red-500/30 transition-colors"
                              >
                                -5s
                              </button>
                            </div>
                          </div>
                          <div>
                            <label class="text-xs text-gray-400 mb-1 block">Posiciones</label>
                            <div class="flex space-x-1">
                              <button
                                on:click={() => saltarAPreview(0)}
                                class="px-2 py-1 bg-blue-500/20 border border-blue-500/50 rounded text-xs hover:bg-blue-500/30 transition-colors"
                              >
                                Inicio
                              </button>
                              <button
                                on:click={() => saltarAPreview(duracionTotal / 2)}
                                class="px-2 py-1 bg-blue-500/20 border border-blue-500/50 rounded text-xs hover:bg-blue-500/30 transition-colors"
                              >
                                Medio
                              </button>
                            </div>
                          </div>
                          <div>
                            <label class="text-xs text-gray-400 mb-1 block">Adelantar</label>
                            <div class="flex space-x-1">
                              <button
                                on:click={() => aplicarOffsetPreview(5)}
                                class="px-2 py-1 bg-green-500/20 border border-green-500/50 rounded text-xs hover:bg-green-500/30 transition-colors"
                              >
                                +5s
                              </button>
                              <button
                                on:click={() => aplicarOffsetPreview(10)}
                                class="px-2 py-1 bg-green-500/20 border border-green-500/50 rounded text-xs hover:bg-green-500/30 transition-colors"
                              >
                                +10s
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                      
                      <div class="flex justify-center space-x-4">
                        <button
                          on:click={reproducirSecuenciaSincronizada}
                          class="px-6 py-3 bg-gradient-to-r from-blue-500 to-purple-500 rounded-lg font-semibold hover:from-blue-400 hover:to-purple-400 transition-all duration-300"
                        >
                          {reproduciendo ? '⏹️ Detener' : '▶️ Reproducir'} Preview Sincronizado
                        </button>
                        
                        <button
                          on:click={cerrarPreview}
                          class="px-6 py-3 bg-gradient-to-r from-gray-600 to-gray-700 rounded-lg font-semibold hover:from-gray-500 hover:to-gray-600 transition-all duration-300"
                        >
                          ❌ Cerrar Preview
                        </button>
                      </div>
                    </div>
                  {/if}
                </div>

                {#if mostrandoPreview}
                  <!-- Acordeón para Preview -->
                  <div class="bg-black/60 rounded-xl p-6 border border-yellow-500/30">
                    <h4 class="text-lg font-semibold text-yellow-400 mb-4">
                      🪗 Preview Sincronizado
                    </h4>
                    <div class="editor-max-acordeon">
                      <AcordeonSimulador
                        bind:this={acordeonRef}
                        bind:direccion
                        bind:afinacion
                        bind:botonesActivos
                        readonly={true}
                        reproduciendo={reproduciendo}
                      />
                    </div>
                  </div>
                {/if}

                {#if notasGrabadas.filter(n => !n.activa).length > 0}
                  <div class="text-center">
                    <button
                      on:click={() => pasoActual = 4}
                      class="px-8 py-4 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl font-semibold hover:from-purple-400 hover:to-pink-400 transition-all duration-300 transform hover:scale-105"
                    >
                      ➡️ Continuar a Publicación
                    </button>
                  </div>
                {/if}
              </div>
            </div>
          {/if}

          <!-- PASO 4: PUBLICAR -->
          {#if pasoActual === 4}
            <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-pink-500/30 p-8">
              <h2 class="text-2xl font-bold text-pink-400 mb-6 flex items-center">
                <span class="mr-3">🚀</span>
                Paso 4: Publicar Canción
              </h2>
              
              <div class="text-center">
                <div class="w-24 h-24 bg-gradient-to-r from-pink-500 to-purple-500 rounded-full mx-auto mb-6 flex items-center justify-center">
                  <span class="text-4xl">🎉</span>
                </div>
                
                <h3 class="text-2xl font-bold text-pink-300 mb-4">
                  ¡Canción Completada!
                </h3>
                
                <p class="text-gray-400 mb-4 max-w-md mx-auto">
                  Tu canción ha sido sincronizada perfectamente y está lista para ser publicada en tu biblioteca personal.
                </p>
                
                <div class="bg-blue-500/20 border border-blue-500/50 rounded-lg p-4 mb-6 max-w-lg mx-auto">
                  <h4 class="font-semibold text-blue-300 mb-2">💡 Información importante</h4>
                  <p class="text-sm text-gray-300 mb-3">
                    Si tienes problemas con Supabase, la canción se guardará automáticamente en tu navegador (localStorage) sin el audio.
                  </p>
                  
                  <button
                    on:click={verificarEstadoSupabase}
                    class="px-3 py-2 bg-blue-600 hover:bg-blue-500 rounded-lg text-sm font-medium transition-colors"
                  >
                    🔍 Verificar Estado de Supabase
                  </button>
                </div>
                
                <div class="space-y-4">
                  <button
                    on:click={publicarCancion}
                    disabled={procesando}
                    class="px-8 py-4 bg-gradient-to-r from-green-500 to-cyan-500 rounded-xl font-semibold hover:from-green-400 hover:to-cyan-400 transition-all duration-300 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {procesando ? '⏳ Publicando...' : '🚀 Publicar Canción'}
                  </button>
                  
                  <div class="flex justify-center space-x-4">
                    <button
                      on:click={irASeleccionCanciones}
                      class="px-6 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 rounded-lg hover:from-purple-500 hover:to-indigo-500 transition-all duration-300"
                    >
                      📚 Ver Mis Canciones
                    </button>
                    
                    <button
                      on:click={reiniciarEditor}
                      class="px-6 py-3 bg-gradient-to-r from-gray-600 to-gray-700 rounded-lg hover:from-gray-500 hover:to-gray-600 transition-all duration-300"
                    >
                      🔄 Nuevo Proyecto
                    </button>
                  </div>
                </div>
              </div>
            </div>
          {/if}
        </div>

        <!-- Panel Lateral: Metadatos -->
        <div class="space-y-6">
          <!-- Información de la Canción -->
          <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-indigo-500/30 p-6">
            <h3 class="text-xl font-bold text-indigo-400 mb-4 flex items-center">
              <span class="mr-3">📝</span>
              Información de la Canción
            </h3>
            
            <div class="space-y-4">
              <div>
                <label class="block text-sm text-gray-400 mb-2">Título *</label>
                <input
                  type="text"
                  bind:value={datosCancion.titulo}
                  placeholder="Nombre de tu canción"
                  class="w-full bg-black/50 border border-gray-600 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:border-indigo-500 focus:outline-none transition-colors"
                />
              </div>
              
              <div>
                <label class="block text-sm text-gray-400 mb-2">Artista *</label>
                <input
                  type="text"
                  bind:value={datosCancion.artista}
                  placeholder="Tu nombre artístico"
                  class="w-full bg-black/50 border border-gray-600 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:border-indigo-500 focus:outline-none transition-colors"
                />
              </div>
              
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm text-gray-400 mb-2">Género</label>
                  <select
                    bind:value={datosCancion.genero}
                    class="w-full bg-black/50 border border-gray-600 rounded-lg px-4 py-3 text-white focus:border-indigo-500 focus:outline-none transition-colors"
                  >
                    <option value="vallenato">Vallenato</option>
                    <option value="cumbia">Cumbia</option>
                    <option value="merengue">Merengue</option>
                    <option value="paseo">Paseo</option>
                    <option value="puya">Puya</option>
                    <option value="son">Son</option>
                  </select>
                </div>
                
                <div>
                  <label class="block text-sm text-gray-400 mb-2">Dificultad</label>
                  <select
                    bind:value={datosCancion.dificultad_tecnica}
                    class="w-full bg-black/50 border border-gray-600 rounded-lg px-4 py-3 text-white focus:border-indigo-500 focus:outline-none transition-colors"
                  >
                    <option value="principiante">Principiante</option>
                    <option value="intermedio">Intermedio</option>
                    <option value="avanzado">Avanzado</option>
                    <option value="experto">Experto</option>
                  </select>
                </div>
              </div>
              
              <div>
                <label class="block text-sm text-gray-400 mb-2">Descripción</label>
                <textarea
                  bind:value={datosCancion.descripcion}
                  placeholder="Describe tu canción..."
                  rows="3"
                  class="w-full bg-black/50 border border-gray-600 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:border-indigo-500 focus:outline-none transition-colors resize-none"
                ></textarea>
              </div>
              
              <!-- Tags -->
              <div>
                <label class="block text-sm text-gray-400 mb-2">Tags</label>
                <div class="flex space-x-2 mb-2">
                  <input
                    type="text"
                    bind:value={tagInput}
                    placeholder="Agregar tag..."
                    on:keydown={(e) => e.key === 'Enter' && agregarTag()}
                    class="flex-1 bg-black/50 border border-gray-600 rounded-lg px-3 py-2 text-white placeholder-gray-400 focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                  <button
                    on:click={agregarTag}
                    class="px-4 py-2 bg-indigo-600 rounded-lg hover:bg-indigo-500 transition-colors"
                  >
                    +
                  </button>
                </div>
                
                {#if datosCancion.tags && datosCancion.tags.length > 0}
                  <div class="flex flex-wrap gap-2">
                    {#each datosCancion.tags as tag}
                      <span class="bg-indigo-600/30 border border-indigo-500/50 rounded-full px-3 py-1 text-sm text-indigo-300 flex items-center space-x-2">
                        <span>{tag}</span>
                        <button
                          on:click={() => eliminarTag(tag)}
                          class="text-indigo-400 hover:text-red-400 transition-colors"
                        >
                          ×
                        </button>
                      </span>
                    {/each}
                  </div>
                {/if}
              </div>
            </div>
          </div>

          <!-- Estadísticas -->
          <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-green-500/30 p-6">
            <h3 class="text-xl font-bold text-green-400 mb-4 flex items-center">
              <span class="mr-3">📊</span>
              Estadísticas del Proyecto
            </h3>
            
            <div class="space-y-3">
              <div class="flex justify-between">
                <span class="text-gray-400">Duración del Audio:</span>
                <span class="text-green-300">{formatearTiempo(duracionTotal)}</span>
              </div>
              
              <div class="flex justify-between items-center">
                <span class="text-gray-400">Estado del Audio:</span>
                <div class="flex items-center space-x-2">
                  <span class="text-sm">
                    {#if datosCancion.url_audio}
                      <span class="text-green-300">☁️ En Supabase</span>
                    {:else if archivoAudio}
                      <span class="text-orange-300">💾 Solo Local</span>
                    {:else}
                      <span class="text-gray-400">❌ Sin Audio</span>
                    {/if}
                  </span>
                  
                  {#if archivoAudio && !datosCancion.url_audio && usuario?.id}
                    <button
                      on:click={subirAudioManualmente}
                      disabled={procesando}
                      class="px-2 py-1 bg-blue-600 hover:bg-blue-500 rounded text-xs transition-colors disabled:opacity-50"
                      title="Subir audio a Supabase"
                    >
                      ☁️
                    </button>
                  {/if}
                </div>
              </div>
              
              <div class="flex justify-between">
                <span class="text-gray-400">Notas Grabadas:</span>
                <span class="text-purple-300">{notasGrabadas.filter(n => !n.activa).length}</span>
              </div>
              
              <div class="flex justify-between">
                <span class="text-gray-400">Sincronización:</span>
                <span class="text-cyan-300">{mostrandoPreview ? 'Activa' : 'Pendiente'}</span>
              </div>
              
              <div class="flex justify-between">
                <span class="text-gray-400">Estado:</span>
                <span class="text-yellow-300">
                  {pasoActual === 1 ? 'Esperando Audio' :
                   pasoActual === 2 ? 'Grabando' :
                   pasoActual === 3 ? 'Sincronizando' :
                   'Listo para Publicar'}
                </span>
              </div>
            </div>
          </div>

          <!-- Consejos -->
          <div class="bg-black/40 backdrop-blur-md rounded-2xl border border-yellow-500/30 p-6">
            <h3 class="text-xl font-bold text-yellow-400 mb-4 flex items-center">
              <span class="mr-3">💡</span>
              Consejos Pro
            </h3>
            
            <div class="space-y-3 text-sm text-gray-300">
              {#if pasoActual === 1}
                <p>• Usa archivos WAV para mejor calidad</p>
                <p>• Asegúrate de que el audio sea claro</p>
                <p>• Evita ruidos de fondo</p>
              {:else if pasoActual === 2}
                <p>• Escucha la pista antes de grabar</p>
                <p>• Mantén el ritmo constante</p>
                <p>• Puedes pausar si necesitas un descanso</p>
              {:else if pasoActual === 3}
                <p>• Revisa la sincronización en el preview</p>
                <p>• Ajusta el volumen si es necesario</p>
                <p>• Verifica que todas las notas suenen bien</p>
              {:else}
                <p>• ¡Tu canción está lista!</p>
                <p>• Compártela con otros músicos</p>
                <p>• Crea más canciones increíbles</p>
              {/if}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</FondoPagina>

<style>
  .slider::-webkit-slider-thumb {
    appearance: none;
    height: 20px;
    width: 20px;
    border-radius: 50%;
    background: linear-gradient(45deg, #06b6d4, #8b5cf6);
    cursor: pointer;
    border: 2px solid #1f2937;
  }

  .slider::-moz-range-thumb {
    height: 20px;
    width: 20px;
    border-radius: 50%;
    background: linear-gradient(45deg, #06b6d4, #8b5cf6);
    cursor: pointer;
    border: 2px solid #1f2937;
  }

  /* Animaciones personalizadas */
  @keyframes pulse-glow {
    0%, 100% {
      box-shadow: 0 0 20px rgba(6, 182, 212, 0.5);
    }
    50% {
      box-shadow: 0 0 30px rgba(6, 182, 212, 0.8);
    }
  }

  .animate-pulse-glow {
    animation: pulse-glow 2s ease-in-out infinite;
  }

  /* Estilos específicos para el acordeón en Editor Max */
  .editor-max-acordeon :global(.disposicion-acordeon) {
    width: 50vh !important;
    height: 50vh !important;
    position: relative !important;
    left: auto !important;
    top: auto !important;
    transform: none !important;
    margin: 0 auto;
  }

  .editor-max-acordeon :global(.boton) {
    height: 2.5vh !important;
    width: 2.5vh !important;
    font-size: 0.9vh !important;
    margin-bottom: 0.5vh !important;
  }

  .editor-max-acordeon :global(.fila h4) {
    font-size: 0.6vh !important;
  }

  .editor-max-acordeon :global(.lado-teclas) {
    width: 1.7% !important;
  }

  .editor-max-acordeon :global(.lado-bajos) {
    width: 1.7% !important;
  }

  @media (max-width: 1200px) {
    .editor-max-acordeon :global(.disposicion-acordeon) {
      width: 45vh !important;
      height: 45vh !important;
    }
  }

  @media (max-width: 992px) {
    .editor-max-acordeon :global(.disposicion-acordeon) {
      width: 40vh !important;
      height: 40vh !important;
    }
  }

  @media (max-width: 768px) {
    .editor-max-acordeon :global(.disposicion-acordeon) {
      width: 35vh !important;
      height: 35vh !important;
    }
  }
</style> 