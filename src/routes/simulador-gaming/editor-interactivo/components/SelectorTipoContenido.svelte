<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import type { TipoContenido } from '../types/tiposEditor.js';
  import { CONFIGURACIONES_UI } from '../types/configuraciones.js';

  export let tipoSeleccionado: TipoContenido | null = null;

  const dispatch = createEventDispatcher<{
    cambioTipo: TipoContenido;
  }>();

  const opciones = [
    {
      tipo: 'cancion' as TipoContenido,
      titulo: 'Canción',
      descripcion: 'Crea una canción interactiva con notas de acordeón',
      icono: '🎵',
      color: CONFIGURACIONES_UI.cancion.color,
      gradiente: CONFIGURACIONES_UI.cancion.gradiente,
      caracteristicas: ['Audio', 'Notas', 'Partitura', 'Gamificación']
    },
    {
      tipo: 'desafio' as TipoContenido,
      titulo: 'Desafío',
      descripcion: 'Diseña un desafío competitivo para otros jugadores',
      icono: '⚔️',
      color: CONFIGURACIONES_UI.desafio.color,
      gradiente: CONFIGURACIONES_UI.desafio.gradiente,
      caracteristicas: ['Competencia', 'Tiempo límite', 'Puntuación', 'Ranking']
    },
    {
      tipo: 'ejercicio' as TipoContenido,
      titulo: 'Ejercicio',
      descripcion: 'Desarrolla ejercicios de práctica y mejora técnica',
      icono: '💪',
      color: CONFIGURACIONES_UI.ejercicio.color,
      gradiente: CONFIGURACIONES_UI.ejercicio.gradiente,
      caracteristicas: ['Práctica', 'Evaluación', 'Progreso', 'Técnica']
    },
    {
      tipo: 'teoria' as TipoContenido,
      titulo: 'Teoría',
      descripcion: 'Crea contenido educativo y teórico interactivo',
      icono: '📚',
      color: CONFIGURACIONES_UI.teoria.color,
      gradiente: CONFIGURACIONES_UI.teoria.gradiente,
      caracteristicas: ['Educación', 'Contenido', 'Interactividad', 'Recursos']
    }
  ];

  const manejarSeleccion = (tipo: TipoContenido) => {
    dispatch('cambioTipo', tipo);
  };
</script>

