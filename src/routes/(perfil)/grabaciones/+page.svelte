<div class="contenedor-grabaciones">
  <div class="encabezado-seccion">
    <div class="icono-seccion">🎥</div>
    <div class="info-seccion">
      <h1>Mis Grabaciones</h1>
      <p>Videos grabados desde el simulador de acordeón</p>
    </div>
    <button class="btn-nueva-grabacion">
      ➕ Nueva Grabación
    </button>
  </div>

  <div class="contenido-grabaciones">
    <div class="estado-vacio">
      <div class="icono-vacio">🎬</div>
      <h3>Aún no tienes grabaciones</h3>
      <p>Usa el simulador de acordeón para grabar y compartir tus interpretaciones. ¡Muestra tu talento!</p>
      
      <div class="acciones-vacio">
                        <a href="/simulador-gaming" class="btn-ir-simulador">
          🎹 Ir al Simulador
        </a>
        <button class="btn-subir-video" on:click={() => alert('Función de subir video próximamente')}>
          📁 Subir Video
        </button>
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
    justify-content: space-between;
    flex-wrap: wrap;
  }

  .icono-seccion {
    font-size: 2.5rem;
    background: linear-gradient(135deg, #ef4444, #dc2626);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .info-seccion {
    flex: 1;
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

  .btn-nueva-grabacion {
    background: linear-gradient(135deg, #ef4444, #dc2626);
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.2s ease;
    box-shadow: 0 3px 10px rgba(239, 68, 68, 0.3);
  }

  .btn-nueva-grabacion:hover {
    background: linear-gradient(135deg, #dc2626, #b91c1c);
    transform: translateY(-2px);
    box-shadow: 0 5px 14px rgba(239, 68, 68, 0.4);
  }

  .contenido-grabaciones {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 350px;
  }

  .estado-vacio {
    text-align: center;
    max-width: 600px;
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

  .acciones-vacio {
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
  }

  .btn-ir-simulador {
    display: inline-block;
    background: linear-gradient(135deg, #3b82f6, #2563eb);
    color: white;
    padding: 12px 24px;
    border-radius: 12px;
    text-decoration: none;
    font-weight: 600;
    font-size: 1rem;
    transition: all 0.2s ease;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
  }

  .btn-ir-simulador:hover {
    background: linear-gradient(135deg, #2563eb, #1d4ed8);
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(59, 130, 246, 0.4);
  }

  .btn-subir-video {
    background: linear-gradient(135deg, #10b981, #059669);
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 12px;
    font-weight: 600;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.2s ease;
    box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
  }

  .btn-subir-video:hover {
    background: linear-gradient(135deg, #059669, #047857);
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(16, 185, 129, 0.4);
  }

  /* Responsive */
  @media (max-width: 768px) {
    .contenedor-grabaciones {
      padding: 1rem;
    }

    .encabezado-seccion {
      flex-direction: column;
      text-align: center;
      gap: 1rem;
    }

    .icono-seccion {
      font-size: 2rem;
    }

    .info-seccion {
      text-align: center;
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

    .acciones-vacio {
      flex-direction: column;
      align-items: center;
      gap: 0.8rem;
    }

    .btn-ir-simulador,
    .btn-subir-video,
    .btn-nueva-grabacion {
      padding: 10px 20px;
      font-size: 0.9rem;
      width: 100%;
      max-width: 200px;
    }
  }
</style> 