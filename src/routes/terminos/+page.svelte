<script>
  import { onMount } from 'svelte';
  
  let fechaActualizacion = "2 de enero de 2025";
  
  onMount(() => {
    // SEO y metadatos
    if (typeof document !== 'undefined') {
      document.title = 'Términos y Condiciones - Academia Vallenata Online';
    }
  });
</script>

<svelte:head>
  <title>Términos y Condiciones - Academia Vallenata Online</title>
  <meta name="description" content="Términos y condiciones de uso de Academia Vallenata Online. Conoce las reglas y condiciones para el uso de nuestra plataforma educativa." />
  <meta name="robots" content="index, follow" />
</svelte:head>

<div class="terminos-container">
  <div class="terminos-content">
    
    <!-- 🏠 HEADER -->
    <header class="terminos-header">
      <div class="breadcrumb">
        <a href="/" class="breadcrumb-link">Inicio</a>
        <span class="breadcrumb-separator">›</span>
        <span class="breadcrumb-current">Términos y Condiciones</span>
      </div>
      <h1 class="terminos-titulo">Términos y Condiciones</h1>
      <p class="terminos-fecha">Última actualización: {fechaActualizacion}</p>
    </header>

    <!-- 📋 CONTENIDO PRINCIPAL -->
    <main class="terminos-main">
      
      <!-- 🤝 INTRODUCCIÓN -->
      <section class="termino-seccion">
        <h2>1. Aceptación de los Términos</h2>
        <p>
          Bienvenido a <strong>Academia Vallenata Online</strong>. Estos Términos y Condiciones de Uso 
          (en adelante "Términos") rigen el acceso y uso de nuestro sitio web 
          <strong>academiavallenataonline.com</strong> y todos los servicios educativos relacionados 
          con el aprendizaje de música vallenata y acordeón.
        </p>
        <p>
          Al acceder o utilizar nuestros servicios, usted acepta quedar legalmente vinculado por estos 
          Términos. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestros servicios.
        </p>
      </section>

      <!-- 🏛️ DEFINICIONES -->
      <section class="termino-seccion">
        <h2>2. Definiciones</h2>
        
        <div class="definiciones-grid">
          <div class="definicion-item">
            <h4>🏫 "Academia" o "Nosotros"</h4>
            <p>Se refiere a Academia Vallenata Online y sus operadores.</p>
          </div>
          <div class="definicion-item">
            <h4>👤 "Usuario" o "Usted"</h4>
            <p>Cualquier persona que accede o utiliza nuestros servicios.</p>
          </div>
          <div class="definicion-item">
            <h4>📚 "Servicios"</h4>
            <p>Todos los cursos, materiales educativos y funcionalidades de la plataforma.</p>
          </div>
          <div class="definicion-item">
            <h4>📝 "Contenido"</h4>
            <p>Videos, audios, textos, ejercicios y materiales educativos proporcionados.</p>
          </div>
          <div class="definicion-item">
            <h4>💰 "Suscripción"</h4>
            <p>Plan de pago que otorga acceso a contenidos premium.</p>
          </div>
          <div class="definicion-item">
            <h4>🎵 "Vallenato"</h4>
            <p>Género musical tradicional colombiano objeto de nuestros cursos.</p>
          </div>
        </div>
      </section>

      <!-- 📋 SERVICIOS EDUCATIVOS -->
      <section class="termino-seccion">
        <h2>3. Descripción de los Servicios</h2>
        
        <h3>3.1 Servicios Ofrecidos</h3>
        <ul>
          <li><strong>Cursos de acordeón:</strong> Desde nivel principiante hasta avanzado</li>
          <li><strong>Música vallenata:</strong> Historia, teoría y práctica del género</li>
          <li><strong>Clases en vivo:</strong> Sesiones interactivas con instructores calificados</li>
          <li><strong>Materiales de apoyo:</strong> Partituras, audios de práctica y ejercicios</li>
          <li><strong>Comunidad estudiantil:</strong> Foros de discusión y eventos virtuales</li>
          <li><strong>Seguimiento personalizado:</strong> Evaluaciones y retroalimentación individual</li>
        </ul>

        <h3>3.2 Modalidades de Acceso</h3>
        <ul>
          <li><strong>Contenido gratuito:</strong> Lecciones básicas y material introductorio</li>
          <li><strong>Suscripción mensual:</strong> Acceso completo con renovación automática</li>
          <li><strong>Paquetes específicos:</strong> Cursos individuales con acceso permanente</li>
          <li><strong>Membresías premium:</strong> Incluye clases personalizadas y eventos exclusivos</li>
        </ul>
      </section>

      <!-- 👤 REGISTRO Y CUENTA DE USUARIO -->
      <section class="termino-seccion">
        <h2>4. Registro y Cuenta de Usuario</h2>
        
        <h3>4.1 Requisitos de Registro</h3>
        <ul>
          <li>Ser mayor de 13 años (menores requieren autorización parental)</li>
          <li>Proporcionar información verdadera y actualizada</li>
          <li>Mantener la confidencialidad de sus credenciales de acceso</li>
          <li>Notificar inmediatamente cualquier uso no autorizado de su cuenta</li>
        </ul>

        <h3>4.2 Responsabilidades del Usuario</h3>
        <ul>
          <li>Usar los servicios únicamente para fines educativos legítimos</li>
          <li>No compartir credenciales de acceso con terceros</li>
          <li>Mantener actualizada su información de contacto</li>
          <li>Cumplir con todas las políticas de la comunidad</li>
        </ul>

        <h3>4.3 Suspensión y Terminación</h3>
        <p>
          Nos reservamos el derecho de suspender o terminar cuentas que violen estos términos, 
          participen en actividades fraudulentas, o interfieran con el funcionamiento normal de la plataforma.
        </p>
      </section>

      <!-- 💳 PAGOS Y SUSCRIPCIONES -->
      <section class="termino-seccion">
        <h2>5. Pagos y Suscripciones</h2>
        
        <h3>5.1 Precios y Facturación</h3>
        <ul>
          <li>Los precios están expresados en pesos colombianos (COP)</li>
          <li>Las suscripciones se renuevan automáticamente hasta cancelación</li>
          <li>Los cambios de precio se notifican con 30 días de anticipación</li>
          <li>Todos los pagos incluyen los impuestos aplicables</li>
        </ul>

        <h3>5.2 Métodos de Pago</h3>
        <ul>
          <li>Tarjetas de crédito y débito (Visa, Mastercard, American Express)</li>
          <li>Transferencias bancarias nacionales</li>
          <li>Pagos por PSE (Pagos Seguros en Línea)</li>
          <li>Billeteras digitales (Nequi, Daviplata)</li>
        </ul>

        <h3>5.3 Política de Reembolsos</h3>
        <ul>
          <li><strong>Período de prueba:</strong> 7 días para nuevas suscripciones</li>
          <li><strong>Cursos individuales:</strong> Reembolso completo dentro de 30 días si no se ha completado más del 20%</li>
          <li><strong>Suscripciones mensuales:</strong> No se reembolsan pagos parciales del mes en curso</li>
          <li><strong>Eventos en vivo:</strong> Reembolso disponible hasta 24 horas antes del evento</li>
        </ul>
      </section>

      <!-- 📄 PROPIEDAD INTELECTUAL -->
      <section class="termino-seccion">
        <h2>6. Propiedad Intelectual</h2>
        
        <h3>6.1 Nuestro Contenido</h3>
        <p>
          Todo el contenido educativo, incluyendo videos, audios, textos, ejercicios, partituras y 
          materiales didácticos, está protegido por derechos de autor y es propiedad exclusiva de 
          Academia Vallenata Online o sus licenciantes.
        </p>

        <h3>6.2 Uso Permitido</h3>
        <ul>
          <li>Visualizar y estudiar el contenido para uso personal y educativo</li>
          <li>Descargar materiales específicamente marcados como descargables</li>
          <li>Compartir su progreso en redes sociales usando nuestras herramientas</li>
          <li>Practicar y ejecutar las canciones aprendidas en contextos no comerciales</li>
        </ul>

        <h3>6.3 Uso Prohibido</h3>
        <ul>
          <li>Copiar, distribuir o reproducir contenido sin autorización escrita</li>
          <li>Crear obras derivadas basadas en nuestro material</li>
          <li>Usar el contenido para fines comerciales o lucrativos</li>
          <li>Compartir credenciales de acceso para evitar pagos</li>
          <li>Realizar ingeniería inversa o intentar extraer contenido</li>
        </ul>

        <h3>6.4 Contenido del Usuario</h3>
        <p>
          Al subir contenido (comentarios, grabaciones, participaciones), usted otorga a la Academia 
          una licencia mundial, libre de regalías para usar, modificar y mostrar dicho contenido 
          con fines educativos y promocionales.
        </p>
      </section>

      <!-- 🎯 USO ACEPTABLE -->
      <section class="termino-seccion">
        <h2>7. Política de Uso Aceptable</h2>
        
        <h3>7.1 Conducta Esperada</h3>
        <ul>
          <li>Mantener un ambiente respetuoso y colaborativo</li>
          <li>Participar constructivamente en foros y comunidades</li>
          <li>Respetar la diversidad cultural y musical</li>
          <li>Ayudar y apoyar a otros estudiantes</li>
        </ul>

        <h3>7.2 Conductas Prohibidas</h3>
        <ul>
          <li><strong>Acoso o intimidación:</strong> Hacia instructores o estudiantes</li>
          <li><strong>Contenido inapropiado:</strong> Material ofensivo, discriminatorio o violento</li>
          <li><strong>Spam o publicidad:</strong> Promoción no autorizada de productos o servicios</li>
          <li><strong>Actividades ilegales:</strong> Cualquier uso que viole leyes locales o internacionales</li>
          <li><strong>Interferencia técnica:</strong> Intentos de hackear o comprometer la plataforma</li>
        </ul>
      </section>

      <!-- ⚠️ LIMITACIONES Y EXCLUSIONES -->
      <section class="termino-seccion">
        <h2>8. Limitaciones de Responsabilidad</h2>
        
        <h3>8.1 Naturaleza del Servicio</h3>
        <p>
          Nuestros servicios se proporcionan "tal como están" y "según disponibilidad". 
          No garantizamos resultados específicos de aprendizaje, ya que estos dependen 
          del esfuerzo, dedicación y habilidades individuales del estudiante.
        </p>

        <h3>8.2 Limitaciones Técnicas</h3>
        <ul>
          <li>Interrupciones ocasionales del servicio por mantenimiento</li>
          <li>Posibles problemas de conectividad fuera de nuestro control</li>
          <li>Limitaciones en la calidad de transmisión según la conexión del usuario</li>
          <li>Incompatibilidad con dispositivos o navegadores obsoletos</li>
        </ul>

        <h3>8.3 Exclusión de Responsabilidad</h3>
        <p>
          En ningún caso seremos responsables por daños indirectos, incidentales, especiales 
          o consecuenciales, incluyendo pérdida de datos, ingresos o oportunidades de negocio.
        </p>
      </section>

      <!-- 🔄 MODIFICACIONES -->
      <section class="termino-seccion">
        <h2>9. Modificaciones de los Términos</h2>
        
        <h3>9.1 Derecho a Modificar</h3>
        <p>
          Nos reservamos el derecho de modificar estos términos en cualquier momento. 
          Los cambios entrarán en vigor inmediatamente después de su publicación en nuestro sitio web.
        </p>

        <h3>9.2 Notificación de Cambios</h3>
        <ul>
          <li>Cambios menores: Notificación en la plataforma</li>
          <li>Cambios significativos: Notificación por email con 30 días de anticipación</li>
          <li>Cambios en precios: Notificación con 30 días de anticipación</li>
        </ul>

        <h3>9.3 Aceptación Continuada</h3>
        <p>
          El uso continuado de nuestros servicios después de cualquier modificación 
          constituye su aceptación de los nuevos términos.
        </p>
      </section>

      <!-- ⚖️ LEY APLICABLE -->
      <section class="termino-seccion">
        <h2>10. Ley Aplicable y Jurisdicción</h2>
        
        <h3>10.1 Ley Aplicable</h3>
        <p>
          Estos términos se rigen por las leyes de la República de Colombia, 
          específicamente por las normas de protección al consumidor y comercio electrónico.
        </p>

        <h3>10.2 Resolución de Controversias</h3>
        <ul>
          <li><strong>Primera instancia:</strong> Mediación directa con nuestro equipo de soporte</li>
          <li><strong>Segunda instancia:</strong> Arbitraje ante la Cámara de Comercio de Bogotá</li>
          <li><strong>Última instancia:</strong> Tribunales competentes de Bogotá, Colombia</li>
        </ul>

        <h3>10.3 Protección al Consumidor</h3>
        <p>
          Los usuarios colombianos mantienen todos los derechos establecidos en el 
          Estatuto del Consumidor (Ley 1480 de 2011) y la Ley de Comercio Electrónico (Ley 527 de 1999).
        </p>
      </section>

      <!-- 📞 CONTACTO Y SOPORTE -->
      <section class="termino-seccion">
        <h2>11. Contacto y Soporte</h2>
        
        <div class="contacto-info">
          <h3>Academia Vallenata Online</h3>
          <p><strong>Representante Legal:</strong> Jesús González</p>
          <p><strong>Email General:</strong> <a href="mailto:info@academiavallenataonline.com">info@academiavallenataonline.com</a></p>
          <p><strong>Email Legal:</strong> <a href="mailto:legal@academiavallenataonline.com">legal@academiavallenataonline.com</a></p>
          <p><strong>Soporte Técnico:</strong> <a href="mailto:soporte@academiavallenataonline.com">soporte@academiavallenataonline.com</a></p>
          <p><strong>WhatsApp:</strong> +57 300 123 4567</p>
          <p><strong>Horario de Atención:</strong> Lunes a Viernes, 8:00 AM - 8:00 PM (GMT-5)</p>
          <p><strong>Sitio Web:</strong> <a href="https://academiavallenataonline.com">academiavallenataonline.com</a></p>
        </div>
      </section>

      <!-- 📋 DISPOSICIONES FINALES -->
      <section class="termino-seccion">
        <h2>12. Disposiciones Finales</h2>
        
        <h3>12.1 Integridad del Acuerdo</h3>
        <p>
          Estos términos, junto con nuestra Política de Privacidad, constituyen el acuerdo 
          completo entre usted y Academia Vallenata Online.
        </p>

        <h3>12.2 Divisibilidad</h3>
        <p>
          Si alguna disposición de estos términos se considera inválida o inaplicable, 
          las disposiciones restantes continuarán en pleno vigor y efecto.
        </p>

        <h3>12.3 Supervivencia</h3>
        <p>
          Las disposiciones relacionadas con propiedad intelectual, limitaciones de responsabilidad 
          y resolución de controversias sobrevivirán a la terminación de estos términos.
        </p>

        <h3>12.4 Idioma</h3>
        <p>
          Estos términos están redactados en español. En caso de conflicto con traducciones 
          a otros idiomas, prevalecerá la versión en español.
        </p>
      </section>

    </main>

    <!-- 🔗 ENLACES RELACIONADOS -->
    <aside class="enlaces-relacionados">
      <h3>Documentos Relacionados</h3>
      <div class="enlaces-grid">
        <a href="/privacidad" class="enlace-documento">
          <span class="enlace-icono">🔒</span>
          <span class="enlace-texto">Políticas de Privacidad</span>
        </a>
        <a href="/contacto" class="enlace-documento">
          <span class="enlace-icono">📞</span>
          <span class="enlace-texto">Contacto</span>
        </a>
        <a href="/" class="enlace-documento">
          <span class="enlace-icono">🏠</span>
          <span class="enlace-texto">Volver al Inicio</span>
        </a>
      </div>
    </aside>

  </div>
