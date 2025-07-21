<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  
  let intentosReconexion = 0;
  let reconectando = false;
  
  onMount(() => {
    // Intentar reconectar cada 30 segundos
    const interval = setInterval(() => {
      if (navigator.onLine) {
        // Si hay conexión, redirigir a la página principal
        goto('/');
        clearInterval(interval);
      }
    }, 30000);
    
    return () => clearInterval(interval);
  });
  
  async function intentarReconectar() {
    reconectando = true;
    intentosReconexion++;
    
    try {
      // Probar conectividad con un fetch simple
      const response = await fetch('/', { method: 'HEAD' });
      if (response.ok) {
        goto('/');
        return;
      }
    } catch (error) {
      console.log('Sin conexión aún');
    }
    
    setTimeout(() => {
      reconectando = false;
    }, 2000);
  }
  
  const funcionesOffline = [
    {
      titulo: '🎵 Simulador de Acordeón',
      descripcion: 'Practica con el simulador offline',
      url: '/simulador-gaming',
      disponible: true
    },
    {
      titulo: '📱 Mi Perfil',
      descripcion: 'Ver tu información guardada',
      url: '/mi-perfil',
      disponible: true
    },
    {
      titulo: '🎯 Configuración',
      descripcion: 'Ajustar preferencias locales',
      url: '/configuracion', 
      disponible: true
    }
  ];
</script>

<svelte:head>
  <title>Sin Conexión - Academia Vallenata</title>
  <meta name="robots" content="noindex" />
</svelte:head>

