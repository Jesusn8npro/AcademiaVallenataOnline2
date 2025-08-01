<script lang="ts">
  import { registrarUsuario, iniciarSesionConCorreo, obtenerPerfil } from '$lib/supabase/autenticacionSupabase';
  import { setUsuario } from '$lib/UsuarioActivo/usuario';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { actividadService } from '$lib/services/actividadTiempoRealService';
  import { trackearUbicacionUsuario } from '$lib/services/geoLocationService';
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
  
  // Estados para mostrar/ocultar contraseñas
  let mostrarContrasena = false;
  let mostrarContrasenaRegistro = false;
  
  // Selector de país para WhatsApp
  let codigoPais = '+57'; // Colombia por defecto
  
  // Lista de países comunes
  const paises = [
    { codigo: '+57', nombre: 'Colombia', bandera: '🇨🇴' },
    { codigo: '+52', nombre: 'México', bandera: '🇲🇽' },
    { codigo: '+1', nombre: 'Estados Unidos', bandera: '🇺🇸' },
    { codigo: '+34', nombre: 'España', bandera: '🇪🇸' },
    { codigo: '+54', nombre: 'Argentina', bandera: '🇦🇷' },
    { codigo: '+56', nombre: 'Chile', bandera: '🇨🇱' },
    { codigo: '+51', nombre: 'Perú', bandera: '🇵🇪' },
    { codigo: '+58', nombre: 'Venezuela', bandera: '🇻🇪' },
    { codigo: '+593', nombre: 'Ecuador', bandera: '🇪🇨' },
    { codigo: '+507', nombre: 'Panamá', bandera: '🇵🇦' }
  ];

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
    mostrarContrasena = false;
    mostrarContrasenaRegistro = false;
    codigoPais = '+57';
    // Limpiar campos de registro
    nombre = '';
    apellido = '';
    whatsapp = '';
    correoRegistro = '';
    contrasenaRegistro = '';
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
      
      // 🚀 REGISTRAR ACTIVIDAD DE LOGIN
      try {
        const ahora = new Date().toISOString();
        
        // Actualizar timestamp en perfiles
        await supabase
          .from('perfiles')
          .update({ updated_at: ahora })
          .eq('id', perfil.id);
        
        // 🔥 CONSULTAR TIEMPO HISTÓRICO TOTAL DEL USUARIO
        let tiempoHistoricoTotal = 0;
        let sesionesTotalesHistoricas = 0;
        
        // Sumar TODAS las sesiones anteriores del usuario
        const { data: sesionesAnteriores } = await supabase
          .from('sesiones_usuario')
          .select('tiempo_total_minutos, sesiones_totales')
          .eq('usuario_id', perfil.id)
          .neq('fecha', ahora.split('T')[0]); // Todas las fechas ANTERIORES
        
        if (sesionesAnteriores && sesionesAnteriores.length > 0) {
          // Sumar tiempo total histórico
          tiempoHistoricoTotal = sesionesAnteriores.reduce((total, sesion) => {
            return total + (sesion.tiempo_total_minutos || 0);
          }, 0);
          
          // Sumar sesiones totales históricas
          sesionesTotalesHistoricas = sesionesAnteriores.reduce((total, sesion) => {
            return total + (sesion.sesiones_totales || 0);
          }, 0);
          
          console.log('📊 [LOGIN] Tiempo histórico encontrado:', tiempoHistoricoTotal, 'min de', sesionesAnteriores.length, 'días');
        }
        
        // Verificar si ya existe sesión HOY
        const { data: sesionHoy } = await supabase
          .from('sesiones_usuario')
          .select('tiempo_total_minutos, sesiones_totales, esta_activo')
          .eq('usuario_id', perfil.id)
          .eq('fecha', ahora.split('T')[0])
          .single();
        
        let tiempoTotalFinal = tiempoHistoricoTotal + 1; // +1 min por esta sesión
        let sesionesTotalesFinal = sesionesTotalesHistoricas + 1;
        
        if (sesionHoy) {
          // Si ya hay sesión hoy, preservar el tiempo de hoy y sumar al histórico
          tiempoTotalFinal = tiempoHistoricoTotal + (sesionHoy.tiempo_total_minutos || 0) + 1;
          
          // Solo incrementar sesiones si estaba inactivo
          if (!sesionHoy.esta_activo) {
            sesionesTotalesFinal = sesionesTotalesHistoricas + (sesionHoy.sesiones_totales || 0) + 1;
          } else {
            sesionesTotalesFinal = sesionesTotalesHistoricas + (sesionHoy.sesiones_totales || 0);
          }
          
          console.log('📊 [LOGIN] Reanudando sesión. Tiempo total:', tiempoTotalFinal, 'min');
        } else {
          console.log('📊 [LOGIN] Nueva sesión del día. Tiempo total:', tiempoTotalFinal, 'min');
        }

        // Crear/actualizar sesión con tiempo acumulado REAL
        await supabase
          .from('sesiones_usuario')
          .upsert({
            usuario_id: perfil.id,
            fecha: ahora.split('T')[0],
            ultima_actividad: ahora,
            pagina_actual: window.location.pathname,
            esta_activo: true,
            tiempo_sesion_actual: 1,
            tiempo_total_minutos: tiempoTotalFinal, // ✅ TIEMPO HISTÓRICO TOTAL
            sesiones_totales: sesionesTotalesFinal, // ✅ SESIONES HISTÓRICAS TOTALES
            updated_at: ahora
          }, {
            onConflict: 'usuario_id,fecha'
          });
        
        // Inicializar tracking si está disponible
        await actividadService.inicializarTracking(perfil.id, window.location.pathname);
        console.log('✅ [LOGIN] Sesión y actividad registrada para:', perfil.nombre);

        // 🌍 TRACKING DE GEOLOCALIZACIÓN AUTOMÁTICO
        try {
          console.log('🌍 [AUTH] Iniciando tracking de geolocalización...');
          const datosGeo = await trackearUbicacionUsuario(perfil.id);
          if (datosGeo) {
            console.log(`✅ [AUTH] Ubicación detectada: ${datosGeo.ciudad}, ${datosGeo.pais} (${datosGeo.ip})`);
          }
        } catch (geoError) {
          console.warn('⚠️ [AUTH] Error en geolocalización (no crítico):', geoError);
          // No interrumpir el login por errores de geolocalización
        }

      } catch (error) {
        console.warn('⚠️ [LOGIN] Error registrando actividad:', error);
      }
      
      cerrarModal();
      // Redirección explícita según el rol
      if (perfil.rol && perfil.rol.toLowerCase() === 'admin') {
        goto('/panel-administracion');
      } else {
        goto('/panel-estudiante');
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
      { nombre, apellido, whatsapp: `${codigoPais}${whatsapp}` }
    );
    cargando = false;
    if (error) {
      errorLogin = error;
      return;
    }
    if (usuario) {
      setUsuario(usuario); // Guardar usuario global
      
      // 🚀 REGISTRAR ACTIVIDAD DE REGISTRO
      try {
        // Actualizar updated_at en perfiles para detectar actividad
        await supabase
          .from('perfiles')
          .update({ updated_at: new Date().toISOString() })
          .eq('id', usuario.id);
        
        // Inicializar tracking si está disponible
        await actividadService.inicializarTracking(usuario.id, window.location.pathname);
        console.log('✅ [REGISTRO] Actividad registrada para usuario:', usuario.nombre);
      } catch (error) {
        console.warn('⚠️ [REGISTRO] Error registrando actividad:', error);
      }
      
      // Redirección explícita según el rol
      if (usuario.rol && usuario.rol.toLowerCase() === 'admin') {
        cerrarModal();
        goto('/panel-administracion');
        return;
      }
    }
    cerrarModal();
    goto('/panel-estudiante');
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
      <div class="modal-header">
        <div class="logo-container">
          <img src="/logo academia vallenata.png" alt="Logo Academia Vallenata" class="logo-modal" />
        </div>
        <button class="boton-cerrar" aria-label="Cerrar" on:click={cerrarModal}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M18 6L6 18M6 6l12 12" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      </div>
      {#if vistaRecuperar}
        <h2 class="titulo-modal">Recuperar contraseña</h2>
        <p class="login-desc">Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.</p>
        <form class="formulario-inicio-sesion" on:submit={enviarRecuperacion}>
          <div class="campo-formulario">
            <label for="recuperarCorreo">Correo electrónico</label>
            <div class="input-icono">
              <input id="recuperarCorreo" type="email" bind:value={correoRecuperar} placeholder="ejemplo@correo.com" required />
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
              <input id="usuario" type="text" bind:value={usuario} placeholder="ejemplo@correo.com o usuario" required />
              <span class="icono-input">📧</span>
            </div>
          </div>
          <div class="campo-formulario">
            <label for="contrasena">Contraseña</label>
            <div class="input-icono">
              <input 
                id="contrasena" 
                type={mostrarContrasena ? 'text' : 'password'} 
                bind:value={contrasena} 
                placeholder="Tu contraseña" 
                required 
              />
              <button 
                type="button" 
                class="boton-mostrar-contrasena"
                on:click={() => mostrarContrasena = !mostrarContrasena}
                aria-label={mostrarContrasena ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              >
                {mostrarContrasena ? '👁️' : '🙈'}
              </button>
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
              <div class="input-icono">
                <input id="nombre" type="text" bind:value={nombre} placeholder="Tu nombre" required />
                <span class="icono-input">👤</span>
              </div>
            </div>
            <div class="campo-formulario">
              <label for="apellido">Apellido</label>
              <div class="input-icono">
                <input id="apellido" type="text" bind:value={apellido} placeholder="Tu apellido" required />
                <span class="icono-input">👤</span>
              </div>
            </div>
          </div>
          <div class="campo-formulario">
            <label for="whatsapp">WhatsApp</label>
            <div class="input-whatsapp">
              <select class="selector-pais" bind:value={codigoPais}>
                {#each paises as pais}
                  <option value={pais.codigo}>
                    {pais.bandera} {pais.codigo}
                  </option>
                {/each}
              </select>
              <div class="input-numero">
                <input 
                  id="whatsapp" 
                  type="tel" 
                  bind:value={whatsapp} 
                  placeholder="Número sin código de país" 
                  required 
                />
                <span class="icono-input">📱</span>
              </div>
            </div>
          </div>
          <div class="campo-formulario">
            <label for="correoRegistro">Correo electrónico</label>
            <div class="input-icono">
              <input id="correoRegistro" type="email" bind:value={correoRegistro} placeholder="ejemplo@correo.com" required />
              <span class="icono-input">📧</span>
            </div>
          </div>
          <div class="campo-formulario">
            <label for="contrasenaRegistro">Contraseña</label>
            <div class="input-icono">
              <input 
                id="contrasenaRegistro" 
                type={mostrarContrasenaRegistro ? 'text' : 'password'} 
                bind:value={contrasenaRegistro} 
                placeholder="Crea una contraseña segura" 
                required 
              />
              <button 
                type="button" 
                class="boton-mostrar-contrasena"
                on:click={() => mostrarContrasenaRegistro = !mostrarContrasenaRegistro}
                aria-label={mostrarContrasenaRegistro ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              >
                {mostrarContrasenaRegistro ? '👁️' : '🙈'}
              </button>
            </div>
          </div>
          {#if errorLogin}
            <div class="mensaje-error">{errorLogin}</div>
          {/if}
          <button type="submit" class="boton-enviar" disabled={cargando}>
            {cargando ? 'Registrando...' : 'Registrarme'}
          </button>
        </form>
        <div class="enlaces-extra">
          <button type="button" class="enlace-olvido" on:click={() => vistaRegistro = false}>¿Ya tienes cuenta? <b>Inicia sesión</b></button>
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
  /* === VARIABLES CSS === */
  :root {
    --modal-primary: #ff6600;
    --modal-primary-hover: #e55a00;
    --modal-secondary: #1a73e8;
    --modal-bg: #ffffff;
    --modal-bg-gradient: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
    --modal-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    --modal-shadow-hover: 0 35px 60px -12px rgba(0, 0, 0, 0.35);
    --modal-border-radius: 24px;
    --input-bg: #f8fafc;
    --input-border: #e2e8f0;
    --input-focus: #3b82f6;
    --text-primary: #1e293b;
    --text-secondary: #64748b;
    --error-bg: #fef2f2;
    --error-color: #dc2626;
    --success-bg: #f0fdf4;
    --success-color: #16a34a;
  }

  /* === FONDO MODAL === */
  .fondo-modal {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: rgba(0, 0, 0, 0.6);
    backdrop-filter: blur(8px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 9999;
    opacity: 0;
    animation: fadeIn 0.3s ease-out forwards;
    padding: 16px;
  }

  /* === MODAL PRINCIPAL === */
  .modal-inicio-sesion {
    width: 100%;
    max-width: 420px;
    background: var(--modal-bg-gradient);
    border-radius: var(--modal-border-radius);
    box-shadow: var(--modal-shadow);
    padding: 0;
    position: relative;
    display: flex;
    flex-direction: column;
    transform: translateY(30px);
    opacity: 0;
    animation: slideInUp 0.4s cubic-bezier(0.16, 1, 0.3, 1) 0.1s forwards;
    overflow: hidden;
    border: 1px solid rgba(255, 255, 255, 0.2);
  }

  /* === HEADER DEL MODAL === */
  .modal-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 24px 32px 16px;
    border-bottom: 1px solid rgba(226, 232, 240, 0.3);
    background: linear-gradient(135deg, rgba(255, 102, 0, 0.03) 0%, rgba(255, 102, 0, 0.08) 100%);
  }

  .logo-container {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .logo-modal {
    width: 56px;
    height: 56px;
    border-radius: 50%;
    box-shadow: 0 4px 12px rgba(255, 102, 0, 0.2);
    transition: transform 0.3s ease;
  }

  .logo-modal:hover {
    transform: scale(1.05);
  }

  .boton-cerrar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    border: none;
    background: rgba(255, 102, 0, 0.1);
    color: var(--modal-primary);
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .boton-cerrar:hover {
    background: var(--modal-primary);
    color: white;
    transform: scale(1.05);
  }

  /* === CONTENIDO DEL MODAL === */
  .titulo-modal {
    font-size: 1.875rem;
    font-weight: 800;
    background: linear-gradient(135deg, var(--modal-primary) 0%, #ff8c42 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    margin: 24px 32px 8px;
    text-align: center;
    line-height: 1.2;
  }

  .login-desc {
    color: var(--text-secondary);
    font-size: 1rem;
    margin: 0 32px 32px;
    text-align: center;
    line-height: 1.5;
  }

  /* === FORMULARIO === */
  .formulario-inicio-sesion {
    display: flex;
    flex-direction: column;
    gap: 20px;
    padding: 0 32px 32px;
  }

  .fila-nombre-apellido {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
  }

  .campo-formulario {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .campo-formulario label {
    font-size: 0.875rem;
    color: var(--text-primary);
    font-weight: 600;
    margin-left: 4px;
  }

  /* === INPUTS MEJORADOS === */
  .input-icono {
    position: relative;
    display: flex;
    align-items: center;
    background: var(--input-bg);
    border: 2px solid var(--input-border);
    border-radius: 12px;
    padding: 0;
    transition: all 0.3s ease;
    overflow: hidden;
  }

  .input-icono:focus-within {
    border-color: var(--input-focus);
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
    background: white;
  }

  .input-icono input {
    flex: 1;
    border: none;
    background: transparent;
    padding: 16px 16px;
    font-size: 1rem;
    color: var(--text-primary);
    outline: none;
  }

  .input-icono input::placeholder {
    color: var(--text-secondary);
  }

  .icono-input {
    padding: 0 16px;
    font-size: 1.25rem;
    color: var(--modal-primary);
  }

  /* === BOTÓN MOSTRAR CONTRASEÑA === */
  .boton-mostrar-contrasena {
    background: none;
    border: none;
    padding: 16px;
    cursor: pointer;
    font-size: 1.25rem;
    color: var(--text-secondary);
    transition: color 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .boton-mostrar-contrasena:hover {
    color: var(--modal-primary);
  }

  /* === SELECTOR DE PAÍS WHATSAPP === */
  .input-whatsapp {
    display: flex;
    background: var(--input-bg);
    border: 2px solid var(--input-border);
    border-radius: 12px;
    overflow: hidden;
    transition: all 0.3s ease;
  }

  .input-whatsapp:focus-within {
    border-color: var(--input-focus);
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
    background: white;
  }

  .selector-pais {
    background: rgba(255, 102, 0, 0.05);
    border: none;
    padding: 16px 12px;
    font-size: 0.875rem;
    color: var(--text-primary);
    cursor: pointer;
    outline: none;
    min-width: 110px;
    border-right: 1px solid var(--input-border);
  }

  .input-numero {
    flex: 1;
    display: flex;
    align-items: center;
  }

  .input-numero input {
    flex: 1;
    border: none;
    background: transparent;
    padding: 16px;
    font-size: 1rem;
    color: var(--text-primary);
    outline: none;
  }

  /* === BOTÓN PRINCIPAL === */
  .boton-enviar {
    background: linear-gradient(135deg, var(--modal-primary) 0%, #ff8c42 100%);
    color: white;
    border: none;
    border-radius: 12px;
    padding: 16px 24px;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    margin-top: 8px;
    box-shadow: 0 4px 12px rgba(255, 102, 0, 0.3);
    position: relative;
    overflow: hidden;
  }

  .boton-enviar:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 20px rgba(255, 102, 0, 0.4);
  }

  .boton-enviar:active {
    transform: translateY(0);
  }

  .boton-enviar:disabled {
    opacity: 0.6;
    cursor: not-allowed;
    transform: none;
  }

  /* === MENSAJES === */
  .mensaje-error {
    background: var(--error-bg);
    color: var(--error-color);
    border: 1px solid rgba(220, 38, 38, 0.2);
    border-radius: 8px;
    padding: 12px 16px;
    font-size: 0.875rem;
    text-align: center;
    margin: -8px 0 8px;
  }

  /* === ENLACES EXTRA === */
  .enlaces-extra {
    padding: 0 32px 32px;
    display: flex;
    flex-direction: column;
    gap: 12px;
    align-items: center;
    border-top: 1px solid rgba(226, 232, 240, 0.3);
    margin-top: 8px;
    padding-top: 24px;
  }

  .enlace-olvido,
  .enlace-registrarse {
    background: none;
    border: none;
    color: var(--modal-secondary);
    font-size: 0.875rem;
    cursor: pointer;
    transition: all 0.3s ease;
    padding: 8px 16px;
    border-radius: 8px;
    font-family: inherit;
    text-decoration: none;
  }

  .enlace-olvido:hover,
  .enlace-registrarse:hover {
    color: var(--modal-primary);
    background: rgba(255, 102, 0, 0.05);
  }

  /* === ANIMACIONES === */
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  @keyframes slideInUp {
    from {
      opacity: 0;
      transform: translateY(30px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  /* === RESPONSIVE === */
  @media (max-width: 768px) {
    .modal-inicio-sesion {
      max-width: 95vw;
      margin: 8px;
    }

    .modal-header,
    .formulario-inicio-sesion,
    .enlaces-extra {
      padding-left: 20px;
      padding-right: 20px;
    }

    .titulo-modal,
    .login-desc {
      margin-left: 20px;
      margin-right: 20px;
    }

    .fila-nombre-apellido {
      grid-template-columns: 1fr;
      gap: 16px;
    }

    .titulo-modal {
      font-size: 1.5rem;
    }

    .login-desc {
      font-size: 0.875rem;
    }

    .selector-pais {
      min-width: 90px;
      font-size: 0.8rem;
    }
  }

  @media (max-width: 480px) {
    .fondo-modal {
      padding: 8px;
    }

    .modal-header {
      padding: 16px 16px 12px;
    }

    .logo-modal {
      width: 48px;
      height: 48px;
    }

    .titulo-modal {
      font-size: 1.25rem;
      margin: 16px 16px 8px;
    }

    .login-desc {
      margin: 0 16px 24px;
    }

    .formulario-inicio-sesion {
      padding: 0 16px 24px;
      gap: 16px;
    }

    .enlaces-extra {
      padding: 0 16px 24px;
      padding-top: 16px;
    }

    .input-icono input,
    .boton-mostrar-contrasena,
    .selector-pais,
    .input-numero input {
      padding: 14px 12px;
    }

    .boton-enviar {
      padding: 14px 20px;
    }
  }
</style>
