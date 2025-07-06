<script lang="ts">
  import { onDestroy } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import ModalVisorImagenPerfil from './ModalVisorImagenPerfil.svelte';
  import { crearPublicacionAutomaticaSegura } from '$lib/services/publicacionesAutoService';

  // --- PROPS (Datos recibidos desde el padre) ---
  export let urlPortada: string | undefined = undefined;
  export let urlAvatar: string | undefined = undefined;
  export let nombreCompleto = 'Usuario';
  export let correoElectronico = 'correo@ejemplo.com';
  export let posicionPortadaY = 50;
  export let userId: string | null = null;
  export let stats = { publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 };
  export let esEditable = true; // 🆕 Nuevo prop para modo lectura

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
  let mostrarMenuPortada = false;
  let mostrarMenuAvatar = false;
  let refMenuPortada: HTMLElement | null = null;
  let refMenuAvatar: HTMLElement | null = null;
  let refInputPortada: HTMLInputElement | null = null;
  let refInputAvatar: HTMLInputElement | null = null;

  // --- ESTADO MODAL ESTILO FACEBOOK ---
  let modalAbierto = false;
  let imagenModalUrl = '';
  let imagenModalId: string | null = null;
  let tipoImagenModal: 'avatar' | 'portada' | null = null;

  // --- MANEJO DE EVENTOS GLOBALES PARA REPOSICIONAR PORTADA ---
  function finalizarReposicion() {
    if (reposicionandoPortada) {
      guardarPosicionPortada();
    }
  }

  $: if (reposicionandoPortada) {
    window.addEventListener('mouseup', finalizarReposicion);
    window.addEventListener('touchend', finalizarReposicion);
  } else {
    window.removeEventListener('mouseup', finalizarReposicion);
    window.removeEventListener('touchend', finalizarReposicion);
  }

  function seleccionarArchivo(event: any, tipo: 'portada' | 'avatar') {
    const archivo = event.target.files[0];
    if (!archivo) return;
    archivoTemporal = archivo;
    modoEdicion = tipo;
    const reader = new FileReader();
    reader.onload = (e) => {
      if (tipo === 'portada') {
        vistaPortadaTemporal = e.target?.result as string;
      } else {
        vistaAvatarTemporal = e.target?.result as string;
      }
    };
    reader.readAsDataURL(archivo);
  }

  async function guardarCambios() {
    if (!archivoTemporal || !userId || !modoEdicion) return;
    subiendo = true;
    mensaje = '';
    const bucket = modoEdicion === 'portada' ? 'fotoportada' : 'avatars';
    const extension = archivoTemporal.name.split('.').pop();
    const nombreArchivo = `${modoEdicion}-${userId}-${Date.now()}.${extension}`;
    
    try {
      // Subir archivo
      const { error: errorSubida } = await supabase.storage.from(bucket).upload(nombreArchivo, archivoTemporal, { upsert: true });
      if (errorSubida) {
        mostrarMensaje('Error al subir: ' + errorSubida.message, modoEdicion);
        subiendo = false;
        return;
      }
      
      const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(nombreArchivo);
      const nuevaUrl = urlData.publicUrl + '?t=' + Date.now();
      
      // Actualizar perfil
      const campoUpdate = modoEdicion === 'portada' ? { portada_url: nuevaUrl } : { url_foto_perfil: nuevaUrl };
      await supabase.from('perfiles').update(campoUpdate).eq('id', userId);
      
      // Guardar en tabla usuario_imagenes para el sistema de likes/comentarios
      const { data: imagenData, error: errorImagen } = await supabase
        .from('usuario_imagenes')
        .insert({
          usuario_id: userId,
          url_imagen: nuevaUrl,
          tipo: modoEdicion,
          fecha_subida: new Date().toISOString(),
          es_actual: true
        })
        .select()
        .single();

      if (errorImagen) {
        console.error('Error guardando imagen en usuario_imagenes:', errorImagen);
      }

      // Marcar otras imágenes del mismo tipo como no actuales
      if (imagenData) {
        await supabase
          .from('usuario_imagenes')
          .update({ es_actual: false })
          .eq('usuario_id', userId)
          .eq('tipo', modoEdicion)
          .neq('id', imagenData.id);
      }
      
      // Actualizar UI
      if (modoEdicion === 'portada') {
        urlPortada = nuevaUrl;
        vistaPortadaTemporal = null;
      } else {
        urlAvatar = nuevaUrl;
        vistaAvatarTemporal = null;
      }
      
      // 🎯 CREAR PUBLICACIÓN AUTOMÁTICA ESTILO FACEBOOK
      try {
        // Determinar el avatar correcto del usuario
        const avatarUsuario = modoEdicion === 'avatar' ? nuevaUrl : urlAvatar;
        
        await crearPublicacionAutomaticaSegura({
          usuario_id: userId,
          tipo: modoEdicion === 'portada' ? 'foto_portada' : 'foto_perfil',
          url_imagen: nuevaUrl, // La imagen de la publicación (nueva foto subida)
          usuario_nombre: nombreCompleto,
          usuario_avatar: avatarUsuario // Avatar actual del usuario (corregido)
        });
        
        console.log('✅ Publicación automática creada:', {
          tipo: modoEdicion,
          url_imagen: nuevaUrl,
          usuario_avatar: avatarUsuario,
          usuario_nombre: nombreCompleto
        });
      } catch (error) {
        console.error('⚠️ Error creando publicación automática (no crítico):', error);
        // No mostramos error al usuario porque la imagen se guardó correctamente
      }
      
      mostrarMensaje('¡Actualizado exitosamente!', modoEdicion);
      limpiarSeleccion();
    } catch (error) {
      console.error('Error completo:', error);
      mostrarMensaje('Error inesperado', modoEdicion);
      subiendo = false;
    }
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

  function abrirMenuPortada(e: any) {
    e.stopPropagation();
    mostrarMenuPortada = true;
  }
  function abrirMenuAvatar(e: any) {
    e.stopPropagation();
    mostrarMenuAvatar = true;
  }
  function cerrarMenus() {
    mostrarMenuPortada = false;
    mostrarMenuAvatar = false;
  }

  function clickFueraMenuPortada(e: Event) {
    if (refMenuPortada && !refMenuPortada.contains(e.target as Node) && 
        !(e.target as Element).closest('.icono-camara-portada')) {
      mostrarMenuPortada = false;
    }
  }
  function clickFueraMenuAvatar(e: any) {
    if (refMenuAvatar && !refMenuAvatar.contains(e.target)) {
      mostrarMenuAvatar = false;
    }
  }

  $: if (mostrarMenuPortada) {
    window.addEventListener('mousedown', clickFueraMenuPortada);
    window.addEventListener('touchstart', clickFueraMenuPortada);
  } else {
    window.removeEventListener('mousedown', clickFueraMenuPortada);
    window.removeEventListener('touchstart', clickFueraMenuPortada);
  }
  $: if (mostrarMenuAvatar) {
    window.addEventListener('mousedown', clickFueraMenuAvatar);
  } else {
    window.removeEventListener('mousedown', clickFueraMenuAvatar);
  }

  // --- FUNCIONES PARA MODAL ESTILO FACEBOOK ---
  async function abrirModalImagen(tipo: 'avatar' | 'portada') {
    if (!userId) return;
    
    try {
      // Buscar la imagen actual en la base de datos
      const { data: imagenData, error } = await supabase
        .from('usuario_imagenes')
        .select('*')
        .eq('usuario_id', userId)
        .eq('tipo', tipo)
        .eq('es_actual', true)
        .single();

      if (error || !imagenData) {
        // Si no hay registro en BD, crear uno con la URL actual
        const urlImagen = tipo === 'avatar' ? urlAvatar : urlPortada;
        if (!urlImagen) return;

        const { data: nuevaImagen, error: errorCrear } = await supabase
          .from('usuario_imagenes')
          .insert({
            usuario_id: userId,
            url_imagen: urlImagen,
            tipo: tipo,
            fecha_subida: new Date().toISOString(),
            es_actual: true
          })
          .select()
          .single();

        if (errorCrear) {
          console.error('Error creando registro de imagen:', errorCrear);
          return;
        }

        imagenModalId = nuevaImagen.id;
        imagenModalUrl = urlImagen;
      } else {
        imagenModalId = imagenData.id;
        imagenModalUrl = imagenData.url_imagen;
      }

      tipoImagenModal = tipo;
      modalAbierto = true;
      
      // Cerrar menús
      cerrarMenus();
    } catch (error) {
      console.error('Error abriendo modal:', error);
    }
  }

  function cerrarModal() {
    modalAbierto = false;
    imagenModalUrl = '';
    imagenModalId = null;
    tipoImagenModal = null;
  }

  function verFotoPortada() {
    abrirModalImagen('portada');
  }
  
  function verFotoAvatar() {
    abrirModalImagen('avatar');
  }
  
  function subirFotoPortada() {
    refInputPortada?.click();
    mostrarMenuPortada = false;
    modoEdicion = 'portada';
  }
  function subirFotoAvatar() {
    refInputAvatar?.click();
    mostrarMenuAvatar = false;
    modoEdicion = 'avatar';
  }
  function moverPortada() {
    reposicionandoPortada = true;
    mostrarMenuPortada = false;
  }

  onDestroy(() => {
    window.removeEventListener('mousedown', clickFueraMenuPortada);
    window.removeEventListener('touchstart', clickFueraMenuPortada);
    window.removeEventListener('mousedown', clickFueraMenuAvatar);
  });
</script>

<!--
  Estructura visual y media queries organizados:
  - General styles
  - Media queries agrupados al final y comentados
-->

<!-- Contenedor Principal -->
<div class="contenedor-portada" on:mousemove={manejarDragPortada} on:touchmove={manejarDragPortada}>
  <img
    src={vistaPortadaTemporal || urlPortada || 'https://i.ytimg.com/vi/lg9metXr5XQ/hq720.jpg'}
    alt="Portada de perfil"
    class="imagen-portada"
    class:reposicionando={reposicionandoPortada}
    style="object-position: 50% {posicionPortadaY}%; cursor: {!reposicionandoPortada && !vistaPortadaTemporal && urlPortada ? 'pointer' : 'default'};"
    on:click={() => {
      if (!reposicionandoPortada && !vistaPortadaTemporal && urlPortada) {
        abrirModalImagen('portada');
      }
    }}
  />
  
  <!-- Menú flotante portada -->
  {#if esEditable && mostrarMenuPortada}
    <div class="menu-flotante-portada" bind:this={refMenuPortada}>
      {#if urlPortada}
        <button on:click={verFotoPortada}><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/></svg> Ver foto de portada</button>
      {/if}
      <button on:click={subirFotoPortada}><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 16V4m0 0l-4 4m4-4l4 4"/><rect x="4" y="16" width="16" height="4" rx="2"/></svg> Subir foto nueva</button>
      <button on:click={moverPortada}><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3v18m9-9H3"/></svg> Mover</button>
    </div>
  {/if}

  <!-- Botones Guardar/Cancelar portada cuando hay imagen temporal -->
  {#if esEditable && (vistaPortadaTemporal || modoEdicion === 'portada')}
    <div class="controles-portada">
      <button class="boton-control" on:click={guardarCambios} disabled={subiendo}>
        {subiendo ? 'Guardando...' : 'Guardar'}
      </button>
      <button class="boton-control secundario" on:click={limpiarSeleccion} disabled={subiendo}>
        Cancelar
      </button>
    </div>
  {/if}

  <!-- Icono cámara portada: SOLO si es editable -->
  {#if esEditable}
    <span class="icono-camara-portada" on:click|stopPropagation={abrirMenuPortada}>
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="13" r="4"/><path d="M5 7h2l2-3h6l2 3h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z"/></svg>
      <span class="texto-cambiar-portada">Cambiar portada</span>
    </span>
    <input type="file" class="input-oculto" bind:this={refInputPortada} on:change={(e) => seleccionarArchivo(e, 'portada')} />
  {/if}

  <!-- Avatar -->
  <div class="contenedor-avatar">
    <div class="avatar-interactivo">
      <img 
        src={vistaAvatarTemporal || urlAvatar || 'https://randomuser.me/api/portraits/women/44.jpg'} 
        alt="Avatar" 
        class="imagen-avatar"
        on:click={() => {
          if (!vistaAvatarTemporal && urlAvatar) {
            abrirModalImagen('avatar');
          }
        }}
        style:cursor={!vistaAvatarTemporal && urlAvatar ? 'pointer' : 'default'}
      />
      <!-- Icono cámara perfil SOLO si es editable -->
      {#if esEditable}
        <span class="icono-camara-avatar" on:click|stopPropagation={abrirMenuAvatar}>
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="13" r="4"/><path d="M5 7h2l2-3h6l2 3h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z"/></svg>
        </span>
      {/if}
    </div>
    {#if esEditable}
      <input type="file" class="input-oculto" bind:this={refInputAvatar} on:change={(e) => seleccionarArchivo(e, 'avatar')} />
    {/if}
    
    <!-- Menú flotante avatar -->
    {#if esEditable && mostrarMenuAvatar}
      <div class="menu-flotante-avatar" bind:this={refMenuAvatar}>
        {#if urlAvatar}
          <button on:click={verFotoAvatar}><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/></svg> Ver foto del perfil</button>
        {/if}
        <button on:click={subirFotoAvatar}><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 16V4m0 0l-4 4m4-4l4 4"/><rect x="4" y="16" width="16" height="4" rx="2"/></svg> Elegir foto del perfil</button>
      </div>
    {/if}
    {#if esEditable && modoEdicion === 'avatar'}
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
  
  {#if esEditable}
    <div class="seccion-accion">
      <div class="saludo-accion">¡Sigue así, {nombreCompleto ? nombreCompleto.split(' ')[0] : 'crack'}!</div>
      <button class="boton-accion-principal" on:click={() => window.location.href = '/mis-cursos'}>
        🎹 Ir a mi aprendizaje
      </button>
    </div>
  {/if}
</div>

<style>
  /* === VARIABLES === */
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
    --sombra-suave: 0 4px 24px rgba(0, 0, 0, 0.06);
    --sombra-fuerte: 0 12px 40px rgba(0, 0, 0, 0.22);
  }

  /* === LAYOUT PRINCIPAL === */
  .contenedor-portada {
    position: relative;
    width: 100%;
    height: 350px;
    overflow: visible;
    border-radius: var(--borde-radius) var(--borde-radius) 0 0;
    z-index: 1;
    padding: 0;
    margin-top: 30px;
  }

  .imagen-portada {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: object-position 0.3s ease;
    z-index: 2;
    position: relative;
    border-radius: var(--borde-radius) var(--borde-radius) 0 0;
  }
  .imagen-portada.reposicionando { cursor: grabbing; }

  .info-usuario {
    background: var(--fondo-blanco);
    margin-top: 90px;
    padding: 1px;
    border-radius: 0 0 var(--borde-radius) var(--borde-radius);
    box-shadow: var(--sombra-suave);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 20px;
    position: relative;
    z-index: 1;
    overflow: visible;
  }

  /* === CONTROLES === */
  .controles-portada {
    position: absolute;
    top: 16px;
    right: 16px;
    display: flex;
    gap: 12px;
    z-index: 9999;
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
    z-index: 9998;
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
    z-index: 100;
  }
  .avatar-interactivo:hover .imagen-avatar { box-shadow: 0 12px 40px rgba(37, 99, 235, 0.2); }

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

  /* === SECCIONES INFO === */
  .seccion-estadisticas {
    display: flex;
    align-items: center;
    gap: 8px;
    flex: 1.5;
    position: relative;
    z-index: 1;
  }

  .estadistica {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    flex: 1;
    margin-bottom: 10px;
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
    margin-top: 10px;
  }

  .nombre-usuario {
    font-size: 1.25rem;
    font-weight: 700;
    color: var(--gris-oscuro);
    margin: 2px 0;
  }
  .correo-usuario {
    color: var(--color-primario);
    font-weight: 500;
    font-size: 0.88rem;
    margin: 0 0 4px 0;
  }
  .estrellas {
    font-size: 1.05rem;
    color: var(--color-secundario);
    margin-bottom: 2px;
  }

  .seccion-accion {
    flex: 1.2;
    text-align: center;
    margin-top: 0;
  }

  .saludo-accion {
    font-size: 1rem;
    font-weight: 700;
    color: var(--gris-oscuro);
    margin-bottom: 4px;
  }

  .boton-accion-principal {
    background: linear-gradient(135deg, var(--color-primario), #1d4ed8);
    color: var(--texto-blanco);
    padding: 8px 12px;
    border-radius: 8px;
    border: none;
    font-weight: 700;
    cursor: pointer;
    transition: all 0.2s ease;
    font-size: 0.92rem;
    width: 100%;
    box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
  }
  .boton-accion-principal:hover { 
    transform: translateY(-2px); 
    box-shadow: 0 6px 16px rgba(37, 99, 235, 0.3); 
  }

  /* === ICONOS Y MENÚS === */
  .icono-camara-portada, .icono-camara-avatar {
    background: rgba(255,255,255,0.85);
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .icono-camara-portada {
    position: absolute;
    bottom: 16px;
    right: 16px;
    border-radius: 30px;
    padding: 6px 12px 6px 6px;
    z-index: 20;
    gap: 8px;
  }

  .icono-camara-avatar {
    position: absolute;
    bottom: 8px;
    right: 8px;
    border-radius: 50%;
    padding: 4px;
    z-index: 30;
  }

  .texto-cambiar-portada {
    display: none;
    color: var(--gris-oscuro);
    font-weight: 500;
    font-size: 0.9rem;
  }

  .menu-flotante-portada, .menu-flotante-avatar {
    position: absolute;
    background: white;
    border-radius: 12px;
    padding: 8px;
    box-shadow: var(--sombra-fuerte);
    z-index: 10000;
  }

  .menu-flotante-portada {
    top: 50%;
    right: 16px;
    transform: translateY(-50%);
    min-width: 200px;
  }

  .menu-flotante-avatar {
    top: auto;
    bottom: 110%;
    left: 50%;
    transform: translate(-50%, -8px);
    min-width: 220px;
    z-index: 9999;
  }

  .menu-flotante-portada button,
  .menu-flotante-avatar button {
    width: 100%;
    text-align: left;
    padding: 10px 12px;
    border: none;
    background: transparent;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
    color: var(--gris-oscuro);
    font-weight: 500;
    transition: all 0.2s ease;
  }

  .menu-flotante-portada button:hover,
  .menu-flotante-avatar button:hover {
    background: var(--gris-claro);
  }

  .menu-flotante-portada button svg,
  .menu-flotante-avatar button svg {
    flex-shrink: 0;
  }

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

  /* === RESPONSIVE DESIGN === */
  


  /* Tablet (600px - 900px) */
  @media (max-width: 900px) {
    .contenedor-portada { 
      height: 200px; 
    }
    .info-usuario { 
      flex-direction: column; 
      align-items: center; 
      gap: 20px; 
      margin-top: 100px;
      padding: 0 1rem;
    }
    .seccion-estadisticas, .seccion-central, .seccion-accion { 
      width: 100%; 
      flex: none; 
    }
    .seccion-estadisticas { justify-content: space-around; }
    .separador-vertical { display: none; }
    .icono-camara-portada { padding: 6px; border-radius: 50%; }
    .menu-flotante-avatar {
      bottom: 150px;
      min-width: 95vw;
      background: rgba(255, 255, 255, 0.98);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(0,0,0,0.1);
      left: 50%;
      transform: translateX(-50%, 0);
    }
    .avatar-interactivo {
    position: relative;
    width: 140px;
    height: 140px;
  }
  .contenedor-avatar {
    position: absolute;
    transform: translateX(-50%) translateY(20%);
    margin-bottom: 10px;
  }
  .info-usuario {
    background: var(--fondo-blanco);
    margin-top: 110px;
    padding: 1px;
    border-radius: 0 0 var(--borde-radius) var(--borde-radius);
    box-shadow: var(--sombra-suave);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 5px;
    position: relative;
    z-index: 1;
    overflow: visible;
  }
    /* === SECCIONES INFO === */
    .seccion-estadisticas {
    display: flex;
    align-items: center;
    gap: 2px;
    margin-top: 10px;
    padding: 0 10px;
  }

  .estadistica {
    flex: 1;
    margin-bottom: 5px;
  }

  .seccion-central {
    flex: 1;
    margin-top: -10px;
    font-size: 1.2rem;
  }

  .nombre-usuario {
    font-size: 2rem;
    font-weight: 700;
    color: var(--gris-oscuro);
    margin: 2px 20px -20px 20px;
  }
  .correo-usuario {
   display: none;
  }
  .estrellas {
    font-size: 2rem;
  }

  .seccion-accion {
    flex: 1.2;
    text-align: center;
    margin-top: -15px;
  }

  .saludo-accion {
    font-size: 1rem;
    font-weight: 700;
    color: var(--gris-oscuro);
    margin-bottom: 4px;
  }

  .boton-accion-principal {
    background: linear-gradient(135deg, var(--color-primario), #1d4ed8);
    color: var(--texto-blanco);
    padding: 8px 12px;
    width: 100%;
    max-width: 200px;
    margin-bottom: 10px;
  }

  }

  /* Móvil (480px - 600px) */
  @media (max-width: 600px) {
    .contenedor-portada { height: 180px; }
    .menu-flotante-portada {
      top: auto;
      bottom: 80px;
      right: 16px;
      transform: translateX(-50%);
      min-width: 95vw;
      background: rgba(255, 255, 255, 0.98);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(0,0,0,0.1);
      left: 50%;
    }
    .menu-flotante-avatar { min-width: 95vw; }
  }

  /* Móvil pequeño (menos de 480px) */
  @media (max-width: 480px) {
    .contenedor-portada { 
      height: 240px;
      border-radius: 0;
    }
    .imagen-portada { border-radius: 0; }
    .controles-portada { gap: 8px; }
    .boton-control { padding: 8px 16px; font-size: 0.85rem; }
    .icono-estadistica { font-size: 1.9rem; }
    .valor { font-size: 1.1rem; }
    .etiqueta { font-size: 0.6rem; }
    .info-usuario { padding: 5px; margin-top: 60px; }
    .contenedor-avatar { bottom: -40px; }
  }
</style>

<!-- Modal estilo Facebook para ver imágenes con likes y comentarios -->
<ModalVisorImagenPerfil
  abierto={modalAbierto}
  imagenUrl={imagenModalUrl}
  imagenId={imagenModalId}
  tipoImagen={tipoImagenModal}
  usuarioPropietario={{
    id: userId || '',
    nombre: nombreCompleto,
    avatar: urlAvatar || ''
  }}
  onCerrar={cerrarModal}
/>

