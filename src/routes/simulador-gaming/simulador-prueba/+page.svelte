<script>
    import { onMount } from 'svelte';
    // Mapea el nombre de la fila a la clase visual para CSS
    function getFilaClase(filaNombre) {
      if (filaNombre === 'primeraFila') return 'tres';
      if (filaNombre === 'segundaFila') return 'dos';
      if (filaNombre === 'terceraFila') return 'uno';
      return filaNombre;
    }
  
      import { sleep } from '$lib/components/SimuladorDefinitivo/SimuladorDeAcordeonJS/utilidadesSimulador.js';
  import { mapaTeclas, tono } from '$lib/components/SimuladorDefinitivo/SimuladorDeAcordeonJS/mapaTecladoYFrecuencias.js';
    import {
      mapaTeclasBajos,
      disposicion,
      disposicionBajos,
      mapaBotonesPorId,
      filas,
      filasBajos,
      tonosFilas,
      cambiarFuelle,
      escalas
    } from '$lib/components/SimuladorDefinitivo/SimuladorDeAcordeonJS/notasAcordeonDiatonico.js';
    
    // Audio - inicializar como variables
    let audio;
    let gainNode;
    
    // State
    let direction = 'halar';
    let afinacion = 'FBE';
    let activeButtonIdMap = {};
  
    onMount(() => {
      // Inicializar Audio solo del lado del cliente
      audio = new (window.AudioContext || window.webkitAudioContext)();
      gainNode = audio.createGain();
      gainNode.gain.value = 0.1;
      gainNode.connect(audio.destination);
    });
  
    function manejarCambioAfinacion(e) {
      afinacion = e.target.value;
    }
  
    // Handlers
    function playTone(id) {
      if (!audio) return { oscillator: null }; // Si no hay audio inicializado
      
      if (!mapaBotonesPorId[id]) {
        console.warn(`ID no encontrado en mapaBotonesPorId:`, id);
        return { oscillator: null };
      }
      const { frecuencia } = mapaBotonesPorId[id];
      let oscillator;
  
      if (Array.isArray(frecuencia)) {
        oscillator = frecuencia.map((hz) => {
          const oscillator = audio.createOscillator();
          oscillator.type = 'sawtooth';
          oscillator.connect(gainNode);
          oscillator.frequency.value = hz;
          oscillator.start();
  
          return oscillator;
        });
      } else {
        oscillator = audio.createOscillator();
        oscillator.type = 'sawtooth';
        oscillator.connect(gainNode);
        oscillator.frequency.value = frecuencia;
        oscillator.start();
      }
  
      return { oscillator };
    }
  
    function stopTone(id) {
      if (!activeButtonIdMap[id]) return;
      
      const { oscillator } = activeButtonIdMap[id];
      if (!oscillator) return;
  
      if (Array.isArray(oscillator)) {
        oscillator.forEach((osc) => osc?.stop());
      } else {
        oscillator?.stop();
      }
    }
  
    function handleToggleBellows(newDirection) {
      if (direction !== newDirection) {
        direction = newDirection;
  
        const newActiveButtonIdMap = { ...activeButtonIdMap };
        let isBass = false;
  
        // When switching the bellows
        for (const [keyId, keyValues] of Object.entries(activeButtonIdMap)) {
          // Remove existing value
          if (Array.isArray(keyValues.oscillator)) {
            isBass = true;
            keyValues.oscillator.forEach((hz) => hz?.stop());
          } else {
            keyValues.oscillator?.stop();
          }
  
          // Must be reassigned in Svelte
          delete newActiveButtonIdMap[keyId];
  
          // Add the reverse value
          const reverseKeyId = `${keyId.split('-')[0]}-${keyId.split('-')[1]}-${newDirection}${
            isBass ? '-bass' : ''
          }`;
          const { oscillator } = playTone(reverseKeyId);
  
          newActiveButtonIdMap[reverseKeyId] = { oscillator, ...mapaBotonesPorId[reverseKeyId] };
        }
        activeButtonIdMap = newActiveButtonIdMap;
      }
    }
  
    function updateActiveButtonMap(id) {
      if (!activeButtonIdMap[id]) {
        const { oscillator } = playTone(id);
        activeButtonIdMap[id] = { oscillator, ...mapaBotonesPorId[id] };
      }
    }
  
    function handleKeyPressNote(e) {
      const key = `${e.key}`.toLowerCase() || e.key;
  
      if (key === cambiarFuelle) {
        handleToggleBellows('empujar');
        return;
      }
  
      const buttonMapData = mapaTeclas[key];
      if (buttonMapData) {
        const { fila, columna } = buttonMapData;
        const id = `${fila}-${columna}-${direction}`;
        return updateActiveButtonMap(id);
      }
  
      const bassButtonMapData = mapaTeclasBajos[key];
      if (bassButtonMapData) {
        const { fila, columna } = bassButtonMapData;
        const id = `${fila}-${columna}-${direction}-bajo`;
        return updateActiveButtonMap(id);
      }
    }
  
    function handleKeyUpNote(e) {
      const key = `${e.key}`.toLowerCase() || e.key;
  
      if (key === cambiarFuelle) {
        handleToggleBellows('halar');
        return;
      }
  
      const buttonMapData = mapaTeclas[key];
      if (buttonMapData) {
        const { fila, columna } = buttonMapData;
        const id = `${fila}-${columna}-${direction}`;
  
        if (activeButtonIdMap[id]) {
          stopTone(id);
          // Must be reassigned in Svelte
          const newActiveButtonIdMap = { ...activeButtonIdMap };
          delete newActiveButtonIdMap[id];
          activeButtonIdMap = newActiveButtonIdMap;
        }
      }
  
      const bassButtonMapData = mapaTeclasBajos[key];
      if (bassButtonMapData) {
        const { fila, columna } = bassButtonMapData;
        const id = `${fila}-${columna}-${direction}-bajo`;
  
        if (activeButtonIdMap[id]) {
          stopTone(id);
          // Must be reassigned in Svelte
          const newActiveButtonIdMap = { ...activeButtonIdMap };
          delete newActiveButtonIdMap[id];
          activeButtonIdMap = newActiveButtonIdMap;
        }
      }
    }
  
    function handleClickNote(id) {
      updateActiveButtonMap(id);
    }
  
    function handleClearAllNotes() {
      for (const [keyId, keyValues] of Object.entries(activeButtonIdMap)) {
        // Remove existing value
        if (Array.isArray(keyValues.oscillator)) {
          keyValues.oscillator.forEach((hz) => hz?.stop());
        } else {
          keyValues.oscillator?.stop();
        }
      }
      activeButtonIdMap = {};
    }
  
    async function playNotesInScale(idSet) {
      handleClearAllNotes();
  
      for (const id of idSet) {
        if (!activeButtonIdMap[id]) {
          const { oscillator } = playTone(id);
          activeButtonIdMap[id] = { oscillator, ...mapaBotonesPorId[id] };
        }
      }
  
      await sleep(600);
  
      for (const id of idSet) {
        stopTone(id);
        // Must be reassigned in Svelte
        const newActiveButtonIdMap = { ...activeButtonIdMap };
        delete newActiveButtonIdMap[id];
        activeButtonIdMap = newActiveButtonIdMap;
      }
    }
  
    const playScale = (scale, type) => async () => {
      const reverse = [...escalas[scale][type]].reverse();
      reverse.shift();
      const scaleBackAndForth = [...escalas[scale][type], ...reverse];
  
      for (const idSet of scaleBackAndForth) {
        await playNotesInScale(idSet);
      }
    };
  </script>
  
  <svelte:head>
    <title>El REY</title>
  </svelte:head>
  
  <svelte:body
    on:keypress={handleKeyPressNote}
    on:keyup={handleKeyUpNote}
    on:mouseup={handleClearAllNotes} />
  
  <main>
  
    <div class="disposicion">
      <!-- Imagen de fondo del acordeón en un solo contenedor -->
      <div class="solo-escritorio disposicion-acordeon">
  <!-- Teclado lado derecho (melodía) -->
  <div class="lado-teclas">
    {#each filas as filaNombre}
      <div class={`fila ${getFilaClase(filaNombre)}`}>
        {#each disposicion[filaNombre].filter(({ id }) => id.includes(direction)) as boton}
          <div
            class={`boton ${activeButtonIdMap[boton.id] ? 'activo' : ''} ${direction}`}
            id={boton.id}
            on:mousedown={() => handleClickNote(boton.id)}
            role="button"
            tabindex="0"
            aria-pressed={activeButtonIdMap[boton.id] ? 'true' : 'false'}
            aria-label={`Nota: ${boton.nombre}`}
          >
            {boton.nombre}
          </div>
        {/each}
        <h4>{tonosFilas[afinacion][filaNombre]}<br />{filaNombre}</h4>
      </div>
    {/each}
  </div>
  
  <!-- Bajos lado izquierdo -->
  <div class="lado-bajos">
    {#each filasBajos as filaBajoNombre}
      <div class={`fila ${filaBajoNombre}`}>
        {#each disposicionBajos[filaBajoNombre].filter(({ id }) => id.includes(direction)) as botonBajo}
          <div
            class={`boton ${activeButtonIdMap[botonBajo.id] ? 'activo' : ''} ${direction}`}
            id={botonBajo.id}
            on:mousedown={() => handleClickNote(botonBajo.id)}
            role="button"
            tabindex="0"
            aria-pressed={activeButtonIdMap[botonBajo.id] ? 'true' : 'false'}
            aria-label={`Bajo: ${botonBajo.nombre}`}
          >
            {botonBajo.nombre}
          </div>
        {/each}
      </div>
    {/each}
  </div>
  </div>
    </div>
  </main>
  
  <style>
     /* ======================================================
        VARIABLES Y CONFIGURACIÓN GLOBAL
        ====================================================== */
     :root {
       --red: #ff8787; /* Color rojo para elementos de acordeón */
       --green: #8ce99a; /* Color verde para elementos de acordeón */
       --yellow: rgba(225, 224, 84, 1); /* Color amarillo para destacados */
       --blue: #5c7cfa; /* Color azul para elementos interactivos */
     }
     
     /* ======================================================
        LAYOUT Y FLEXBOX
        ====================================================== */
     .flex {
       display: flex;
       gap: 1rem;
     }
     
     .col {
       flex-direction: row;
       align-items: center;
     }
     
     .disposicion {
       display: flex;
       justify-content: center;
       align-items: center;
       width: 100%;
       height: 100vh;
       position: relative;
       padding-top: 70px;
     }
     
     /* ======================================================
        ACORDEÓN - LAYOUT
        ====================================================== */
     .disposicion-acordeon {
       display: flex;
       justify-content: center;
       align-items: center;
       text-align: center;
       background: url('/Acordeon PRO MAX.png') no-repeat center center;
       background-size: contain;
       width: 95vh;
       height: 95vh;
       position: absolute;
       left: 50%;
       top: 50%;
       transform: translate(-50%, -50%);
     }
     
     /* ======================================================
        POSICIONAMIENTO DE LOS LADOS DEL ACORDEÓN
        ====================================================== */
     
     /* 🔹 Sección de las teclas del acordeón (lado derecho/melodía) */
     .lado-teclas {
       position: absolute;
       left: 5.05%;
       top: 14%;
       display: flex;
       flex-direction: row;
       justify-content: space-between;
       width: 3.4%;
       z-index: 10;
     }
     
     /* 🔹 Estilo de los bajos (lado izquierdo) */
     .lado-bajos {
       position: absolute;
       left: 82.5%;
       top: 31%;
       display: flex;
       flex-direction: row;
       justify-content: space-between;
       width: 3.4%;
       z-index: 10;
     }
     
     /* 🔹 Fila bajos de afuera BAJOS */
     .lado-bajos .fila.uno {
       margin-right: 0.3vh;
     }
     
     /* 🔹 Fila bajos de adentro BAJOS */
     .lado-bajos .fila.dos {
       margin-top: 0;
     }
     
     /* 🔹 Configuración base de cada fila de botones */
     .fila {
       display: flex;
       flex-direction: column;
       align-items: center;
       margin-bottom: 8vh;
     }
     
     /* ======================================================
        DISEÑO DE LOS BOTONES Y FUNCIONALIDADES
        ====================================================== */
     .boton {
       display: flex;
       align-items: center;
       justify-content: center;
       border-radius: 50%;
       height: 5.1vh;
       width: 5.1vh;
       margin-bottom: 1vh;
       margin-right: 0.5vh;
       background-image: url('https://acordeonvirtual.com/wp-content/uploads/acordium-prod-av-nov-24/img/blanca.JPG');
       background-size: cover;
       background-position: center;
       box-shadow: inset 2px 2px 5px rgba(255, 255, 255, 0.6), 0px 6px rgba(0, 0, 0, 0.3);
       color: #222;
       font-weight: 600;
       font-size: 1.8vh;
       cursor: pointer;
       transition: all 0.2s ease-in-out;
     }
     
     /* Efecto hover en los botones */
     .boton:hover {
       filter: brightness(1.1);
       transform: scale(1.05);
     }
     
     .boton.activo {
       transform: translateY(4px);
       box-shadow: inset 2px 2px 5px rgba(255, 255, 255, 0.6), 0px 2px rgba(0, 0, 0, 0.3);
       background-image: url('https://acordeonvirtual.com/wp-content/uploads/acordium-prod-av-nov-24/img/blanca-activa.JPG');
       color: #ffffff;
     }
     
     /* Colores sutiles del fuelle */
     .boton.halar.activo {
       background: rgba(0, 200, 0, 0.6);
       border: 2px solid rgba(0, 200, 0, 0.5);
       box-shadow: 0px 6px 10px rgba(0, 200, 0, 0.4);
     }
     
     .boton.empujar.activo {
       background: rgba(200, 0, 0, 0.3);
       border: 2px solid rgba(200, 0, 0, 0.5);
       box-shadow: 0px 6px 10px rgba(200, 0, 0, 0.4);
     }
     
     /* ======================================================
        DISTRIBUCIÓN DE BOTONES ESPECÍFICOS
        ====================================================== */
     /*  Hilera interna de pitos */
     .lado-teclas .fila.tres {
       margin-top: 3vh;
     }
     
     /*  Hilera interna de pitos */
     .lado-teclas .fila.dos {
       margin-top: 0;
     }
     
     .lado-teclas .fila.uno {
       margin-top: 3vh;
     }
     
     /* 🔹 Espaciado entre los botones dentro de cada fila */
     .fila .boton {
       margin-bottom: 1vh;
     }
     
     /* 🔹 Texto para nombrar cada hilera */
     .fila h4 {
       margin-top: 0.4vh;
       font-size: 1.2vh;
       text-align: center;
       color: #efeaea;
     }
     
     
     @media screen and (min-width: 600px) {
       .solo-escritorio {
         display: flex !important;
       }
     
       .solo-movil {
         display: none !important;
       }
     
       .disposicion {
         flex-direction: column;
         justify-content: center;
         align-items: center;
         width: 100%;
         height: 100vh;
       }
     }
     
     /* ======================================================
        MEDIA QUERIES - RESPONSIVE
        ====================================================== */
     @media (max-width: 1200px) {
       .disposicion-acordeon {
         width: 90vh;
         height: 90vh;
       }
     }
     
     @media (max-width: 992px) {
       .disposicion-acordeon {
         width: 85vh;
         height: 85vh;
       }
       
       .boton {
         height: 5vh;
         width: 5vh;
         font-size: 1.6vh;
       }
     }
     
  
  </style> 
  
  