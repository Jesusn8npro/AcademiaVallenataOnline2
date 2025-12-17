<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { browser } from '$app/environment';
  import { editorActions } from '../../stores/editorStore';
  import { EditorService } from '../../services/EditorService';
  import StorageService from '$lib/services/storageService';
  
  export let contenido: any = {};
  
  const dispatch = createEventDispatcher<{
    avanzar: any;
    actualizar: any;
  }>();
  
  let archivoAudio: File | null = null;
  let arrastrando = false;
  let procesando = false;
  let mensaje = '';
  let tipoMensaje = 'info';
  let reproductor: HTMLAudioElement | null = null;
  let reproduciendo = false;
  let tiempoActual = 0;
  let duracionTotal = 0;
  let volumen = 0.8;
  
  // Metadatos de la canción
  let titulo = contenido.titulo || '';
  let artista = contenido.artista || '';
  let genero = contenido.genero || 'vallenato';
  let descripcion = contenido.descripcion || '';
  let nivel_dificultad = contenido.nivel_dificultad || 1;
  let bpm = contenido.bpm || 120;
  let afinacion = contenido.afinacion || 'FBE';
  

  
  const manejarArrastrar = (e: DragEvent) => {
    e.preventDefault();
    arrastrando = true;
  };
  
  const manejarSalirArrastrar = (e: DragEvent) => {
    e.preventDefault();
    arrastrando = false;
  };
  
  const manejarSoltar = (e: DragEvent) => {
    e.preventDefault();
    arrastrando = false;
    
    const archivos = e.dataTransfer?.files;
    if (archivos && archivos.length > 0) {
      procesarArchivoAudio(archivos[0]);
    }
  };
  
  const manejarSeleccionArchivo = (e: Event) => {
    const input = e.target as HTMLInputElement;
    const archivo = input.files?.[0];
    if (archivo) {
      procesarArchivoAudio(archivo);
    }
  };
  
  const procesarArchivoAudio = async (archivo: File) => {
    // Usar la misma validación que el Editor Max original
    const validacion = StorageService.validarArchivo(archivo);
    if (!validacion.valido) {
      mensaje = `❌ ${validacion.error}`;
      tipoMensaje = 'error';
      return;
    }
    
    try {
      procesando = true;
      mensaje = 'Procesando archivo de audio...';
      tipoMensaje = 'info';
      
      archivoAudio = archivo;
      
      // Procesar metadata del audio
      const editorService = new EditorService();
      const metadata = await editorService.procesarAudio(archivo);
      
      duracionTotal = metadata.duracion;
      
      // Autocompletar algunos campos si están vacíos
      if (!titulo) {
        titulo = archivo.name.replace(/\.[^/.]+$/, '');
      }
      
      // Crear reproductor
      if (reproductor) {
        reproductor.pause();
        reproductor.removeEventListener('timeupdate', actualizarTiempo);
        reproductor.removeEventListener('ended', finalizarReproduccion);
      }
      
      reproductor = new Audio();
      reproductor.src = URL.createObjectURL(archivo);
      reproductor.volume = volumen;
      reproductor.addEventListener('timeupdate', actualizarTiempo);
      reproductor.addEventListener('ended', finalizarReproduccion);
      reproductor.addEventListener('loadedmetadata', () => {
        duracionTotal = reproductor?.duration || 0;
      });
      
      // Actualizar contenido
      const contenidoActualizado = {
        ...contenido,
        audio: archivo,
        titulo,
        artista,
        genero,
        descripcion,
        nivel_dificultad,
        bpm,
        afinacion,
        duracion_segundos: duracionTotal,
        url_audio: '',
        metadata: metadata
      };
      
      dispatch('actualizar', contenidoActualizado);
      
      mensaje = '✅ Archivo cargado exitosamente';
      tipoMensaje = 'success';
      
    } catch (error) {
      console.error('Error procesando archivo:', error);
      mensaje = `❌ ${error instanceof Error ? error.message : 'Error desconocido'}`;
      tipoMensaje = 'error';
      archivoAudio = null;
    } finally {
      procesando = false;
    }
  };
  

  
  const toggleReproduccion = () => {
    if (!reproductor) return;
    
    if (reproduciendo) {
      reproductor.pause();
      reproduciendo = false;
    } else {
      reproductor.play();
      reproduciendo = true;
    }
  };
  
  const actualizarTiempo = () => {
    if (reproductor) {
      tiempoActual = reproductor.currentTime;
    }
  };
  
  const finalizarReproduccion = () => {
    reproduciendo = false;
    tiempoActual = 0;
  };
  
  const cambiarTiempo = (e: Event) => {
    const input = e.target as HTMLInputElement;
    const nuevoTiempo = parseFloat(input.value);
    if (reproductor) {
      reproductor.currentTime = nuevoTiempo;
      tiempoActual = nuevoTiempo;
    }
  };
  
  const cambiarVolumen = (e: Event) => {
    const input = e.target as HTMLInputElement;
    volumen = parseFloat(input.value);
    if (reproductor) {
      reproductor.volume = volumen;
    }
  };
  
  const actualizarMetadatos = () => {
    const contenidoActualizado = {
      ...contenido,
      titulo,
      artista,
      genero,
      descripcion,
      nivel_dificultad,
      bpm,
      afinacion
    };
    
    dispatch('actualizar', contenidoActualizado);
  };
  
  const validarYAvanzar = () => {
    if (!archivoAudio) {
      mensaje = 'Debe seleccionar un archivo de audio';
      tipoMensaje = 'error';
      return;
    }
    
    if (!titulo.trim()) {
      mensaje = 'El título es obligatorio';
      tipoMensaje = 'error';
      return;
    }
    
    if (!artista.trim()) {
      mensaje = 'El artista es obligatorio';
      tipoMensaje = 'error';
      return;
    }
    
    actualizarMetadatos();
    dispatch('avanzar', { 
      audio: archivoAudio,
      titulo,
      artista,
      genero,
      descripcion,
      nivel_dificultad,
      bpm,
      afinacion,
      duracion_segundos: duracionTotal
    });
  };
  
  const formatearTiempo = (segundos: number): string => {
    const minutos = Math.floor(segundos / 60);
    const segs = Math.floor(segundos % 60);
    return `${minutos}:${segs.toString().padStart(2, '0')}`;
  };
  
  $: {
    if (titulo || artista || genero || descripcion || nivel_dificultad || bpm || afinacion) {
      actualizarMetadatos();
    }
  }
