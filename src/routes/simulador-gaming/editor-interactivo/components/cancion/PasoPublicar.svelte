<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { goto } from '$app/navigation';
  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
  
  // Servicios (simular importación)
  import CancionesService from '$lib/services/cancionesService';
  import StorageService from '$lib/services/storageService';
  
  export let contenido: any = {};
  
  const dispatch = createEventDispatcher<{
    finalizar: any;
    regresar: void;
  }>();
  
  let publicando = false;
  let progreso = 0;
  let mensaje = '';
  let tipoMensaje = 'info';
  let cancionPublicada = false;
  let idCancionPublicada = null;
  
  // Configuración de publicación
  let esPublica = true;
  let esPremium = false;
  let tagsPersonalizados = '';
  let comentarios = '';
  let permitirDescargas = true;
  let permitirRemezclas = true;
  let notificacionesActivadas = true;
  
  // Validación final
  let validacionCompleta = false;
  let erroresValidacion: string[] = [];
  
  // Verificar validación al cargar
  $: {
    validarCancionCompleta();
  }
  
  const validarCancionCompleta = () => {
    erroresValidacion = [];
    
    // Validar metadatos básicos
    if (!contenido.titulo?.trim()) {
      erroresValidacion.push('Título es requerido');
    }
    
    if (!contenido.artista?.trim()) {
      erroresValidacion.push('Artista es requerido');
    }
    
    // Validar audio
    if (!contenido.audio) {
      erroresValidacion.push('Archivo de audio es requerido');
    }
    
    // Validar notas
    if (!contenido.notas || contenido.notas.length === 0) {
      erroresValidacion.push('Debe tener al menos una nota grabada');
    }
    
    // Validar duraciones
    if (contenido.duracion_segundos < 10) {
      erroresValidacion.push('La canción debe durar al menos 10 segundos');
    }
    
    if (contenido.duracion_segundos > 600) {
      erroresValidacion.push('La canción no puede durar más de 10 minutos');
    }
    
    validacionCompleta = erroresValidacion.length === 0;
  };
  
  const publicarCancion = async () => {
    if (!validacionCompleta) {
      mensaje = 'Corrige los errores antes de publicar';
      tipoMensaje = 'error';
      return;
    }
    
    const usuario = $estadoUsuarioActual;
    if (!usuario) {
      mensaje = 'Debes estar logueado para publicar';
      tipoMensaje = 'error';
      return;
    }
    
    try {
      publicando = true;
      progreso = 0;
      mensaje = 'Iniciando publicación...';
      tipoMensaje = 'info';
      
      // Paso 1: Subir audio a Supabase (30%)
      progreso = 10;
      mensaje = 'Subiendo archivo de audio...';
      
      const urlAudio = await subirAudioASupabase();
      if (!urlAudio) {
        throw new Error('Error subiendo el archivo de audio');
      }
      
      progreso = 30;
      mensaje = 'Audio subido exitosamente';
      
      // Paso 2: Preparar datos de la canción (40%)
      progreso = 40;
      mensaje = 'Preparando datos de la canción...';
      
      const tagsArray = [
        contenido.genero,
        contenido.afinacion,
        ...procesarTags(tagsPersonalizados)
      ];
      
      const datosCancion = {
        titulo: contenido.titulo,
        artista: contenido.artista,
        genero: contenido.genero,
        nivel_dificultad: contenido.nivel_dificultad,
        duracion_segundos: contenido.duracion_segundos,
        bpm: contenido.bpm,
        afinacion: contenido.afinacion,
        url_audio: urlAudio,
        descripcion: contenido.descripcion || '',
        tags: tagsArray,
        dificultad_tecnica: obtenerDificultadTecnica(contenido.nivel_dificultad),
        requiere_cambios_fuelle: verificarCambiosFuelle(contenido.notas),
        requiere_acordes: verificarAcordes(contenido.notas),
        requiere_bajos: verificarBajos(contenido.notas),
        xp_recompensa: calcularXP(contenido.notas, contenido.nivel_dificultad),
        monedas_recompensa: calcularMonedas(contenido.notas, contenido.nivel_dificultad),
        puntos_precision: 100,
        tiempo_maximo_minutos: Math.ceil(contenido.duracion_segundos / 60) + 2,
        precision_minima_requerida: 75,
        intentos_maximos: 3,
        estado: 'activa',
        es_publica: esPublica,
        es_premium: esPremium,
        orden_mostrar: Date.now(),
        creado_por: usuario.id,
        configuracion_adicional: {
          permitir_descargas: permitirDescargas,
          permitir_remezclas: permitirRemezclas,
          comentarios: comentarios,
          velocidad_grabacion: contenido.velocidad_grabacion || 1.0,
          direccion_inicial: contenido.direccion_inicial || 'halar'
        }
      };
      
      // Paso 3: Crear canción en base de datos (60%)
      progreso = 50;
      mensaje = 'Creando canción en la base de datos...';
      
      const cancionCreada = await CancionesService.crearCancion(datosCancion);
      if (!cancionCreada) {
        throw new Error('Error creando la canción en la base de datos');
      }
      
      idCancionPublicada = cancionCreada.id;
      progreso = 60;
      mensaje = 'Canción creada exitosamente';
      
      // Paso 4: Crear secuencia de notas (80%)
      progreso = 70;
      mensaje = 'Procesando secuencia de notas...';
      
      const notasEstructuradas = convertirNotasAEstructurado(contenido.notas);
      
      const datosSecuencia = {
        cancion_id: cancionCreada.id,
        nombre_secuencia: 'Secuencia principal',
        descripcion: 'Secuencia creada en Editor Interactivo',
        notas_secuencia: notasEstructuradas,
        duracion_total_ms: contenido.duracion_segundos * 1000,
        tolerancia_timing_ms: 150,
        auto_cuantizar: false,
        usar_metronomo: false,
        marcadores_tiempo: {},
        es_secuencia_principal: true,
        nivel_dificultad: contenido.nivel_dificultad,
        estado: 'activa',
        configuracion_reproduccion: {
          velocidad_original: contenido.velocidad_grabacion || 1.0,
          direccion_inicial: contenido.direccion_inicial || 'halar',
          total_notas: contenido.notas.length
        }
      };
      
      progreso = 80;
      mensaje = 'Guardando secuencia de notas...';
      
      const secuenciaCreada = await CancionesService.crearSecuencia(datosSecuencia);
      if (!secuenciaCreada) {
        throw new Error('Error creando la secuencia de notas');
      }
      
      // Paso 5: Finalizar y notificar (100%)
      progreso = 90;
      mensaje = 'Finalizando publicación...';
      
      // Enviar notificación si está habilitada
      if (notificacionesActivadas) {
        await enviarNotificacionPublicacion(cancionCreada);
      }
      
      progreso = 100;
      mensaje = '🎉 ¡Canción publicada exitosamente!';
      tipoMensaje = 'success';
      cancionPublicada = true;
      
      // Dispatch evento de finalización
      dispatch('finalizar', {
        cancion: cancionCreada,
        secuencia: secuenciaCreada,
        url_audio: urlAudio
      });
      
      // Redirigir después de un momento
      setTimeout(() => {
        goto('/simulador-gaming/seleccion-canciones');
      }, 3000);
      
    } catch (error) {
      console.error('Error publicando canción:', error);
      
      let mensajeError = 'Error al publicar la canción';
      
      if (error.message.includes('demasiado grande')) {
        mensajeError = 'El archivo de audio es demasiado grande (máx. 50MB)';
      } else if (error.message.includes('inválido')) {
        mensajeError = 'El archivo de audio no es válido';
      } else if (error.message.includes('autenticado')) {
        mensajeError = 'Sesión expirada. Por favor inicia sesión nuevamente';
      } else {
        mensajeError = error.message || 'Error desconocido';
      }
      
      mensaje = `❌ ${mensajeError}`;
      tipoMensaje = 'error';
      progreso = 0;
      
    } finally {
      publicando = false;
    }
  };
  
  const subirAudioASupabase = async (): Promise<string | null> => {
    const usuario = $estadoUsuarioActual;
    if (!usuario?.id) {
      throw new Error('Usuario no autenticado');
    }
    
    try {
      // Verificar bucket
      const bucketOk = await StorageService.verificarYCrearBucket();
      if (!bucketOk) {
        throw new Error('No se pudo acceder al bucket de storage');
      }
    } catch (error) {
      console.error('Error verificando bucket:', error);
      throw new Error('Error de conexión con el storage');
    }
    
    // Validar archivo
    const validacion = StorageService.validarArchivo(contenido.audio);
    if (!validacion.valido) {
      throw new Error(`Archivo inválido: ${validacion.error}`);
    }
    
    // Generar nombre único
    const extension = contenido.audio.name.split('.').pop() || 'mp3';
    const rutaArchivo = StorageService.generarNombreArchivo(
      contenido.titulo, 
      usuario.id, 
      extension
    );
    
    // Subir archivo
    const resultado = await StorageService.subirArchivo(
      contenido.audio,
      rutaArchivo,
      (progress) => {
        progreso = Math.min(10 + (progress * 0.2), 30);
      }
    );
    
    if (!resultado.success) {
      throw new Error(`Error de subida: ${resultado.error}`);
    }
    
    return resultado.url;
  };
  
  const convertirNotasAEstructurado = (notasGrabadas: any[]) => {
    return notasGrabadas
      .filter(nota => !nota.activa)
      .map(nota => ({
        timestamp_ms: (nota.tiempo || 0) * 1000,
        duracion_ms: (nota.duracion || 0.2) * 1000,
        nota_id: nota.idBoton || 'desconocida',
        nota_nombre: nota.nombre || 'Desconocida',
        fuelle_direccion: nota.direccion || 'halar',
        es_acorde: false,
        notas_acorde: [],
        intensidad: 'normal',
        es_opcional: false,
        tipo_nota: 'melodia'
      }))
      .sort((a, b) => a.timestamp_ms - b.timestamp_ms);
  };
  
  const procesarTags = (tagsString: string): string[] => {
    if (!tagsString.trim()) return [];
    
    return tagsString
      .split(',')
      .map(tag => tag.trim())
      .filter(tag => tag.length > 0)
      .slice(0, 10); // Máximo 10 tags
  };
  
  const obtenerDificultadTecnica = (nivel: number): string => {
    switch (nivel) {
      case 1: return 'principiante';
      case 2: return 'intermedio';
      case 3: return 'avanzado';
      case 4: return 'experto';
      default: return 'principiante';
    }
  };
  
  const verificarCambiosFuelle = (notas: any[]): boolean => {
    const direcciones = new Set(notas.map(n => n.direccion));
    return direcciones.size > 1;
  };
  
  const verificarAcordes = (notas: any[]): boolean => {
    // Verificar si hay notas simultáneas (acordes)
    const tiempos = notas.map(n => Math.round(n.tiempo * 100) / 100);
    const tiemposUnicos = new Set(tiempos);
    return tiempos.length > tiemposUnicos.size;
  };
  
  const verificarBajos = (notas: any[]): boolean => {
    // Verificar si hay notas de bajo (dependería de la configuración del acordeón)
    return notas.some(n => n.idBoton?.includes('bajo') || n.tipo === 'bajo');
  };
  
  const calcularXP = (notas: any[], dificultad: number): number => {
    const baseXP = 50;
    const notasMultiplier = Math.min(notas.length / 10, 5);
    const difficultyMultiplier = dificultad * 0.5;
    
    return Math.round(baseXP + (notasMultiplier * 10) + (difficultyMultiplier * 20));
  };
  
  const calcularMonedas = (notas: any[], dificultad: number): number => {
    const baseMonedas = 10;
    const notasMultiplier = Math.min(notas.length / 20, 3);
    const difficultyMultiplier = dificultad * 0.3;
    
    return Math.round(baseMonedas + (notasMultiplier * 5) + (difficultyMultiplier * 10));
  };
  
  const enviarNotificacionPublicacion = async (cancion: any) => {
    // Simular envío de notificación
    console.log('Enviando notificación de nueva canción:', cancion.titulo);
    
    // Aquí se implementaría la lógica real de notificaciones
    // por ejemplo, notificar a seguidores, etc.
  };
  
  const formatearTiempo = (segundos: number): string => {
    const minutos = Math.floor(segundos / 60);
    const segs = Math.floor(segundos % 60);
    return `${minutos}:${segs.toString().padStart(2, '0')}`;
  };
