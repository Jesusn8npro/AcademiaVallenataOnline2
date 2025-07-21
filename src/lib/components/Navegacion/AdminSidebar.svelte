<script lang="ts">
  import { usuario, limpiarUsuario } from '$lib/UsuarioActivo/usuario';
  import { cerrarSesion as cerrarSesionSupabase } from '$lib/supabase/autenticacionSupabase';
  import { sidebarColapsado } from '$lib/stores/sidebarStore';
  import ModalBusqueda from '$lib/components/Busqueda/ModalBusqueda.svelte';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';

  let colapsado = false;
  let menuPerfilAbierto = false;
  let modalBusquedaAbierto = false;

  // Determinar el tipo de usuario
  $: tipoUsuario = $usuario?.rol === 'admin' ? 'admin' : 'estudiante';
  $: nombreUsuario = $usuario?.nombre || 'Usuario';
  $: avatarUsuario = $usuario?.url_foto_perfil || '/images/avatar-generico.png';

  function alternarBarraLateral() {
    colapsado = !colapsado;
    sidebarColapsado.set(colapsado);
  }

  function alternarMenuPerfil(evento: Event) {
    evento.stopPropagation();
    menuPerfilAbierto = !menuPerfilAbierto;
  }

  async function cerrarSesionCompleta() {
    await cerrarSesionSupabase();
    limpiarUsuario();
    goto('/');
  }

  function irAPerfil() {
    menuPerfilAbierto = false;
    goto('/mi-perfil');
  }

  function irACursos() {
    menuPerfilAbierto = false;
    goto(tipoUsuario === 'admin' ? '/cursos' : '/mis-cursos');
  }

  function abrirModalBusqueda() {
    modalBusquedaAbierto = true;
  }

  function cerrarModalBusqueda() {
    modalBusquedaAbierto = false;
  }

  onMount(() => {
    const manejarClicFuera = (evento: Event) => {
      const elementoPerfil = document.querySelector('.perfil-usuario');
      if (elementoPerfil && !elementoPerfil.contains(evento.target as Node) && menuPerfilAbierto) {
        menuPerfilAbierto = false;
      }
    };
    
    document.addEventListener('click', manejarClicFuera);
    return () => document.removeEventListener('click', manejarClicFuera);
  });
</script>

