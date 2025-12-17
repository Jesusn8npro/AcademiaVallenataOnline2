<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { goto } from '$app/navigation';
  let nuevaContrasena = '';
  let confirmarContrasena = '';
  let mensaje = '';
  let error = '';
  let cargando = false;
  let exito = false;

  async function cambiarContrasena(e: Event) {
    e.preventDefault();
    mensaje = '';
    error = '';
    if (nuevaContrasena !== confirmarContrasena) {
      error = 'Las contraseñas no coinciden.';
      return;
    }
    cargando = true;
    const { error: err } = await supabase.auth.updateUser({ password: nuevaContrasena });
    cargando = false;
    if (err) {
      error = 'No se pudo cambiar la contraseña. Intenta de nuevo.';
    } else {
      exito = true;
      mensaje = '¡Contraseña cambiada exitosamente! Ahora puedes iniciar sesión.';
      setTimeout(() => {
        goto('/'); // Redirige a inicio, puedes cambiar a /login si tienes esa ruta
      }, 2200);
    }
  }
</script>

<div class="recuperar-bg">
  <div class="recuperar-card animate-in">
    <img src="/logo academia vallenata.png" alt="Logo" class="logo-recuperar" />
    <h2 class="titulo-recuperar">Restablecer contraseña</h2>
    <p class="desc-recuperar">Crea una nueva contraseña para tu cuenta.<br>Por seguridad, elige una contraseña que no uses en otros sitios.</p>
    {#if !exito}
      <form class="form-recuperar" on:submit={cambiarContrasena}>
        <div class="campo-form">
          <label for="nueva">Nueva contraseña</label>
          <input id="nueva" type="password" bind:value={nuevaContrasena} placeholder="Nueva contraseña" required minlength="6" />
        </div>
        <div class="campo-form">
          <label for="confirmar">Confirmar contraseña</label>
          <input id="confirmar" type="password" bind:value={confirmarContrasena} placeholder="Repite la contraseña" required minlength="6" />
        </div>
        {#if error}
          <div class="mensaje-error">{error}</div>
        {/if}
        <button class="boton-recuperar" type="submit" disabled={cargando}>
          {cargando ? 'Cambiando...' : 'Cambiar contraseña'}
        </button>
      </form>
    {/if}
    {#if mensaje}
      <div class="mensaje-exito animate-pop">{mensaje}</div>
    {/if}
  </div>
</div>

<style>
.recuperar-bg {
  min-height: 100vh;
  background: linear-gradient(120deg, #ff6600 0%, #fff7e6 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  animation: fadeInBg 1s;
}
@keyframes fadeInBg {
  from { opacity: 0; }
  to { opacity: 1; }
}
.recuperar-card {
  background: #fff;
  border-radius: 2rem;
  box-shadow: 0 8px 40px #ff660033, 0 1.5px 8px #ff66001a;
  padding: 2.5rem 2rem 2rem 2rem;
  max-width: 370px;
  width: 100%;
  text-align: center;
  position: relative;
  animation: popIn .7s cubic-bezier(.4,1.2,.6,1);
}
@keyframes popIn {
  from { opacity: 0; transform: scale(0.85) translateY(40px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}
.animate-in { animation: popIn .7s cubic-bezier(.4,1.2,.6,1); }
.logo-recuperar {
  width: 70px;
  margin-bottom: 1rem;
  display: block;
  margin-left: auto;
  margin-right: auto;
}
.titulo-recuperar {
  font-size: 1.5rem;
  font-weight: 900;
  color: #ff6600;
  margin-bottom: .5rem;
}
.desc-recuperar {
  color: #444;
  font-size: 1rem;
  margin-bottom: 1.5rem;
}
.form-recuperar {
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
}
.campo-form {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  text-align: left;
}
.campo-form label {
  font-size: 1rem;
  color: #23235b;
  font-weight: 600;
}
.campo-form input {
  border-radius: 10px;
  border: 1.5px solid #eee;
  padding: .7rem 1rem;
  font-size: 1rem;
  background: #f7f7f7;
  margin-top: .3rem;
}
.campo-form input:focus {
  outline: none !important;
  border: none !important;
  box-shadow: none !important;
}
.boton-recuperar {
  background: linear-gradient(90deg, #ff6600, #ff8c42);
  color: #fff;
  border: none;
  border-radius: 30px;
  padding: 1rem;
  font-size: 1.1rem;
  font-weight: 700;
  margin-top: .5rem;
  cursor: pointer;
  box-shadow: 0 2px 12px #ff660033;
  transition: background .2s, transform .2s;
}
.boton-recuperar:hover {
  background: linear-gradient(90deg, #ff8c42, #ff6600);
  transform: scale(1.04);
}
.mensaje-error {
  color: #e74c3c;
  background: #fff3f0;
  border-radius: 8px;
  padding: .5rem .7rem;
  font-size: .98rem;
  margin-bottom: .2rem;
  text-align: center;
  animation: shake .3s;
}
@keyframes shake {
  10%, 90% { transform: translateX(-2px); }
  20%, 80% { transform: translateX(4px); }
  30%, 50%, 70% { transform: translateX(-8px); }
  40%, 60% { transform: translateX(8px); }
}
.mensaje-exito {
  color: #fff;
  background: linear-gradient(90deg, #ff6600, #ff8c42);
  border-radius: 12px;
  padding: 1rem 1.2rem;
  font-size: 1.08rem;
  margin-top: 1.2rem;
  font-weight: 700;
  box-shadow: 0 2px 12px #ff660033;
  animation: popSuccess .5s;
}
@keyframes popSuccess {
  from { opacity: 0; transform: scale(0.7); }
  to { opacity: 1; transform: scale(1); }
}
@media (max-width: 600px) {
  .recuperar-card { padding: 1.2rem .5rem 1.5rem .5rem; }
}
</style> 