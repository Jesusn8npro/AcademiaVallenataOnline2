<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';

  let mounted = false;
  let currentTestimonial = 0;

  const testimonios = [
    {
      nombre: "Carlos Mendoza",
      ciudad: "Valledupar, Cesar",
      tiempo: "6 meses",
      texto: "El simulador es increíble, siento que tengo al maestro Jesús aquí conmigo. Jamás pensé aprender tan rápido.",
      nivel: "Principiante a Intermedio"
    },
    {
      nombre: "María González",
      ciudad: "Barranquilla, Atlántico", 
      tiempo: "1 año",
      texto: "La metodología es única. En un año ya toco canciones completas y mi familia no lo puede creer.",
      nivel: "Avanzada"
    },
    {
      nombre: "Luis Restrepo",
      ciudad: "Medellín, Antioquia",
      tiempo: "8 meses", 
      texto: "Desde Medellín siguiendo las clases. El acordeón virtual es una genialidad, mejor que clases presenciales.",
      nivel: "Intermedio"
    }
  ];

  const cronologia = [
    {
      año: "2020",
      titulo: "Los Inicios",
      descripcion: "Jesús González inicia su carrera profesional acompañando a Orlando Acosta, adquiriendo experiencia invaluable en el vallenato auténtico.",
      imagen: "/images/Jesus-Gonzalez,-Orlando-Acosta-y-Felipe-Pelaez.jpg",
      color: "#ff6600"
    },
    {
      año: "2021", 
      titulo: "Nace la Academia",
      descripcion: "Se funda Academia Vallenata Online, revolucionando la enseñanza del acordeón con metodología efectiva y resultados comprobados.",
      imagen: "/images/Bienvenido--Academia-Vallenata-ONLINE.jpg",
      color: "#ff8c42"
    },
    {
      año: "2022",
      titulo: "Consolidación",
      descripcion: "Consolidación como acordeonista profesional, perfeccionando técnicas que luego transmite a miles de estudiantes en línea.",
      imagen: "/images/Foto maestro oficial JESUS GONZALEZ.jpg", 
      color: "#ffb366"
    },
    {
      año: "2023-2024",
      titulo: "Giras Internacionales", 
      descripcion: "Recorre Colombia y el mundo acompañando a Poncho Zuleta, llevando el vallenato auténtico a nuevos territorios.",
      imagen: "/images/Jesus-Gonzalez--BANNER.jpg",
      color: "#ffd699"
    },
    {
      año: "2025",
      titulo: "Revolución Digital",
      descripcion: "Lanzamiento del Acordeón Interactivo estilo videojuego. Aprender teoría musical, canciones y técnicas nunca fue tan efectivo.",
      imagen: "/Acordeon PRO MAX.png",
      color: "#ff6600"
    }
  ];

  onMount(() => {
    mounted = true;
    
    // Rotar testimonios cada 5 segundos
    setInterval(() => {
      currentTestimonial = (currentTestimonial + 1) % testimonios.length;
    }, 5000);
  });

  function irACursos() {
    goto('/cursos');
  }

  function irASimulador() {
          goto('/simulador-gaming');
  }
</script>

<svelte:head>
  <title>Nuestra Academia - Academia Vallenata Online</title>
  <meta name="description" content="Conoce la historia de la Academia Vallenata Online y por qué somos la mejor opción para aprender acordeón vallenato con el maestro Jesús González.">
</svelte:head>

<!-- HERO SECTION -->
<section class="hero-academia">
  <div class="hero-content">
    <div class="hero-text" class:visible={mounted}>
      <h1>15 Años Formando <span class="text-gradient">Acordeoneros Auténticos</span></h1>
      <p class="hero-subtitle">
        De acompañar a las leyendas del vallenato a crear la metodología más efectiva para aprender acordeón desde casa
      </p>
      
      <div class="stats-grid">
        <div class="stat-item">
          <span class="stat-number">5,000+</span>
          <span class="stat-label">Estudiantes Activos</span>
        </div>
        <div class="stat-item">
          <span class="stat-number">200+</span>
          <span class="stat-label">Horas de Contenido</span>
        </div>
        <div class="stat-item">
          <span class="stat-number">95%</span>
          <span class="stat-label">Satisfacción</span>
        </div>
      </div>
    </div>
    
    <div class="hero-image" class:visible={mounted}>
      <img src="/images/Foto maestro oficial JESUS GONZALEZ.jpg" alt="Maestro Jesús González" class="maestro-img">
      <div class="glow-effect"></div>
    </div>
  </div>
