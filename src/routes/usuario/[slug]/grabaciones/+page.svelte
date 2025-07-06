<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
  import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';

  // Props de la página (del servidor)
  export let data: any;
  const { perfil, esUsuarioPropio } = data;

  // Datos de grabaciones (simulados por ahora)
  let grabaciones: any[] = [];
  let cargando = true;

  onMount(async () => {
    // Simular carga de grabaciones
    setTimeout(() => {
      grabaciones = [
        {
          id: 1,
          titulo: "Vallenato Clásico - La Gota Fría",
          duracion: "3:45",
          fecha: "2024-01-15",
          reproducciones: 250,
          url_audio: "/audio/ejemplo1.mp3"
        },
        {
          id: 2,
          titulo: "Paseo Vallenato - El Centurión",
          duracion: "4:12",
          fecha: "2024-01-10",
          reproducciones: 180,
          url_audio: "/audio/ejemplo2.mp3"
        }
      ];
      cargando = false;
    }, 1000);
  });
</script>

<svelte:head>
  <title>Grabaciones de {perfil.nombre} {perfil.apellido} - Academia Vallenata</title>
  <meta name="description" content="Escucha las grabaciones de {perfil.nombre} {perfil.apellido} en la Academia Vallenata Online." />
</svelte:head>

<div class="contenedor-perfil">
  <!-- Encabezado del perfil -->
  <EncabezadoPerfil 
    bind:nombreCompleto={perfil.nombre_completo} 
    bind:correoElectronico={perfil.correo_electronico} 
    bind:urlAvatar={perfil.url_foto_perfil} 
    bind:urlPortada={perfil.portada_url} 
    bind:posicionPortadaY={perfil.posicion_img_portada}
    userId={perfil.id}
    stats={{ publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 }}
    esEditable={esUsuarioPropio}
  />

  <!-- Pestañas de navegación -->
  <PestanasPerfil 
    esPerfilPublico={!esUsuarioPropio}
    usuarioSlug={perfil.nombre_usuario || 'usuario'}
  />

  <!-- Contenido de grabaciones -->
  <div class="contenedor-grabaciones">
    <div class="header-grabaciones">
      <h2>🎵 Grabaciones</h2>
      <div class="stats-grabaciones">
        <span class="total-grabaciones">{grabaciones.length} grabaciones</span>
      </div>
    </div>

    {#if cargando}
      <div class="cargando">
        <div class="spinner"></div>
        <p>Cargando grabaciones...</p>
      </div>
    {:else if grabaciones.length === 0}
      <div class="sin-grabaciones">
        <div class="icono-vacio">🎤</div>
        <h3>No hay grabaciones</h3>
        <p>{esUsuarioPropio ? 'Aún no has subido grabaciones.' : `${perfil.nombre} no ha subido grabaciones aún.`}</p>
      </div>
    {:else}
      <div class="lista-grabaciones">
        {#each grabaciones as grabacion (grabacion.id)}
          <div class="tarjeta-grabacion">
            <div class="info-grabacion">
              <div class="icono-audio">🎵</div>
              <div class="detalles-grabacion">
                <h3 class="titulo-grabacion">{grabacion.titulo}</h3>
                <div class="metadata-grabacion">
                  <span class="duracion">⏱️ {grabacion.duracion}</span>
                  <span class="separador">•</span>
                  <span class="fecha">{new Date(grabacion.fecha).toLocaleDateString()}</span>
                  <span class="separador">•</span>
                  <span class="reproducciones">▶️ {grabacion.reproducciones}</span>
                </div>
              </div>
            </div>
            <button class="boton-reproducir">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M8 5v14l11-7z"/>
              </svg>
            </button>
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<style>
  .contenedor-perfil {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0;
  }

  .contenedor-grabaciones {
    background: white;
    border-radius: 16px;
    padding: 2rem;
    margin-top: 1rem;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  }

  .header-grabaciones {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
    padding-bottom: 1rem;
    border-bottom: 2px solid #f1f5f9;
  }

  .header-grabaciones h2 {
    font-size: 1.75rem;
    font-weight: 700;
    color: #1e293b;
    margin: 0;
  }

  .stats-grabaciones {
    color: #64748b;
    font-weight: 500;
  }

  .cargando {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 0;
    color: #64748b;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #f1f5f9;
    border-top: 4px solid #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .sin-grabaciones {
    text-align: center;
    padding: 4rem 0;
    color: #64748b;
  }

  .icono-vacio {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .sin-grabaciones h3 {
    font-size: 1.5rem;
    font-weight: 600;
    margin: 0 0 0.5rem 0;
    color: #475569;
  }

  .lista-grabaciones {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .tarjeta-grabacion {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1.5rem;
    background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
    border-radius: 12px;
    border: 1px solid #e2e8f0;
    transition: all 0.2s ease;
  }

  .tarjeta-grabacion:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
    border-color: #3b82f6;
  }

  .info-grabacion {
    display: flex;
    align-items: center;
    gap: 1rem;
    flex: 1;
  }

  .icono-audio {
    width: 48px;
    height: 48px;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5rem;
    color: white;
  }

  .detalles-grabacion {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .titulo-grabacion {
    font-size: 1.1rem;
    font-weight: 600;
    color: #1e293b;
    margin: 0;
  }

  .metadata-grabacion {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.875rem;
    color: #64748b;
  }

  .separador {
    color: #cbd5e0;
  }

  .boton-reproducir {
    width: 48px;
    height: 48px;
    background: linear-gradient(135deg, #10b981, #059669);
    border: none;
    border-radius: 50%;
    color: white;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
  }

  .boton-reproducir:hover {
    transform: scale(1.1);
    box-shadow: 0 4px 15px rgba(16, 185, 129, 0.3);
  }

  @media (max-width: 768px) {
    .contenedor-grabaciones {
      padding: 1rem;
      margin-top: 0.5rem;
    }

    .header-grabaciones {
      flex-direction: column;
      gap: 1rem;
      align-items: flex-start;
    }

    .tarjeta-grabacion {
      padding: 1rem;
    }

    .info-grabacion {
      gap: 0.75rem;
    }

    .icono-audio {
      width: 40px;
      height: 40px;
      font-size: 1.25rem;
    }

    .boton-reproducir {
      width: 40px;
      height: 40px;
    }
  }
</style> 