<div class="offline-container">
  <div class="offline-content">
    
    <!-- Header -->
    <header class="offline-header">
      <div class="offline-icon">🎵</div>
      <h1>Academia Vallenata</h1>
      <div class="offline-status">
        <span class="status-indicator"></span>
        Sin Conexión
      </div>
    </header>

    <!-- Mensaje principal -->
    <section class="offline-message">
      <h2>📡 ¡Ups! No hay conexión a internet</h2>
      <p>No te preocupes, algunas funciones siguen disponibles mientras recuperas la conexión.</p>
    </section>

    <!-- Botón reconectar -->
    <section class="offline-actions">
      <button 
        class="btn-reconectar" 
        class:reconectando
        on:click={intentarReconectar}
        disabled={reconectando}
      >
        {#if reconectando}
          <span class="spinner"></span>
          Verificando conexión...
        {:else}
          🔄 Intentar Reconectar
        {/if}
      </button>
      
      {#if intentosReconexion > 0}
        <p class="intentos-info">Intentos: {intentosReconexion}</p>
      {/if}
    </section>

    <!-- Funciones disponibles offline -->
    <section class="funciones-offline">
      <h3>✨ Disponible sin conexión:</h3>
      
      <div class="funciones-grid">
        {#each funcionesOffline as funcion}
          <a 
            href={funcion.url}
            class="funcion-card"
            class:disponible={funcion.disponible}
          >
            <h4>{funcion.titulo}</h4>
            <p>{funcion.descripcion}</p>
            <span class="status-badge">
              {funcion.disponible ? '✅ Disponible' : '❌ Requiere conexión'}
            </span>
          </a>
        {/each}
      </div>
    </section>

    <!-- Tips de uso offline -->
    <section class="offline-tips">
      <h3>💡 Consejos para uso offline:</h3>
      <ul>
        <li>🎹 El simulador funciona completamente sin conexión</li>
        <li>💾 Tus datos se sincronizarán cuando recuperes la conexión</li>
        <li>⏰ Las notificaciones programadas seguirán funcionando</li>
        <li>🔄 La página se actualizará automáticamente al reconectarse</li>
      </ul>
    </section>

    <!-- Footer -->
    <footer class="offline-footer">
      <p>© 2024 Academia Vallenata Online</p>
      <p>Versión offline disponible 🚀</p>
    </footer>

  </div>
</div>

<style>
  .offline-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
    color: white;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    padding: 20px;
  }

  .offline-content {
    max-width: 600px;
    width: 100%;
    text-align: center;
    animation: fadeIn 0.6s ease-in;
  }

  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
  }

  /* Header */
  .offline-header {
    margin-bottom: 40px;
  }

  .offline-icon {
    font-size: 80px;
    margin-bottom: 16px;
    animation: bounce 2s infinite;
  }

  @keyframes bounce {
    0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
    40% { transform: translateY(-10px); }
    60% { transform: translateY(-5px); }
  }

  .offline-header h1 {
    margin: 0 0 16px 0;
    font-size: 32px;
    font-weight: bold;
  }

  .offline-status {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    font-size: 16px;
    opacity: 0.9;
  }

  .status-indicator {
    width: 12px;
    height: 12px;
    background: #ef4444;
    border-radius: 50%;
    animation: pulse 2s infinite;
  }

  @keyframes pulse {
    0% { transform: scale(1); opacity: 1; }
    50% { transform: scale(1.1); opacity: 0.7; }
    100% { transform: scale(1); opacity: 1; }
  }

  /* Mensaje */
  .offline-message {
    margin-bottom: 40px;
  }

  .offline-message h2 {
    margin: 0 0 16px 0;
    font-size: 24px;
  }

  .offline-message p {
    margin: 0;
    font-size: 16px;
    opacity: 0.9;
    line-height: 1.5;
  }

  /* Acciones */
  .offline-actions {
    margin-bottom: 40px;
  }

  .btn-reconectar {
    background: white;
    color: #1e40af;
    border: none;
    padding: 12px 24px;
    border-radius: 8px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
    display: inline-flex;
    align-items: center;
    gap: 8px;
  }

  .btn-reconectar:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }

  .btn-reconectar:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .btn-reconectar.reconectando {
    animation: shake 0.5s ease-in-out;
  }

  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    25% { transform: translateX(-4px); }
    75% { transform: translateX(4px); }
  }

  .spinner {
    width: 16px;
    height: 16px;
    border: 2px solid #1e40af;
    border-top: 2px solid transparent;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .intentos-info {
    margin-top: 12px;
    font-size: 14px;
    opacity: 0.8;
  }

  /* Funciones offline */
  .funciones-offline {
    margin-bottom: 40px;
    text-align: left;
  }

  .funciones-offline h3 {
    text-align: center;
    margin-bottom: 24px;
    font-size: 20px;
  }

  .funciones-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 16px;
  }

  .funcion-card {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 12px;
    padding: 20px;
    text-decoration: none;
    color: white;
    transition: all 0.3s;
  }

  .funcion-card:hover {
    background: rgba(255, 255, 255, 0.15);
    transform: translateY(-2px);
  }

  .funcion-card h4 {
    margin: 0 0 8px 0;
    font-size: 16px;
  }

  .funcion-card p {
    margin: 0 0 12px 0;
    font-size: 14px;
    opacity: 0.9;
  }

  .status-badge {
    font-size: 12px;
    padding: 4px 8px;
    border-radius: 4px;
    background: rgba(255, 255, 255, 0.2);
  }

  /* Tips */
  .offline-tips {
    text-align: left;
    margin-bottom: 40px;
  }

  .offline-tips h3 {
    text-align: center;
    margin-bottom: 20px;
    font-size: 20px;
  }

  .offline-tips ul {
    list-style: none;
    padding: 0;
    max-width: 400px;
    margin: 0 auto;
  }

  .offline-tips li {
    padding: 8px 0;
    font-size: 14px;
    line-height: 1.4;
    opacity: 0.9;
  }

  /* Footer */
  .offline-footer {
    opacity: 0.7;
    font-size: 12px;
  }

  .offline-footer p {
    margin: 4px 0;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .offline-content {
      padding: 0 16px;
    }

    .offline-icon {
      font-size: 60px;
    }

    .offline-header h1 {
      font-size: 28px;
    }

    .offline-message h2 {
      font-size: 20px;
    }

    .funciones-grid {
      grid-template-columns: 1fr;
    }
  }
</style> 