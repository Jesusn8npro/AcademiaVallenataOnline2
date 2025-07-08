<script>
    // --- LÓGICA DE SVELTE (Sin cambios) ---
    let abierto = false;
  
    function toggleFuelle() {
      abierto = !abierto;
    }
  </script>
  
  <div class="escenario">
    <button on:click={toggleFuelle}>
      {abierto ? 'Cerrar Acordeón' : 'Abrir Acordeón'}
    </button>
  
    <div class="cuerpo-acordeon">
      <div class="marco superior">
        <div class="nombre-marca">Cassoto</div>
      </div>
  
      <div class="fuelle-wrapper">
        <div class="fuelle" class:abierto>
          
          <div class="esquina izquierda"></div>
          <div class="esquina derecha"></div>
  
          <div class="texto-cerrado">Simulador</div>
  
          <div class="pliegues-centrales">
            {#each Array(20) as _, i}
              <div class="segmento"></div>
            {/each}
          </div>
  
        </div>
      </div>
  
      <div class="marco inferior"></div>
    </div>
  </div>
  
  <style>
    /* --- Contenedor General, Botón, Marcos (Sin cambios) --- */
    .escenario { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; background: #1e1e1e; padding: 2rem; overflow: hidden; }
    .cuerpo-acordeon { width: 700px; max-width: 90%; }
    button { margin-bottom: 2.5rem; padding: 10px 20px; font-size: 1rem; font-weight: bold; color: white; background: #0d6efd; border: none; border-radius: 8px; cursor: pointer; transition: background-color 0.3s, transform 0.1s; }
    button:active { transform: scale(0.95); }
    .marco { background: #1a1a1a; height: 50px; position: relative; border-left: 5px solid #282828; border-right: 5px solid #282828; }
    .marco.superior { border-top-left-radius: 8px; border-top-right-radius: 8px; border-top: 3px solid #333; display: flex; align-items: center; justify-content: center; }
    .marco.inferior { border-bottom-left-radius: 8px; border-bottom-right-radius: 8px; border-bottom: 3px solid #333; }
    .marco::before { content: ''; position: absolute; left: 0; right: 0; height: 4px; background: linear-gradient(to right, #a88d52, #e7d192, #a88d52); box-shadow: 0 0 5px rgba(255, 215, 0, 0.5); }
    .marco.superior::before { top: 8px; }
    .marco.inferior::before { bottom: 8px; }
    .nombre-marca { color: #d1d1d1; font-family: 'Times New Roman', serif; font-size: 2.5rem; font-style: italic; font-weight: 100; letter-spacing: 2px; opacity: 0.8; }
    
    /* --- El Fuelle 3D (Wrapper y Fuelle principal) --- */
    .fuelle-wrapper {
      perspective: 1500px;
    }
    .fuelle {
      position: relative;
      width: 100%;
      height: 180px;
      transform-style: preserve-3d;
      cursor: pointer;
      transform-origin: center;
      transform: scaleY(0);
      transition: transform 0.7s cubic-bezier(0.65, 0, 0.35, 1);
    }
    .fuelle.abierto {
      transform: scaleY(1);
    }
  
    /* Texto "Simulador" */
    .texto-cerrado {
      position: absolute;
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #1a1a1a;
      color: #e0e0e0;
      font-size: 2.5rem;
      font-weight: bold;
      font-family: Arial, sans-serif;
      letter-spacing: 2px;
      z-index: 10;
      opacity: 0;
      transition: opacity 0.2s ease-out;
    }
    .fuelle:not(.abierto) .texto-cerrado {
       opacity: 1;
       transition: opacity 0.2s 0.5s ease-in;
    }
  
    /* ======================================================= */
    /* ===== ¡NUEVO! Estilos para las Esquinas Metálicas ===== */
    /* ======================================================= */
    .esquina {
      position: absolute;
      top: 0;
      width: 40px; /* Ancho de la pieza metálica */
      height: 100%;
      z-index: 5; /* Se asegura que esté por encima de los pliegues */
      
      /* Fondo en capas para simular metal pulido y apilado */
      background-image:
        /* 1. Capa de brillo central para dar curvatura */
        linear-gradient(to right, 
          rgba(255,255,255,0) 0%, 
          rgba(255,255,255,0.3) 50%, 
          rgba(255,255,255,0) 100%
        ),
        /* 2. Capa de placas metálicas apiladas */
        repeating-linear-gradient(to bottom,
          #d1d1d1,
          #a8a8a8 5%,
          #8a8a8a 50%,
          #a8a8a8 95%,
          #505050 100% /* Línea oscura de separación */
        );
  
      /* Hacemos que el gradiente de placas se repita verticalmente */
      background-size: 100% 10px; /* Cada "placa" mide 10px de alto */
    }
  
    .esquina.izquierda {
      left: 0;
      border-top-left-radius: 5px;
      border-bottom-left-radius: 5px;
    }
    .esquina.derecha {
      right: 0;
      border-top-right-radius: 5px;
      border-bottom-right-radius: 5px;
    }
  
    /* ========================================================== */
    /* ===== ¡AJUSTE! Pliegues centrales y Segmento Individual ===== */
    /* ========================================================== */
    
    /* Nuevo contenedor para los pliegues, para que no queden debajo de las esquinas */
    .pliegues-centrales {
      position: absolute;
      /* Ocupa el espacio entre las dos esquinas (100% - 40px - 40px) */
      width: calc(100% - 80px); 
      height: 100%;
      left: 40px; /* Lo movemos para que empiece después de la esquina izquierda */
      transform-style: preserve-3d;
    }
  
    .segmento {
      position: absolute;
      width: 100%; /* Ahora es 100% del contenedor .pliegues-centrales */
      height: 100%;
      backface-visibility: hidden;
      background-image:
        repeating-linear-gradient(
          to right,
          #FDEE73 0,
          #FDEE73 1px,
          transparent 1px,
          transparent 10px
        ),
        linear-gradient(
          180deg,
          #000000 0%,
          #0c2a8c 15%,
          #1544d4 50%,
          #0c2a8c 85%,
          #000000 100%
        );
      background-size: cover;
    }
  
    /* Posicionamiento 3D (sin cambios en los valores) */
    .segmento:nth-child(2) { transform: rotateX(9deg) translateZ(85px); }
    .segmento:nth-child(3) { transform: rotateX(18deg) translateZ(83px); }
    .segmento:nth-child(4) { transform: rotateX(27deg) translateZ(79px); }
    .segmento:nth-child(5) { transform: rotateX(36deg) translateZ(73px); }
    .segmento:nth-child(6) { transform: rotateX(45deg) translateZ(66px); }
    .segmento:nth-child(7) { transform: rotateX(54deg) translateZ(58px); }
    .segmento:nth-child(8) { transform: rotateX(63deg) translateZ(48px); }
    .segmento:nth-child(9) { transform: rotateX(72deg) translateZ(37px); }
    .segmento:nth-child(10) { transform: rotateX(81deg) translateZ(25px); }
    .segmento:nth-child(11) { transform: rotateX(90deg) translateZ(12px); }
    .segmento:nth-child(12) { transform: rotateX(99deg) translateZ(0px); }
    .segmento:nth-child(13) { transform: rotateX(108deg) translateZ(-12px); }
    .segmento:nth-child(14) { transform: rotateX(117deg) translateZ(-25px); }
    .segmento:nth-child(15) { transform: rotateX(126deg) translateZ(-37px); }
    .segmento:nth-child(16) { transform: rotateX(135deg) translateZ(-48px); }
    .segmento:nth-child(17) { transform: rotateX(144deg) translateZ(-58px); }
    .segmento:nth-child(18) { transform: rotateX(153deg) translateZ(-66px); }
    .segmento:nth-child(19) { transform: rotateX(162deg) translateZ(-73px); }
    .segmento:nth-child(20) { transform: rotateX(171deg) translateZ(-79px); }
    .segmento:nth-child(21) { transform: rotateX(180deg) translateZ(-85px); }
  </style>