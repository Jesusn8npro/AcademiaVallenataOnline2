<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  
  let loading = true;
  let datosError: any = null;
  
  onMount(async () => {
    try {
      // Obtener parámetros de la URL
      const urlParams = new URLSearchParams(window.location.search);
      const refPayco = urlParams.get('ref_payco');
      const codigo = urlParams.get('cod_response');
      const descripcion = urlParams.get('response_reason_text');
      
      datosError = {
        referencia: refPayco || 'No disponible',
        codigo: codigo || '0',
        descripcion: descripcion || 'Error desconocido',
        fecha: new Date().toLocaleDateString('es-CO'),
        hora: new Date().toLocaleTimeString('es-CO')
      };
      
      loading = false;
      
    } catch (err) {
      console.error('Error cargando datos del error:', err);
      loading = false;
    }
  });
  
  function intentarDeNuevo() {
    // Volver a la página anterior o al curso
    history.back();
  }
  
  function irAInicio() {
    goto('/');
  }
  
  function contactarSoporte() {
    // Puedes cambiar esto por tu método de contacto preferido
    window.open('https://wa.me/573001234567?text=Hola, tuve un problema con mi pago. Referencia: ' + (datosError?.referencia || ''), '_blank');
  }
</script>

<svelte:head>
  <title>Error en el Pago - Academia Vallenata Online</title>
</svelte:head>