<div class="selector-contenido">
  <div class="titulo-seccion">
    <h2>🎮 Selecciona el tipo de contenido</h2>
    <p>Elige qué tipo de contenido interactivo deseas crear</p>
  </div>

  <div class="opciones-grid">
    {#each opciones as opcion}
      <div 
        class="opcion-card"
        class:seleccionada={tipoSeleccionado === opcion.tipo}
        style="--color-principal: {opcion.color}; --gradiente: {opcion.gradiente}"
        on:click={() => manejarSeleccion(opcion.tipo)}
        on:keydown={(e) => e.key === 'Enter' && manejarSeleccion(opcion.tipo)}
        role="button"
        tabindex="0"
      >
        <div class="icono-contenido">
          {opcion.icono}
        </div>
        
        <div class="info-contenido">
          <h3>{opcion.titulo}</h3>
          <p>{opcion.descripcion}</p>
        </div>
        
        <div class="caracteristicas">
          {#each opcion.caracteristicas as caracteristica}
            <span class="caracteristica-badge">{caracteristica}</span>
          {/each}
        </div>
        
        <div class="overlay-seleccion">
          <span class="check-icon">✓</span>
          <span class="texto-seleccion">SELECCIONADO</span>
        </div>
      </div>
    {/each}
  </div>

  {#if tipoSeleccionado}
    <div class="info-seleccion">
      <div class="seleccion-actual">
        <span class="icono-seleccionado">
          {opciones.find(o => o.tipo === tipoSeleccionado)?.icono}
        </span>
        <div class="texto-seleccionado">
          <strong>Tipo seleccionado:</strong>
          {opciones.find(o => o.tipo === tipoSeleccionado)?.titulo}
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .selector-contenido {
    padding: 1rem;
  }

  .titulo-seccion {
    text-align: center;
    margin-bottom: 2rem;
  }

  .titulo-seccion h2 {
    font-size: 2rem;
    margin-bottom: 0.5rem;
    background: linear-gradient(45deg, #4ecdc4, #44a08d);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .titulo-seccion p {
    color: #b8b8d4;
    font-size: 1.1rem;
  }

  .opciones-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  .opcion-card {
    background: rgba(255, 255, 255, 0.05);
    border: 2px solid rgba(255, 255, 255, 0.1);
    border-radius: 20px;
    padding: 1.5rem;
    cursor: pointer;
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
    backdrop-filter: blur(10px);
    min-height: 220px;
    display: flex;
    flex-direction: column;
  }

  .opcion-card:hover {
    transform: translateY(-5px);
    border-color: var(--color-principal);
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
  }

  .opcion-card.seleccionada {
    border-color: var(--color-principal);
    background: var(--gradiente);
    transform: translateY(-3px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.4);
  }

  .icono-contenido {
    font-size: 3rem;
    text-align: center;
    margin-bottom: 1rem;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
  }

  .info-contenido {
    text-align: center;
    flex-grow: 1;
  }

  .info-contenido h3 {
    font-size: 1.3rem;
    margin-bottom: 0.5rem;
    color: white;
  }

  .info-contenido p {
    color: #b8b8d4;
    font-size: 0.9rem;
    line-height: 1.4;
    margin-bottom: 1rem;
  }

  .caracteristicas {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    justify-content: center;
    margin-top: auto;
  }

  .caracteristica-badge {
    background: rgba(255, 255, 255, 0.2);
    padding: 0.3rem 0.8rem;
    border-radius: 15px;
    font-size: 0.8rem;
    color: white;
    font-weight: 500;
  }

  .opcion-card.seleccionada .caracteristica-badge {
    background: rgba(255, 255, 255, 0.3);
  }

  .overlay-seleccion {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.7);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    opacity: 0;
    transition: opacity 0.3s ease;
    border-radius: 18px;
  }

  .opcion-card.seleccionada .overlay-seleccion {
    opacity: 1;
  }

  .check-icon {
    font-size: 3rem;
    color: var(--color-principal);
    margin-bottom: 0.5rem;
    animation: checkAnimation 0.6s ease-in-out;
  }

  .texto-seleccion {
    color: white;
    font-weight: bold;
    font-size: 1.1rem;
    letter-spacing: 1px;
  }

  @keyframes checkAnimation {
    0% {
      transform: scale(0);
      opacity: 0;
    }
    50% {
      transform: scale(1.2);
    }
    100% {
      transform: scale(1);
      opacity: 1;
    }
  }

  .info-seleccion {
    padding: 1rem;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 15px;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .seleccion-actual {
    display: flex;
    align-items: center;
    gap: 1rem;
    justify-content: center;
  }

  .icono-seleccionado {
    font-size: 2rem;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
  }

  .texto-seleccionado {
    font-size: 1.1rem;
    color: white;
  }

  .texto-seleccionado strong {
    color: #4ecdc4;
  }

  /* Efectos de focus para accesibilidad */
  .opcion-card:focus {
    outline: none;
    box-shadow: 0 0 0 3px rgba(78, 205, 196, 0.5);
  }

  /* Responsive */
  @media (max-width: 768px) {
    .opciones-grid {
      grid-template-columns: 1fr;
    }
    
    .titulo-seccion h2 {
      font-size: 1.5rem;
    }
    
    .opcion-card {
      min-height: 200px;
    }
    
    .icono-contenido {
      font-size: 2.5rem;
    }
  }

  /* Animaciones de entrada */
  .opcion-card {
    animation: slideInUp 0.6s ease-out;
  }

  .opcion-card:nth-child(1) {
    animation-delay: 0.1s;
  }

  .opcion-card:nth-child(2) {
    animation-delay: 0.2s;
  }

  .opcion-card:nth-child(3) {
    animation-delay: 0.3s;
  }

  .opcion-card:nth-child(4) {
    animation-delay: 0.4s;
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
</style> 