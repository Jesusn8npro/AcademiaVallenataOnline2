<script lang="ts">
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { goto } from '$app/navigation';
  import { cerrarSesion as cerrarSesionSupabase } from '$lib/supabase/autenticacionSupabase';
  import { limpiarUsuario } from '$lib/UsuarioActivo/usuario';
  import ModalBusqueda from '$lib/components/Busqueda/ModalBusqueda.svelte';
  import MenuLateralResponsive from './MenuLateralResponsive.svelte';
  import CampanaNotificaciones from './CampanaNotificaciones.svelte';

  let nombre = '';
  let mostrarMenu = false;
  let mostrarModalBusqueda = false;
  let mostrarMenuLateral = false;
  let cerrandoSesion = false;

  $: if ($usuario) {
    nombre = $usuario.nombre || '';
  }

  async function cerrarSesion() {
    cerrandoSesion = true;
    const error = await cerrarSesionSupabase();
    if (error) {
      cerrandoSesion = false;
      alert('Error al cerrar sesión: ' + error);
      return;
    }
    limpiarUsuario();
    goto('/sesion_cerrada');
  }

  function abrirModalBusqueda() {
    mostrarModalBusqueda = true;
  }

  function cerrarModalBusqueda() {
    mostrarModalBusqueda = false;
  }

  function toggleMenuLateral() {
    mostrarMenuLateral = !mostrarMenuLateral;
  }

  function cerrarMenuLateral() {
    mostrarMenuLateral = false;
  }
</script>

<nav class="menu-superior">
  <!-- Lado Izquierdo: Logo + Hamburguesa -->
  <div class="lado-izquierdo">
    <div class="logo">
      <a href="/administrador">
        <img src="/logo academia vallenata.png" alt="Logo Academia" class="logo-img" />
      </a>
    </div>

    <!-- Botón Hamburguesa Creativo - Solo Móvil -->
    <button class="boton-hamburguesa-lujo" on:click={toggleMenuLateral} aria-label="Menú">
      <div class="hamburguesa-container">
        <div class="hamburguesa-linea linea-1"></div>
        <div class="hamburguesa-linea linea-2"></div>
        <div class="hamburguesa-linea linea-3"></div>
      </div>
      <div class="hamburguesa-fondo"></div>
    </button>
  </div>

  <!-- Menú Central - Solo Desktop -->
  <div class="menu-central">
    <a href="/administrador" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/></svg>
      </span>
      <span>Panel</span>
    </a>
    <a href="/administrador/crear-contenido" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><line x1="12" y1="18" x2="12" y2="12"/><line x1="9" y1="15" x2="15" y2="15"/></svg>
      </span>
      <span>Crear</span>
    </a>
    <a href="/administrador/panel-contenido" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
      </span>
      <span>Contenido</span>
    </a>
    <a href="/cursos" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><rect x="2" y="7" width="20" height="13" rx="2"/><path d="M16 3v4M8 3v4"/></svg>
      </span>
      <span>Cursos</span>
    </a>
    <a href="/administrador/usuarios" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><circle cx="12" cy="7" r="4"/><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/></svg>
      </span>
      <span>Usuarios</span>
    </a>
    <a href="/administrador/blog" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 7h10M7 11h10M7 15h6"/></svg>
      </span>
      <span>Blog</span>
    </a>
    <a href="/administrador/pagos" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><rect x="2" y="7" width="20" height="13" rx="2"/><path d="M2 10h20"/><circle cx="8" cy="15" r="2"/><circle cx="16" cy="15" r="2"/></svg>
      </span>
      <span>Pagos</span>
    </a>
    <a href="/administrador/notificaciones" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
      </span>
      <span>Notificaciones</span>
    </a>
    <a href="/mensajes" class="enlace">
      <span class="icono-enlace-nav">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#222" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
      </span>
      <span>Mensajes</span>
    </a>
  </div>

  <!-- Área Derecha -->
  <div class="area-derecha">
    <!-- Iconos Desktop -->
    <div class="iconos-desktop">
      <button class="icono" aria-label="Buscar" on:click={abrirModalBusqueda}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/>
          <path d="m21 21-4.35-4.35"/>
        </svg>
      </button>
      
      <CampanaNotificaciones esMobile={false} />
    </div>

    <!-- Campana Notificaciones Móvil -->
    <div class="icono-movil">
      <CampanaNotificaciones esMobile={true} />
    </div>
    
    <!-- Menú Usuario -->
    <div class="menu-usuario">
      <button class="boton-usuario" on:click={() => mostrarMenu = !mostrarMenu} on:blur={() => mostrarMenu = false}>
        <span class="nombre">{nombre}</span>
        <img src={$usuario?.url_foto_perfil || '/images/avatar-generico.png'} alt="Avatar" class="avatar" />
      </button>
      
      {#if mostrarMenu}
        <div class="desplegable">
          <div class="header">
            <img src={$usuario?.url_foto_perfil || '/images/avatar-generico.png'} alt="Avatar" class="avatar-grande" />
            <div>
              <div class="nombre-completo">{nombre}</div>
              <div class="rol">{$usuario?.rol === 'admin' ? 'Administrador' : 'Estudiante'}</div>
            </div>
          </div>
          
          <div class="links">
            <a href="/perfil" class="link">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
              Ver Perfil
            </a>
            <a href="/cuenta" class="link">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="3"/>
                <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1 1.51V6a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
              </svg>
              Configuración
            </a>
          </div>
          
          <div class="separador"></div>
          
          <button class="boton-salir" on:mousedown={cerrarSesion} disabled={cerrandoSesion}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
              <polyline points="16 17 21 12 16 7"/>
              <line x1="21" y1="12" x2="9" y2="12"/>
            </svg>
            {cerrandoSesion ? 'Cerrando...' : 'Cerrar Sesión'}
          </button>
        </div>
      {/if}
    </div>
  </div>
</nav>

<!-- Modal de Búsqueda -->
{#if mostrarModalBusqueda}
  <ModalBusqueda abierto={mostrarModalBusqueda} onCerrar={cerrarModalBusqueda} />
{/if}

<!-- Menú Lateral Responsive -->
<MenuLateralResponsive 
  bind:abierto={mostrarMenuLateral} 
  onCerrar={cerrarMenuLateral}
  usuario={$usuario}
  {cerrarSesion}
  {cerrandoSesion}
/>

<style>
.menu-superior {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  padding: 2.3rem 2rem;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  z-index: 1200;
  border-bottom: 1px solid #e5e7eb;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  height: 60px;
}

/* Lado Izquierdo */
.lado-izquierdo {
  display: flex;
  align-items: center;
  gap: 0.8rem;
}

.logo {
  display: flex;
  align-items: center;
}

.logo-img {
  max-width: 90px;
  height: auto;
  object-fit: contain;
}

/* Botón Hamburguesa de Lujo */
.boton-hamburguesa-lujo {
  display: none;
  position: relative;
  width: 42px;
  height: 42px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 3px 12px rgba(102, 126, 234, 0.25);
  overflow: hidden;
}

.boton-hamburguesa-lujo:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.35);
}

