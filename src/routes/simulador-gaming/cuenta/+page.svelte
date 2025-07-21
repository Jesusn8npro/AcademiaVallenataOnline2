<!-- Página de cuenta y configuración en español -->
<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import FondoEspacial from '$lib/components/SimuladorDefinitivo/components/efectos/FondoEspacial.svelte';
  import { audioManager, TipoEfectoUI } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
  
  // Estado de autenticación simulado (en un proyecto real usarías un store real)
  let usuarioAutenticado = false;
  let usuarioVerificado = false;
  let perfilUsuario = {
    nombre: 'Acordeonista Pro',
    email: 'usuario@acordeon.com',
    avatar: '/Acordeon PRO MAX.png',
    nivel: 15,
    experiencia: 2500,
    experienciaMaxima: 3000
  };
  
  // Estado de la aplicación
  let mostrarModal = false;
  let emailEnviandoTimeout = false;
  let cargando = false;
  
  // Configuración simulada
  let configuracion = {
    volumenMaster: 0.7,
    volumenEfectos: 0.5,
    volumenMusica: 0.8,
    calidad: 'alta',
    pantaCompleta: false,
    notificaciones: true,
    idioma: 'español'
  };
  
  // Enlaces externos
  const enlaces = {
    reporteBugs: 'https://forms.gle/8gmuaWU7E9h82i4A7',
    github: 'https://github.com/tuproyecto/acordeon-simulator',
    discord: 'https://discord.gg/ejemplo'
  };
  
  // Información de la app
  const versionApp = 'v2.0-Alpha';
  const build = 'Build 2025.01';
  
  onMount(() => {
    // Simular autenticación (en un proyecto real cargarías desde un store/API)
    setTimeout(() => {
      usuarioAutenticado = true;
      usuarioVerificado = true;
      cargando = false;
    }, 1500);
  });
  
  function irAlInicio() {
    audioManager.transicion();
    goto('/');
  }
  
  function iniciarSesion() {
    audioManager.clickBoton();
    // En un proyecto real, aquí abriríais Firebase Auth o similar
    alert('Funcionalidad de login será implementada próximamente');
  }
  
  function registrarse() {
    audioManager.clickBoton();
    alert('Funcionalidad de registro será implementada próximamente');
  }
  
  function cerrarSesion() {
    audioManager.abrirModal();
    mostrarModal = true;
  }
  
  function confirmarCerrarSesion() {
    audioManager.clickBoton();
    usuarioAutenticado = false;
    usuarioVerificado = false;
    mostrarModal = false;
    audioManager.exito();
  }
  
  function cancelarCerrarSesion() {
    audioManager.cerrarModal();
    mostrarModal = false;
  }
  
  function reenviarEmail() {
    if (emailEnviandoTimeout) return;
    
    audioManager.mostrarAlerta();
    emailEnviandoTimeout = true;
    setTimeout(() => {
      emailEnviandoTimeout = false;
    }, 30000);
    
    alert('Email de verificación enviado! Revisa tu bandeja de entrada.');
  }
  
  function actualizarConfiguracion() {
    audioManager.exito();
    alert('Configuración guardada correctamente');
  }
  
  function manejarHover() {
    audioManager.hoverNavegacion();
  }
</script>

<svelte:head>
  <title>Cuenta y Configuración - Acordeón Simulator</title>
</svelte:head>

<FondoEspacial />

