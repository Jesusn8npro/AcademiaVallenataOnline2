<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';

  onMount(() => {
    // Redirigir inmediatamente al simulador gaming protegido
    goto('/simulador-gaming', { replaceState: true });
  });
</script>

<svelte:head>
  <title>Simulador de Acordeón - Redirigiendo...</title>
  <meta name="robots" content="noindex, nofollow">
</svelte:head>

<!-- Mostrar mensaje de redirección temporal -->
<div class="redirigiendo">
  <div class="mensaje">
    <div class="spinner"></div>
    <h2>Redirigiendo al Simulador...</h2>
    <p>Te llevamos al simulador de acordeón más avanzado</p>
  </div>
</div>

<style>
  .redirigiendo {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
    color: white;
  }

  .mensaje {
    text-align: center;
    padding: 2rem;
    background: rgba(0, 0, 0, 0.7);
    border-radius: 20px;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid rgba(230, 168, 0, 0.3);
    border-top: 4px solid #e6a800;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 1.5rem auto;
  }

  h2 {
    color: #f1f5f9;
    font-size: 1.5rem;
    margin-bottom: 0.5rem;
  }

  p {
    color: #94a3b8;
    font-size: 1rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
</style> 