</section>

<!-- POR QUÉ SOMOS DIFERENTES -->
<section class="section-diferencias">
  <div class="container">
    <h2 class="section-title text-center">¿Por Qué Elegir Academia Vallenata Online?</h2>
    <p class="section-subtitle text-center">Resolvemos los 3 problemas más grandes que tienen los estudiantes de acordeón</p>
    
    <div class="diferencias-grid">
      <div class="diferencia-card" class:visible={mounted}>
        <div class="card-icon">🎯</div>
        <h3>Sin Profesor Cerca</h3>
        <p><strong>Problema:</strong> No hay maestros de acordeón vallenato en tu ciudad</p>
        <p><strong>Solución:</strong> Clases en vivo y simulador interactivo 24/7</p>
        <img src="/images/Home/Clases-de-acordeon-virtuales.jpg" alt="Clases virtuales" class="card-img">
      </div>
      
      <div class="diferencia-card" class:visible={mounted}>
        <div class="card-icon">💰</div>
        <h3>Clases Muy Costosas</h3>
        <p><strong>Problema:</strong> Clases presenciales cuestan $50,000+ por hora</p>
        <p><strong>Solución:</strong> Acceso ilimitado por menos de $30,000 al mes</p>
        <img src="/images/Home/Cursos-de-acordeon.jpg" alt="Cursos económicos" class="card-img">
      </div>
      
      <div class="diferencia-card" class:visible={mounted}>
        <div class="card-icon">⏰</div>
        <h3>Horarios Rígidos</h3>
        <p><strong>Problema:</strong> Horarios fijos que no se adaptan a tu vida</p>
        <p><strong>Solución:</strong> Aprende a tu ritmo, cuando quieras, donde quieras</p>
        <img src="/images/Home/Clases-Personalizadas-de-acordeón.jpg" alt="Horarios flexibles" class="card-img">
      </div>
    </div>
  </div>
</section>