<div class="contenedor-principal">
  <!-- Área de autenticación -->
  <div class="seccion-auth">
    {#if !usuarioAutenticado}
      <!-- No autenticado -->
      <div class="centro-auth">
        <h2>Iniciar Sesión o Registrarse</h2>
        <h4>¡Para la experiencia completa!</h4>
        
        <div class="botones-auth">
          <button class="boton-auth primario" on:click={iniciarSesion} on:mouseenter={manejarHover}>
            🔑 Iniciar Sesión
          </button>
          <button class="boton-auth secundario" on:click={registrarse} on:mouseenter={manejarHover}>
            📝 Registrarse
          </button>
        </div>
      </div>
    {:else if !usuarioVerificado}
      <!-- Autenticado pero no verificado -->
      <div class="centro-auth">
        <div class="mensaje-verificacion">
          ¡Por favor revisa tu email para verificar tu cuenta!
        </div>
        <div class="botones-verificacion">
          <button class="boton-texto" on:click={() => location.reload()} on:mouseenter={manejarHover}>
            🔄 Actualizar
          </button>
          <button 
            class="boton-texto" 
            class:deshabilitado={emailEnviandoTimeout}
            on:click={reenviarEmail} 
            on:mouseenter={manejarHover}
          >
            📧 Reenviar Email
          </button>
          <button class="boton-texto" on:click={cerrarSesion} on:mouseenter={manejarHover}>
            🚪 Cerrar Sesión
          </button>
        </div>
      </div>
    {/if}
  </div>
  
  <!-- Área principal de configuración -->
  <div class="area-principal" class:cortada={!usuarioAutenticado}>
    {#if usuarioVerificado}
      <div class="contenedor-configuracion">
        <!-- Perfil de usuario -->
        <div class="seccion-perfil">
          <div class="tarjeta-perfil">
            <div class="avatar-usuario">
              <img src={perfilUsuario.avatar} alt="Avatar" />
            </div>
            <div class="info-usuario">
              <h3>{perfilUsuario.nombre}</h3>
              <p>{perfilUsuario.email}</p>
              <div class="nivel-usuario">
                <span>Nivel {perfilUsuario.nivel}</span>
                <div class="barra-experiencia">
                  <div 
                    class="progreso-experiencia" 
                    style="width: {(perfilUsuario.experiencia / perfilUsuario.experienciaMaxima) * 100}%"
                  ></div>
                </div>
                <span>{perfilUsuario.experiencia}/{perfilUsuario.experienciaMaxima} EXP</span>
              </div>
            </div>
            <button class="boton-cerrar-sesion" on:click={cerrarSesion} on:mouseenter={manejarHover}>
              Cerrar Sesión
            </button>
          </div>
        </div>
        
        <!-- Configuración de audio -->
        <div class="seccion-configuracion">
          <h3>🎵 Configuración de Audio</h3>
          <div class="controles-audio">
            <div class="control-volumen">
              <label>Volumen Master</label>
              <input 
                type="range" 
                min="0" 
                max="1" 
                step="0.1" 
                bind:value={configuracion.volumenMaster}
                on:change={actualizarConfiguracion}
              />
              <span>{Math.round(configuracion.volumenMaster * 100)}%</span>
            </div>
            <div class="control-volumen">
              <label>Efectos de Sonido</label>
              <input 
                type="range" 
                min="0" 
                max="1" 
                step="0.1" 
                bind:value={configuracion.volumenEfectos}
                on:change={actualizarConfiguracion}
              />
              <span>{Math.round(configuracion.volumenEfectos * 100)}%</span>
            </div>
            <div class="control-volumen">
              <label>Música de Fondo</label>
              <input 
                type="range" 
                min="0" 
                max="1" 
                step="0.1" 
                bind:value={configuracion.volumenMusica}
                on:change={actualizarConfiguracion}
              />
              <span>{Math.round(configuracion.volumenMusica * 100)}%</span>
            </div>
          </div>
        </div>
        
        <!-- Configuración visual -->
        <div class="seccion-configuracion">
          <h3>👁️ Configuración Visual</h3>
          <div class="controles-visuales">
            <div class="control-checkbox">
              <input 
                type="checkbox" 
                id="pantalla-completa" 
                bind:checked={configuracion.pantaCompleta}
                on:change={actualizarConfiguracion}
              />
              <label for="pantalla-completa">Pantalla Completa por Defecto</label>
            </div>
            <div class="control-select">
              <label>Calidad Gráfica</label>
              <select bind:value={configuracion.calidad} on:change={actualizarConfiguracion}>
                <option value="baja">Baja</option>
                <option value="media">Media</option>
                <option value="alta">Alta</option>
                <option value="ultra">Ultra</option>
              </select>
            </div>
          </div>
        </div>
        
        <!-- Configuración general -->
        <div class="seccion-configuracion">
          <h3>⚙️ Configuración General</h3>
          <div class="controles-generales">
            <div class="control-checkbox">
              <input 
                type="checkbox" 
                id="notificaciones" 
                bind:checked={configuracion.notificaciones}
                on:change={actualizarConfiguracion}
              />
              <label for="notificaciones">Activar Notificaciones</label>
            </div>
            <div class="control-select">
              <label>Idioma</label>
              <select bind:value={configuracion.idioma} on:change={actualizarConfiguracion}>
                <option value="español">Español</option>
                <option value="english">English</option>
                <option value="português">Português</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    {:else}
      <div class="espacio-vacio"></div>
    {/if}
    
    <!-- Información de la aplicación -->
    <div class="creditos-app">
      <div class="info-version">
        {versionApp} · {build}
      </div>
      <br />
      {#if usuarioAutenticado}
        <div class="texto-creditos">
          ¡Gracias por jugar Acordeón Simulator Alpha! Únete a nuestro 
          <a href={enlaces.discord} target="_blank" on:mouseenter={manejarHover}>servidor de Discord</a> 
          para obtener las últimas actualizaciones. Puedes reportar bugs y enviar comentarios 
          <a href={enlaces.reporteBugs} target="_blank" on:mouseenter={manejarHover}>aquí</a> 
          o en nuestro 
          <a href={enlaces.github} target="_blank" on:mouseenter={manejarHover}>repositorio de GitHub</a>.
          ¡También puedes darnos una estrella para apoyarnos!
        </div>
      {:else}
        <div class="enlaces-publicos">
          <a href={enlaces.reporteBugs} target="_blank" on:mouseenter={manejarHover}>Reportar Bug</a> ·
          <a href={enlaces.discord} target="_blank" on:mouseenter={manejarHover}>Discord</a> ·
          <a href={enlaces.github} target="_blank" on:mouseenter={manejarHover}>GitHub</a>
        </div>
      {/if}
    </div>
  </div>
  

</div>

<!-- Modal de confirmación -->
{#if mostrarModal}
  <div class="modal-overlay" on:click={cancelarCerrarSesion}>
    <div class="modal-contenido" on:click|stopPropagation>
      <h3>¿Estás seguro de que quieres cerrar sesión?</h3>
      <div class="botones-modal">
        <button class="boton-modal cancelar" on:click={cancelarCerrarSesion}>Cancelar</button>
        <button class="boton-modal confirmar" on:click={confirmarCerrarSesion}>Cerrar Sesión</button>
      </div>
    </div>
  </div>
{/if}

<!-- Loading -->
{#if cargando}
  <div class="loading-overlay">
    <div class="loading-contenido">
      <div class="spinner"></div>
      <p>Comunicando...</p>
    </div>
  </div>
{/if}

<style>
  .contenedor-principal {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    position: relative;
    z-index: 1;
  }
  
  .seccion-auth {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 300px;
    padding: 2rem;
  }
  
  .centro-auth {
    text-align: center;
    max-width: 500px;
  }
  
  .centro-auth h2 {
    color: white;
    font-size: 2rem;
    margin-bottom: 1rem;
  }
  
  .centro-auth h4 {
    color: rgba(255, 255, 255, 0.8);
    font-size: 1.2rem;
    margin-bottom: 2rem;
  }
  
  .botones-auth {
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
  }
  
  .boton-auth {
    padding: 12px 24px;
    border: none;
    border-radius: 25px;
    font-size: 1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  
  .boton-auth.primario {
    background: linear-gradient(135deg, #4ecdc4, #44a08d);
    color: white;
  }
  
  .boton-auth.secundario {
    background: linear-gradient(135deg, #667eea, #764ba2);
    color: white;
  }
  
  .boton-auth:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
  }
  
  .mensaje-verificacion {
    font-size: 1.2rem;
    color: white;
    margin-bottom: 2rem;
  }
  
  .botones-verificacion {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    align-items: center;
  }
  
  .boton-texto {
    background: none;
    border: none;
    color: rgba(255, 255, 255, 0.8);
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.3s ease;
    text-decoration: underline;
    padding: 8px 16px;
  }
  
  .boton-texto:hover {
    color: white;
    transform: translateY(-1px);
  }
  
  .boton-texto.deshabilitado {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  .area-principal {
    flex: 1;
    background: rgba(0, 0, 0, 0.1);
    backdrop-filter: blur(10px);
    margin: 0 2rem 2rem 2rem;
    border-radius: 15px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    overflow-y: auto;
  }
  
  .area-principal.cortada {
    min-height: calc(100vh - 400px);
  }
  
  .contenedor-configuracion {
    padding: 2rem;
    max-width: 800px;
    margin: 0 auto;
  }
  
  .seccion-perfil {
    margin-bottom: 3rem;
  }
  
  .tarjeta-perfil {
    display: flex;
    align-items: center;
    gap: 2rem;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 15px;
    padding: 2rem;
    border: 1px solid rgba(255, 255, 255, 0.2);
  }
  
  .avatar-usuario img {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    border: 3px solid rgba(255, 255, 255, 0.3);
  }
  
  .info-usuario {
    flex: 1;
  }
  
  .info-usuario h3 {
    color: white;
    margin-bottom: 0.5rem;
  }
  
  .info-usuario p {
    color: rgba(255, 255, 255, 0.7);
    margin-bottom: 1rem;
  }
  
  .nivel-usuario {
    display: flex;
    align-items: center;
    gap: 1rem;
    font-size: 0.9rem;
    color: rgba(255, 255, 255, 0.8);
  }
  
  .barra-experiencia {
    flex: 1;
    height: 8px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 4px;
    overflow: hidden;
  }
  
  .progreso-experiencia {
    height: 100%;
    background: linear-gradient(90deg, #4ecdc4, #44a08d);
    transition: width 0.3s ease;
  }
  
  .boton-cerrar-sesion {
    background: linear-gradient(135deg, #ff6b6b, #ee5a24);
    border: none;
    border-radius: 20px;
    padding: 10px 20px;
    color: white;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .boton-cerrar-sesion:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(255, 107, 107, 0.3);
  }
  
  .seccion-configuracion {
    margin-bottom: 2rem;
  }
  
  .seccion-configuracion h3 {
    color: white;
    margin-bottom: 1rem;
    font-size: 1.3rem;
  }
  
  .controles-audio,
  .controles-visuales,
  .controles-generales {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  
  .control-volumen {
    display: flex;
    align-items: center;
    gap: 1rem;
    background: rgba(255, 255, 255, 0.05);
    padding: 1rem;
    border-radius: 10px;
  }
  
  .control-volumen label {
    color: white;
    min-width: 150px;
  }
  
  .control-volumen input[type="range"] {
    flex: 1;
    margin: 0 1rem;
  }
  
  .control-volumen span {
    color: #4ecdc4;
    font-weight: bold;
    min-width: 50px;
  }
  
  .control-checkbox {
    display: flex;
    align-items: center;
    gap: 1rem;
    background: rgba(255, 255, 255, 0.05);
    padding: 1rem;
    border-radius: 10px;
  }
  
  .control-checkbox label {
    color: white;
    cursor: pointer;
  }
  
  .control-select {
    display: flex;
    align-items: center;
    gap: 1rem;
    background: rgba(255, 255, 255, 0.05);
    padding: 1rem;
    border-radius: 10px;
  }
  
  .control-select label {
    color: white;
    min-width: 150px;
  }
  
  .control-select select {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 5px;
    padding: 8px 12px;
    color: white;
  }
  
  .espacio-vacio {
    min-height: calc(100% - 120px);
  }
  
  .creditos-app {
    text-align: center;
    padding: 2rem;
    color: rgba(255, 255, 255, 0.7);
    font-size: 0.9rem;
    line-height: 1.6;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
  }
  
  .info-version {
    font-weight: bold;
    color: rgba(255, 255, 255, 0.9);
  }
  
  .texto-creditos a,
  .enlaces-publicos a {
    color: #4ecdc4;
    text-decoration: none;
    transition: color 0.3s ease;
  }
  
  .texto-creditos a:hover,
  .enlaces-publicos a:hover {
    color: #44a08d;
  }
  
  .boton-volver {
    position: fixed;
    top: 20px;
    right: 20px;
    background: linear-gradient(135deg, #667eea, #764ba2);
    border: none;
    border-radius: 25px;
    padding: 12px 24px;
    color: white;
    cursor: pointer;
    transition: all 0.3s ease;
    z-index: 10;
  }
  
  .boton-volver:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(102, 126, 234, 0.3);
  }
  
  /* Modal */
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
  }
  
  .modal-contenido {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(20px);
    border-radius: 15px;
    padding: 2rem;
    border: 1px solid rgba(255, 255, 255, 0.2);
    text-align: center;
    max-width: 400px;
  }
  
  .modal-contenido h3 {
    color: white;
    margin-bottom: 2rem;
  }
  
  .botones-modal {
    display: flex;
    gap: 1rem;
    justify-content: center;
  }
  
  .boton-modal {
    padding: 10px 20px;
    border: none;
    border-radius: 20px;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .boton-modal.cancelar {
    background: rgba(255, 255, 255, 0.2);
    color: white;
  }
  
  .boton-modal.confirmar {
    background: linear-gradient(135deg, #ff6b6b, #ee5a24);
    color: white;
  }
  
  .boton-modal:hover {
    transform: translateY(-2px);
  }
  
  /* Loading */
  .loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.9);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 999;
  }
  
  .loading-contenido {
    text-align: center;
    color: white;
  }
  
  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid rgba(255, 255, 255, 0.3);
    border-top: 4px solid #4ecdc4;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 1rem auto;
  }
  
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .area-principal {
      margin: 0 1rem 1rem 1rem;
    }
    
    .contenedor-configuracion {
      padding: 1rem;
    }
    
    .tarjeta-perfil {
      flex-direction: column;
      text-align: center;
    }
    
    .nivel-usuario {
      flex-direction: column;
      align-items: stretch;
    }
    
    .control-volumen,
    .control-select {
      flex-direction: column;
      align-items: stretch;
    }
    
    .control-volumen label,
    .control-select label {
      min-width: auto;
    }
    
    .boton-volver {
      top: auto;
      bottom: 20px;
      right: 20px;
    }
  }
</style> 