</div>

<style>
  /* 🎨 ESTILOS GENERALES */
  .terminos-container {
    min-height: 100vh;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    padding: 80px 20px 40px;
  }

  .terminos-content {
    max-width: 1000px;
    margin: 0 auto;
    background: white;
    border-radius: 20px;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
    overflow: hidden;
  }

  /* 📋 HEADER */
  .terminos-header {
    background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
    color: white;
    padding: 40px;
    text-align: center;
  }

  .breadcrumb {
    margin-bottom: 20px;
    font-size: 0.9rem;
    opacity: 0.9;
  }

  .breadcrumb-link {
    color: white;
    text-decoration: none;
    transition: opacity 0.3s ease;
  }

  .breadcrumb-link:hover {
    opacity: 0.8;
  }

  .breadcrumb-separator {
    margin: 0 10px;
  }

  .breadcrumb-current {
    font-weight: 600;
  }

  .terminos-titulo {
    font-size: 2.5rem;
    font-weight: 800;
    margin: 0 0 10px 0;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  }

  .terminos-fecha {
    font-size: 1rem;
    opacity: 0.9;
    margin: 0;
  }

  /* 📝 CONTENIDO PRINCIPAL */
  .terminos-main {
    padding: 40px;
  }

  .termino-seccion {
    margin-bottom: 40px;
    padding-bottom: 30px;
    border-bottom: 1px solid #e2e8f0;
  }

  .termino-seccion:last-child {
    border-bottom: none;
    margin-bottom: 0;
  }

  .termino-seccion h2 {
    color: #1e293b;
    font-size: 1.5rem;
    font-weight: 700;
    margin: 0 0 20px 0;
    position: relative;
    padding-left: 20px;
  }

  .termino-seccion h2::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 4px;
    height: 100%;
    background: linear-gradient(135deg, #f59e0b, #d97706);
    border-radius: 2px;
  }

  .termino-seccion h3 {
    color: #374151;
    font-size: 1.2rem;
    font-weight: 600;
    margin: 25px 0 15px 0;
  }

  .termino-seccion h4 {
    color: #4b5563;
    font-size: 1rem;
    font-weight: 600;
    margin: 15px 0 10px 0;
  }

  .termino-seccion p {
    color: #4b5563;
    line-height: 1.7;
    margin: 0 0 15px 0;
    text-align: justify;
  }

  .termino-seccion ul {
    margin: 15px 0;
    padding-left: 0;
    list-style: none;
  }

  .termino-seccion li {
    color: #4b5563;
    line-height: 1.6;
    margin: 10px 0;
    padding-left: 25px;
    position: relative;
  }

  .termino-seccion li::before {
    content: '⚡';
    position: absolute;
    left: 0;
    top: 0;
    color: #f59e0b;
    font-weight: bold;
    font-size: 1.1rem;
  }

  .termino-seccion strong {
    color: #1e293b;
    font-weight: 600;
  }

  .termino-seccion a {
    color: #f59e0b;
    text-decoration: none;
    font-weight: 500;
    transition: color 0.3s ease;
  }

  .termino-seccion a:hover {
    color: #d97706;
    text-decoration: underline;
  }

  /* 📖 GRID DE DEFINICIONES */
  .definiciones-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin: 25px 0;
  }

  .definicion-item {
    background: #fffbeb;
    border: 1px solid #fed7aa;
    border-radius: 12px;
    padding: 20px;
    transition: all 0.3s ease;
  }

  .definicion-item:hover {
    background: #fef3c7;
    border-color: #f59e0b;
    transform: translateY(-2px);
  }

  .definicion-item h4 {
    margin: 0 0 10px 0;
    font-size: 1rem;
    color: #92400e;
  }

  .definicion-item p {
    margin: 0;
    font-size: 0.9rem;
    color: #64748b;
    text-align: left;
  }

  /* 📞 INFORMACIÓN DE CONTACTO */
  .contacto-info {
    background: #fffbeb;
    border: 1px solid #fed7aa;
    border-radius: 12px;
    padding: 25px;
  }

  .contacto-info h3 {
    color: #92400e;
    margin: 0 0 15px 0;
    font-size: 1.2rem;
  }

  .contacto-info p {
    margin: 8px 0;
    text-align: left;
  }

  /* 🔗 ENLACES RELACIONADOS */
  .enlaces-relacionados {
    background: #f8fafc;
    padding: 30px 40px;
    border-top: 1px solid #e2e8f0;
  }

  .enlaces-relacionados h3 {
    color: #1e293b;
    font-size: 1.2rem;
    font-weight: 600;
    margin: 0 0 20px 0;
    text-align: center;
  }

  .enlaces-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 15px;
  }

  .enlace-documento {
    display: flex;
    align-items: center;
    gap: 10px;
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 10px;
    padding: 15px;
    text-decoration: none;
    color: #374151;
    transition: all 0.3s ease;
  }

  .enlace-documento:hover {
    background: #f59e0b;
    color: white;
    border-color: #f59e0b;
    transform: translateY(-2px);
  }

  .enlace-icono {
    font-size: 1.2rem;
  }

  .enlace-texto {
    font-weight: 500;
  }

  /* 📱 RESPONSIVE */
  @media (max-width: 768px) {
    .terminos-container {
      padding: 60px 15px 20px;
    }

    .terminos-header,
    .terminos-main,
    .enlaces-relacionados {
      padding: 25px 20px;
    }

    .terminos-titulo {
      font-size: 2rem;
    }

    .termino-seccion h2 {
      font-size: 1.3rem;
    }

    .definiciones-grid {
      grid-template-columns: 1fr;
    }

    .enlaces-grid {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 480px) {
    .terminos-titulo {
      font-size: 1.7rem;
    }

    .termino-seccion h2 {
      font-size: 1.2rem;
    }

    .terminos-header,
    .terminos-main,
    .enlaces-relacionados {
      padding: 20px 15px;
    }

    .definiciones-grid {
      gap: 15px;
    }
  }
</style> 