<div class="container">
  {#if loading}
    <div class="loading">
      <div class="spinner"></div>
      <p>Verificando información del error...</p>
    </div>
  {:else}
    <div class="error-container">
      <!-- Icono de error -->
      <div class="error-icon">
        <div class="x-mark">✕</div>
      </div>
      
      <!-- Título principal -->
      <h1>¡Oops! Algo salió mal</h1>
      <p class="subtitle">Tu pago no pudo ser procesado correctamente</p>
      
      <!-- Información del error -->
      {#if datosError}
        <div class="error-info">
          <h2>Detalles del error</h2>
          
          <div class="info-grid">
            <div class="info-item">
              <span class="label">Referencia:</span>
              <span class="value">{datosError.referencia}</span>
            </div>
            
            <div class="info-item">
              <span class="label">Código de error:</span>
              <span class="value error-code">{datosError.codigo}</span>
            </div>
            
            <div class="info-item">
              <span class="label">Descripción:</span>
              <span class="value">{datosError.descripcion}</span>
            </div>
            
            <div class="info-item">
              <span class="label">Fecha del intento:</span>
              <span class="value">{datosError.fecha} - {datosError.hora}</span>
            </div>
          </div>
        </div>
      {/if}
      
      <!-- Posibles causas -->
      <div class="causes-info">
        <h3>Posibles causas:</h3>
        <ul>
          <li>Fondos insuficientes en la tarjeta</li>
          <li>Datos de la tarjeta incorrectos</li>
          <li>Tarjeta bloqueada o vencida</li>
          <li>Problema temporal con el procesador de pagos</li>
          <li>Límites de transacción excedidos</li>
        </ul>
      </div>
      
      <!-- Acciones -->
      <div class="actions">
        <button on:click={intentarDeNuevo} class="btn btn-primary">
          🔄 Intentar de Nuevo
        </button>
        
        <button on:click={contactarSoporte} class="btn btn-support">
          💬 Contactar Soporte
        </button>
        
        <button on:click={irAInicio} class="btn btn-secondary">
          🏠 Volver al Inicio
        </button>
      </div>
      
      <!-- Mensaje de ayuda -->
      <div class="help-info">
        <p>
          <strong>¿Necesitas ayuda?</strong><br>
          No te preocupes, estos errores son comunes y tienen solución.
          Puedes intentar nuevamente con otra tarjeta o contactar a nuestro
          equipo de soporte para recibir asistencia personalizada.
        </p>
      </div>
    </div>
  {/if}
</div>

<style>
  .container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
    padding: 20px;
    font-family: 'Arial', sans-serif;
  }
  
  .loading {
    text-align: center;
    color: white;
  }
  
  .spinner {
    border: 4px solid rgba(255, 255, 255, 0.3);
    border-top: 4px solid white;
    border-radius: 50%;
    width: 40px;
    height: 40px;
    animation: spin 1s linear infinite;
    margin: 0 auto 20px;
  }
  
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  .error-container {
    background: white;
    border-radius: 20px;
    padding: 40px;
    max-width: 600px;
    width: 100%;
    text-align: center;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
    position: relative;
    overflow: hidden;
  }
  
  .error-icon {
    margin-bottom: 30px;
  }
  
  .x-mark {
    background: #e74c3c;
    color: white;
    border-radius: 50%;
    width: 80px;
    height: 80px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 40px;
    font-weight: bold;
    margin: 0 auto;
    animation: shakeIn 0.6s ease-out;
  }
  
  @keyframes shakeIn {
    0% { transform: scale(0.3) rotate(-10deg); opacity: 0; }
    50% { transform: scale(1.05) rotate(5deg); }
    70% { transform: scale(0.9) rotate(-2deg); }
    100% { transform: scale(1) rotate(0deg); opacity: 1; }
  }
  
  h1 {
    color: #333;
    font-size: 2.5rem;
    margin-bottom: 10px;
    font-weight: bold;
  }
  
  .subtitle {
    color: #666;
    font-size: 1.2rem;
    margin-bottom: 30px;
  }
  
  .error-info {
    background: #fff5f5;
    border-radius: 15px;
    padding: 30px;
    margin-bottom: 30px;
    text-align: left;
    border: 1px solid #fed7d7;
  }
  
  .error-info h2 {
    color: #333;
    margin-bottom: 20px;
    text-align: center;
    font-size: 1.5rem;
  }
  
  .info-grid {
    display: grid;
    gap: 15px;
  }
  
  .info-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 0;
    border-bottom: 1px solid #fed7d7;
  }
  
  .info-item:last-child {
    border-bottom: none;
  }
  
  .label {
    font-weight: 600;
    color: #555;
  }
  
  .value {
    color: #333;
    font-weight: 500;
  }
  
  .error-code {
    color: #e74c3c;
    font-weight: bold;
    font-family: monospace;
  }
  
  .causes-info {
    background: #f8f9fa;
    border-radius: 15px;
    padding: 25px;
    margin-bottom: 30px;
    text-align: left;
  }
  
  .causes-info h3 {
    color: #333;
    margin-bottom: 15px;
    text-align: center;
  }
  
  .causes-info ul {
    margin: 0;
    padding-left: 20px;
    color: #555;
    line-height: 1.6;
  }
  
  .causes-info li {
    margin-bottom: 8px;
  }
  
  .actions {
    display: flex;
    gap: 15px;
    justify-content: center;
    margin-bottom: 30px;
    flex-wrap: wrap;
  }
  
  .btn {
    padding: 15px 25px;
    border: none;
    border-radius: 25px;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    gap: 8px;
  }
  
  .btn-primary {
    background: #3498db;
    color: white;
  }
  
  .btn-primary:hover {
    background: #2980b9;
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(52, 152, 219, 0.4);
  }
  
  .btn-support {
    background: #27ae60;
    color: white;
  }
  
  .btn-support:hover {
    background: #229954;
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(39, 174, 96, 0.4);
  }
  
  .btn-secondary {
    background: #6c757d;
    color: white;
  }
  
  .btn-secondary:hover {
    background: #5a6268;
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(108, 117, 125, 0.4);
  }
  
  .help-info {
    background: #e8f4fd;
    border-radius: 10px;
    padding: 20px;
    border-left: 4px solid #3498db;
  }
  
  .help-info p {
    margin: 0;
    color: #2c3e50;
    line-height: 1.6;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .container {
      padding: 10px;
    }
    
    .error-container {
      padding: 20px;
    }
    
    h1 {
      font-size: 2rem;
    }
    
    .actions {
      flex-direction: column;
    }
    
    .btn {
      width: 100%;
      justify-content: center;
    }
  }
</style> 