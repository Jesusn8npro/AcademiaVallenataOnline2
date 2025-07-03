<script lang="ts">
  import { registrarUsuario, iniciarSesionConCorreo, obtenerPerfil } from '$lib/supabase/autenticacionSupabase';
  import { setUsuario } from '$lib/UsuarioActivo/usuario';
  import { goto } from '$app/navigation';
  export let abierto = false;
  export let onCerrar = () => {};
  let usuario = '';
  let contrasena = '';
  let vistaRegistro = false;
  // Campos de registro
  let nombre = '';
  let apellido = '';
  let whatsapp = '';
  let correoRegistro = '';
  let contrasenaRegistro = '';

  // Estado para login
  let cargando = false;
  let errorLogin = '';

  function cerrarModal() {
    onCerrar();
    vistaRegistro = false;
    usuario = '';
    contrasena = '';
    errorLogin = '';
    cargando = false;
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
</script>

{#if abierto}
  <div class="fondo-modal" on:click={cerrarModal} on:keydown={(e) => e.key === 'Escape' && cerrarModal()} role="presentation">
    <div class="modal-inicio-sesion" on:click={detenerPropagacion} role="dialog" aria-modal="true" tabindex="-1">
      <button class="boton-cerrar" aria-label="Cerrar" on:click={cerrarModal}>
        &times;
      </button>
      <img src="/logo academia vallenata.png" alt="Logo Academia Vallenata" class="logo-modal" />
      {#if !vistaRegistro}
        <h2 class="titulo-modal">Iniciar sesión</h2>
        <form class="formulario-inicio-sesion" autocomplete="off" on:submit={manejarLogin}>
  <div class="campo-formulario">
    <label for="usuario">Correo electrónico o usuario</label>
    <input id="usuario" type="text" bind:value={usuario} placeholder="Tu correo o usuario" required />
  </div>
  <div class="campo-formulario">
    <label for="contrasena">Contraseña</label>
    <input id="contrasena" type="password" bind:value={contrasena} placeholder="Tu contraseña" required />
  </div>
  {#if errorLogin}
    <div class="mensaje-error">{errorLogin}</div>
  {/if}
  <button type="submit" class="boton-enviar" disabled={cargando}>
    {cargando ? 'Ingresando...' : 'Entrar'}
  </button>
</form>
        <div class="enlaces-extra">
          <button type="button" class="enlace-olvido">¿Olvidaste tu contraseña?</button>
          <button type="button" class="enlace-registrarse" on:click={() => vistaRegistro = true}>¿No tienes cuenta? Regístrate</button>
        </div>
      {:else}
        <h2 class="titulo-modal">Crear cuenta nueva</h2>
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
            <input id="whatsapp" type="tel" bind:value={whatsapp} placeholder="Tu número de WhatsApp" required />
          </div>
          <div class="campo-formulario">
            <label for="correoRegistro">Correo electrónico</label>
            <input id="correoRegistro" type="email" bind:value={correoRegistro} placeholder="Tu correo electrónico" required />
          </div>
          <div class="campo-formulario">
            <label for="contrasenaRegistro">Contraseña</label>
            <input id="contrasenaRegistro" type="password" bind:value={contrasenaRegistro} placeholder="Crea una contraseña" required />
          </div>
          {#if errorLogin}
            <div class="mensaje-error">{errorLogin}</div>
          {/if}
          <button type="submit" class="boton-enviar">Registrarme</button>
        </form>
        <div class="enlaces-extra">
          <button type="button" class="enlace-olvido" on:click={() => vistaRegistro = false}>¿Ya tienes cuenta? Inicia sesión</button>
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
  z-index: 9999; /* Muy por encima de todo */
  transition: opacity 0.2s;
  padding: 0 12px; /* Margen lateral en móviles */
}

.modal-inicio-sesion {
  width: 100%;
  max-width: 370px;
  margin: 24px auto;
  box-sizing: border-box;

  background: #fff;
  border-radius: 22px;
  box-shadow: 0 6px 32px rgba(0,0,0,0.16), 0 1.5px 8px rgba(0,0,0,0.09);
  padding: 1.7rem 1.5rem 1.2rem 1.5rem;
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  animation: aparecerModal 0.26s cubic-bezier(.4,1.2,.6,1) both;
}
@media (max-width: 600px) {
  .modal-inicio-sesion {
    padding: 0.8rem 0.65rem 0.7rem 0.65rem;
    max-width: 97vw;
    margin: 12px 4px;
  }
}
@media (max-width: 600px) {
  .modal-inicio-sesion {
    padding: 1.2rem 0.6rem 1.1rem 0.6rem;
    max-width: 97vw;
    margin: 18px 7px;
  }
}
@media (max-width: 600px) {
  .modal-inicio-sesion {
    padding: 2rem 1.2rem 1.5rem 1.2rem;
    max-width: 98vw;
    margin: 0 22px;
  }
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
}
@keyframes aparecerModal {
  from { opacity: 0; transform: translateY(-32px) scale(0.95); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}
.boton-cerrar {
  position: absolute;
  top: 1.1rem;
  right: 1.1rem;
  background: none;
  border: none;
  font-size: 1.7rem;
  color: #888;
  cursor: pointer;
  transition: color 0.15s;
}
.boton-cerrar:hover {
  color: #e74c3c;
}
.titulo-modal {
  text-align: center;
  font-size: 1.45rem;
  font-weight: 700;
  color: #23235b;
  margin-bottom: 0.7rem;
}
.formulario-inicio-sesion {
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
}
.campo-formulario {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.campo-formulario label {
  font-size: 1rem;
  color: #23235b;
  font-weight: 500;
}
.campo-formulario input {
  padding: 0.38rem 0.7rem;
  border: 1px solid #d2d2d2;
  border-radius: 8px;
  font-size: 1rem;
  outline: none;
  transition: border 0.17s;
}
.campo-formulario input:focus {
  border: 1.5px solid #23235b;
}
.boton-enviar {
  background: #e6a800;
  color: #181818;
  border: none;
  border-radius: 7px;
  padding: 0.5rem 0;
  font-size: 1.08rem;
  font-weight: 600;
  cursor: pointer;
  margin-top: 0.25rem;
  transition: background 0.18s;
}
.boton-enviar:hover {
  background: #ffce3a;
}
.enlaces-extra {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  margin-top: 0.7rem;
  align-items: center;
}
.enlace-olvido, .enlace-registrarse {
  background: none;
  border: none;
  color: #23235b;
  font-size: 0.98rem;
  text-decoration: underline;
  cursor: pointer;
  transition: color 0.16s;
  padding: 0;
  font-family: inherit;
}
.enlace-olvido:hover, .enlace-registrarse:hover {
  color: #e6a800;
}
.logo-modal {
  display: block;
  margin: 0 auto 0.6rem auto;
  max-width: 120px;
  width: 100%;
  height: auto;
}
@media (max-width: 600px) {
  .modal-inicio-sesion {
    padding: 1.3rem 0.7rem 1.2rem 0.7rem;
    max-width: 90vw;
  }
  .titulo-modal {
    font-size: 1.15rem;
  }
  .boton-cerrar {
    top: 0.6rem;
    right: 0.7rem;
    font-size: 1.4rem;
  }
}
</style>
