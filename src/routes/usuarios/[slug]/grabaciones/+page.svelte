<script lang="ts">
  import { page } from '$app/stores';
  
  $: slugUsuario = $page.params.slug;
</script>

<div class="contenedor-grabaciones">
  <div class="encabezado-seccion">
    <div class="icono-seccion">🎥</div>
    <div class="info-seccion">
      <h1>Grabaciones de Acordeón</h1>
      <p>Videos grabados con el simulador de acordeón</p>
    </div>
  </div>

  <div class="contenido-grabaciones">
    <div class="estado-vacio">
      <div class="icono-vacio">🎬</div>
      <h3>No hay grabaciones disponibles</h3>
      <p>Este usuario aún no ha subido grabaciones de acordeón desde el simulador.</p>
      
      <div class="accion-vacio">
        <a href="/simulador-gaming" class="btn-probar-simulador">
          🎹 Probar el Simulador
        </a>
      </div>
    </div>
  </div>
</div>

<style>
  .contenedor-grabaciones {
    padding: 2rem;
    min-height: 500px;
  }

  .encabezado-seccion {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 2rem;
    padding-bottom: 1rem;
    border-bottom: 2px solid #e5e7eb;
  }

  .icono-seccion {
    font-size: 2.5rem;
    background: linear-gradient(135deg, #ef4444, #dc2626);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .info-seccion h1 {
    font-size: 1.75rem;
    font-weight: 700;
    color: #1f2937;
    margin: 0;
  }

  .info-seccion p {
    color: #6b7280;
    margin: 0.25rem 0 0 0;
    font-size: 0.95rem;
  }

  .contenido-grabaciones {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 350px;
  }

  .estado-vacio {
    text-align: center;
    max-width: 500px;
    padding: 3rem 2rem;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    border-radius: 16px;
    border: 1px solid #e5e7eb;
  }

  .icono-vacio {
    font-size: 4rem;
    margin-bottom: 1rem;
    opacity: 0.7;
  }

  .estado-vacio h3 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #374151;
    margin: 0 0 0.5rem 0;
  }

  .estado-vacio p {
    color: #6b7280;
    font-size: 1rem;
    line-height: 1.5;
    margin: 0 0 2rem 0;
  }

  .accion-vacio {
    margin-top: 1.5rem;
  }

  .btn-probar-simulador {
    display: inline-block;
    background: linear-gradient(135deg, #ef4444, #dc2626);
    color: white;
    padding: 12px 24px;
    border-radius: 12px;
    text-decoration: none;
    font-weight: 600;
    font-size: 1rem;
    transition: all 0.2s ease;
    box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
  }

  .btn-probar-simulador:hover {
    background: linear-gradient(135deg, #dc2626, #b91c1c);
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(239, 68, 68, 0.4);
  }

  /* Responsive */
  @media (max-width: 768px) {
    .contenedor-grabaciones {
      padding: 1rem;
    }

    .encabezado-seccion {
      flex-direction: column;
      text-align: center;
      gap: 0.5rem;
    }

    .icono-seccion {
      font-size: 2rem;
    }

    .info-seccion h1 {
      font-size: 1.5rem;
    }

    .estado-vacio {
      padding: 2rem 1rem;
      margin: 0 0.5rem;
    }

    .icono-vacio {
      font-size: 3rem;
    }

    .estado-vacio h3 {
      font-size: 1.25rem;
    }

    .btn-probar-simulador {
      padding: 10px 20px;
      font-size: 0.9rem;
    }
  }
</style> 