.boton-hamburguesa-lujo:active {
  transform: translateY(0);
}

.hamburguesa-fondo {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(45deg, rgba(255,255,255,0.1), rgba(255,255,255,0.3));
  opacity: 0;
  transition: opacity 0.3s ease;
}

.boton-hamburguesa-lujo:hover .hamburguesa-fondo {
  opacity: 1;
}

.hamburguesa-container {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
  gap: 3px;
}

.hamburguesa-linea {
  width: 20px;
  height: 2.5px;
  background: #fff;
  border-radius: 2px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.linea-1 {
  transform-origin: center;
}

.linea-2 {
  width: 16px;
  opacity: 0.9;
}

.linea-3 {
  width: 18px;
  transform-origin: center;
}

.boton-hamburguesa-lujo:hover .linea-1 {
  transform: rotate(5deg);
}

.boton-hamburguesa-lujo:hover .linea-2 {
  width: 20px;
  opacity: 1;
}

.boton-hamburguesa-lujo:hover .linea-3 {
  transform: rotate(-5deg);
}

.menu-central {
  display: flex;
  gap: 1rem;
}

.enlace {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-decoration: none;
  color: #374151;
  font-weight: 500;
  transition: color 0.2s;
  padding: 0.3rem 0.4rem;
  border-radius: 8px;
}

.enlace:hover {
  color: #ff6d1a;
  background: rgba(255, 109, 26, 0.05);
}

.enlace svg {
  width: 20px;
  height: 20px;
  margin-bottom: 0.2rem;
}

.area-derecha {
  display: flex;
  align-items: center;
  gap: 0.8rem;
}

.iconos-desktop {
  display: flex;
  align-items: center;
  gap: 0.6rem;
}

.icono {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
  color: #6b7280;
  position: relative;
}

.icono:hover {
  background: #f3f4f6;
  color: #374151;
}

.icono svg {
  width: 18px;
  height: 18px;
}

.badge .num {
  position: absolute;
  top: -4px;
  right: -4px;
  background: #ff6d1a;
  color: #fff;
  font-size: 0.7rem;
  font-weight: 700;
  border-radius: 50%;
  width: 16px;
  height: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: pulso 2s infinite;
}

/* Iconos Móvil */
.icono-movil {
  display: none;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.2s;
  color: #64748b;
  position: relative;
}

.icono-movil:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
  transform: translateY(-1px);
}

