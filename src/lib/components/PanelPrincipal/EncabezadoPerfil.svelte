<script lang="ts">
  import { supabase } from '$lib/supabase/clienteSupabase';

  // --- PROPS (Datos recibidos desde el padre) ---
  export let urlPortada: string | undefined = undefined;
  export let urlAvatar: string | undefined = undefined;
  export let nombreCompleto = 'Usuario';
  export let correoElectronico = 'correo@ejemplo.com';
  export let posicionPortadaY = 50;
  export let userId: string | null = null;
  export let stats = { publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 };

  // --- MANEJO DE ARCHIVOS ---
  let vistaPortadaTemporal: string | null = null;
  let vistaAvatarTemporal: string | null = null;
  let archivoTemporal: File | null = null;
  
  // --- ESTADO UI ---
  let subiendo = false;
  let mensaje = '';
  let tipoMensaje: 'portada' | 'avatar' | 'posicion' | null = null;
  let modoEdicion: 'portada' | 'avatar' | null = null;
  let reposicionandoPortada = false;

  function seleccionarArchivo(event: Event, tipo: 'portada' | 'avatar') {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    archivoTemporal = file;
    const reader = new FileReader();
    reader.onload = (e) => {
      if (tipo === 'portada') {
        vistaPortadaTemporal = e.target?.result as string;
      } else {
        vistaAvatarTemporal = e.target?.result as string;
      }
    };
    reader.readAsDataURL(file);
    modoEdicion = tipo;
  }

  async function guardarCambios() {
    if (!archivoTemporal || !userId || !modoEdicion) return;

    subiendo = true;
    mensaje = '';

    const bucket = modoEdicion === 'portada' ? 'fotoportada' : 'avatars';
    const extension = archivoTemporal.name.split('.').pop();
    const nombreArchivo = `${modoEdicion}-${userId}-${Date.now()}.${extension}`;

    const { error: errorSubida } = await supabase.storage.from(bucket).upload(nombreArchivo, archivoTemporal, { upsert: true });

    if (errorSubida) {
      mostrarMensaje('Error al subir: ' + errorSubida.message, modoEdicion);
      subiendo = false;
      return;
    }

    const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(nombreArchivo);
    const nuevaUrl = urlData.publicUrl + '?t=' + Date.now();

    const campoUpdate = modoEdicion === 'portada' ? { portada_url: nuevaUrl } : { url_foto_perfil: nuevaUrl };
    await supabase.from('perfiles').update(campoUpdate).eq('id', userId);

    if (modoEdicion === 'portada') {
      urlPortada = nuevaUrl;
      vistaPortadaTemporal = null;
    } else {
      urlAvatar = nuevaUrl;
      vistaAvatarTemporal = null;
    }

    mostrarMensaje('¡Actualizado exitosamente!', modoEdicion);
    limpiarSeleccion();
  }

  function limpiarSeleccion() {
    subiendo = false;
    archivoTemporal = null;
    vistaAvatarTemporal = null;
    vistaPortadaTemporal = null;
    modoEdicion = null;
  }
  
  function manejarDragPortada(event: MouseEvent | TouchEvent) {
    if (!reposicionandoPortada) return;
    event.preventDefault();
    
    const targetElement = (event.currentTarget as HTMLElement);
    const clientY = event instanceof MouseEvent ? event.clientY : event.touches[0].clientY;
    const rect = targetElement.getBoundingClientRect();
    const y = clientY - rect.top;
    
    posicionPortadaY = Math.max(0, Math.min(100, (y / rect.height) * 100));
  }

  async function guardarPosicionPortada() {
    if (!userId) return;
    
    await supabase.from('perfiles').update({ posicion_img_portada: String(posicionPortadaY) }).eq('id', userId);
    
    reposicionandoPortada = false;
    mostrarMensaje('¡Posición guardada!', 'posicion');
  }

  function mostrarMensaje(texto: string, tipo: 'portada' | 'avatar' | 'posicion') {
    mensaje = texto;
    tipoMensaje = tipo;
    setTimeout(() => {
      mensaje = '';
      tipoMensaje = null;
    }, 3000);
  }
