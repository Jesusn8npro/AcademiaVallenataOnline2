<script lang="ts">
  import { registrarUsuario, iniciarSesionConCorreo, obtenerPerfil } from '$lib/supabase/autenticacionSupabase';
  import { setUsuario } from '$lib/UsuarioActivo/usuario';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  export let abierto = false;
  export let onCerrar = () => {};
  let usuario = '';
  let contrasena = '';
  let vistaRegistro = false;
  let vistaRecuperar = false;
  // Campos de registro
  let nombre = '';
  let apellido = '';
  let whatsapp = '';
  let correoRegistro = '';
  let contrasenaRegistro = '';
  // Estado para login
  let cargando = false;
  let errorLogin = '';
  // Recuperar contraseña
  let correoRecuperar = '';
  let mensajeRecuperar = '';

  function cerrarModal() {
    onCerrar();
    vistaRegistro = false;
    vistaRecuperar = false;
    usuario = '';
    contrasena = '';
    errorLogin = '';
    cargando = false;
    correoRecuperar = '';
    mensajeRecuperar = '';
  }
  function detenerPropagacion(e: Event) {
    e.stopPropagation();
  }

  async function manejarLogin(e: Event) {
    e.preventDefault();
    errorLogin = '';
    cargando = true;
    const { usuario: usuarioSesion, error } = await iniciarSesionConCorreo(usuario, contrasena);
    cargando = false;
    if (error) {
      errorLogin = error;
      return;
    }
    // Obtener el perfil para saber el rol
    let perfil = null;
    let errorPerfil = null;
    if (usuarioSesion && usuarioSesion.id) {
      const resultadoPerfil = await obtenerPerfil(usuarioSesion.id);
      perfil = resultadoPerfil.perfil;
      errorPerfil = resultadoPerfil.error;
    }
    if (perfil && !errorPerfil) {
      setUsuario(perfil); // Guardar usuario global
      cerrarModal();
      // Redirección explícita según el rol
      if (perfil.rol && perfil.rol.toLowerCase() === 'admin') {
        goto('/administrador');
      } else {
        goto('/estudiante');
      }
    }
  }

  async function manejarRegistro(e: Event) {
    e.preventDefault();
    errorLogin = '';
    cargando = true;
    const { usuario, error } = await registrarUsuario(
      correoRegistro,
      contrasenaRegistro,
      { nombre, apellido, whatsapp }
    );
    cargando = false;
    if (error) {
      errorLogin = error;
      return;
    }
    if (usuario) {
      setUsuario(usuario); // Guardar usuario global
      // Redirección explícita según el rol
      if (usuario.rol && usuario.rol.toLowerCase() === 'admin') {
        cerrarModal();
        goto('/administrador');
        return;
      }
    }
    cerrarModal();
    goto('/estudiante');
  }

  async function enviarRecuperacion(e: Event) {
    e.preventDefault();
    mensajeRecuperar = '';
    cargando = true;
    const { error } = await supabase.auth.resetPasswordForEmail(correoRecuperar, {
      redirectTo: window.location.origin + '/recuperar-contrasena'
    });
    cargando = false;
    if (error) {
      mensajeRecuperar = 'No se pudo enviar el correo. Verifica tu email.';
    } else {
      mensajeRecuperar = '¡Revisa tu correo para restablecer la contraseña!';
    }
  }
</script>