</script>

<div class="paso-publicar">
  <div class="header-paso">
    <h3>🚀 Paso 4: Publicar Canción</h3>
    <p>Configura los detalles finales y publica tu canción</p>
  </div>
  
  <!-- Resumen de la canción -->
  <div class="resumen-cancion">
    <h4>📋 Resumen de la Canción</h4>
    <div class="grid-resumen">
      <div class="info-basica">
        <div class="campo-resumen">
          <span class="etiqueta">Título:</span>
          <span class="valor">{contenido.titulo}</span>
        </div>
        <div class="campo-resumen">
          <span class="etiqueta">Artista:</span>
          <span class="valor">{contenido.artista}</span>
        </div>
        <div class="campo-resumen">
          <span class="etiqueta">Género:</span>
          <span class="valor">{contenido.genero}</span>
        </div>
        <div class="campo-resumen">
          <span class="etiqueta">Duración:</span>
          <span class="valor">{formatearTiempo(contenido.duracion_segundos)}</span>
        </div>
      </div>
      
      <div class="estadisticas-resumen">
        <div class="stat-item">
          <span class="stat-numero">{contenido.notas?.length || 0}</span>
          <span class="stat-label">Notas</span>
        </div>
        <div class="stat-item">
          <span class="stat-numero">{contenido.bpm}</span>
          <span class="stat-label">BPM</span>
        </div>
        <div class="stat-item">
          <span class="stat-numero">{contenido.afinacion}</span>
          <span class="stat-label">Afinación</span>
        </div>
        <div class="stat-item">
          <span class="stat-numero">{contenido.velocidad_grabacion || 1.0}x</span>
          <span class="stat-label">Velocidad</span>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Validación -->
  <div class="validacion-final">
    <h4>✅ Validación Final</h4>
    <div class="estado-validacion" class:valido={validacionCompleta} class:invalido={!validacionCompleta}>
      <div class="icono-validacion">
        {validacionCompleta ? '✅' : '❌'}
      </div>
      <div class="texto-validacion">
        {validacionCompleta ? 'Canción lista para publicar' : 'Se encontraron errores'}
      </div>
    </div>
    
    {#if erroresValidacion.length > 0}
      <div class="errores-validacion">
        <h5>Errores encontrados:</h5>
        <ul>
          {#each erroresValidacion as error}
            <li>{error}</li>
          {/each}
        </ul>
      </div>
    {/if}
  </div>
  
  <!-- Configuración de publicación -->
  <div class="configuracion-publicacion">
    <h4>⚙️ Configuración de Publicación</h4>
    
    <div class="opciones-publicacion">
      <div class="opcion">
        <label class="checkbox-label">
          <input type="checkbox" bind:checked={esPublica} />
          <span class="checkmark"></span>
          Hacer canción pública
        </label>
        <p class="descripcion-opcion">
          Otros usuarios podrán ver y tocar tu canción
        </p>
      </div>
      
      <div class="opcion">
        <label class="checkbox-label">
          <input type="checkbox" bind:checked={esPremium} />
          <span class="checkmark"></span>
          Contenido premium
        </label>
        <p class="descripcion-opcion">
          Solo usuarios premium podrán acceder
        </p>
      </div>
      
      <div class="opcion">
        <label class="checkbox-label">
          <input type="checkbox" bind:checked={permitirDescargas} />
          <span class="checkmark"></span>
          Permitir descargas
        </label>
        <p class="descripcion-opcion">
          Otros usuarios podrán descargar el audio
        </p>
      </div>
      
      <div class="opcion">
        <label class="checkbox-label">
          <input type="checkbox" bind:checked={permitirRemezclas} />
          <span class="checkmark"></span>
          Permitir remezclas
        </label>
        <p class="descripcion-opcion">
          Otros usuarios podrán usar tu canción como base
        </p>
      </div>
      
      <div class="opcion">
        <label class="checkbox-label">
          <input type="checkbox" bind:checked={notificacionesActivadas} />
          <span class="checkmark"></span>
          Enviar notificaciones
        </label>
        <p class="descripcion-opcion">
          Notificar a seguidores sobre la nueva canción
        </p>
      </div>
    </div>
    
    <div class="campos-adicionales">
      <div class="campo">
        <label for="tags">Tags adicionales (separados por comas)</label>
        <input 
          id="tags"
          type="text"
          bind:value={tagsPersonalizados}
          placeholder="rock, instrumental, cover..."
          maxlength="200"
        />
      </div>
      
      <div class="campo">
        <label for="comentarios">Comentarios para la comunidad</label>
        <textarea 
          id="comentarios"
          bind:value={comentarios}
          placeholder="Comparte algo sobre tu canción..."
          rows="3"
          maxlength="500"
        ></textarea>
      </div>
    </div>
  </div>
  
  <!-- Progreso de publicación -->
  {#if publicando}
    <div class="progreso-publicacion">
      <h4>📤 Publicando Canción</h4>
      <div class="barra-progreso">
        <div class="progreso-fill" style="width: {progreso}%"></div>
      </div>
      <p class="texto-progreso">{progreso}% - {mensaje}</p>
    </div>
  {/if}
  
  <!-- Resultado de publicación -->
  {#if cancionPublicada}
    <div class="resultado-publicacion">
      <div class="icono-exito">🎉</div>
      <h4>¡Canción Publicada Exitosamente!</h4>
      <p>Tu canción "{contenido.titulo}" ya está disponible para la comunidad</p>
      
      <div class="acciones-post-publicacion">
        <button 
          class="btn-ver-cancion"
          on:click={() => goto(`/simulador-gaming/cancion/${idCancionPublicada}`)}
        >
          Ver Canción
        </button>
        
        <button 
          class="btn-compartir"
          on:click={() => navigator.clipboard.writeText(window.location.origin + `/simulador-gaming/cancion/${idCancionPublicada}`)}
        >
          Compartir
        </button>
      </div>
    </div>
  {/if}
  
  <!-- Mensaje de estado -->
  {#if mensaje && !publicando}
    <div class="mensaje-estado" class:error={tipoMensaje === 'error'} class:success={tipoMensaje === 'success'}>
      {mensaje}
    </div>
  {/if}
  
  <!-- Acciones -->
  <div class="acciones">
    <button 
      class="btn-regresar"
      on:click={() => dispatch('regresar')}
      disabled={publicando}
    >
      ← Regresar a Preview
    </button>
    
    <button 
      class="btn-publicar"
      on:click={publicarCancion}
      disabled={!validacionCompleta || publicando || cancionPublicada}
    >
      {publicando ? 'Publicando...' : '🚀 Publicar Canción'}
    </button>
  </div>
</div>

<style>
  .paso-publicar {
    padding: 1.5rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 15px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }
  
  .header-paso {
    text-align: center;
  }
  
  .header-paso h3 {
    font-size: 1.5rem;
    color: #4ecdc4;
    margin-bottom: 0.5rem;
  }
  
  .header-paso p {
    color: #b8b8d4;
  }
  
  .resumen-cancion {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
  }
  
  .resumen-cancion h4 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }
  
  .grid-resumen {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
  }
  
  .campo-resumen {
    display: flex;
    justify-content: space-between;
    margin-bottom: 0.5rem;
  }
  
  .etiqueta {
    color: #b8b8d4;
    font-weight: 500;
  }
  
  .valor {
    color: white;
    font-weight: bold;
  }
  
  .estadisticas-resumen {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
  }
  
  .stat-item {
    text-align: center;
    padding: 1rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 8px;
  }
  
  .stat-numero {
    display: block;
    font-size: 1.5rem;
    font-weight: bold;
    color: #4ecdc4;
  }
  
  .stat-label {
    font-size: 0.9rem;
    color: #b8b8d4;
  }
  
  .validacion-final {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
  }
  
  .validacion-final h4 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }
  
  .estado-validacion {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    border-radius: 8px;
    font-weight: bold;
  }
  
  .estado-validacion.valido {
    background: rgba(76, 175, 80, 0.2);
    border: 1px solid rgba(76, 175, 80, 0.5);
    color: #4caf50;
  }
  
  .estado-validacion.invalido {
    background: rgba(244, 67, 54, 0.2);
    border: 1px solid rgba(244, 67, 54, 0.5);
    color: #f44336;
  }
  
  .icono-validacion {
    font-size: 1.5rem;
  }
  
  .errores-validacion {
    margin-top: 1rem;
    padding: 1rem;
    background: rgba(244, 67, 54, 0.1);
    border-radius: 8px;
    border: 1px solid rgba(244, 67, 54, 0.3);
  }
  
  .errores-validacion h5 {
    color: #f44336;
    margin-bottom: 0.5rem;
  }
  
  .errores-validacion ul {
    color: #f44336;
    margin: 0;
    padding-left: 1.5rem;
  }
  
  .configuracion-publicacion {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
  }
  
  .configuracion-publicacion h4 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }
  
  .opciones-publicacion {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-bottom: 1.5rem;
  }
  
  .opcion {
    padding: 1rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 8px;
  }
  
  .checkbox-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
    font-weight: 500;
    color: white;
  }
  
  .checkbox-label input[type="checkbox"] {
    width: 18px;
    height: 18px;
    accent-color: #4ecdc4;
  }
  
  .descripcion-opcion {
    margin: 0.5rem 0 0 1.5rem;
    color: #b8b8d4;
    font-size: 0.9rem;
  }
  
  .campos-adicionales {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  
  .campo {
    display: flex;
    flex-direction: column;
  }
  
  .campo label {
    color: #b8b8d4;
    font-size: 0.9rem;
    margin-bottom: 0.5rem;
  }
  
  .campo input,
  .campo textarea {
    padding: 0.8rem;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 8px;
    color: white;
    outline: none;
    transition: border-color 0.3s ease;
  }
  
  .campo input:focus,
  .campo textarea:focus {
    border-color: #4ecdc4;
  }
  
  .campo textarea {
    resize: vertical;
    min-height: 80px;
  }
  
  .progreso-publicacion {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
    text-align: center;
  }
  
  .progreso-publicacion h4 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }
  
  .barra-progreso {
    width: 100%;
    height: 20px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 10px;
    overflow: hidden;
    margin-bottom: 1rem;
  }
  
  .progreso-fill {
    height: 100%;
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    transition: width 0.3s ease;
  }
  
  .texto-progreso {
    color: #b8b8d4;
    font-size: 0.9rem;
  }
  
  .resultado-publicacion {
    background: rgba(76, 175, 80, 0.1);
    border: 1px solid rgba(76, 175, 80, 0.3);
    border-radius: 10px;
    padding: 2rem;
    text-align: center;
  }
  
  .icono-exito {
    font-size: 3rem;
    margin-bottom: 1rem;
  }
  
  .resultado-publicacion h4 {
    color: #4caf50;
    margin-bottom: 0.5rem;
  }
  
  .resultado-publicacion p {
    color: #b8b8d4;
    margin-bottom: 1.5rem;
  }
  
  .acciones-post-publicacion {
    display: flex;
    gap: 1rem;
    justify-content: center;
  }
  
  .btn-ver-cancion,
  .btn-compartir {
    padding: 0.8rem 1.5rem;
    border: none;
    border-radius: 25px;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-ver-cancion {
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
  }
  
  .btn-compartir {
    background: linear-gradient(45deg, #667eea, #764ba2);
    color: white;
  }
  
  .mensaje-estado {
    padding: 1rem;
    border-radius: 8px;
    text-align: center;
  }
  
  .mensaje-estado.success {
    background: rgba(76, 175, 80, 0.1);
    border: 1px solid rgba(76, 175, 80, 0.3);
    color: #4caf50;
  }
  
  .mensaje-estado.error {
    background: rgba(244, 67, 54, 0.1);
    border: 1px solid rgba(244, 67, 54, 0.3);
    color: #f44336;
  }
  
  .acciones {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .btn-regresar {
    padding: 0.8rem 1.5rem;
    background: rgba(255, 255, 255, 0.1);
    color: white;
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 25px;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-publicar {
    padding: 1rem 2rem;
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
    border: none;
    border-radius: 25px;
    font-size: 1.1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-regresar:hover,
  .btn-publicar:hover:not(:disabled),
  .btn-ver-cancion:hover,
  .btn-compartir:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }
  
  .btn-publicar:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .grid-resumen {
      grid-template-columns: 1fr;
    }
    
    .estadisticas-resumen {
      grid-template-columns: repeat(2, 1fr);
    }
    
    .acciones {
      flex-direction: column;
      gap: 1rem;
    }
    
    .acciones-post-publicacion {
      flex-direction: column;
    }
  }
</style> 