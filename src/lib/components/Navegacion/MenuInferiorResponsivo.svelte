<script lang="ts">
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';

  // Determinar el tipo de usuario y ruta actual
  $: tipoUsuario = $usuario?.rol === 'admin' ? 'admin' : 'estudiante';
  $: rutaActual = $page.url.pathname;

  // Función para verificar si una ruta está activa
  function esRutaActiva(ruta: string): boolean {
    if (ruta === '/administrador' || ruta === '/estudiante') {
      return rutaActual === ruta;
    }
    return rutaActual.startsWith(ruta);
  }

  // Navegación para administradores
  const menuAdmin = [
    {
      id: 'dashboard',
      icono: 'dashboard',
      texto: 'Panel',
      ruta: '/administrador',
      badge: '3'
    },
    {
      id: 'contenido',
      icono: 'contenido',
      texto: 'Contenido',
      ruta: '/administrador/panel-contenido',
      badge: null
    },
    {
      id: 'crear',
      icono: 'crear',
      texto: 'Crear',
      ruta: '/administrador/crear-contenido',
      badge: 'Nuevo'
    },
    {
      id: 'comunidad',
      icono: 'comunidad',
      texto: 'Comunidad',
      ruta: '/comunidad',
      badge: '12'
    },
    {
      id: 'perfil',
      icono: 'perfil',
      texto: 'Perfil',
      ruta: '/mi-perfil',
      badge: null
    }
  ];

  // Navegación para estudiantes
  const menuEstudiante = [
    {
      id: 'panel',
      icono: 'dashboard',
      texto: 'Inicio',
      ruta: '/estudiante',
      badge: null
    },
    {
      id: 'cursos',
      icono: 'cursos',
      texto: 'Mis Cursos',
      ruta: '/mis-cursos',
      badge: '75%'
    },
    {
      id: 'tutoriales',
      icono: 'tutoriales',
      texto: 'Tutoriales',
      ruta: '/tutoriales',
      badge: null
    },
    {
      id: 'comunidad',
      icono: 'comunidad',
      texto: 'Comunidad',
      ruta: '/comunidad',
      badge: '5'
    },
    {
      id: 'perfil',
      icono: 'perfil',
      texto: 'Perfil',
      ruta: '/mi-perfil',
      badge: null
    }
  ];

  $: menuItems = tipoUsuario === 'admin' ? menuAdmin : menuEstudiante;

  function navegarA(ruta: string) {
    goto(ruta);
  }

  function obtenerIcono(tipo: string) {
    const iconos: { [key: string]: string } = {
      dashboard: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <rect x="3" y="3" width="7" height="9"/>
        <rect x="14" y="3" width="7" height="5"/>
        <rect x="14" y="12" width="7" height="9"/>
        <rect x="3" y="16" width="7" height="5"/>
      </svg>`,
      contenido: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14,2 14,8 20,8"/>
        <line x1="16" y1="13" x2="8" y2="13"/>
        <line x1="16" y1="17" x2="8" y2="17"/>
      </svg>`,
      crear: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
        <polyline points="14,2 14,8 20,8"/>
        <line x1="12" y1="18" x2="12" y2="12"/>
        <line x1="9" y1="15" x2="15" y2="15"/>
      </svg>`,
      cursos: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
        <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
      </svg>`,
      tutoriales: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polygon points="23 7 16 12 23 17 23 7"/>
        <rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>
      </svg>`,
      comunidad: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>`,
      perfil: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
        <circle cx="12" cy="7" r="4"/>
      </svg>`
    };
    return iconos[tipo] || iconos.dashboard;
  }
</script>

<!-- Solo mostrar para usuarios logueados y en pantallas móviles -->
{#if $usuario}
  <nav class="menu-inferior-responsivo">
    <div class="menu-container">
      {#each menuItems as item}
        <button 
          class="menu-item" 
          class:activo={esRutaActiva(item.ruta)}
          on:click={() => navegarA(item.ruta)}
          aria-label={item.texto}
        >
          <div class="item-icon">
            {@html obtenerIcono(item.icono)}
          </div>
          <span class="item-text">{item.texto}</span>
          {#if item.badge}
            <div class="item-badge" class:progreso={item.badge.includes('%')} class:nuevo={item.badge === 'Nuevo'}>
              {item.badge}
            </div>
          {/if}
        </button>
      {/each}
    </div>
  </nav>
{/if}

<style>
  .menu-inferior-responsivo {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px);
    border-top: 1px solid #e2e8f0;
    z-index: 1000;
    padding: 0;
    display: none; /* Oculto por defecto */
    box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.08);
  }

  /* Mostrar solo en pantallas móviles */
  @media (max-width: 900px) {
    .menu-inferior-responsivo {
      display: block;
    }
  }

  .menu-container {
    display: flex;
    justify-content: space-around;
    align-items: center;
    padding: 8px 16px;
    max-width: 100%;
    margin: 0 auto;
    gap: 4px;
  }

  .menu-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 8px 12px;
    background: none;
    border: none;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    border-radius: 16px;
    position: relative;
    min-width: 60px;
    flex: 1;
    max-width: 80px;
  }

  .menu-item:hover {
    background: rgba(102, 126, 234, 0.1);
    transform: translateY(-2px);
  }

  .menu-item.activo {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  }

  .menu-item.activo:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
  }

  .item-icon {
    width: 24px;
    height: 24px;
    margin-bottom: 4px;
    color: #64748b;
    transition: color 0.3s ease;
  }

  .menu-item.activo .item-icon {
    color: white;
  }

  .menu-item:hover .item-icon {
    color: #667eea;
  }

  .menu-item.activo:hover .item-icon {
    color: white;
  }

  .item-text {
    font-size: 11px;
    font-weight: 600;
    color: #64748b;
    text-align: center;
    line-height: 1.2;
    transition: color 0.3s ease;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 100%;
  }

  .menu-item.activo .item-text {
    color: white;
  }

  .menu-item:hover .item-text {
    color: #667eea;
  }

  .menu-item.activo:hover .item-text {
    color: white;
  }

  .item-badge {
    position: absolute;
    top: 4px;
    right: 8px;
    background: #ef4444;
    color: white;
    font-size: 9px;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 10px;
    min-width: 16px;
    text-align: center;
    line-height: 1.2;
    transform: scale(0.9);
    animation: badge-pulse 2s infinite;
  }

  .item-badge.progreso {
    background: #3b82f6;
    animation: none;
  }

  .item-badge.nuevo {
    background: #22c55e;
    animation: badge-bounce 1s ease-in-out infinite alternate;
  }

  .menu-item.activo .item-badge {
    background: rgba(255, 255, 255, 0.9);
    color: #667eea;
  }

  /* Animaciones */
  @keyframes badge-pulse {
    0% { transform: scale(0.9); }
    50% { transform: scale(1.1); }
    100% { transform: scale(0.9); }
  }

  @keyframes badge-bounce {
    0% { transform: scale(0.9) translateY(0); }
    100% { transform: scale(1) translateY(-2px); }
  }

  /* Ajustes para pantallas muy pequeñas */
  @media (max-width: 480px) {
    .menu-container {
      padding: 6px 8px;
      gap: 2px;
    }

    .menu-item {
      padding: 6px 8px;
      min-width: 50px;
      max-width: 70px;
    }

    .item-icon {
      width: 20px;
      height: 20px;
      margin-bottom: 2px;
    }

    .item-text {
      font-size: 10px;
    }

    .item-badge {
      font-size: 8px;
      padding: 1px 4px;
      top: 2px;
      right: 4px;
    }
  }

  /* Ajuste para evitar que el contenido se oculte detrás del menú */
  @media (max-width: 900px) {
    :global(body) {
      padding-bottom: 80px;
    }
  }
</style> 