<!-- Página de demostración de todos los efectos de sonido -->
<script lang="ts">
  import { 
    audioManager, 
    TipoEfectoUI, 
    TipoEfectoUI2, 
    TipoEfectoJuego 
  } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
  import FondoEspacial from '$lib/components/SimuladorDefinitivo/components/efectos/FondoEspacial.svelte';
  import { goto } from '$app/navigation';
  
  // Organizados por categorías para mostrar
  const efectosUI = Object.entries(TipoEfectoUI).map(([nombre, valor]) => ({
    nombre: nombre.replace(/_/g, ' ').toLowerCase(),
    valor,
    descripcion: getDescripcionUI(nombre)
  }));
  
  const efectosUI2 = Object.entries(TipoEfectoUI2).map(([nombre, valor]) => ({
    nombre: nombre.replace(/_/g, ' ').toLowerCase(),
    valor,
    descripcion: getDescripcionUI2(nombre)
  }));
  
  const efectosJuego = Object.entries(TipoEfectoJuego).map(([nombre, valor]) => ({
    nombre: nombre.replace(/_/g, ' ').toLowerCase(),
    valor,
    descripcion: getDescripcionJuego(nombre)
  }));
  
  function getDescripcionUI(nombre: string): string {
    const descripciones: Record<string, string> = {
      'HOVER_SUTIL': 'Efecto suave para hover de botones',
      'CLICK_BOTON': 'Click principal de botones importantes',
      'CLICK_GENERAL': 'Click general para elementos',
      'POP': 'Efecto pop para apariciones',
      'SLIDE_1': 'Deslizamiento suave',
      'SLIDE_2': 'Deslizamiento de pestañas',
      'HOVER_NAVEGACION': 'Hover sutil para navegación',
      'MODAL_ABRIR': 'Abrir ventana modal',
      'MODAL_CERRAR': 'Cerrar ventana modal',
      'ALERTA_PING': 'Notificación de alerta',
      'ALERTA_BONK': 'Error o acción denegada',
      'ALERTA_LOOSE': 'Perder o fallar',
      'EVENTO_IMPORTANTE': 'Eventos importantes del juego',
      'FLOURISH': 'Efecto decorativo elegante',
      'ESPACIAL': 'Efecto futurista/espacial',
      'TELETRANSPORTE': 'Efecto de teletransporte',
      'PROFUNDO': 'Efecto profundo/grave',
      'INICIO': 'Arranque del sistema',
      'DENEGAR': 'Acción denegada',
      'DENEGAR_2': 'Acción denegada alternativa',
    };
    return descripciones[nombre] || 'Efecto UI';
  }
  
  function getDescripcionUI2(nombre: string): string {
    const descripciones: Record<string, string> = {
      'CHECKBOX_DOWN': 'Checkbox presionado',
      'CHECKBOX_ON': 'Checkbox activado',
      'CHECKBOX_OFF': 'Checkbox desactivado',
      'BOTON_GENERAL': 'Botón general alternativo',
      'BOTON_ATRAS': 'Botón de retroceso',
      'EXITO': 'Éxito/victoria',
      'ERROR': 'Error del sistema',
      'ADVERTENCIA': 'Advertencia importante',
      'FANFARRIA': 'Celebración épica',
      'DRUMS': 'Ritmo de batería',
    };
    return descripciones[nombre] || 'Efecto UI2';
  }
  
  function getDescripcionJuego(nombre: string): string {
    const descripciones: Record<string, string> = {
      'NOTA_DU': 'Nota musical du',
      'NOTA_DU2': 'Nota musical du (variante)',
      'NOTA_TA': 'Nota musical ta',
      'EXPLOSION': 'Explosión normal',
      'EXPLOSION_LARGA': 'Explosión extendida',
      'WHOOSH': 'Efecto de viento/movimiento',
      'CRISTAL': 'Efecto cristalino',
      'WOW': 'Exclamación de asombro',
      'EXITO_GENERAL': 'Éxito general',
      'ERROR_JUEGO': 'Error en el juego',
    };
    return descripciones[nombre] || 'Efecto de juego';
  }
  
  function probarEfecto(valor: string) {
    audioManager.playEffect(valor);
  }
  
  function probarEfectoHover(valor: string) {
    audioManager.playHoverEffect(valor);
  }
  
  function probarTodosSonidos() {
    let delay = 0;
    
    // Reproducir todos los efectos con delay
    [...efectosUI, ...efectosUI2, ...efectosJuego].forEach((efecto, index) => {
      setTimeout(() => {
        audioManager.playEffect(efecto.valor);
      }, delay);
      delay += 800; // 800ms entre cada sonido
    });
  }
  
  function volverInicio() {
    audioManager.transicion();
    goto('/simulador-gaming');
  }
</script>

<svelte:head>
  <title>Prueba de Sonidos - Acordeón Simulator</title>
</svelte:head>

<FondoEspacial />