</script>

<!-- Contenedor Principal -->
<div class="contenedor-portada" on:mousemove={manejarDragPortada} on:touchmove={manejarDragPortada}>
  <img
    src={vistaPortadaTemporal || urlPortada || 'https://i.ytimg.com/vi/lg9metXr5XQ/hq720.jpg'}
    alt="Portada de perfil"
    class="imagen-portada"
    class:reposicionando={reposicionandoPortada}
    style="object-position: 50% {posicionPortadaY}%"
  />
  
  <!-- Controles -->
  <div class="controles-portada">
    {#if modoEdicion === 'portada'}
      <button class="boton-control" on:click={guardarCambios} disabled={subiendo}>{subiendo ? 'Guardando...' : 'Guardar'}</button>
      <button class="boton-control secundario" on:click={limpiarSeleccion} disabled={subiendo}>Cancelar</button>
    {:else if reposicionandoPortada}
      <button class="boton-control" on:click={guardarPosicionPortada}>Guardar Posición</button>
      <button class="boton-control secundario" on:click={() => reposicionandoPortada = false}>Cancelar</button>
    {:else if !modoEdicion}
      <label class="boton-control">
        Cambiar Portada <input type="file" class="input-oculto" on:change={(e) => seleccionarArchivo(e, 'portada')} />
      </label>
      <button class="boton-control secundario" on:click={() => reposicionandoPortada = true}>Reposicionar</button>
    {/if}
  </div>

  <!-- Avatar -->
  <div class="contenedor-avatar">
    <div class="avatar-interactivo">
      <img src={vistaAvatarTemporal || urlAvatar || 'https://randomuser.me/api/portraits/women/44.jpg'} alt="Avatar" class="imagen-avatar" />
      {#if !modoEdicion}
        <label class="overlay-avatar">
          Cambiar Foto <input type="file" class="input-oculto" on:change={(e) => seleccionarArchivo(e, 'avatar')} />
        </label>
      {/if}
    </div>
    
    {#if modoEdicion === 'avatar'}
      <div class="controles-avatar">
        <button class="boton-guardar-avatar" on:click={guardarCambios} disabled={subiendo}>{subiendo ? 'Guardando...' : 'Guardar'}</button>
        <button class="boton-cancelar-avatar" on:click={limpiarSeleccion} disabled={subiendo}>Cancelar</button>
      </div>
    {/if}
  </div>

  <!-- Mensajes de estado -->
  {#if mensaje}
    <div class="mensaje-flotante" class:avatar={tipoMensaje === 'avatar'}>{mensaje}</div>
  {/if}
</div>

<!-- Info Usuario -->
<div class="info-usuario">
  <div class="seccion-estadisticas">
    <div class="estadistica">
      <div class="icono-estadistica publicacion">📝</div>
      <div class="valor">{stats.publicaciones}</div>
      <div class="etiqueta">Publicaciones</div>
    </div>
    <div class="estadistica">
      <div class="icono-estadistica curso">📚</div>
      <div class="valor">{stats.cursos}</div>
      <div class="etiqueta">Cursos</div>
    </div>
    <div class="estadistica">
      <div class="icono-estadistica tutorial">🎓</div>
      <div class="valor">{stats.tutoriales}</div>
      <div class="etiqueta">Tutoriales</div>
    </div>
    <div class="estadistica">
      <div class="icono-estadistica ranking">🏆</div>
      <div class="valor">#{stats.ranking || '--'}</div>
      <div class="etiqueta">Ranking</div>
    </div>
  </div>
  
  <div class="separador-vertical"></div>
  
  <div class="seccion-central">
    <div class="nombre-usuario">{nombreCompleto}</div>
    <div class="correo-usuario">{correoElectronico}</div>
    <div class="estrellas">
      {'★'.repeat(4)}{'☆'.repeat(1)}
    </div>
  </div>
  
  <div class="seccion-accion">
    <div class="saludo-accion">¡Sigue así, {nombreCompleto ? nombreCompleto.split(' ')[0] : 'crack'}!</div>
    <button class="boton-accion-principal" on:click={() => window.location.href = '/mis-cursos'}>
      🎹 Ir a mi aprendizaje
    </button>
  </div>
</div>

<style>
  :root {
    --color-primario: #2563eb;
    --color-secundario: #f59e0b;
    --color-exito: #22c55e;
    --texto-blanco: white;
    --fondo-blanco: white;
    --gris-claro: #f3f4f6;
    --gris-medio: #9ca3af;
    --gris-oscuro: #1f2937;
    --borde-radius: 16px;
  }

  /* === CONTENEDOR PRINCIPAL === */
  .contenedor-portada {
    position: relative;
    width: 100%;
    height: 300px;
    overflow: visible;
    border-radius: var(--borde-radius) var(--borde-radius) 0 0;
    z-index: 1;
  }

  .imagen-portada {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: object-position 0.3s ease;
    z-index: 2;
    position: relative;
  }
  .imagen-portada.reposicionando { cursor: grabbing; }

  /* === CONTROLES === */
  .controles-portada {
    position: absolute;
    top: 16px;
    right: 16px;
    display: flex;
    gap: 12px;
    z-index: 10;
  }

  .boton-control {
    background: rgba(0, 0, 0, 0.7);
    color: var(--texto-blanco);
    padding: 10px 18px;
    border-radius: 8px;
    border: none;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    backdrop-filter: blur(10px);
    font-size: 0.9rem;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  }
  .boton-control:hover:not(:disabled) {
    background: rgba(0, 0, 0, 0.85);
    transform: translateY(-2px);
  }
  .boton-control.secundario { background: rgba(245, 158, 107, 0.8); }
  .boton-control.secundario:hover:not(:disabled) { background: rgba(245, 158, 107, 1); }
  .boton-control:disabled { background: var(--gris-medio); cursor: not-allowed; }

  /* === AVATAR === */
  .contenedor-avatar {
    position: absolute;
    left: 50%;
    bottom: -80px;
    transform: translateX(-50%);
    z-index: 15;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .avatar-interactivo {
    position: relative;
    width: 160px;
    height: 160px;
  }

  .imagen-avatar {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    border: 6px solid var(--fondo-blanco);
    object-fit: cover;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
    transition: all 0.3s ease;
  }
  .avatar-interactivo:hover .imagen-avatar { box-shadow: 0 12px 40px rgba(37, 99, 235, 0.2); }

  .overlay-avatar {
    position: absolute;
    inset: 0;
    background: rgba(37, 99, 235, 0.8);
    color: var(--texto-blanco);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    opacity: 0;
    cursor: pointer;
    transition: opacity 0.3s ease;
  }
  .avatar-interactivo:hover .overlay-avatar { opacity: 1; }

  .controles-avatar {
    display: flex;
    gap: 8px;
    margin-top: 12px;
  }

  .boton-guardar-avatar, .boton-cancelar-avatar {
    color: var(--texto-blanco);
    padding: 8px 16px;
    border-radius: 6px;
    border: none;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }
  .boton-guardar-avatar { background: var(--color-exito); }
  .boton-guardar-avatar:hover:not(:disabled) { background: #16a34a; }
  .boton-cancelar-avatar { background: var(--gris-medio); }
  .boton-cancelar-avatar:hover:not(:disabled) { background: #6b7280; }
  .boton-guardar-avatar:disabled, .boton-cancelar-avatar:disabled {
    background: var(--gris-claro);
    cursor: not-allowed;
  }

  /* === INFO USUARIO === */
  .info-usuario {
    background: var(--fondo-blanco);
    margin-top: 70px;
    padding: 8px 32px;
    border-radius: 0 0 var(--borde-radius) var(--borde-radius);
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 20px;
    position: relative;
    z-index: 1;
  }

  /* --- Secciones Info --- */
  .seccion-estadisticas {
    display: flex;
    align-items: center;
    gap: 16px;
    flex: 1.5;
  }

  .estadistica {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    flex: 1;
  }

  .icono-estadistica { font-size: 2.2rem; line-height: 1; }
  .icono-estadistica.publicacion { color: #3b82f6; }
  .icono-estadistica.curso { color: #10b981; }
  .icono-estadistica.tutorial { color: #8b5cf6; }
  .icono-estadistica.ranking { color: var(--color-secundario); }

  .valor { font-size: 1.2rem; font-weight: 700; color: var(--gris-oscuro); }
  .etiqueta { font-size: 0.65rem; color: #6b7280; font-weight: 600; text-transform: uppercase; }

  .separador-vertical { width: 1px; background-color: var(--gris-claro); align-self: stretch; }
  
  .seccion-central {
    text-align: center;
    flex: 1;
  }

  .nombre-usuario { font-size: 1.5rem; font-weight: 700; color: var(--gris-oscuro); }
  .correo-usuario { color: var(--color-primario); font-weight: 500; font-size: 0.9rem; margin-block: 2px 8px; }
  .estrellas { font-size: 1.2rem; color: var(--color-secundario); }

  .seccion-accion {
    flex: 1.2;
    text-align: center;
  }

  .saludo-accion { font-size: 1.1rem; font-weight: 700; color: var(--gris-oscuro); margin-bottom: 8px;}

  .boton-accion-principal {
    background: linear-gradient(135deg, var(--color-primario), #1d4ed8);
    color: var(--texto-blanco);
    padding: 12px 20px;
    border-radius: 8px;
    border: none;
    font-weight: 700;
    cursor: pointer;
    transition: all 0.2s ease;
    font-size: 0.9rem;
    width: 100%;
    box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
  }
  .boton-accion-principal:hover { transform: translateY(-2px); box-shadow: 0 6px 16px rgba(37, 99, 235, 0.3); }

  /* === MENSAJES === */
  .mensaje-flotante {
    position: absolute;
    top: 20px;
    right: 20px;
    background: var(--color-exito);
    color: var(--texto-blanco);
    padding: 12px 20px;
    border-radius: 8px;
    font-weight: 600;
    z-index: 30;
    animation: fadeInOut 3s ease-in-out forwards;
  }
  .mensaje-flotante.avatar {
    top: auto;
    bottom: -90px;
    right: auto;
    left: 50%;
    transform: translateX(-50%);
  }

  .input-oculto { display: none; }

  @keyframes fadeInOut {
    0%, 100% { opacity: 0; transform: translateY(-10px); }
    10%, 90% { opacity: 1; transform: translateY(0); }
  }

  /* === RESPONSIVE === */
  @media (max-width: 900px) {
    .contenedor-portada {
      height: 190px;
    }
    .info-usuario { flex-direction: column; align-items: center; gap: 24px; }
    .seccion-estadisticas, .seccion-central, .seccion-accion { width: 100%; flex: none; }
    .seccion-estadisticas { justify-content: space-around; }
    .separador-vertical { display: none; }
  }

  @media (max-width: 480px) {
    .seccion-estadisticas {
      display: flex;
      justify-content: space-around;
      width: 100%;
      gap: 8px;
    }
    .estadistica .icono-estadistica {
      font-size: 1.9rem;
    }
    .estadistica .valor {
      font-size: 1.1rem;
    }
    .estadistica .etiqueta {
      font-size: 0.6rem;
    }

    .info-usuario { padding: 10px; }

    .controles-portada {
      gap: 2px;
    }
    .boton-control {
      padding: 5px 8px;
      font-size: 0.8rem;
    }
  }
</style>
