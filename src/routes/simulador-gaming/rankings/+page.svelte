<!-- Página de rankings con efectos exactos de Rhythm Plus -->
<script lang="ts">
  import { onMount } from 'svelte';
  import FondoEspacial from '$lib/components/SimuladorDefinitivo/components/efectos/FondoEspacial.svelte';
  import { audioManager, TipoEfectoUI } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
  
  let rankings = [
    { puesto: 1, nombre: 'Acordeonista Pro', puntuacion: 98500, cancion: 'Vals de las Flores' },
    { puesto: 2, nombre: 'Maestro del Acordeón', puntuacion: 95200, cancion: 'Cumbia Sampuesana' },
    { puesto: 3, nombre: 'Rey del Vallenato', puntuacion: 92800, cancion: 'Porro Sabanero' },
    { puesto: 4, nombre: 'Virtuoso Musical', puntuacion: 88900, cancion: 'Merengue Alegre' },
    { puesto: 5, nombre: 'Artista Nacional', puntuacion: 85400, cancion: 'Pasillo Bogotano' }
  ];
  
  function hoverRanking() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.HOVER_NAVEGACION);
  }
  
  function clickRanking() {
    audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_GENERAL);
  }
</script>

<svelte:head>
  <title>Rankings - Simulador 2.0</title>
  <meta name="description" content="Tabla de posiciones de los mejores acordeonistas" />
</svelte:head>

<FondoEspacial />

<div class="contenedor-principal">
  <div class="titulo-pagina">🏆 Rankings</div>
  
  <div class="contenedor-rankings">
    <div class="tabla-rankings">
      <div class="encabezado">
        <div class="columna">Puesto</div>
        <div class="columna">Jugador</div>
        <div class="columna">Puntuación</div>
        <div class="columna">Canción</div>
      </div>
      
      {#each rankings as ranking}
        <div 
          class="fila-ranking"
          on:mouseenter={hoverRanking}
          on:click={clickRanking}
        >
          <div class="puesto puesto-{ranking.puesto}">
            {#if ranking.puesto === 1}
              🥇
            {:else if ranking.puesto === 2}
              🥈
            {:else if ranking.puesto === 3}
              🥉
            {:else}
              #{ranking.puesto}
            {/if}
          </div>
          <div class="nombre">{ranking.nombre}</div>
          <div class="puntuacion">{ranking.puntuacion.toLocaleString()}</div>
          <div class="cancion">{ranking.cancion}</div>
        </div>
      {/each}
    </div>
    
    <div class="mensaje-proximamente">
      <div class="icono">🚧</div>
      <div class="texto">Los rankings globales estarán disponibles próximamente</div>
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
  
  .contenedor-rankings {
    max-width: 1000px;
    margin: 0 auto;
    padding: 0 20px;
  }
  
  .tabla-rankings {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 15px;
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
    backdrop-filter: blur(10px);
  }
  
  .encabezado {
    display: grid;
    grid-template-columns: 80px 1fr 120px 200px;
    gap: 20px;
    padding: 20px;
    background: rgba(255, 255, 255, 0.2);
    font-weight: bold;
    color: white;
    border-bottom: 2px solid rgba(255, 255, 255, 0.3);
  }
  
  .fila-ranking {
    display: grid;
    grid-template-columns: 80px 1fr 120px 200px;
    gap: 20px;
    padding: 20px;
    color: white;
    transition: all 0.3s ease;
    cursor: pointer;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  }
  
  .fila-ranking:hover {
    background: rgba(255, 255, 255, 0.2);
    transform: translateX(5px);
  }
  
  .puesto {
    font-weight: bold;
    text-align: center;
    font-size: 1.2rem;
  }
  
  .puesto-1 { color: #ffd700; }
  .puesto-2 { color: #c0c0c0; }
  .puesto-3 { color: #cd7f32; }
  
  .nombre {
    font-weight: bold;
  }
  
  .puntuacion {
    font-weight: bold;
    color: #4ecdc4;
  }
  
  .cancion {
    opacity: 0.8;
  }
  
  .mensaje-proximamente {
    text-align: center;
    color: white;
    opacity: 0.7;
    margin-top: 40px;
    padding: 20px;
  }
  
  .icono {
    font-size: 3rem;
    margin-bottom: 10px;
  }
  
  .texto {
    font-size: 1.1rem;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .encabezado,
    .fila-ranking {
      grid-template-columns: 60px 1fr 100px;
      gap: 10px;
    }
    
    .cancion {
      display: none;
    }
    
    .contenedor-principal {
      padding-top: 120px;
    }
  }
</style> 