<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  
  let procesando = true;
  let mensaje = 'Procesando tu pago...';
  let progreso = 0;
  let exito = false;
  let error = '';
  
  onMount(async () => {
    try {
      // Obtener referencia del pago de la URL
      const refPayco = $page.url.searchParams.get('ref_payco');
      
      if (!refPayco) {
        throw new Error('Referencia de pago no encontrada');
      }
      
      console.log('🔄 Iniciando confirmación automática del pago:', refPayco);
      
      // Paso 1: Consultar estado actual
      mensaje = 'Consultando estado del pago...';
      progreso = 25;
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Paso 2: Confirmar pago automáticamente
      mensaje = 'Confirmando pago e inscribiendo...';
      progreso = 50;
      
      const responseConfirmar = await fetch('/api/pagos/confirmar', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
          ref_payco: refPayco,
          forzar_confirmacion: false 
        })
      });
      
      const resultadoConfirmacion = await responseConfirmar.json();
      console.log('📊 Resultado confirmación:', resultadoConfirmacion);
      
      // Paso 3: Procesar resultado
      mensaje = 'Procesando inscripción...';
      progreso = 75;
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Paso 4: Finalizar
      progreso = 100;
      
      if (resultadoConfirmacion.success) {
        if (resultadoConfirmacion.estado_nuevo === 'aceptada' || resultadoConfirmacion.estado === 'aceptada') {
          exito = true;
          mensaje = '¡Pago confirmado exitosamente!';
          
          // Redirigir a página de éxito después de 2 segundos
          setTimeout(() => {
            goto(`/pago-exitoso?ref_payco=${refPayco}&auto_confirmado=true`);
          }, 2000);
          
        } else if (resultadoConfirmacion.ya_procesado) {
          exito = true;
          mensaje = 'Pago ya procesado anteriormente';
          
          setTimeout(() => {
            goto(`/pago-exitoso?ref_payco=${refPayco}&ya_procesado=true`);
          }, 2000);
          
        } else {
          // Pago no aceptado, redirigir según estado
          const estado = resultadoConfirmacion.estado_nuevo || resultadoConfirmacion.estado;
          if (estado === 'pendiente') {
            goto(`/pago-pendiente?ref_payco=${refPayco}`);
          } else if (estado === 'rechazada') {
            goto(`/pago-error?ref_payco=${refPayco}&error=rechazado`);
          } else {
            goto(`/pago-error?ref_payco=${refPayco}&error=estado-desconocido&estado=${estado}`);
          }
        }
      } else {
        error = resultadoConfirmacion.error || 'Error procesando el pago';
        setTimeout(() => {
          goto(`/pago-error?ref_payco=${refPayco}&error=confirmacion-fallida`);
        }, 3000);
      }
      
    } catch (err) {
      console.error('❌ Error en confirmación automática:', err);
      error = err instanceof Error ? err.message : 'Error desconocido';
      
      setTimeout(() => {
        goto('/pago-error?error=error-interno');
      }, 3000);
    } finally {
      procesando = false;
    }
  });
</script>

<svelte:head>
  <title>Confirmando Pago - Academia Vallenata Online</title>
</svelte:head>

<div class="confirmacion-container">
  <div class="confirmacion-card">
    <!-- Icono de procesamiento -->
    <div class="icono-procesamiento">
      {#if procesando}
        <div class="spinner-grande"></div>
      {:else if exito}
        <div class="check-mark-grande">✓</div>
      {:else}
        <div class="error-mark-grande">✗</div>
      {/if}
    </div>
    
    <!-- Mensaje principal -->
    <h1 class="titulo-confirmacion">
      {#if procesando}
        Confirmando tu pago
      {:else if exito}
        ¡Pago confirmado!
      {:else}
        Error en confirmación
      {/if}
    </h1>
    
    <!-- Mensaje de estado -->
    <p class="mensaje-estado">
      {#if error}
        {error}
      {:else}
        {mensaje}
      {/if}
    </p>
    
    <!-- Barra de progreso -->
    {#if procesando}
      <div class="barra-progreso">
        <div class="progreso-fill" style="width: {progreso}%"></div>
      </div>
      <p class="texto-progreso">{progreso}%</p>
    {/if}
    
    <!-- Mensaje de redirección -->
    {#if !procesando && exito}
      <p class="mensaje-redireccion">
        Serás redirigido automáticamente en unos segundos...
      </p>
    {/if}
    
    {#if !procesando && error}
      <p class="mensaje-redireccion error">
        Serás redirigido a la página de error...
      </p>
    {/if}
  </div>
</div>

<style>
  .confirmacion-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 20px;
  }
  
  .confirmacion-card {
    background: white;
    border-radius: 20px;
    padding: 40px;
    text-align: center;
    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
    max-width: 500px;
    width: 100%;
  }
  
  .icono-procesamiento {
    margin-bottom: 30px;
    height: 80px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .spinner-grande {
    width: 60px;
    height: 60px;
    border: 4px solid #f3f3f3;
    border-top: 4px solid #667eea;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  
  .check-mark-grande {
    width: 80px;
    height: 80px;
    background: #4CAF50;
    border-radius: 50%;
    color: white;
    font-size: 48px;
    display: flex;
    align-items: center;
    justify-content: center;
    animation: scaleIn 0.5s ease-out;
  }
  
  .error-mark-grande {
    width: 80px;
    height: 80px;
    background: #f44336;
    border-radius: 50%;
    color: white;
    font-size: 48px;
    display: flex;
    align-items: center;
    justify-content: center;
    animation: scaleIn 0.5s ease-out;
  }
  
  .titulo-confirmacion {
    font-size: 28px;
    font-weight: bold;
    color: #333;
    margin-bottom: 15px;
  }
  
  .mensaje-estado {
    font-size: 16px;
    color: #666;
    margin-bottom: 30px;
    line-height: 1.5;
  }
  
  .barra-progreso {
    width: 100%;
    height: 8px;
    background: #f0f0f0;
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: 15px;
  }
  
  .progreso-fill {
    height: 100%;
    background: linear-gradient(90deg, #667eea, #764ba2);
    border-radius: 4px;
    transition: width 0.3s ease;
  }
  
  .texto-progreso {
    font-size: 14px;
    color: #888;
    margin-bottom: 20px;
  }
  
  .mensaje-redireccion {
    font-size: 14px;
    color: #666;
    font-style: italic;
  }
  
  .mensaje-redireccion.error {
    color: #f44336;
  }
  
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  @keyframes scaleIn {
    0% { transform: scale(0); }
    100% { transform: scale(1); }
  }
  
  @media (max-width: 768px) {
    .confirmacion-card {
      padding: 30px 20px;
    }
    
    .titulo-confirmacion {
      font-size: 24px;
    }
    
    .icono-procesamiento {
      height: 60px;
    }
    
    .spinner-grande {
      width: 50px;
      height: 50px;
    }
    
    .check-mark-grande,
    .error-mark-grande {
      width: 60px;
      height: 60px;
      font-size: 36px;
    }
  }
</style> 