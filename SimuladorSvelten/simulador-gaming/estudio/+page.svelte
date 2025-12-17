<!-- Página de Mi Estudio con efectos exactos de Rhythm Plus -->
<script lang="ts">
  import { onMount } from 'svelte';
  import FondoEspacial from '$lib/components/SimuladorDefinitivo/components/efectos/FondoEspacial.svelte';
  import { audioManager, TipoEfectoUI } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
  
  let canciones = [
    { 
      id: 1, 
      nombre: 'Mi Canción Favorita', 
      artista: 'Acordeonista Pro',
      genero: 'Vals',
      estado: 'Terminada',
      fecha: '2025-01-15'
    },
    { 
      id: 2, 
      nombre: 'Cumbia Experimental', 
      artista: 'Acordeonista Pro',
      genero: 'Cumbia',
      estado: 'En Progreso',
      fecha: '2025-01-14'
    },
    { 
      id: 3, 
      nombre: 'Borrador de Merengue', 
      artista: 'Acordeonista Pro',
      genero: 'Merengue',
      estado: 'Borrador',
      fecha: '2025-01-13'
    }
  ];
  
  function hoverCancion() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.HOVER_NAVEGACION);
  }
  
  function clickCancion() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_GENERAL);
  }
  
  function crearCancion() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    alert('Función de creación de canciones estará disponible próximamente');
  }
  
  function importarCancion() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
    alert('Función de importación de canciones estará disponible próximamente');
  }
</script>

<svelte:head>
  <title>Mi Estudio - Simulador 2.0</title>
  <meta name="description" content="Crea y gestiona tus canciones personalizadas" />
</svelte:head>

<FondoEspacial />

<div class="contenedor-principal">
  <div class="titulo-pagina">🎹 Mi Estudio</div>
  
  <div class="contenedor-estudio">
    <!-- Botones de acción -->
    <div class="botones-accion">
      <button 
        class="boton-crear"
        on:click={crearCancion}
        on:mouseenter={hoverCancion}
      >
        <span class="icono">➕</span>
        <span class="texto">Crear Nueva Canción</span>
      </button>
      
      <button 
        class="boton-importar"
        on:click={importarCancion}
        on:mouseenter={hoverCancion}
      >
        <span class="icono">📁</span>
        <span class="texto">Importar Canción</span>
      </button>
    </div>
    
    <!-- Descripción -->
    <div class="descripcion">
      <h2>¡Crea e importa tus canciones favoritas para tocar y compartir!</h2>
      <p>Aquí puedes crear tus propias canciones o importar archivos existentes para practicar en el simulador.</p>
    </div>
    
    <!-- Lista de canciones -->
    <div class="lista-canciones">
      <h3>Mis Canciones</h3>
      
      {#if canciones.length === 0}
        <div class="sin-canciones">
          <div class="icono">🎵</div>
          <div class="texto">No tienes canciones creadas aún</div>
          <div class="subtexto">¡Comienza creando tu primera canción!</div>
        </div>
      {:else}
        <div class="tabla-canciones">
          <div class="encabezado">
            <div class="columna">Nombre</div>
            <div class="columna">Artista</div>
            <div class="columna">Género</div>
            <div class="columna">Estado</div>
            <div class="columna">Fecha</div>
          </div>
          
          {#each canciones as cancion}
            <div 
              class="fila-cancion"
              on:mouseenter={hoverCancion}
              on:click={clickCancion}
            >
              <div class="nombre">{cancion.nombre}</div>
              <div class="artista">{cancion.artista}</div>
              <div class="genero">{cancion.genero}</div>
              <div class="estado estado-{cancion.estado.toLowerCase().replace(' ', '-')}">
                {cancion.estado}
              </div>
              <div class="fecha">{cancion.fecha}</div>
            </div>
          {/each}
        </div>
      {/if}
    </div>
    
    <!-- Mensaje de desarrollo -->
    <div class="mensaje-desarrollo">
      <div class="icono">🚧</div>
      <div class="texto">
        Esta función estará completamente disponible en futuras versiones. 
        Por ahora puedes explorar las canciones predefinidas en la sección de selección.
      </div>
    </div>
  </div>
</div>

<style>
  .contenedor-principal {
    position: fixed;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    overflow-y: auto;
    padding-top: 100px;
    padding-bottom: 100px;
  }
  
  .titulo-pagina {
    font-size: 2.5rem;
    font-weight: bold;
    color: white;
    text-align: center;
    margin-bottom: 40px;
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8);
  }
  
  .contenedor-estudio {
    max-width: 1000px;
    margin: 0 auto;
    padding: 0 20px;
  }
  
  .botones-accion {
    display: flex;
    gap: 20px;
    justify-content: center;
    margin-bottom: 40px;
  }
  
  .boton-crear,
  .boton-importar {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 15px 30px;
    border: none;
    border-radius: 25px;
    color: white;
    font-size: 1.1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .boton-crear {
    background: linear-gradient(135deg, #ff6b6b, #4ecdc4);
  }
  
  .boton-importar {
    background: linear-gradient(135deg, #667eea, #764ba2);
  }
  
  .boton-crear:hover,
  .boton-importar:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
  }
  
  .descripcion {
    text-align: center;
    color: white;
    margin-bottom: 40px;
    padding: 20px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 15px;
  }
  
  .descripcion h2 {
    margin-bottom: 15px;
    color: #4ecdc4;
  }
  
  .lista-canciones {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 15px;
    padding: 20px;
    margin-bottom: 40px;
  }
  
  .lista-canciones h3 {
    color: white;
    margin-bottom: 20px;
    text-align: center;
  }
  
  .sin-canciones {
    text-align: center;
    color: white;
    opacity: 0.7;
    padding: 40px;
  }
  
  .sin-canciones .icono {
    font-size: 3rem;
    margin-bottom: 15px;
  }
  
  .sin-canciones .texto {
    font-size: 1.2rem;
    margin-bottom: 10px;
  }
  
  .tabla-canciones {
    color: white;
  }
  
  .encabezado {
    display: grid;
    grid-template-columns: 2fr 1fr 1fr 1fr 1fr;
    gap: 20px;
    padding: 15px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 10px;
    font-weight: bold;
    margin-bottom: 10px;
  }
  
  .fila-cancion {
    display: grid;
    grid-template-columns: 2fr 1fr 1fr 1fr 1fr;
    gap: 20px;
    padding: 15px;
    transition: all 0.3s ease;
    cursor: pointer;
    border-radius: 10px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  }
  
  .fila-cancion:hover {
    background: rgba(255, 255, 255, 0.2);
    transform: translateX(5px);
  }
  
  .estado {
    font-weight: bold;
    padding: 5px 10px;
    border-radius: 15px;
    text-align: center;
    font-size: 0.9rem;
  }
  
  .estado-terminada {
    background: #4caf50;
    color: white;
  }
  
  .estado-en-progreso {
    background: #ff9800;
    color: white;
  }
  
  .estado-borrador {
    background: #9e9e9e;
    color: white;
  }
  
  .mensaje-desarrollo {
    text-align: center;
    color: white;
    opacity: 0.8;
    padding: 20px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 15px;
  }
  
  .mensaje-desarrollo .icono {
    font-size: 2rem;
    margin-bottom: 10px;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .botones-accion {
      flex-direction: column;
      align-items: center;
    }
    
    .boton-crear,
    .boton-importar {
      width: 100%;
      max-width: 300px;
    }
    
    .encabezado,
    .fila-cancion {
      grid-template-columns: 1fr;
      gap: 10px;
    }
    
    .contenedor-principal {
      padding-top: 120px;
    }
  }
</style> 