.icono-movil svg {
  width: 20px;
  height: 20px;
}

.num-movil {
  position: absolute;
  top: -6px;
  right: -6px;
  background: #ef4444;
  color: #fff;
  font-size: 0.65rem;
  font-weight: 700;
  border-radius: 50%;
  width: 18px;
  height: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #fff;
  animation: pulso 2s infinite;
}

.menu-usuario {
  position: relative;
}

.boton-usuario {
  display: flex;
  align-items: center;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.2rem 0.4rem;
  border-radius: 1.5rem;
  transition: background 0.15s;
  gap: 0.5rem;
}

.boton-usuario:hover {
  background: #f3f4f6;
}

.nombre {
  font-weight: 600;
  color: #374151;
  font-size: 0.9rem;
}

.avatar {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #e5e7eb;
}

.desplegable {
  position: absolute;
  top: 110%;
  right: 0;
  min-width: 260px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  border: 1px solid #e5e7eb;
  z-index: 1000;
}

.header {
  display: flex;
  align-items: center;
  padding: 0.8rem;
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
  border-radius: 12px 12px 0 0;
  gap: 0.8rem;
}

.avatar-grande {
  width: 45px;
  height: 45px;
  border-radius: 50%;
  object-fit: cover;
}

.nombre-completo {
  font-weight: 600;
  color: #111827;
  font-size: 0.95rem;
}

.rol {
  color: #6b7280;
  font-size: 0.85rem;
}

.links {
  padding: 0.4rem 0;
}

.link {
  display: flex;
  align-items: center;
  padding: 0.6rem 0.8rem;
  color: #374151;
  text-decoration: none;
  transition: background 0.15s;
  gap: 0.6rem;
  font-size: 0.9rem;
}

.link:hover {
  background: #f3f4f6;
}

.link svg {
  width: 16px;
  height: 16px;
  color: #6b7280;
}

.separador {
  height: 1px;
  background: #e5e7eb;
  margin: 0.3rem 0;
}

.boton-salir {
  width: 100%;
  background: none;
  border: none;
  padding: 0.6rem 0.8rem;
  color: #dc2626;
  cursor: pointer;
  transition: background 0.15s;
  text-align: left;
  border-radius: 0 0 12px 12px;
  display: flex;
  align-items: center;
  gap: 0.6rem;
  font-size: 0.9rem;
}

.boton-salir:hover {
  background: #fef2f2;
}

.boton-salir:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.boton-salir svg {
  width: 16px;
  height: 16px;
}

@keyframes pulso {
  0% { transform: scale(1); }
  50% { transform: scale(1.1); }
  100% { transform: scale(1); }
}

/* Responsive */
@media (max-width: 1100px) {
  .menu-central {
    gap: 0.6rem;
  }
  .enlace {
    min-width: 55px;
    max-width: 75px;
    padding: 0.3rem 0.2rem;
  }
  .icono-enlace-nav svg {
    width: 16px;
    height: 16px;
  }
  .enlace span {
    font-size: 0.8rem;
  }
}

@media (max-width: 900px) {
  .menu-superior {
    padding: 2.4rem 0.8rem;
    height: 56px;
  }
  .boton-hamburguesa-lujo {
    display: flex;
  }
  .menu-central {
    display: none !important;
  }
  .iconos-desktop {
    display: none;
  }
  .icono-movil {
    display: flex;
  }
  .nombre {
    display: none;
  }
  .avatar {
    width: 60px;
    height: 60px;
    border: 2px solid #e5e7eb;
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
  }
  .logo-img {
    max-width: 90px;
  }
}

.icono-enlace-nav {
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 0 0.1rem 0;
}

.enlace {
  flex-direction: column;
  align-items: center;
  gap: 0.1rem;
  min-width: 80px;
  max-width: 100px;
}

.enlace span {
  font-size: 0.9rem;
  font-weight: 500;
  color: #222;
  margin-top: 0;
  line-height: 1.2;
}
</style>