<div class="sidebar-moderno" class:colapsado>
  <!-- Header con Ícono de Sidebar -->
  <div class="sidebar-header">
    <div class="sidebar-icon-container">
      <div class="sidebar-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="3" width="18" height="18" rx="2"/>
          <line x1="9" y1="3" x2="9" y2="21"/>
        </svg>
      </div>
      {#if !colapsado}
        <span class="sidebar-label">Menú</span>
      {/if}
    </div>
    
    <button class="btn-toggle-moderno" aria-label={colapsado ? 'Expandir menú' : 'Contraer menú'} on:click={alternarBarraLateral}>
      <div class="toggle-icon" class:rotado={colapsado}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M15 18l-6-6 6-6"/>
        </svg>
      </div>
    </button>
  </div>

  <!-- Buscador Moderno -->
  <div class="search-container">
    <button class="search-btn-moderno" class:colapsado on:click={abrirModalBusqueda} aria-label="Abrir búsqueda">
      <div class="search-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/>
          <path d="m21 21-4.35-4.35"/>
        </svg>
      </div>
      {#if !colapsado}
        <span class="search-text">Buscar contenido...</span>
        <div class="search-shortcut">⌘K</div>
      {/if}
    </button>
  </div>

  <!-- Navegación Principal -->
  <nav class="navegacion-principal">
    
    {#if tipoUsuario === 'admin'}
      <!-- MENÚ PARA ADMINISTRADORES -->
      
      <!-- Sección Principal -->
      <div class="nav-section">
        {#if !colapsado}
          <div class="section-title">Principal</div>
        {/if}
        
        <a href="/administrador" class="nav-item destacado">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="7" height="9"/>
              <rect x="14" y="3" width="7" height="5"/>
              <rect x="14" y="12" width="7" height="9"/>
              <rect x="3" y="16" width="7" height="5"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Dashboard</span>
            <div class="nav-badge activo">3</div>
          {/if}
        </a>

        <a href="/administrador/panel-contenido" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14,2 14,8 20,8"/>
              <line x1="16" y1="13" x2="8" y2="13"/>
              <line x1="16" y1="17" x2="8" y2="17"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Gestionar Contenido</span>
          {/if}
        </a>

        <a href="/administrador/crear-contenido" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
              <polyline points="14,2 14,8 20,8"/>
              <line x1="12" y1="18" x2="12" y2="12"/>
              <line x1="9" y1="15" x2="15" y2="15"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Crear Contenido</span>
            <div class="nav-badge nuevo">Nuevo</div>
          {/if}
        </a>
      </div>

      <!-- Sección Contenido -->
      <div class="nav-section">
        {#if !colapsado}
          <div class="section-title">Contenido</div>
        {/if}
        
        <a href="/cursos" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
              <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Cursos</span>
          {/if}
        </a>

        <a href="/tutoriales" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polygon points="23 7 16 12 23 17 23 7"/>
              <rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Tutoriales</span>
          {/if}
        </a>

        <a href="/administrador/blog" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
              <path d="M18.5 2.5a2.12 2.12 0 0 1 3 3L12 15l-4 1l1-4z"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Blog</span>
          {/if}
        </a>

        <a href="/administrador/eventos" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
              <line x1="16" y1="2" x2="16" y2="6"/>
              <line x1="8" y1="2" x2="8" y2="6"/>
              <line x1="3" y1="10" x2="21" y2="10"/>
              <rect x="8" y="14" width="8" height="4"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Eventos</span>
            <div class="nav-badge nuevo">Nuevo</div>
          {/if}
        </a>
      </div>

      <!-- Sección Herramientas -->
      <div class="nav-section">
        {#if !colapsado}
          <div class="section-title">Herramientas</div>
        {/if}
        
        <a href="/simulador-gaming" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="3" width="20" height="14" rx="2" ry="2"/>
              <line x1="8" y1="21" x2="16" y2="21"/>
              <line x1="12" y1="17" x2="12" y2="21"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Simulador</span>
          {/if}
        </a>

        <a href="/comunidad" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Comunidad</span>
            <div class="nav-badge">12</div>
          {/if}
        </a>
      </div>

    {:else}
      <!-- MENÚ PARA ESTUDIANTES -->
      
      <!-- Sección Principal -->
      <div class="nav-section">
        {#if !colapsado}
          <div class="section-title">Mi Aprendizaje</div>
        {/if}
        
        <a href="/estudiante" class="nav-item destacado">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="7" height="9"/>
              <rect x="14" y="3" width="7" height="5"/>
              <rect x="14" y="12" width="7" height="9"/>
              <rect x="3" y="16" width="7" height="5"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Mi Panel</span>
          {/if}
        </a>

        <a href="/mis-cursos" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
              <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Mis Cursos</span>
            <div class="nav-badge progreso">75%</div>
          {/if}
        </a>

        <a href="/tutoriales" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polygon points="23 7 16 12 23 17 23 7"/>
              <rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Tutoriales</span>
          {/if}
        </a>
      </div>

      <!-- Sección Práctica -->
      <div class="nav-section">
        {#if !colapsado}
          <div class="section-title">Práctica</div>
        {/if}
        
        <a href="/simulador-de-acordeon" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="3" width="20" height="14" rx="2" ry="2"/>
              <line x1="8" y1="21" x2="16" y2="21"/>
              <line x1="12" y1="17" x2="12" y2="21"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Simulador</span>
            <div class="nav-badge gratis">GRATIS</div>
          {/if}
        </a>

        <a href="/comunidad" class="nav-item">
          <div class="nav-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
            </svg>
          </div>
          {#if !colapsado}
            <span class="nav-text">Comunidad</span>
            <div class="nav-badge">12</div>
          {/if}
        </a>
      </div>
    {/if}
  </nav>

  <!-- Stats Card - Solo para admins cuando no está colapsado -->
  {#if !colapsado && tipoUsuario === 'admin'}
    <div class="stats-card">
      <div class="stats-header">
        <div class="stats-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 3v18h18"/>
            <path d="M18.7 8l-5.1 5.2-2.8-2.7L7 14.3"/>
          </svg>
        </div>
        <div class="stats-title">Estadísticas</div>
      </div>
      <div class="stats-content">
        <div class="stat-item">
          <div class="stat-value">1,247</div>
          <div class="stat-label">Estudiantes</div>
        </div>
        <div class="stat-item">
          <div class="stat-value">89</div>
          <div class="stat-label">Cursos</div>
        </div>
      </div>
      <div class="stats-progress">
        <div class="progress-bar">
          <div class="progress-fill" style="width: 78%"></div>
        </div>
        <div class="progress-text">78% del objetivo mensual</div>
      </div>
    </div>
  {/if}

  <!-- Progress Card - Solo para estudiantes cuando no está colapsado -->
  {#if !colapsado && tipoUsuario === 'estudiante'}
    <div class="progress-card">
      <div class="progress-header">
        <div class="progress-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
            <polyline points="22,4 12,14.01 9,11.01"/>
          </svg>
        </div>
        <div class="progress-title">Mi Progreso</div>
      </div>
      <div class="progress-content">
        <div class="progress-circle">
          <svg class="progress-svg" viewBox="0 0 36 36">
            <path class="progress-bg" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
            <path class="progress-meter" stroke-dasharray="75, 100" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
          </svg>
          <div class="progress-percentage">75%</div>
        </div>
        <div class="progress-stats">
          <div class="progress-stat">
            <span class="stat-number">12</span>
            <span class="stat-text">Completados</span>
          </div>
          <div class="progress-stat">
            <span class="stat-number">4</span>
            <span class="stat-text">En progreso</span>
          </div>
        </div>
      </div>
    </div>
  {/if}

  <!-- Perfil Usuario (Manteniendo funcionalidad original) -->
  <div class="perfil-usuario-moderno">
    <div class="perfil-btn-moderno" class:colapsado on:click={alternarMenuPerfil} role="button" tabindex="0" on:keydown={(e) => e.key === 'Enter' && alternarMenuPerfil(e)}>
      <div class="avatar-container">
        <img src={avatarUsuario} alt="Avatar" class="avatar-moderno" />
        <div class="status-indicator"></div>
      </div>
      {#if !colapsado}
        <div class="perfil-info">
          <div class="perfil-nombre">{nombreUsuario}</div>
          <div class="perfil-rol">{tipoUsuario === 'admin' ? 'Administrador' : 'Estudiante'}</div>
        </div>
        <div class="perfil-chevron">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="6,9 12,15 18,9"/>
          </svg>
        </div>
      {/if}
    </div>
    
    {#if menuPerfilAbierto}
      <div class="menu-perfil-moderno" on:click|stopPropagation role="menu" tabindex="-1">
        <!-- Header del perfil -->
        <div class="perfil-header-moderno">
          <div class="avatar-header-container">
            <img src={avatarUsuario} alt="Avatar" class="avatar-header-moderno" />
            <div class="status-indicator-header"></div>
          </div>
          <div class="info-header-moderno">
            <div class="nombre-header-moderno">{nombreUsuario}</div>
            <div class="correo-header-moderno">{$usuario?.correo_electronico || 'usuario@email.com'}</div>
          </div>
        </div>
        
        <!-- Opciones del menú -->
        <div class="menu-opciones">
          <button class="opcion-moderna" on:click={irAPerfil}>
            <div class="opcion-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
            </div>
            <span class="opcion-text">Mi Perfil</span>
          </button>
          
          <button class="opcion-moderna" on:click={irACursos}>
            <div class="opcion-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
              </svg>
            </div>
            <span class="opcion-text">{tipoUsuario === 'admin' ? 'Cursos' : 'Mis Cursos'}</span>
          </button>
          
          <div class="menu-divider"></div>
          
          <button class="opcion-moderna logout-moderna" on:click={cerrarSesionCompleta}>
            <div class="opcion-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                <polyline points="16 17 21 12 16 7"/>
                <line x1="21" y1="12" x2="9" y2="12"/>
              </svg>
            </div>
            <span class="opcion-text">Cerrar Sesión</span>
          </button>
        </div>
      </div>
    {/if}
  </div>
</div>

{#if modalBusquedaAbierto}
  <ModalBusqueda abierto={modalBusquedaAbierto} onCerrar={cerrarModalBusqueda} />
{/if}

<style>
.sidebar-moderno {
  position: fixed;
  top: 63px;
  left: 0;
  height: calc(100vh - 63px);
  min-height: calc(100vh - 63px);
  display: flex;
  flex-direction: column;
  background: linear-gradient(180deg, #ffffff 0%, #fafbfc 100%);
  border-right: 1px solid #e1e5e9;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 10;
  width: 280px;
  padding: 0;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

.sidebar-moderno.colapsado {
  width: 80px;
}

/* Header */
.sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 30px 10px 0px 24px;
  border-bottom: 1px solid #f0f2f5;
  background: #fff;
}

.sidebar-icon-container {
  display: flex;
  align-items: center;
  gap: 12px;
}

.sidebar-icon {
  width: 36px;
  height: 36px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.sidebar-icon svg {
  width: 20px;
  height: 20px;
}

.sidebar-label {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
  letter-spacing: -0.5px;
}

.btn-toggle-moderno {
  width: 32px;
  height: 32px;
  border: none;
  background: #f8fafc;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  color: #64748b;
}

.btn-toggle-moderno:hover {
  background: #e2e8f0;
  color: #475569;
}

.toggle-icon {
  width: 16px;
  height: 16px;
  transition: transform 0.3s ease;
}

.toggle-icon.rotado {
  transform: rotate(180deg);
}

/* Search */
.search-container {
  padding: 16px 24px;
}

.sidebar-moderno.colapsado .search-container {
  padding: 16px 20px;
}

.search-btn-moderno {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  color: #64748b;
}

.search-btn-moderno:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
}

.search-btn-moderno.colapsado {
  justify-content: center;
  padding: 12px;
}

.search-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

.search-text {
  flex: 1;
  text-align: left;
  font-size: 14px;
  color: #64748b;
}

.search-shortcut {
  background: #e2e8f0;
  color: #64748b;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
}

/* Navigation */
.navegacion-principal {
  flex: 1;
  padding: 8px 0;
  overflow-y: auto;
}

.nav-section {
  margin-bottom: 32px;
}

.section-title {
  font-size: 11px;
  font-weight: 700;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: 1px;
  padding: 0 24px 12px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 24px;
  margin: 2px 16px;
  text-decoration: none;
  color: #475569;
  font-weight: 500;
  font-size: 14px;
  border-radius: 12px;
  transition: all 0.2s ease;
  position: relative;
}

.nav-item:hover {
  background: #f8fafc;
  color: #1e293b;
  transform: translateX(4px);
}

.nav-item.destacado {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.25);
}

.nav-item.destacado:hover {
  transform: translateX(4px) translateY(-1px);
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.35);
}

.sidebar-moderno.colapsado .nav-item {
  justify-content: center;
  padding: 12px 20px;
}

.nav-icon {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
}

.nav-text {
  flex: 1;
}

.nav-badge {
  background: #e2e8f0;
  color: #64748b;
  font-size: 11px;
  font-weight: 700;
  padding: 4px 8px;
  border-radius: 12px;
  min-width: 20px;
  text-align: center;
}

.nav-badge.activo {
  background: #ef4444;
  color: white;
  animation: pulse-badge 2s infinite;
}

.nav-badge.nuevo {
  background: #22c55e;
  color: white;
}

.nav-badge.progreso {
  background: #3b82f6;
  color: white;
}

.nav-badge.gratis {
  background: #10b981;
  color: white;
  font-weight: 800;
}

.nav-item.destacado .nav-badge {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

/* Stats Card */
.stats-card {
  margin: 0 16px 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 16px;
  padding: 20px;
  color: white;
}

.stats-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.stats-icon {
  width: 24px;
  height: 24px;
}

.stats-title {
  font-size: 16px;
  font-weight: 700;
}

.stats-content {
  display: flex;
  gap: 20px;
  margin-bottom: 16px;
}

.stat-item {
  flex: 1;
}

.stat-value {
  font-size: 24px;
  font-weight: 800;
  line-height: 1;
}

.stat-label {
  font-size: 12px;
  opacity: 0.8;
  margin-top: 4px;
}

.stats-progress {
  margin-top: 16px;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 3px;
  overflow: hidden;
  margin-bottom: 8px;
}

.progress-fill {
  height: 100%;
  background: rgba(255, 255, 255, 0.9);
  border-radius: 3px;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 12px;
  opacity: 0.9;
}

/* Progress Card */
.progress-card {
  margin: 0 16px 20px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 20px;
}

.progress-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.progress-icon {
  width: 20px;
  height: 20px;
  color: #22c55e;
}

.progress-title {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
}

.progress-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.progress-circle {
  position: relative;
  width: 60px;
  height: 60px;
}

.progress-svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.progress-bg {
  fill: none;
  stroke: #f1f5f9;
  stroke-width: 2;
}

.progress-meter {
  fill: none;
  stroke: #22c55e;
  stroke-width: 2;
  stroke-linecap: round;
  animation: progress-animation 1s ease-in-out;
}

.progress-percentage {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 14px;
  font-weight: 700;
  color: #22c55e;
}

.progress-stats {
  flex: 1;
}

.progress-stat {
  display: flex;
  flex-direction: column;
  margin-bottom: 8px;
}

.stat-number {
  font-size: 18px;
  font-weight: 700;
  color: #1e293b;
}

.stat-text {
  font-size: 12px;
  color: #64748b;
}

/* Perfil Usuario */
.perfil-usuario-moderno {
  margin-top: auto;
  position: relative;
  padding: 16px;
  border-top: 1px solid #f0f2f5;
}

.perfil-btn-moderno {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: 12px 16px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.perfil-btn-moderno:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.perfil-btn-moderno.colapsado {
  justify-content: center;
  padding: 12px;
}

.avatar-container {
  position: relative;
  flex-shrink: 0;
}

.avatar-moderno {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  object-fit: cover;
  border: 2px solid white;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.status-indicator {
  position: absolute;
  bottom: 2px;
  right: 2px;
  width: 10px;
  height: 10px;
  background: #22c55e;
  border: 2px solid white;
  border-radius: 50%;
}

.perfil-info {
  flex: 1;
  text-align: left;
  min-width: 0;
}

.perfil-nombre {
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.perfil-rol {
  font-size: 12px;
  color: #64748b;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.perfil-chevron {
  width: 16px;
  height: 16px;
  color: #94a3b8;
  transition: transform 0.2s ease;
}

.perfil-btn-moderno:hover .perfil-chevron {
  transform: rotate(180deg);
}

/* Menu Perfil */
.menu-perfil-moderno {
  position: absolute;
  bottom: 100%;
  left: 16px;
  right: 16px;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  margin-bottom: 8px;
  z-index: 50;
  overflow: hidden;
}

.perfil-header-moderno {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-bottom: 1px solid #e2e8f0;
}

.avatar-header-container {
  position: relative;
  flex-shrink: 0;
}

.avatar-header-moderno {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  object-fit: cover;
  border: 3px solid white;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.status-indicator-header {
  position: absolute;
  bottom: 2px;
  right: 2px;
  width: 12px;
  height: 12px;
  background: #22c55e;
  border: 3px solid white;
  border-radius: 50%;
}

.info-header-moderno {
  flex: 1;
  text-align: left;
  min-width: 0;
}

.nombre-header-moderno {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.correo-header-moderno {
  font-size: 13px;
  color: #64748b;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.menu-opciones {
  padding: 8px;
}

.opcion-moderna {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: 12px 16px;
  background: none;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #475569;
  transition: all 0.2s ease;
  text-align: left;
}

.opcion-moderna:hover {
  background: #f8fafc;
  color: #1e293b;
}

.opcion-moderna.logout-moderna {
  color: #dc2626;
}

.opcion-moderna.logout-moderna:hover {
  background: #fef2f2;
}

.opcion-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

.opcion-text {
  flex: 1;
}

.menu-divider {
  height: 1px;
  background: #f0f2f5;
  margin: 8px 0;
}

/* Animations */
@keyframes pulse-badge {
  0% { transform: scale(1); }
  50% { transform: scale(1.1); }
  100% { transform: scale(1); }
}

@keyframes progress-animation {
  0% { stroke-dasharray: 0, 100; }
  100% { stroke-dasharray: 75, 100; }
}

/* Responsive */
@media (max-width: 768px) {
  .sidebar-moderno:not(.colapsado) {
    width: 260px;
  }
  
  .stats-card,
  .progress-card {
    display: none;
  }
}

/* Ocultar sidebar en pantallas menores a 900px */
@media (max-width: 900px) {
  .sidebar-moderno {
    display: none;
  }
}

/* Para pantallas muy pequeñas, asegurar que esté oculto */
@media (max-width: 768px) {
  .sidebar-moderno {
    display: none !important;
  }
}
</style>
