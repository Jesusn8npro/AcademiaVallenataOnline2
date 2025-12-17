<script>
  import { onMount } from 'svelte';
  
  let fechaActualizacion = "2 de enero de 2025";
  
  onMount(() => {
    // SEO y metadatos
    if (typeof document !== 'undefined') {
      document.title = 'Políticas de Privacidad - Academia Vallenata Online';
    }
  });
</script>

<svelte:head>
  <title>Políticas de Privacidad - Academia Vallenata Online</title>
  <meta name="description" content="Políticas de privacidad y protección de datos de Academia Vallenata Online. Conoce cómo protegemos tu información personal." />
  <meta name="robots" content="index, follow" />
</svelte:head>

<div class="politicas-container">
  <div class="politicas-content">
    
    <!-- 🏠 HEADER -->
    <header class="politicas-header">
      <div class="breadcrumb">
        <a href="/" class="breadcrumb-link">Inicio</a>
        <span class="breadcrumb-separator">›</span>
        <span class="breadcrumb-current">Políticas de Privacidad</span>
      </div>
      <h1 class="politicas-titulo">Políticas de Privacidad</h1>
      <p class="politicas-fecha">Última actualización: {fechaActualizacion}</p>
    </header>

    <!-- 📋 CONTENIDO PRINCIPAL -->
    <main class="politicas-main">
      
      <!-- 🔒 INTRODUCCIÓN -->
      <section class="politica-seccion">
        <h2>1. Introducción</h2>
        <p>
          En <strong>Academia Vallenata Online</strong> (en adelante "la Academia", "nosotros" o "nuestro"), 
          nos comprometemos a proteger la privacidad y seguridad de los datos personales de nuestros usuarios. 
          Esta Política de Privacidad describe cómo recopilamos, utilizamos, almacenamos y protegemos su 
          información cuando utiliza nuestros servicios educativos de música vallenata y acordeón.
        </p>
        <p>
          Al utilizar nuestro sitio web <strong>academiavallenataonline.com</strong> y nuestros servicios, 
          usted acepta las prácticas descritas en esta política.
        </p>
      </section>

      <!-- 📊 INFORMACIÓN QUE RECOPILAMOS -->
      <section class="politica-seccion">
        <h2>2. Información que Recopilamos</h2>
        
        <h3>2.1 Información Personal Directa</h3>
        <ul>
          <li><strong>Datos de registro:</strong> Nombre completo, dirección de correo electrónico, número de WhatsApp</li>
          <li><strong>Información de perfil:</strong> Foto de perfil, nivel musical, preferencias de aprendizaje</li>
          <li><strong>Datos de contacto:</strong> País, ciudad, zona horaria para personalizar su experiencia</li>
          <li><strong>Información de pago:</strong> Datos de facturación para procesar suscripciones y compras</li>
        </ul>

        <h3>2.2 Información de Uso y Actividad</h3>
        <ul>
          <li><strong>Progreso académico:</strong> Lecciones completadas, tiempo de estudio, calificaciones</li>
          <li><strong>Actividad en la plataforma:</strong> Navegación, cursos visitados, interacciones sociales</li>
          <li><strong>Contenido generado:</strong> Comentarios, publicaciones en la comunidad, grabaciones de práctica</li>
          <li><strong>Datos técnicos:</strong> Dirección IP, tipo de dispositivo, navegador, sistema operativo</li>
        </ul>

        <h3>2.3 Cookies y Tecnologías Similares</h3>
        <p>
          Utilizamos cookies esenciales para el funcionamiento del sitio, cookies de análisis para mejorar 
          nuestros servicios, y cookies de personalización para adaptar su experiencia de aprendizaje.
        </p>
      </section>

      <!-- 🎯 CÓMO UTILIZAMOS LA INFORMACIÓN -->
      <section class="politica-seccion">
        <h2>3. Cómo Utilizamos su Información</h2>
        
        <h3>3.1 Servicios Educativos</h3>
        <ul>
          <li>Proporcionar acceso a cursos de acordeón y música vallenata</li>
          <li>Personalizar el contenido según su nivel y progreso</li>
          <li>Realizar seguimiento de su avance académico</li>
          <li>Facilitar la interacción con instructores y otros estudiantes</li>
        </ul>

        <h3>3.2 Comunicación y Soporte</h3>
        <ul>
          <li>Enviar notificaciones sobre clases, eventos y actualizaciones</li>
          <li>Proporcionar soporte técnico y académico</li>
          <li>Responder a sus consultas y comentarios</li>
          <li>Compartir noticias y promociones relacionadas con la música vallenata</li>
        </ul>

        <h3>3.3 Mejora de Servicios</h3>
        <ul>
          <li>Analizar patrones de uso para mejorar nuestros cursos</li>
          <li>Desarrollar nuevos contenidos educativos</li>
          <li>Optimizar la experiencia del usuario</li>
          <li>Realizar investigación educativa y musical</li>
        </ul>
      </section>

      <!-- 🔄 COMPARTIR INFORMACIÓN -->
      <section class="politica-seccion">
        <h2>4. Compartir Información</h2>
        
        <p><strong>No vendemos, alquilamos ni comercializamos su información personal.</strong> Podemos compartir su información únicamente en estas circunstancias:</p>
        
        <h3>4.1 Proveedores de Servicios</h3>
        <ul>
          <li><strong>Supabase:</strong> Para gestión de bases de datos y autenticación</li>
          <li><strong>Procesadores de pago:</strong> Para procesar transacciones de forma segura</li>
          <li><strong>Servicios de email:</strong> Para comunicaciones automatizadas</li>
          <li><strong>Analítica web:</strong> Google Analytics para métricas de uso</li>
        </ul>

        <h3>4.2 Comunidad Educativa</h3>
        <ul>
          <li>Información de perfil público (nombre, foto) en foros y rankings</li>
          <li>Progreso académico con instructores para seguimiento personalizado</li>
          <li>Comentarios y publicaciones en espacios comunitarios</li>
        </ul>

        <h3>4.3 Requerimientos Legales</h3>
        <p>
          Podemos divulgar información cuando sea requerido por ley, para proteger nuestros derechos 
          o la seguridad de usuarios, o para cumplir con procesos legales válidos.
        </p>
      </section>

      <!-- 🔐 SEGURIDAD DE DATOS -->
      <section class="politica-seccion">
        <h2>5. Seguridad de Datos</h2>
        
        <p>Implementamos múltiples capas de seguridad para proteger su información:</p>
        
        <ul>
          <li><strong>Encriptación:</strong> Todos los datos se transmiten mediante HTTPS/SSL</li>
          <li><strong>Autenticación segura:</strong> Sistemas de login robustos con verificación en dos pasos</li>
          <li><strong>Almacenamiento seguro:</strong> Bases de datos protegidas con acceso restringido</li>
          <li><strong>Monitoreo continuo:</strong> Sistemas de detección de amenazas 24/7</li>
          <li><strong>Respaldos regulares:</strong> Copias de seguridad automáticas y cifradas</li>
        </ul>
      </section>

      <!-- 📍 TRANSFERENCIAS INTERNACIONALES -->
      <section class="politica-seccion">
        <h2>6. Transferencias Internacionales</h2>
        
        <p>
          Sus datos pueden ser procesados en servidores ubicados en diferentes países, 
          incluyendo Estados Unidos y Europa, donde nuestros proveedores de servicios mantienen 
          sus infraestructuras. Garantizamos que todas las transferencias cumplen con 
          estándares internacionales de protección de datos.
        </p>
      </section>

      <!-- ⏰ RETENCIÓN DE DATOS -->
      <section class="politica-seccion">
        <h2>7. Retención de Datos</h2>
        
        <ul>
          <li><strong>Datos de cuenta:</strong> Se conservan mientras mantenga su cuenta activa</li>
          <li><strong>Progreso académico:</strong> Se mantiene indefinidamente para certificaciones</li>
          <li><strong>Datos de pago:</strong> Se conservan según requerimientos fiscales (5 años)</li>
          <li><strong>Datos técnicos:</strong> Se eliminan automáticamente después de 24 meses</li>
          <li><strong>Comunicaciones:</strong> Se conservan por 3 años para soporte y calidad</li>
        </ul>
      </section>

      <!-- 🎛️ SUS DERECHOS -->
      <section class="politica-seccion">
        <h2>8. Sus Derechos</h2>
        
        <p>Usted tiene los siguientes derechos sobre sus datos personales:</p>
        
        <div class="derechos-grid">
          <div class="derecho-item">
            <h4>🔍 Acceso</h4>
            <p>Solicitar una copia de todos los datos que tenemos sobre usted</p>
          </div>
          <div class="derecho-item">
            <h4>✏️ Rectificación</h4>
            <p>Corregir información inexacta o incompleta</p>
          </div>
          <div class="derecho-item">
            <h4>🗑️ Eliminación</h4>
            <p>Solicitar la eliminación de sus datos personales</p>
          </div>
          <div class="derecho-item">
            <h4>⏸️ Limitación</h4>
            <p>Restringir el procesamiento de su información</p>
          </div>
          <div class="derecho-item">
            <h4>📤 Portabilidad</h4>
            <p>Obtener sus datos en formato estructurado</p>
          </div>
          <div class="derecho-item">
            <h4>❌ Oposición</h4>
            <p>Oponerse al procesamiento de sus datos</p>
          </div>
        </div>

        <p>
          Para ejercer cualquiera de estos derechos, contacte con nosotros en 
          <a href="mailto:privacidad@academiavallenataonline.com">privacidad@academiavallenataonline.com</a>
        </p>
      </section>

      <!-- 👶 MENORES DE EDAD -->
      <section class="politica-seccion">
        <h2>9. Protección de Menores</h2>
        
        <p>
          Nuestros servicios están dirigidos a usuarios mayores de 13 años. Para estudiantes 
          menores de 18 años, requerimos consentimiento parental verificable. No recopilamos 
          conscientemente información personal de niños menores de 13 años sin consentimiento parental.
        </p>
      </section>

      <!-- 🔄 ACTUALIZACIONES -->
      <section class="politica-seccion">
        <h2>10. Actualizaciones de la Política</h2>
        
        <p>
          Esta política puede actualizarse ocasionalmente para reflejar cambios en nuestros 
          servicios o requerimientos legales. Le notificaremos sobre cambios significativos 
          por email y destacaremos las modificaciones en nuestro sitio web.
        </p>
      </section>

      <!-- 📞 CONTACTO -->
      <section class="politica-seccion">
        <h2>11. Información de Contacto</h2>
        
        <div class="contacto-info">
          <h3>Academia Vallenata Online</h3>
          <p><strong>Responsable de Datos:</strong> Jesús González</p>
          <p><strong>Email:</strong> <a href="mailto:privacidad@academiavallenataonline.com">privacidad@academiavallenataonline.com</a></p>
          <p><strong>Sitio web:</strong> <a href="https://academiavallenataonline.com">academiavallenataonline.com</a></p>
          <p><strong>Horario de atención:</strong> Lunes a Viernes, 9:00 AM - 6:00 PM (GMT-5)</p>
        </div>
      </section>

    </main>

    <!-- 🔗 ENLACES RELACIONADOS -->
    <aside class="enlaces-relacionados">
      <h3>Documentos Relacionados</h3>
      <div class="enlaces-grid">
        <a href="/terminos" class="enlace-documento">
          <span class="enlace-icono">📋</span>
          <span class="enlace-texto">Términos y Condiciones</span>
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
  .politicas-container {
    min-height: 100vh;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    padding: 80px 20px 40px;
  }

  .politicas-content {
    max-width: 900px;
    margin: 0 auto;
    background: white;
    border-radius: 20px;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
    overflow: hidden;
  }

  /* 📋 HEADER */
  .politicas-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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

  .politicas-titulo {
    font-size: 2.5rem;
    font-weight: 800;
    margin: 0 0 10px 0;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  }

  .politicas-fecha {
    font-size: 1rem;
    opacity: 0.9;
    margin: 0;
  }

  /* 📝 CONTENIDO PRINCIPAL */
  .politicas-main {
    padding: 40px;
  }

  .politica-seccion {
    margin-bottom: 40px;
    padding-bottom: 30px;
    border-bottom: 1px solid #e2e8f0;
  }

  .politica-seccion:last-child {
    border-bottom: none;
    margin-bottom: 0;
  }

  .politica-seccion h2 {
    color: #1e293b;
    font-size: 1.5rem;
    font-weight: 700;
    margin: 0 0 20px 0;
    position: relative;
    padding-left: 20px;
  }

  .politica-seccion h2::before {
    content: '';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    width: 4px;
    height: 100%;
    background: linear-gradient(135deg, #667eea, #764ba2);
    border-radius: 2px;
  }

  .politica-seccion h3 {
    color: #374151;
    font-size: 1.2rem;
    font-weight: 600;
    margin: 25px 0 15px 0;
  }

  .politica-seccion h4 {
    color: #4b5563;
    font-size: 1rem;
    font-weight: 600;
    margin: 15px 0 10px 0;
  }

  .politica-seccion p {
    color: #4b5563;
    line-height: 1.7;
    margin: 0 0 15px 0;
    text-align: justify;
  }

  .politica-seccion ul {
    margin: 15px 0;
    padding-left: 0;
    list-style: none;
  }

  .politica-seccion li {
    color: #4b5563;
    line-height: 1.6;
    margin: 10px 0;
    padding-left: 25px;
    position: relative;
  }

  .politica-seccion li::before {
    content: '✓';
    position: absolute;
    left: 0;
    top: 0;
    color: #10b981;
    font-weight: bold;
    font-size: 1.1rem;
  }

  .politica-seccion strong {
    color: #1e293b;
    font-weight: 600;
  }

  .politica-seccion a {
    color: #667eea;
    text-decoration: none;
    font-weight: 500;
    transition: color 0.3s ease;
  }

  .politica-seccion a:hover {
    color: #764ba2;
    text-decoration: underline;
  }

  /* 🎛️ GRID DE DERECHOS */
  .derechos-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 20px;
    margin: 25px 0;
  }

  .derecho-item {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 20px;
    transition: all 0.3s ease;
  }

  .derecho-item:hover {
    background: #f1f5f9;
    border-color: #667eea;
    transform: translateY(-2px);
  }

  .derecho-item h4 {
    margin: 0 0 10px 0;
    font-size: 1rem;
    color: #1e293b;
  }

  .derecho-item p {
    margin: 0;
    font-size: 0.9rem;
    color: #64748b;
    text-align: left;
  }

  /* 📞 INFORMACIÓN DE CONTACTO */
  .contacto-info {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 25px;
  }

  .contacto-info h3 {
    color: #1e293b;
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
    background: #667eea;
    color: white;
    border-color: #667eea;
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
    .politicas-container {
      padding: 60px 15px 20px;
    }

    .politicas-header,
    .politicas-main,
    .enlaces-relacionados {
      padding: 25px 20px;
    }

    .politicas-titulo {
      font-size: 2rem;
    }

    .politica-seccion h2 {
      font-size: 1.3rem;
    }

    .derechos-grid {
      grid-template-columns: 1fr;
    }

    .enlaces-grid {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 480px) {
    .politicas-titulo {
      font-size: 1.7rem;
    }

    .politica-seccion h2 {
      font-size: 1.2rem;
    }

    .politicas-header,
    .politicas-main,
    .enlaces-relacionados {
      padding: 20px 15px;
    }
  }
</style> 