<!-- NUESTRA HISTORIA -->
<section class="section-historia">
  <div class="container">
    <h2 class="section-title text-center">Nuestra Historia</h2>
    <p class="historia-intro text-center">
      De tocar con las leyendas del vallenato a revolucionar la educación musical online
    </p>
    
    <div class="cronologia">
      {#each cronologia as evento, index}
        <div class="cronologia-item" class:visible={mounted} style="--delay: {index * 0.2}s;">
          <div class="cronologia-fecha" style="background: {evento.color};">
            {evento.año}
          </div>
          <div class="cronologia-content">
            <div class="cronologia-imagen">
              <img src="{evento.imagen}" alt="{evento.titulo}" loading="lazy">
            </div>
            <div class="cronologia-texto">
              <h3>{evento.titulo}</h3>
              <p>{evento.descripcion}</p>
            </div>
          </div>
        </div>
      {/each}
    </div>
  </div>
</section>

<!-- SIMULADOR SHOWCASE -->
<section class="section-simulador">
  <div class="container">
    <div class="simulador-content">
      <div class="simulador-text">
        <h2>Acordeón Interactivo <span class="text-gradient">Estilo Videojuego</span></h2>
        <p>La primera plataforma que combina gamificación con aprendizaje musical real. Aprende teoría, técnicas y canciones de forma divertida y efectiva.</p>
        
        <div class="simulador-features">
          <div class="feature">
            <span class="feature-icon">🎮</span>
            <span>Experiencia de videojuego</span>
          </div>
          <div class="feature">
            <span class="feature-icon">🎵</span>
            <span>Teoría musical interactiva</span>
          </div>
          <div class="feature">
            <span class="feature-icon">🏆</span>
            <span>Sistema de logros y ranking</span>
          </div>
        </div>
        
        <button class="btn-simulador" on:click={irASimulador}>
          Probar Simulador Gratis
        </button>
      </div>
      
      <div class="simulador-imagen">
        <img src="/Acordeon PRO MAX.png" alt="Acordeón Interactivo" class="acordeon-img">
        <div class="simulador-glow"></div>
      </div>
    </div>
  </div>
</section>

<!-- TESTIMONIOS -->
<section class="section-testimonios">
  <div class="container">
    <h2 class="section-title text-center">Lo Que Dicen Nuestros Estudiantes</h2>
    
    <div class="testimonios-container">
      {#each testimonios as testimonio, index}
        <div class="testimonio-card" class:active={currentTestimonial === index}>
          <div class="testimonio-content">
            <p>"{testimonio.texto}"</p>
            <div class="testimonio-author">
              <strong>{testimonio.nombre}</strong>
              <span>{testimonio.ciudad}</span>
              <span class="nivel">Nivel: {testimonio.nivel}</span>
              <span class="tiempo">Tiempo estudiando: {testimonio.tiempo}</span>
            </div>
          </div>
        </div>
      {/each}
      
      <div class="testimonios-dots">
        {#each testimonios as _, index}
          <button 
            class="dot" 
            class:active={currentTestimonial === index}
            on:click={() => currentTestimonial = index}
          ></button>
        {/each}
      </div>
    </div>
  </div>
</section>

<!-- CTA FINAL -->
<section class="section-cta">
  <div class="container">
    <div class="cta-content">
      <h2>¿Listo Para Convertirte en <span class="text-gradient">Acordeonero Profesional</span>?</h2>
      <p>Únete a los 5,000+ estudiantes que ya están tocando sus canciones favoritas</p>
      
      <div class="cta-buttons">
        <button class="btn-primary" on:click={irACursos}>
          Ver Nuestros Cursos
        </button>
        <button class="btn-secondary" on:click={irASimulador}>
          Probar Simulador Gratis
        </button>
      </div>
    </div>
  </div>
</section>

<style>
  :global(body) {
    overflow-x: hidden;
  }
  
  .hero-academia {
    background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
    min-height: 90vh;
    display: flex;
    align-items: center;
    padding: 2rem 0;
    position: relative;
    overflow: hidden;
  }
  
  .hero-academia::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: url('/images/Jesus-Gonzalez--Fondo.jpg') center/cover;
    opacity: 0.1;
    z-index: 0;
  }
  
  .hero-content {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 4rem;
    align-items: center;
    position: relative;
    z-index: 1;
  }
  
  .hero-text {
    opacity: 0;
    transform: translateX(-50px);
    transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  }
  
  .hero-text.visible {
    opacity: 1;
    transform: translateX(0);
  }
  
  .hero-text h1 {
    font-size: clamp(2.5rem, 5vw, 4rem);
    font-weight: 900;
    color: white;
    margin-bottom: 1.5rem;
    line-height: 1.1;
  }
  
  .text-gradient {
    background: linear-gradient(135deg, #ff6600, #ff8c42);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }
  
  .hero-subtitle {
    font-size: 1.2rem;
    color: #cccccc;
    margin-bottom: 2rem;
    line-height: 1.6;
  }
  
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 2rem;
    margin-top: 2rem;
  }
  
  .stat-item {
    text-align: center;
  }
  
  .stat-number {
    display: block;
    font-size: 2.5rem;
    font-weight: 900;
    color: #ff6600;
    line-height: 1;
  }
  
  .stat-label {
    display: block;
    font-size: 0.9rem;
    color: #999;
    margin-top: 0.5rem;
  }
  
  .hero-image {
    text-align: center;
    position: relative;
    opacity: 0;
    transform: translateX(50px);
    transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  }
  
  .hero-image.visible {
    opacity: 1;
    transform: translateX(0);
  }
  
  .maestro-img {
    width: 100%;
    max-width: 400px;
    height: auto;
    border-radius: 20px;
    box-shadow: 0 20px 40px rgba(255, 102, 0, 0.3);
    position: relative;
    z-index: 2;
  }
  
  .glow-effect {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 80%;
    height: 80%;
    background: radial-gradient(circle, rgba(255, 102, 0, 0.3) 0%, transparent 70%);
    border-radius: 50%;
    animation: pulse 3s ease-in-out infinite;
    z-index: 1;
  }
  
  @keyframes pulse {
    0%, 100% { transform: translate(-50%, -50%) scale(1); opacity: 0.3; }
    50% { transform: translate(-50%, -50%) scale(1.1); opacity: 0.6; }
  }
  
  .section-diferencias, .section-historia, .section-simulador, .section-testimonios, .section-cta {
    padding: 6rem 0;
  }
  
  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem;
  }
  
  .section-title {
    font-size: clamp(2rem, 4vw, 3rem);
    font-weight: 800;
    color: #333;
    margin-bottom: 1rem;
  }
  
  .section-subtitle {
    font-size: 1.1rem;
    color: #666;
    margin-bottom: 3rem;
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
  }
  
  .text-center {
    text-align: center;
  }
  
  .diferencias-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: 2rem;
  }
  
  .diferencia-card {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    border-top: 4px solid #ff6600;
    opacity: 0;
    transform: translateY(50px);
    transition: all 0.6s cubic-bezier(0.4, 0, 0.2, 1);
  }
  
  .diferencia-card.visible {
    opacity: 1;
    transform: translateY(0);
  }
  
  .diferencia-card:hover {
    transform: translateY(-10px);
    box-shadow: 0 20px 40px rgba(255, 102, 0, 0.15);
  }
  
  .card-icon {
    font-size: 3rem;
    margin-bottom: 1rem;
  }
  
  .diferencia-card h3 {
    font-size: 1.5rem;
    font-weight: 700;
    color: #333;
    margin-bottom: 1rem;
  }
  
  .diferencia-card p {
    margin-bottom: 1rem;
    line-height: 1.6;
    color: #555;
  }
  
  .diferencia-card p strong {
    color: #ff6600;
  }
  
  .card-img {
    width: 100%;
    height: 200px;
    object-fit: cover;
    border-radius: 10px;
    margin-top: 1rem;
  }
  
  .section-historia {
    background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%);
  }
  
  .historia-intro {
    font-size: 1.2rem;
    color: #666;
    margin-bottom: 4rem;
    max-width: 700px;
    margin-left: auto;
    margin-right: auto;
  }
  
  .cronologia {
    position: relative;
    max-width: 800px;
    margin: 0 auto;
  }
  
  .cronologia::before {
    content: '';
    position: absolute;
    left: 50%;
    top: 0;
    bottom: 0;
    width: 4px;
    background: linear-gradient(to bottom, #ff6600, #ff8c42);
    transform: translateX(-50%);
    border-radius: 2px;
  }
  
  .cronologia-item {
    position: relative;
    margin-bottom: 4rem;
    opacity: 0;
    transform: translateY(50px);
    transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
    transition-delay: var(--delay, 0s);
  }
  
  .cronologia-item.visible {
    opacity: 1;
    transform: translateY(0);
  }
  
  .cronologia-fecha {
    position: absolute;
    left: 50%;
    top: 2rem;
    transform: translateX(-50%);
    background: #ff6600;
    color: white;
    padding: 0.8rem 1.5rem;
    border-radius: 50px;
    font-weight: 800;
    font-size: 1.1rem;
    box-shadow: 0 4px 15px rgba(255, 102, 0, 0.3);
    z-index: 2;
  }
  
  .cronologia-content {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 3rem;
    align-items: center;
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    margin: 0 2rem;
  }
  
  .cronologia-item:nth-child(even) .cronologia-content {
    grid-template-columns: 1fr 1fr;
    direction: rtl;
  }
  
  .cronologia-item:nth-child(even) .cronologia-texto {
    direction: ltr;
  }
  
  .cronologia-imagen img {
    width: 100%;
    height: 250px;
    object-fit: cover;
    border-radius: 15px;
    box-shadow: 0 10px 25px rgba(0,0,0,0.15);
  }
  
  .cronologia-texto h3 {
    font-size: 1.8rem;
    font-weight: 700;
    color: #333;
    margin-bottom: 1rem;
  }
  
  .cronologia-texto p {
    color: #555;
    line-height: 1.6;
    font-size: 1rem;
  }
  
  .section-simulador {
    background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
    color: white;
  }
  
  .simulador-content {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 4rem;
    align-items: center;
  }
  
  .simulador-text h2 {
    font-size: clamp(2rem, 4vw, 3rem);
    font-weight: 800;
    margin-bottom: 1.5rem;
    color: white;
  }
  
  .simulador-text p {
    font-size: 1.1rem;
    color: #cccccc;
    margin-bottom: 2rem;
    line-height: 1.6;
  }
  
  .simulador-features {
    margin-bottom: 2rem;
  }
  
  .feature {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1rem;
    font-size: 1rem;
    color: #cccccc;
  }
  
  .feature-icon {
    font-size: 1.5rem;
  }
  
  .btn-simulador {
    background: linear-gradient(135deg, #ff6600, #ff8c42);
    color: white;
    border: none;
    padding: 1rem 2rem;
    border-radius: 50px;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 4px 15px rgba(255, 102, 0, 0.3);
  }
  
  .btn-simulador:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(255, 102, 0, 0.4);
  }
  
  .simulador-imagen {
    position: relative;
    text-align: center;
  }
  
  .acordeon-img {
    width: 100%;
    max-width: 400px;
    height: auto;
    filter: drop-shadow(0 20px 40px rgba(255, 102, 0, 0.3));
    animation: float 3s ease-in-out infinite;
  }
  
  @keyframes float {
    0%, 100% { transform: translateY(0px); }
    50% { transform: translateY(-20px); }
  }
  
  .simulador-glow {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 60%;
    height: 60%;
    background: radial-gradient(circle, rgba(255, 102, 0, 0.2) 0%, transparent 70%);
    border-radius: 50%;
    animation: pulse 3s ease-in-out infinite;
  }
  
  .section-testimonios {
    background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%);
  }
  
  .testimonios-container {
    position: relative;
    max-width: 600px;
    margin: 0 auto;
  }
  
  .testimonio-card {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    border-left: 4px solid #ff6600;
    opacity: 0;
    transform: translateX(50px);
    transition: all 0.5s ease;
    position: absolute;
    width: 100%;
    left: 0;
  }
  
  .testimonio-card.active {
    opacity: 1;
    transform: translateX(0);
    position: relative;
  }
  
  .testimonio-content p {
    font-size: 1.1rem;
    font-style: italic;
    color: #333;
    margin-bottom: 1.5rem;
    line-height: 1.6;
  }
  
  .testimonio-author strong {
    display: block;
    color: #ff6600;
    font-size: 1.1rem;
    margin-bottom: 0.25rem;
  }
  
  .testimonio-author span {
    display: block;
    color: #666;
    font-size: 0.9rem;
    margin-bottom: 0.25rem;
  }
  
  .nivel {
    color: #ff6600 !important;
    font-weight: 600 !important;
  }
  
  .testimonios-dots {
    display: flex;
    justify-content: center;
    gap: 0.5rem;
    margin-top: 2rem;
  }
  
  .dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    border: none;
    background: #ddd;
    cursor: pointer;
    transition: all 0.3s ease;
  }
  
  .dot.active {
    background: #ff6600;
    transform: scale(1.2);
  }
  
  .section-cta {
    background: linear-gradient(135deg, #ff6600 0%, #ff8c42 100%);
    color: white;
    text-align: center;
  }
  
  .cta-content h2 {
    font-size: clamp(2rem, 4vw, 3rem);
    font-weight: 800;
    margin-bottom: 1rem;
    color: white;
  }
  
  .cta-content p {
    font-size: 1.2rem;
    margin-bottom: 2rem;
    opacity: 0.9;
  }
  
  .cta-buttons {
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
  }
  
  .btn-primary, .btn-secondary {
    padding: 1rem 2rem;
    border: none;
    border-radius: 50px;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    min-width: 200px;
  }
  
  .btn-primary {
    background: white;
    color: #ff6600;
  }
  
  .btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.2);
  }
  
  .btn-secondary {
    background: transparent;
    color: white;
    border: 2px solid white;
  }
  
  .btn-secondary:hover {
    background: white;
    color: #ff6600;
    transform: translateY(-2px);
  }
  
  /* RESPONSIVE */
  @media (max-width: 768px) {
    .hero-content {
      grid-template-columns: 1fr;
      gap: 2rem;
      text-align: center;
    }
    
    .stats-grid {
      grid-template-columns: repeat(3, 1fr);
      gap: 1rem;
    }
    
    .diferencias-grid {
      grid-template-columns: 1fr;
    }
    
    .cronologia::before {
      left: 2rem;
    }
    
    .cronologia-fecha {
      left: 2rem;
      transform: translateX(-50%);
    }
    
    .cronologia-content {
      grid-template-columns: 1fr;
      margin-left: 4rem;
      margin-right: 1rem;
    }
    
    .cronologia-item:nth-child(even) .cronologia-content {
      grid-template-columns: 1fr;
      direction: ltr;
    }
    
    .simulador-content {
      grid-template-columns: 1fr;
      gap: 2rem;
      text-align: center;
    }
    
    .cta-buttons {
      flex-direction: column;
      align-items: center;
    }
  }
</style>