<div class="contenedor-principal">
  <div class="contenedor-sonidos">
    <div class="header">
      <h1>🎵 Prueba de Todos los Sonidos</h1>
      <p class="descripcion">
        Todos los efectos de sonido de Rhythm Plus implementados en tu simulador
      </p>
      
      <div class="controles-globales">
        <button class="boton-global exito" on:click={probarTodosSonidos}>
          🎼 Reproducir Todos (Demo)
        </button>
        <button class="boton-global atras" on:click={volverInicio}>
          🏠 Volver al Inicio
        </button>
      </div>
    </div>
    
    <!-- Efectos UI Principales -->
    <div class="categoria">
      <h2>🎛️ Efectos UI Principales</h2>
      <div class="grid-efectos">
        {#each efectosUI as efecto}
          <div class="tarjeta-efecto">
            <h3>{efecto.nombre}</h3>
            <p class="descripcion-efecto">{efecto.descripcion}</p>
            <div class="controles-efecto">
              <button 
                class="boton-efecto primario" 
                on:click={() => probarEfecto(efecto.valor)}
              >
                🔊 Reproducir
              </button>
              <button 
                class="boton-efecto secundario" 
                on:click={() => probarEfectoHover(efecto.valor)}
              >
                👆 Hover
              </button>
            </div>
            <div class="ruta-archivo">
              <code>{efecto.valor}</code>
            </div>
          </div>
        {/each}
      </div>
    </div>
    
    <!-- Efectos UI2 -->
    <div class="categoria">
      <h2>🎮 Efectos UI Secundarios</h2>
      <div class="grid-efectos">
        {#each efectosUI2 as efecto}
          <div class="tarjeta-efecto">
            <h3>{efecto.nombre}</h3>
            <p class="descripcion-efecto">{efecto.descripcion}</p>
            <div class="controles-efecto">
              <button 
                class="boton-efecto primario" 
                on:click={() => probarEfecto(efecto.valor)}
              >
                🔊 Reproducir
              </button>
              <button 
                class="boton-efecto secundario" 
                on:click={() => probarEfectoHover(efecto.valor)}
              >
                👆 Hover
              </button>
            </div>
            <div class="ruta-archivo">
              <code>{efecto.valor}</code>
            </div>
          </div>
        {/each}
      </div>
    </div>
    
    <!-- Efectos de Juego -->
    <div class="categoria">
      <h2>🎯 Efectos de Juego</h2>
      <div class="grid-efectos">
        {#each efectosJuego as efecto}
          <div class="tarjeta-efecto">
            <h3>{efecto.nombre}</h3>
            <p class="descripcion-efecto">{efecto.descripcion}</p>
            <div class="controles-efecto">
              <button 
                class="boton-efecto primario" 
                on:click={() => probarEfecto(efecto.valor)}
              >
                🔊 Reproducir
              </button>
              <button 
                class="boton-efecto secundario" 
                on:click={() => probarEfectoHover(efecto.valor)}
              >
                👆 Hover
              </button>
            </div>
            <div class="ruta-archivo">
              <code>{efecto.valor}</code>
            </div>
          </div>
        {/each}
      </div>
    </div>
  </div>
</div>

<style>
  .contenedor-principal {
    min-height: 100vh;
    padding: 2rem;
    position: relative;
    z-index: 1;
  }
  
  .contenedor-sonidos {
    max-width: 1200px;
    margin: 0 auto;
  }
  
  .header {
    text-align: center;
    margin-bottom: 3rem;
  }
  
  .header h1 {
    font-size: 2.5rem;
    color: #ffffff;
    margin-bottom: 1rem;
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8);
  }
  
  .descripcion {
    color: rgba(255, 255, 255, 0.8);
    font-size: 1.1rem;
    margin-bottom: 2rem;
  }
  
  .controles-globales {
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
  }
  
  .boton-global {
    padding: 12px 24px;
    border: none;
    border-radius: 25px;
    font-size: 1rem;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  
  .boton-global.exito {
    background: linear-gradient(135deg, #4ecdc4, #44a08d);
    color: white;
  }
  
  .boton-global.atras {
    background: linear-gradient(135deg, #667eea, #764ba2);
    color: white;
  }
  
  .boton-global:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
  }
  
  .categoria {
    margin-bottom: 3rem;
  }
  
  .categoria h2 {
    color: #ffffff;
    font-size: 1.8rem;
    margin-bottom: 1.5rem;
    text-align: center;
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
  }
  
  .grid-efectos {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 1.5rem;
  }
  
  .tarjeta-efecto {
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 15px;
    padding: 1.5rem;
    backdrop-filter: blur(10px);
    transition: all 0.3s ease;
  }
  
  .tarjeta-efecto:hover {
    background: rgba(255, 255, 255, 0.15);
    transform: translateY(-2px);
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
  }
  
  .tarjeta-efecto h3 {
    color: #ffffff;
    font-size: 1.2rem;
    margin-bottom: 0.5rem;
    text-transform: capitalize;
  }
  
  .descripcion-efecto {
    color: rgba(255, 255, 255, 0.7);
    font-size: 0.9rem;
    margin-bottom: 1rem;
    line-height: 1.4;
  }
  
  .controles-efecto {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }
  
  .boton-efecto {
    padding: 8px 16px;
    border: none;
    border-radius: 20px;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.3s ease;
    flex: 1;
  }
  
  .boton-efecto.primario {
    background: linear-gradient(135deg, #ff6b6b, #ee5a24);
    color: white;
  }
  
  .boton-efecto.secundario {
    background: rgba(255, 255, 255, 0.2);
    color: white;
    border: 1px solid rgba(255, 255, 255, 0.3);
  }
  
  .boton-efecto:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  }
  
  .ruta-archivo {
    margin-top: 0.5rem;
    padding: 0.5rem;
    background: rgba(0, 0, 0, 0.3);
    border-radius: 5px;
    border-left: 3px solid #4ecdc4;
  }
  
  .ruta-archivo code {
    color: #4ecdc4;
    font-size: 0.8rem;
    font-family: 'Courier New', monospace;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .contenedor-principal {
      padding: 1rem;
    }
    
    .header h1 {
      font-size: 2rem;
    }
    
    .grid-efectos {
      grid-template-columns: 1fr;
    }
    
    .controles-globales {
      flex-direction: column;
      align-items: center;
    }
    
    .boton-global {
      width: 100%;
      max-width: 300px;
    }
  }
</style> 