{#if abierto}
  <div class="fondo-modal" on:click={cerrarModal} on:keydown={(e) => e.key === 'Escape' && cerrarModal()} role="presentation">
    <div class="modal-inicio-sesion" on:click={detenerPropagacion} role="dialog" aria-modal="true" tabindex="-1">
      <button class="boton-cerrar" aria-label="Cerrar" on:click={cerrarModal}>
        &times;
      </button>
      <img src="/logo academia vallenata.png" alt="Logo Academia Vallenata" class="logo-modal" />
      {#if vistaRecuperar}
        <h2 class="titulo-modal">Recuperar contraseña</h2>
        <p class="login-desc">Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.</p>
        <form class="formulario-inicio-sesion" on:submit={enviarRecuperacion}>
          <div class="campo-formulario">
            <label for="recuperarCorreo">Correo electrónico</label>
            <div class="input-icono">
              <input id="recuperarCorreo" type="email" bind:value={correoRecuperar} placeholder="Tu correo" required />
              <span class="icono-input">📧</span>
            </div>
          </div>
          {#if mensajeRecuperar}
            <div class="mensaje-error">{mensajeRecuperar}</div>
          {/if}
          <button type="submit" class="boton-enviar" disabled={cargando}>
            {cargando ? 'Enviando...' : 'Enviar enlace'}
          </button>
        </form>
        <div class="enlaces-extra">
          <button type="button" class="enlace-olvido" on:click={() => { vistaRecuperar = false; mensajeRecuperar = ''; correoRecuperar = ''; }}>Volver al inicio de sesión</button>
        </div>
      {:else if !vistaRegistro}
        <h2 class="titulo-modal">¡Bienvenido de nuevo!</h2>
        <p class="login-desc">Accede a tu cuenta para disfrutar de todos los beneficios de la Academia Vallenata Online.</p>
        <form class="formulario-inicio-sesion" autocomplete="off" on:submit={manejarLogin}>
          <div class="campo-formulario">
            <label for="usuario">Correo electrónico o usuario</label>
            <div class="input-icono">
              <input id="usuario" type="text" bind:value={usuario} placeholder="Tu correo o usuario" required />
              <span class="icono-input">📧</span>
            </div>
          </div>
          <div class="campo-formulario">
            <label for="contrasena">Contraseña</label>
            <div class="input-icono">
              <input id="contrasena" type="password" bind:value={contrasena} placeholder="Tu contraseña" required />
              <span class="icono-input">🔒</span>
            </div>
          </div>
          {#if errorLogin}
            <div class="mensaje-error">{errorLogin}</div>
          {/if}
          <button type="submit" class="boton-enviar" disabled={cargando}>
            {cargando ? 'Ingresando...' : 'Entrar'}
          </button>
        </form>
        <div class="enlaces-extra">
          <button type="button" class="enlace-olvido" on:click={() => { vistaRecuperar = true; }}>¿Olvidaste tu contraseña?</button>
          <button type="button" class="enlace-registrarse" on:click={() => vistaRegistro = true}>¿No tienes cuenta? <b>Regístrate</b></button>
        </div>
      {:else}
        <h2 class="titulo-modal">Crear cuenta nueva</h2>
        <p class="login-desc">Únete a la comunidad y accede a todos los cursos, eventos y beneficios exclusivos.</p>
        <form class="formulario-inicio-sesion" autocomplete="off" on:submit={manejarRegistro}>
          <div class="fila-nombre-apellido">
            <div class="campo-formulario">
              <label for="nombre">Nombre</label>
              <input id="nombre" type="text" bind:value={nombre} placeholder="Tu nombre" required />
            </div>
            <div class="campo-formulario">
              <label for="apellido">Apellido</label>
              <input id="apellido" type="text" bind:value={apellido} placeholder="Tu apellido" required />
            </div>
          </div>
          <div class="campo-formulario">
            <label for="whatsapp">WhatsApp</label>
            <div class="input-icono">
              <input id="whatsapp" type="tel" bind:value={whatsapp} placeholder="Tu número de WhatsApp" required />
              <span class="icono-input">📱</span>
            </div>
          </div>
          <div class="campo-formulario">
            <label for="correoRegistro">Correo electrónico</label>
            <div class="input-icono">
              <input id="correoRegistro" type="email" bind:value={correoRegistro} placeholder="Tu correo electrónico" required />
              <span class="icono-input">📧</span>
            </div>
          </div>
          <div class="campo-formulario">
            <label for="contrasenaRegistro">Contraseña</label>
            <div class="input-icono">
              <input id="contrasenaRegistro" type="password" bind:value={contrasenaRegistro} placeholder="Crea una contraseña" required />
              <span class="icono-input">🔒</span>
            </div>
          </div>
          {#if errorLogin}
            <div class="mensaje-error">{errorLogin}</div>
          {/if}
          <button type="submit" class="boton-enviar">Registrarme</button>
        </form>
        <div class="enlaces-extra">
          <button type="button" class="enlace-olvido" on:click={() => vistaRegistro = false}>¿Ya tienes cuenta? <b>Inicia sesión</b></button>
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
.fondo-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0,0,0,0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  transition: opacity 0.2s;
  padding: 0 12px;
}
.modal-inicio-sesion {
  width: 100%;
  max-width: 370px;
  margin: 24px auto;
  box-sizing: border-box;
  background: linear-gradient(135deg, #fff 80%, #ffe5d0 100%);
  border-radius: 2rem;
  box-shadow: 0 8px 40px #0002;
  padding: 2.5rem 2rem 2rem 2rem;
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  animation: aparecerModal 0.26s cubic-bezier(.4,1.2,.6,1) both;
  text-align: center;
}
@media (max-width: 600px) {
  .modal-inicio-sesion {
    padding: 1.2rem .5rem 1.5rem .5rem;
    max-width: 97vw;
    margin: 12px 4px;
  }
}
.login-logo, .logo-modal {
  width: 70px; margin-bottom: 1rem; display: block; margin-left: auto; margin-right: auto;
}
.titulo-modal {
  font-size: 1.5rem; font-weight: 900; color: #ff6600; margin-bottom: .5rem; text-align: center;
}
.login-desc {
  color: #444; font-size: 1rem; margin-bottom: 1.5rem; text-align: center;
}
.formulario-inicio-sesion {
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
}
.fila-nombre-apellido {
  display: flex;
  gap: 0.4rem;
}
.fila-nombre-apellido .campo-formulario {
  flex: 1 1 0;
  min-width: 0;
}
.campo-formulario {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  text-align: left;
}
.campo-formulario label {
  font-size: 1rem;
  color: #23235b;
  font-weight: 600;
}
.input-icono {
  display: flex;
  align-items: center;
  background: #f7f7f7;
  border-radius: 10px;
  border: 1.5px solid #eee;
  padding: .5rem 1rem;
  margin-top: .3rem;
}
.input-icono input {
  border: none;
  background: transparent;
  flex: 1;
  font-size: 1rem;
  padding: .5rem 0;
}
.input-icono input:focus {
  outline: none !important;
  border: none !important;
  box-shadow: none !important;
}
.icono-input { font-size: 1.2rem; color: #ff6600; margin-left: .5rem; }
.boton-enviar {
  background: linear-gradient(90deg, #ff6600, #ff8c42);
  color: #fff; border: none; border-radius: 30px; padding: 1rem; font-size: 1.1rem; font-weight: 700;
  margin-top: .5rem; cursor: pointer; box-shadow: 0 2px 12px #ff660033; transition: background .2s;
}
.boton-enviar:hover { background: linear-gradient(90deg, #ff8c42, #ff6600); }
.mensaje-error {
  color: #e74c3c; background: #fff3f0; border-radius: 8px; padding: .5rem .7rem; font-size: .98rem; margin-bottom: .2rem; text-align: center;
}
.enlaces-extra {
  margin-top: 1.2rem; display: flex; flex-direction: column; gap: .5rem; align-items: center;
}
.enlace-olvido, .enlace-registrarse {
  background: none; border: none; color: #1a73e8; font-size: .97rem; text-decoration: underline; cursor: pointer; transition: color .2s; padding: 0; font-family: inherit;
}
.enlace-olvido:hover, .enlace-registrarse:hover { color: #ff6600; }
.boton-cerrar {
  position: absolute; top: 1.2rem; right: 1.2rem;
  background: none; border: none; font-size: 2rem; color: #ff6600; cursor: pointer; transition: color .2s;
}
.boton-cerrar:hover { color: #d35400; }
@media (max-width: 500px) {
  .modal-inicio-sesion { padding: 1.2rem .5rem 1.5rem .5rem; }
}
</style>
