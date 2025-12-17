<script lang="ts">
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';

  let cargando = true;
  let guardando = false;
  let mensaje = '';
  let perfilData: any = null;
  let membresiaActual: any = null;
  let historialPagos: any[] = [];

  let configuraciones = {
    notificaciones_email: true,
    notificaciones_push: true,
    publico_perfil: true
  };

  let mostrarModalEliminar = false;
  let mostrarFormularioContrasena = false;
  let correoRecuperar = '';
  let cargandoRecuperar = false;
  let mensajeRecuperar = '';
  let confirmacionEliminar = '';

  let datosPersonales = {
    nombre_completo: '',
    correo_electronico: '',
    whatsapp: '',
    ciudad: '',
    fecha_creacion: ''
  };

  async function cargarDatosUsuario() {
    if (!$usuario?.id) return;

    try {
      cargando = true;

      const { data: perfil, error: errorPerfil } = await supabase
        .from('perfiles')
        .select('*')
        .eq('id', $usuario.id)
        .single();

      if (errorPerfil) throw errorPerfil;
      perfilData = perfil;

      if (perfil?.suscripcion && perfil.suscripcion !== 'free') {
        const { data: membresia } = await supabase
          .from('membresias')
          .select('*')
          .eq('nombre', perfil.suscripcion)
          .single();
        membresiaActual = membresia;
      }

      const { data: pagos } = await supabase
        .from('pagos_epayco')
        .select('*')
        .eq('usuario_id', $usuario.id)
        .eq('estado', 'Aceptada')
        .order('created_at', { ascending: false })
        .limit(3);

      historialPagos = pagos || [];

      configuraciones = {
        notificaciones_email: perfil.notificaciones_email ?? true,
        notificaciones_push: perfil.notificaciones_push ?? true,
        publico_perfil: perfil.publico_perfil ?? true
      };

      datosPersonales = {
        nombre_completo: perfil.nombre_completo || '',
        correo_electronico: perfil.correo_electronico || '',
        whatsapp: perfil.whatsapp || '',
        ciudad: perfil.ciudad || perfil.pais || '',
        fecha_creacion: new Date(perfil.fecha_creacion).toLocaleDateString('es-ES')
      };

      correoRecuperar = perfil.correo_electronico || '';

    } catch (error) {
      console.error('Error cargando datos:', error);
      mensaje = 'Error cargando la configuración';
    } finally {
      cargando = false;
    }
  }

  async function guardarConfiguracion() {
    if (!$usuario?.id) return;
    
    guardando = true;
    
    try {
      const { error } = await supabase
        .from('perfiles')
        .update(configuraciones)
        .eq('id', $usuario.id);

      if (error) throw error;

      mensaje = '¡Configuración guardada exitosamente!';
      perfilStore.actualizarPerfil(configuraciones);
    } catch (error: any) {
      mensaje = 'Error al guardar configuración: ' + error.message;
    } finally {
      guardando = false;
      setTimeout(() => mensaje = '', 3000);
    }
  }

  async function enviarRecuperacionContrasena() {
    if (!correoRecuperar) return;

    cargandoRecuperar = true;
    mensajeRecuperar = '';

    try {
      const { error } = await supabase.auth.resetPasswordForEmail(correoRecuperar, {
        redirectTo: window.location.origin + '/recuperar-contrasena'
      });

      if (error) throw error;
      
      mensajeRecuperar = '¡Revisa tu correo para restablecer la contraseña!';
      mostrarFormularioContrasena = false;
    } catch (error: any) {
      mensajeRecuperar = 'Error: ' + error.message;
    } finally {
      cargandoRecuperar = false;
    }
  }

  async function eliminarCuenta() {
    if (confirmacionEliminar !== 'ELIMINAR MI CUENTA') {
      mensaje = 'Debes escribir exactamente "ELIMINAR MI CUENTA" para confirmar';
      return;
    }

    if (!$usuario?.id) return;

    try {
      const { error } = await supabase
        .from('perfiles')
        .update({ eliminado: true })
        .eq('id', $usuario.id);

      if (error) throw error;

      await supabase.auth.signOut();
      perfilStore.resetear();
      goto('/sesion_cerrada');
    } catch (error: any) {
      mensaje = 'Error al eliminar cuenta: ' + error.message;
    }
  }

  async function cerrarSesion() {
    const { error } = await supabase.auth.signOut();
    if (!error) {
      perfilStore.resetear();
      goto('/sesion_cerrada');
    }
  }

  function formatearPrecio(precio: number): string {
    return new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency: 'COP',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(precio);
  }

  function formatearFecha(fecha: string): string {
    return new Date(fecha).toLocaleDateString('es-ES', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  }

  onMount(() => {
    cargarDatosUsuario();
  });
</script>

<svelte:head>
  <title>Configuración - Academia Vallenata</title>
</svelte:head>

<div class="contenido-configuracion">
  {#if cargando}
    <div class="estado-carga">
      <div class="spinner"></div>
      <p>Cargando configuración...</p>
    </div>
  {:else}
    <div class="header">
      <h1>⚙️ Configuración</h1>
      <p>Administra tu cuenta y preferencias</p>
    </div>

    <div class="grid">
      <!-- Información de cuenta -->
      <div class="seccion">
        <h2>👤 Mi cuenta</h2>
        <div class="info">
          <div class="campo">
            <span>Nombre:</span>
            <span>{datosPersonales.nombre_completo || 'No especificado'}</span>
          </div>
          <div class="campo">
            <span>Email:</span>
            <span>{datosPersonales.correo_electronico || 'No especificado'}</span>
          </div>
          <div class="campo">
            <span>WhatsApp:</span>
            <span>{datosPersonales.whatsapp || 'No especificado'}</span>
          </div>
          <div class="campo">
            <span>Ubicación:</span>
            <span>{datosPersonales.ciudad || 'No especificado'}</span>
          </div>
          <div class="campo">
            <span>Miembro desde:</span>
            <span>{datosPersonales.fecha_creacion}</span>
          </div>
        </div>
        <a href="/mi-perfil" class="boton-secundario">✏️ Editar información</a>
      </div>

      <!-- Membresía -->
      <div class="seccion">
        <h2>💎 Mi membresía</h2>
        {#if membresiaActual}
          <div class="tarjeta-membresia" style="border-color: {membresiaActual.color_hex}">
            <div class="icono" style="background: {membresiaActual.color_hex}">
              {membresiaActual.icono}
            </div>
            <div>
              <h3>{membresiaActual.nombre}</h3>
              <p>{membresiaActual.descripcion}</p>
              <div class="precio">{formatearPrecio(membresiaActual.precio_mensual)}/mes</div>
            </div>
          </div>
        {:else}
          <div class="membresia-gratuita">
            <div class="icono">🎵</div>
            <div>
              <h3>Plan Gratuito</h3>
              <p>Acceso limitado a contenido gratuito</p>
            </div>
          </div>
        {/if}
        <a href="/membresias" class="boton-principal">
          {membresiaActual ? '🔄 Cambiar plan' : '⬆️ Mejorar plan'}
        </a>
      </div>

      <!-- Historial de pagos -->
      {#if historialPagos.length > 0}
        <div class="seccion">
          <h2>💳 Pagos recientes</h2>
          <div class="lista-pagos">
            {#each historialPagos as pago}
              <div class="pago">
                <div>
                  <span class="producto">{pago.nombre_producto}</span>
                  <span class="fecha">{formatearFecha(pago.created_at)}</span>
                </div>
                <span class="precio">{formatearPrecio(pago.valor)}</span>
              </div>
            {/each}
          </div>
        </div>
      {/if}

      <!-- Notificaciones -->
      <div class="seccion">
        <h2>🔔 Notificaciones</h2>
        <div class="opciones">
          <label class="toggle-opcion">
            <input type="checkbox" bind:checked={configuraciones.notificaciones_email} />
            <span class="toggle"></span>
            <div>
              <span class="titulo">Notificaciones por email</span>
              <span class="desc">Recibe actualizaciones importantes</span>
            </div>
          </label>
          
          <label class="toggle-opcion">
            <input type="checkbox" bind:checked={configuraciones.notificaciones_push} />
            <span class="toggle"></span>
            <div>
              <span class="titulo">Notificaciones push</span>
              <span class="desc">Notificaciones en tiempo real</span>
            </div>
          </label>
        </div>
      </div>

      <!-- Privacidad -->
      <div class="seccion">
        <h2>🔒 Privacidad</h2>
        <div class="opciones">
          <label class="toggle-opcion">
            <input type="checkbox" bind:checked={configuraciones.publico_perfil} />
            <span class="toggle"></span>
            <div>
              <span class="titulo">Perfil público</span>
              <span class="desc">Otros usuarios pueden ver tu perfil</span>
            </div>
          </label>
        </div>
      </div>

      <!-- Seguridad -->
      <div class="seccion">
        <h2>🔐 Seguridad</h2>
        <div class="opciones">
          {#if !mostrarFormularioContrasena}
            <button class="boton-secundario" on:click={() => mostrarFormularioContrasena = true}>
              🔑 Restablecer contraseña
            </button>
          {:else}
            <div class="formulario">
              <h4>Restablecer contraseña</h4>
              <p>Te enviaremos un enlace para cambiar tu contraseña</p>
              <input type="email" bind:value={correoRecuperar} placeholder="Confirma tu email" />
              <div class="botones">
                <button class="boton-principal" on:click={enviarRecuperacionContrasena} disabled={cargandoRecuperar}>
                  {cargandoRecuperar ? 'Enviando...' : 'Enviar enlace'}
                </button>
                <button class="boton-cancelar" on:click={() => {mostrarFormularioContrasena = false; mensajeRecuperar = '';}}>
                  Cancelar
                </button>
              </div>
              {#if mensajeRecuperar}
                <div class="mensaje-recuperar" class:exito={mensajeRecuperar.includes('Revisa')}>
                  {mensajeRecuperar}
                </div>
              {/if}
            </div>
          {/if}
        </div>
      </div>

      <!-- Acciones -->
      <div class="seccion">
        <h2>⚙️ Acciones</h2>
        <div class="acciones">
          <button class="boton-warning" on:click={cerrarSesion}>🚪 Cerrar sesión</button>
          <button class="boton-danger" on:click={() => mostrarModalEliminar = true}>🗑️ Eliminar cuenta</button>
        </div>
      </div>
    </div>

    <!-- Botón guardar -->
    <div class="acciones-principales">
      <button class="boton-guardar" on:click={guardarConfiguracion} disabled={guardando}>
        {guardando ? 'Guardando...' : '💾 Guardar configuración'}
      </button>
    </div>

    <!-- Mensajes -->
    {#if mensaje}
      <div class="mensaje" class:exito={mensaje.includes('exitosamente')} class:error={mensaje.includes('Error')}>
        {mensaje}
      </div>
    {/if}
  {/if}
</div>

<!-- Modal eliminar cuenta -->
{#if mostrarModalEliminar}
  <div class="modal-fondo" on:click={() => mostrarModalEliminar = false}>
    <div class="modal" on:click={(e) => e.stopPropagation()}>
      <h3>⚠️ Eliminar cuenta</h3>
      <p>Esta acción <strong>NO se puede deshacer</strong>. Perderás acceso a todos tus cursos y datos.</p>
      
      <div class="campo-confirmacion">
        <label>Para confirmar, escribe: <strong>ELIMINAR MI CUENTA</strong></label>
        <input type="text" bind:value={confirmacionEliminar} placeholder="Escribe: ELIMINAR MI CUENTA" />
      </div>

      <div class="botones">
        <button class="boton-cancelar" on:click={() => mostrarModalEliminar = false}>Cancelar</button>
        <button class="boton-danger" on:click={eliminarCuenta} disabled={confirmacionEliminar !== 'ELIMINAR MI CUENTA'}>
          Eliminar cuenta
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  .contenido-configuracion {
    padding: 2rem;
    max-width: 100%;
    margin: 0 auto;
  }

  .estado-carga {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding: 4rem 2rem;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .header {
    margin-bottom: 2rem;
    text-align: center;
  }

  .header h1 {
    font-size: 2rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }

  .header p {
    color: #6b7280;
    font-size: 1.1rem;
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  .seccion {
    background: #ffffff;
    border-radius: 12px;
    padding: 1.5rem;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
    border: 1px solid #e5e7eb;
  }

  .seccion h2 {
    font-size: 1.2rem;
    font-weight: 600;
    color: #1f2937;
    margin-bottom: 1rem;
    padding-bottom: 0.5rem;
    border-bottom: 1px solid #f3f4f6;
  }

  .info {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    margin-bottom: 1rem;
  }

  .campo {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.5rem 0;
  }

  .campo span:first-child {
    font-weight: 600;
    color: #374151;
  }

  .campo span:last-child {
    color: #6b7280;
    text-align: right;
    max-width: 60%;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .tarjeta-membresia, .membresia-gratuita {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    border: 2px solid #d1d5db;
    border-radius: 8px;
    margin-bottom: 1rem;
  }

  .tarjeta-membresia {
    background: linear-gradient(135deg, rgba(255,255,255,0.9), rgba(248,250,252,0.9));
  }

  .membresia-gratuita {
    background: #f9fafb;
  }

  .icono {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.2rem;
    color: white;
    background: #64748b;
    flex-shrink: 0;
  }

  .tarjeta-membresia h3, .membresia-gratuita h3 {
    font-size: 1.1rem;
    font-weight: 600;
    margin-bottom: 0.25rem;
    color: #1f2937;
  }

  .tarjeta-membresia p, .membresia-gratuita p {
    color: #6b7280;
    margin-bottom: 0.5rem;
    font-size: 0.9rem;
  }

  .precio {
    font-weight: 600;
    color: #059669;
  }

  .lista-pagos {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .pago {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.75rem;
    background: #f9fafb;
    border-radius: 6px;
  }

  .producto {
    font-weight: 600;
    color: #1f2937;
    display: block;
  }

  .fecha {
    font-size: 0.8rem;
    color: #6b7280;
    display: block;
  }

  .pago .precio {
    font-weight: 600;
    color: #059669;
  }

  .opciones {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .toggle-opcion {
    display: flex;
    align-items: flex-start;
    gap: 0.75rem;
    cursor: pointer;
  }

  .toggle {
    position: relative;
    width: 40px;
    height: 22px;
    background: #d1d5db;
    border-radius: 11px;
    transition: background 0.2s ease;
    flex-shrink: 0;
    margin-top: 2px;
  }

  .toggle::after {
    content: '';
    position: absolute;
    top: 2px;
    left: 2px;
    width: 18px;
    height: 18px;
    background: white;
    border-radius: 50%;
    transition: transform 0.2s ease;
  }

  .toggle-opcion input:checked + .toggle {
    background: #3b82f6;
  }

  .toggle-opcion input:checked + .toggle::after {
    transform: translateX(18px);
  }

  .toggle-opcion input {
    display: none;
  }

  .titulo {
    font-weight: 600;
    color: #1f2937;
    display: block;
  }

  .desc {
    font-size: 0.85rem;
    color: #6b7280;
    display: block;
  }

  .formulario {
    background: #f9fafb;
    padding: 1rem;
    border-radius: 6px;
    border: 1px solid #e5e7eb;
  }

  .formulario h4 {
    margin-bottom: 0.5rem;
    color: #1f2937;
  }

  .formulario p {
    color: #6b7280;
    margin-bottom: 1rem;
    font-size: 0.9rem;
  }

  .formulario input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    margin-bottom: 1rem;
  }

  .botones {
    display: flex;
    gap: 0.75rem;
    flex-wrap: wrap;
  }

  .acciones {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .boton-principal, .boton-secundario, .boton-warning, .boton-danger, .boton-cancelar, .boton-guardar {
    padding: 0.75rem 1rem;
    border-radius: 6px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s ease;
    border: none;
    text-decoration: none;
    text-align: center;
    display: inline-block;
  }

  .boton-principal {
    background: #3b82f6;
    color: white;
  }

  .boton-principal:hover:not(:disabled) {
    background: #2563eb;
  }

  .boton-secundario {
    background: #f3f4f6;
    color: #374151;
    border: 1px solid #d1d5db;
  }

  .boton-secundario:hover {
    background: #e5e7eb;
  }

  .boton-warning {
    background: #fef3c7;
    color: #92400e;
    border: 1px solid #fbbf24;
  }

  .boton-warning:hover {
    background: #fde68a;
  }

  .boton-danger {
    background: #fee2e2;
    color: #991b1b;
    border: 1px solid #fca5a5;
  }

  .boton-danger:hover:not(:disabled) {
    background: #fecaca;
  }

  .boton-danger:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .boton-cancelar {
    background: transparent;
    color: #6b7280;
    border: 1px solid #d1d5db;
  }

  .boton-cancelar:hover {
    background: #f3f4f6;
  }

  .acciones-principales {
    display: flex;
    justify-content: center;
    margin: 2rem 0;
  }

  .boton-guardar {
    background: linear-gradient(135deg, #059669, #047857);
    color: white;
    padding: 1rem 2rem;
    font-size: 1.1rem;
    font-weight: 600;
    box-shadow: 0 4px 12px rgba(5, 150, 105, 0.2);
  }

  .boton-guardar:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 6px 20px rgba(5, 150, 105, 0.3);
  }

  .boton-guardar:disabled {
    opacity: 0.7;
    cursor: not-allowed;
    transform: none;
  }

  .mensaje {
    margin: 1rem auto;
    padding: 1rem;
    border-radius: 6px;
    text-align: center;
    max-width: 600px;
  }

  .mensaje.exito {
    background: #d1fae5;
    color: #065f46;
    border: 1px solid #a7f3d0;
  }

  .mensaje.error {
    background: #fee2e2;
    color: #991b1b;
    border: 1px solid #fca5a5;
  }

  .mensaje-recuperar {
    margin-top: 0.5rem;
    padding: 0.75rem;
    border-radius: 6px;
    font-size: 0.875rem;
  }

  .mensaje-recuperar.exito {
    background: #d1fae5;
    color: #065f46;
  }

  .mensaje-recuperar:not(.exito) {
    background: #fee2e2;
    color: #991b1b;
  }

  .modal-fondo {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 9999;
  }

  .modal {
    background: white;
    padding: 1.5rem;
    border-radius: 8px;
    max-width: 450px;
    width: 90%;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  }

  .modal h3 {
    color: #dc2626;
    margin-bottom: 1rem;
  }

  .modal p {
    color: #374151;
    margin-bottom: 1rem;
    line-height: 1.4;
  }

  .campo-confirmacion {
    margin-bottom: 1rem;
  }

  .campo-confirmacion label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 600;
    color: #374151;
    font-size: 0.9rem;
  }

  .campo-confirmacion input {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #d1d5db;
    border-radius: 6px;
  }

  @media (max-width: 768px) {
    .contenido-configuracion {
      padding: 1rem;
    }

    .grid {
      grid-template-columns: 1fr;
      gap: 1rem;
    }

    .seccion {
      padding: 1rem;
    }

    .header h1 {
      font-size: 1.75rem;
    }

    .campo {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.25rem;
    }

    .campo span:last-child {
      text-align: left;
      max-width: none;
    }

    .tarjeta-membresia, .membresia-gratuita {
      flex-direction: column;
      text-align: center;
    }

    .pago {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.5rem;
    }

    .botones {
      flex-direction: column;
    }

    .modal {
      margin: 1rem;
      padding: 1rem;
    }
  }
</style> 