</script>

<div class="paso-subir-audio">
  <div class="header-paso">
    <h3>🎵 Paso 1: Subir Audio</h3>
    <p>Sube el archivo de audio de tu canción para comenzar la creación</p>
  </div>
  
  <!-- Zona de subida de archivos -->
  <div class="zona-subida">
    <div 
      class="drop-zone"
      class:arrastrando
      class:con-archivo={archivoAudio}
      on:dragover={manejarArrastrar}
      on:dragleave={manejarSalirArrastrar}
      on:drop={manejarSoltar}
    >
      {#if archivoAudio}
        <div class="archivo-cargado">
          <div class="icono-archivo">🎵</div>
          <div class="info-archivo">
            <h4>{archivoAudio.name}</h4>
            <p>{(archivoAudio.size / 1024 / 1024).toFixed(2)}MB • {formatearTiempo(duracionTotal)}</p>
          </div>
          <button 
            class="btn-cambiar"
            on:click={() => document.getElementById('inputAudio')?.click()}
          >
            Cambiar
          </button>
        </div>
      {:else}
        <div class="contenido-drop">
          <div class="icono-subida">📤</div>
          <h4>Arrastra tu archivo de audio aquí</h4>
          <p>o haz clic para seleccionar</p>
          <button 
            class="btn-seleccionar"
            on:click={() => document.getElementById('inputAudio')?.click()}
            disabled={procesando}
          >
            {procesando ? 'Procesando...' : 'Seleccionar Archivo'}
          </button>
        </div>
      {/if}
    </div>
    
    <input 
      id="inputAudio"
      type="file"
      accept="audio/mp3,audio/mpeg,audio/wav,audio/ogg"
      on:change={manejarSeleccionArchivo}
      style="display: none"
    >
    
    <div class="formatos-aceptados">
      <p>Formatos soportados: MP3, WAV, OGG (máx. 50MB)</p>
    </div>
  </div>
  
  <!-- Reproductor de audio -->
  {#if archivoAudio}
    <div class="reproductor-audio">
      <div class="controles-reproduccion">
        <button 
          class="btn-play"
          on:click={toggleReproduccion}
          disabled={!reproductor}
        >
          {reproduciendo ? '⏸️' : '▶️'}
        </button>
        
        <div class="timeline">
          <input 
            type="range"
            min="0"
            max={duracionTotal}
            value={tiempoActual}
            on:input={cambiarTiempo}
            class="slider-tiempo"
          />
          <div class="tiempo-info">
            <span>{formatearTiempo(tiempoActual)}</span>
            <span>{formatearTiempo(duracionTotal)}</span>
          </div>
        </div>
        
        <div class="control-volumen">
          <span>🔊</span>
          <input 
            type="range"
            min="0"
            max="1"
            step="0.1"
            value={volumen}
            on:input={cambiarVolumen}
            class="slider-volumen"
          />
        </div>
      </div>
    </div>
  {/if}
  
  <!-- Metadatos de la canción -->
  <div class="metadatos-cancion">
    <h4>📝 Información de la Canción</h4>
    
    <div class="grid-metadatos">
      <div class="campo">
        <label for="titulo">Título *</label>
        <input 
          id="titulo"
          type="text"
          bind:value={titulo}
          placeholder="Nombre de la canción"
          required
        />
      </div>
      
      <div class="campo">
        <label for="artista">Artista *</label>
        <input 
          id="artista"
          type="text"
          bind:value={artista}
          placeholder="Nombre del artista"
          required
        />
      </div>
      
      <div class="campo">
        <label for="genero">Género</label>
        <select id="genero" bind:value={genero}>
          <option value="vallenato">Vallenato</option>
          <option value="cumbia">Cumbia</option>
          <option value="merengue">Merengue</option>
          <option value="paseo">Paseo</option>
          <option value="son">Son</option>
          <option value="otro">Otro</option>
        </select>
      </div>
      
      <div class="campo">
        <label for="dificultad">Dificultad</label>
        <select id="dificultad" bind:value={nivel_dificultad}>
          <option value={1}>Principiante</option>
          <option value={2}>Intermedio</option>
          <option value={3}>Avanzado</option>
          <option value={4}>Experto</option>
        </select>
      </div>
      
      <div class="campo">
        <label for="bpm">BPM</label>
        <input 
          id="bpm"
          type="number"
          bind:value={bpm}
          min="60"
          max="200"
          placeholder="120"
        />
      </div>
      
      <div class="campo">
        <label for="afinacion">Afinación</label>
        <select id="afinacion" bind:value={afinacion}>
          <option value="FBE">FBE (Fa-Si-Mi)</option>
          <option value="GCF">GCF (Sol-Do-Fa)</option>
          <option value="ADG">ADG (La-Re-Sol)</option>
        </select>
      </div>
    </div>
    
    <div class="campo campo-completo">
      <label for="descripcion">Descripción</label>
      <textarea 
        id="descripcion"
        bind:value={descripcion}
        placeholder="Descripción opcional de la canción"
        rows="3"
      ></textarea>
    </div>
  </div>
  
  <!-- Mensaje de estado -->
  {#if mensaje}
    <div class="mensaje-estado" class:error={tipoMensaje === 'error'} class:success={tipoMensaje === 'success'}>
      {mensaje}
    </div>
  {/if}
  
  <!-- Acciones -->
  <div class="acciones">
    <button 
      class="btn-avanzar"
      on:click={validarYAvanzar}
      disabled={!archivoAudio || procesando}
    >
      Continuar a Grabación →
    </button>
  </div>
</div>

<style>
  .paso-subir-audio {
    padding: 1.5rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 15px;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }
  
  .header-paso {
    text-align: center;
    margin-bottom: 2rem;
  }
  
  .header-paso h3 {
    font-size: 1.5rem;
    color: #4ecdc4;
    margin-bottom: 0.5rem;
  }
  
  .header-paso p {
    color: #b8b8d4;
  }
  
  .zona-subida {
    margin-bottom: 2rem;
  }
  
  .drop-zone {
    border: 2px dashed rgba(255, 255, 255, 0.3);
    border-radius: 15px;
    padding: 3rem;
    text-align: center;
    background: rgba(255, 255, 255, 0.02);
    transition: all 0.3s ease;
    cursor: pointer;
  }
  
  .drop-zone.arrastrando {
    border-color: #4ecdc4;
    background: rgba(78, 205, 196, 0.1);
  }
  
  .drop-zone.con-archivo {
    border-color: #4ecdc4;
    background: rgba(78, 205, 196, 0.05);
  }
  
  .contenido-drop {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
  }
  
  .icono-subida {
    font-size: 3rem;
    opacity: 0.7;
  }
  
  .archivo-cargado {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
  }
  
  .icono-archivo {
    font-size: 2rem;
  }
  
  .info-archivo {
    flex-grow: 1;
    text-align: left;
  }
  
  .info-archivo h4 {
    margin: 0 0 0.5rem 0;
    color: white;
  }
  
  .info-archivo p {
    margin: 0;
    color: #b8b8d4;
    font-size: 0.9rem;
  }
  
  .btn-seleccionar,
  .btn-cambiar {
    padding: 0.8rem 1.5rem;
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-weight: 500;
    transition: all 0.3s ease;
  }
  
  .btn-seleccionar:hover,
  .btn-cambiar:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(78, 205, 196, 0.4);
  }
  
  .btn-seleccionar:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
  
  .formatos-aceptados {
    text-align: center;
    margin-top: 1rem;
  }
  
  .formatos-aceptados p {
    color: #b8b8d4;
    font-size: 0.9rem;
  }
  
  .reproductor-audio {
    margin-bottom: 2rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1.5rem;
  }
  
  .controles-reproduccion {
    display: flex;
    align-items: center;
    gap: 1rem;
  }
  
  .btn-play {
    width: 50px;
    height: 50px;
    border: none;
    border-radius: 50%;
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    color: white;
    font-size: 1.2rem;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .btn-play:hover {
    transform: scale(1.1);
  }
  
  .timeline {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .slider-tiempo {
    width: 100%;
    height: 6px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 3px;
    outline: none;
    appearance: none;
  }
  
  .slider-tiempo::-webkit-slider-thumb {
    appearance: none;
    width: 16px;
    height: 16px;
    background: #4ecdc4;
    border-radius: 50%;
    cursor: pointer;
  }
  
  .tiempo-info {
    display: flex;
    justify-content: space-between;
    font-size: 0.9rem;
    color: #b8b8d4;
  }
  
  .control-volumen {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  
  .slider-volumen {
    width: 80px;
    height: 4px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 2px;
    outline: none;
    appearance: none;
  }
  
  .slider-volumen::-webkit-slider-thumb {
    appearance: none;
    width: 12px;
    height: 12px;
    background: #4ecdc4;
    border-radius: 50%;
    cursor: pointer;
  }
  
  .metadatos-cancion {
    margin-bottom: 2rem;
  }
  
  .metadatos-cancion h4 {
    color: #4ecdc4;
    margin-bottom: 1rem;
  }
  
  .grid-metadatos {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1rem;
    margin-bottom: 1rem;
  }
  
  .campo {
    display: flex;
    flex-direction: column;
  }
  
  .campo-completo {
    grid-column: 1 / -1;
  }
  
  .campo label {
    color: #b8b8d4;
    font-size: 0.9rem;
    margin-bottom: 0.5rem;
  }
  
  .campo input,
  .campo select,
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
  .campo select:focus,
  .campo textarea:focus {
    border-color: #4ecdc4;
  }
  
  .campo textarea {
    resize: vertical;
    min-height: 80px;
  }
  
  .mensaje-estado {
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1rem;
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
    justify-content: flex-end;
  }
  
  .btn-avanzar {
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
  
  .btn-avanzar:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(78, 205, 196, 0.4);
  }
  
  .btn-avanzar:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .grid-metadatos {
      grid-template-columns: 1fr;
    }
    
    .controles-reproduccion {
      flex-direction: column;
      align-items: stretch;
    }
    
    .control-volumen {
      justify-content: center;
    }
  }
</style> 