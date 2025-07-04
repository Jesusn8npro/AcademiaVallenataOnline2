<script lang="ts">
  export let abierto = false;
  export let onCerrar = () => {};

  function handleModalClick(event: MouseEvent) {
    if (event.target === event.currentTarget) {
      onCerrar();
    }
  }

  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Escape') {
      onCerrar();
    }
  }

  // Prevenir scroll del body cuando el modal está abierto
  $: if (abierto) {
    document.body.style.overflow = 'hidden';
  } else {
    document.body.style.overflow = '';
  }
</script>

{#if abierto}
  <div 
    class="modal-busqueda-overlay" 
    on:click={handleModalClick}
    on:keydown={handleKeydown}
    role="dialog"
    aria-modal="true"
    aria-label="Modal de búsqueda"
    tabindex="-1"
  >
    <div class="modal-busqueda-contenido">
      <!-- Botón cerrar -->
      <button class="boton-cerrar-modal" on:click={onCerrar} aria-label="Cerrar búsqueda">
        <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
          <path stroke="#ff6600" stroke-width="2" stroke-linecap="round" d="M18 6L6 18M6 6l12 12"/>
        </svg>
      </button>
      
      <!-- Contenido principal -->
      <div class="busqueda-principal">
        <div class="input-busqueda-container">
          <input 
            type="search" 
            placeholder="Search Here..." 
            class="input-busqueda-modal"
          />
          <button class="boton-buscar-modal" aria-label="Buscar">
            <svg width="20" height="20" fill="none" viewBox="0 0 24 24">
              <circle cx="11" cy="11" r="7" stroke="#ff6600" stroke-width="2"/>
              <path d="M20 20l-3.5-3.5" stroke="#ff6600" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </button>
        </div>
        
        <p class="texto-descriptivo">
          Explore la experiencia de la Academia Vallenata
        </p>
      </div>
    </div>
  </div>
{/if}

<style>
.modal-busqueda-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 3000;
}

.modal-busqueda-contenido {
  width: 100%;
  height: 100%;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

.boton-cerrar-modal {
  position: absolute;
  top: 2rem;
  right: 2rem;
  background: #ffffff;
  border: none;
  padding: 8px;
  cursor: pointer;
  border-radius: 50%;
  transition: background 0.2s;
}

.boton-cerrar-modal:hover {
  background: rgba(255, 102, 0, 0.1);
}

.busqueda-principal {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  max-width: 600px;
  width: 100%;
  padding: 0 2rem;
}

.input-busqueda-container {
  display: flex;
  align-items: center;
  background: transparent;
  border: 2px solid #ff6600;
  border-radius: 50px;
  padding: 4px 4px 4px 20px;
  margin-bottom: 2rem;
  width: 100%;
  max-width: 500px;
}

.input-busqueda-modal {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  padding: 16px 12px;
  font-size: 1.1rem;
  color: #fff;
  font-family: inherit;
}

.input-busqueda-modal::placeholder {
  color: rgba(255, 255, 255, 0.7);
}

.boton-buscar-modal {
  background: #ff6600;
  border: none;
  border-radius: 50%;
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s;
  margin-left: 8px;
}

.boton-buscar-modal:hover {
  background: #e14d00;
}

.texto-descriptivo {
  color: rgba(255, 255, 255, 0.8);
  font-size: 1.1rem;
  text-align: center;
  margin: 0;
  font-weight: 300;
  letter-spacing: 0.5px;
}

/* Responsive */
@media (max-width: 768px) {
  .busqueda-principal {
    padding: 0 1rem;
  }
  
  .input-busqueda-container {
    max-width: 100%;
  }
  
  .boton-cerrar-modal {
    top: 1rem;
    right: 1rem;
  }
  
  .texto-descriptivo {
    font-size: 1rem;
  }
}
</style>
