<script lang="ts">
  import ContadorOferta from '$lib/components/ComponentesLanding/ContadorOferta.svelte';
  import ModalPagoInteligente from '$lib/components/ComponentesLanding/ModalPagoInteligente.svelte';

  // Modal de pago
  let mostrarModalPago = false;

  // Datos del curso "Aprende desde cero"
  const cursoAcordeion = {
    id: 'curso-acordeon-desde-cero',
    titulo: 'Curso de Acordeón desde Cero',
    precio_normal: 379000,
    precio_rebajado: 289000,
    descripcion: 'Aprende a tocar acordeón vallenato desde cero absoluto hasta tocar como un profesional'
  };

  function comprarAhora() {
    console.log('🚀 Abriendo modal de pago para curso acordeón desde cero');
    mostrarModalPago = true;
  }
</script>

<ContadorOferta />

<section class="heroe">
  <div class="contenedor">
    <div class="heroe-contenido">
      <div class="insignia fuego">🔥 ¡CURSO ESTRELLA! 🔥</div>
      <div class="insignia actualizado">⚡ ¡CURSO ACTUALIZADO! Ahora incluye 50% MÁS contenido y nuevas clases exclusivas</div>
      
      <h1 class="titulo-principal">
        <span class="dolor">¿Llevas AÑOS soñando con tocar acordeón pero nunca sabes por dónde empezar?</span>
        <span class="solucion">¡Deja de ser EL QUE OBSERVA y conviértete en EL QUE TODOS APLAUDEN!</span>
      </h1>

      <div class="beneficios">
        <div class="beneficio">✅ Desde cero absoluto - No necesitas experiencia previa</div>
        <div class="beneficio">✅ Primera canción en menos de 7 días</div>
        <div class="beneficio">✅ Método del maestro Jesús González</div>
      </div>

      <div class="video">
        <iframe 
          src="https://iframe.mediadelivery.net/embed/296804/dfc4d85e-c010-4ed8-96ad-ba6bbb264fcd?autoplay=false&loop=false&muted=false&preload=true&responsive=true"
          title="Aprende a tocar acordeón desde cero">
        </iframe>
      </div>

      <button class="boton-principal" on:click={comprarAhora}>
        🚀 ¡SÍ, QUIERO APRENDER YA!
      </button>
      
      <div class="precios">
        <div class="precio-antes">$379.000 COP</div>
        <div class="precio-ahora">$289.000 COP</div>
        <div class="ahorro">¡Ahorras $90.000 pesos hoy!</div>
      </div>
      
      <div class="metodos-pago">
        <img src="/images/Metodos-de-pago.jpg" alt="Métodos de pago" />
        <p>💳 Paga seguro con tarjeta, PSE o efectivo</p>
      </div>

      <div class="social">
        <div><span class="numero">+5,000</span> Estudiantes felices</div>
        <div>★★★★★ 4.9/5 (847 reseñas)</div>
      </div>
    </div>
  </div>
</section>

<section class="problemas">
  <div class="contenedor">
    <h2 class="titulo">¿Te identificas con alguna de estas situaciones?</h2>
    <div class="grid">
      <div class="tarjeta">
        <div class="emoji">😔</div>
        <h3>La vergüenza en las reuniones</h3>
        <p>Cuando sacan el acordeón y todos esperan que toques algo... pero solo te quedas callado viendo a otros brillar.</p>
      </div>
      <div class="tarjeta">
        <div class="emoji">😤</div>
        <h3>Años de "algún día lo haré"</h3>
        <p>Ya perdiste la cuenta de cuántas veces dijiste "este año sí aprendo acordeón"... pero nunca sabes por dónde empezar.</p>
      </div>
      <div class="tarjeta">
        <div class="emoji">🤷‍♂️</div>
        <h3>Intentos fallidos sin guía</h3>
        <p>Has probado videos de YouTube, aplicaciones, incluso un primo te "enseñó"... pero siempre te quedas en lo mismo: ruido sin sentido.</p>
      </div>
      <div class="tarjeta">
        <div class="emoji">😰</div>
        <h3>"Es muy difícil para mí"</h3>
        <p>Crees que no tienes "el don" o que empezaste "muy tarde"... mientras ves a niños de 8 años tocar mejor que tú.</p>
      </div>
    </div>
  </div>
</section>

<section class="solucion">
  <div class="contenedor">
    <div class="grid-dos">
      <img src="/images/Jesus-Gonzalez--Fondo.jpg" alt="Jesús González" class="foto" />
      <div>
        <h2 class="titulo">¡Pero todo eso cambia HOY!</h2>
        <h3 class="subtitulo">El método que ha transformado a +5,000 personas</h3>
        
        <div class="curso-info">
          <span class="badge">🚀 RECIÉN ACTUALIZADO</span>
          <h4>"Aprende a Tocar Acordeón Desde Cero"</h4>
          <p>El único curso paso a paso que te lleva de tu primera nota hasta tocar como un profesional, sin importar tu edad o experiencia.</p>
          <div class="nuevas-clases">
            <strong>🎯 NUEVAS CLASES INCLUIDAS:</strong>
            <ul>
              <li>✨ Técnicas avanzadas de digitación</li>
              <li>✨ Secretos de acordeonistas profesionales</li>
              <li>✨ Clases EXCLUSIVAS de acompañamiento</li>
            </ul>
          </div>
        </div>

        <div class="instructor">
          <h4>Tu instructor: Jesús González</h4>
          <p>He tenido el honor de acompañar con mi acordeón a grandes intérpretes de la música vallenata como Felipe Peláez y Orlando Acosta. Con más de 20 años de experiencia musical, sé exactamente qué necesitas para dominar este hermoso instrumento.</p>
        </div>
      </div>
    </div>
  </div>
</section>

<section class="testimonios">
  <div class="contenedor">
    <h2 class="titulo">Resultados reales de estudiantes:</h2>
    <div class="grid-tres">
      <div class="tarjeta">
        <p>"En solo 2 semanas ya estaba tocando 'La Gota Fría' completa. Mi familia no lo podía creer. ¡Ahora soy el alma de la fiesta!"</p>
        <div class="autor">Carlos Mendoza - Barranquilla, Colombia</div>
        <div class="rating">★★★★★</div>
      </div>
      <div class="tarjeta">
        <p>"Tengo 58 años y pensé que era muy tarde para aprender. Jesús me demostró que nunca es tarde para cumplir un sueño. ¡Ya toco 15 canciones!"</p>
        <div class="autor">María Elena Vega - Medellín, Colombia</div>
        <div class="rating">★★★★★</div>
      </div>
      <div class="tarjeta">
        <p>"Mi hijo de 12 años y yo aprendemos juntos. Es increíble cómo Jesús hace que algo tan complejo se vea tan fácil."</p>
        <div class="autor">Roberto Jiménez - Cali, Colombia</div>
        <div class="rating">★★★★★</div>
      </div>
    </div>
  </div>
</section>

<section class="oferta" id="seccion-oferta">
  <div class="contenedor">
    <h2 class="titulo">⚠️ ATENCIÓN: Esta oferta desaparece en pocas horas</h2>
    
    <div class="precios-comparacion">
      <div class="precio-normal">
        <div class="label">Precio Normal</div>
        <div class="valor">$379.000 COP</div>
      </div>
      <div class="precio-oferta">
        <div class="label">¡HOY SOLO!</div>
        <div class="valor especial">$289.000 COP</div>
      </div>
    </div>

    <div class="urgencia">
      <p><strong>¿Por qué esta oferta especial?</strong> Porque sé lo frustrante que es soñar con tocar acordeón y no saber cómo empezar. He decidido abrir solo <strong>100 cupos</strong> con precio especial para personas que, como tú, están listas para hacer realidad su sueño.</p>
      <div class="cupos">
        <span class="numero">23</span>
        <span>cupos disponibles</span>
      </div>
    </div>

    <button class="boton-oferta" on:click={comprarAhora}>
      🚀 ¡QUIERO ACCESO INMEDIATO!
      <small>✅ Garantía de 30 días • ✅ Acceso de por vida</small>
    </button>

    <div class="garantia">
      <div class="icono">🛡️</div>
      <div>
        <strong>Garantía de 30 días</strong><br>
        Si no estás 100% satisfecho, te devolvemos tu dinero sin preguntas
      </div>
    </div>
  </div>
</section>

<footer class="footer">
  <div class="contenedor">
    <p>© 2025 Academia Vallenata Online. Todos los derechos reservados.</p>
    <p>Este sitio no está afiliado con Facebook o ninguna entidad de Facebook.</p>
  </div>
</footer>

<style>
  :root {
    --primary: #e6a800;
    --secondary: #ff8c00;
    --text: #1e293b;
    --text-light: #64748b;
    --white: #ffffff;
    --red: #dc2626;
    --green: #059669;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }
  
  body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: var(--text); }
  
  .contenedor { max-width: 1200px; margin: 0 auto; padding: 0 20px; }

  /* HÉROE */
  .heroe {
    background: linear-gradient(135deg, #1f2937 0%, #374151 50%, #111827 100%);
    color: white;
    padding: 60px 0;
    position: relative;
    overflow: hidden;
  }
  .heroe::before {
    content: '';
    position: absolute;
    inset: 0;
    background: url('/images/Jesus-Gonzalez--BANNER.jpg') center/cover;
    opacity: 0.1;
    z-index: 1;
  }
  .heroe-contenido {
    position: relative;
    z-index: 2;
    max-width: 800px;
    margin: 0 auto;
    text-align: center;
  }

  /* INSIGNIAS Y BADGES */
  .insignia {
    display: inline-block;
    color: white;
    padding: 10px 20px;
    border-radius: 30px;
    font-weight: 600;
    margin: 10px auto;
    width: fit-content;
  }
  .insignia.fuego {
    background: var(--red);
    padding: 12px 25px;
    border-radius: 50px;
    font-weight: bold;
    animation: pulse 2s infinite;
  }
  .insignia.actualizado {
    background: linear-gradient(135deg, #10b981, #059669);
    font-size: 0.9rem;
    box-shadow: 0 4px 15px rgba(16, 185, 129, 0.3);
    animation: glow 2s infinite;
  }

  /* TÍTULOS */
  .titulo-principal .dolor {
    display: block;
    font-size: 1.1rem;
    font-weight: 400;
    margin-bottom: 15px;
    opacity: 0.9;
  }
  .titulo-principal .solucion {
    display: block;
    font-size: 2.2rem;
    font-weight: 900;
    line-height: 1.2;
    margin: 30px 0;
    color: #fbbf24;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
  }

  /* BENEFICIOS */
  .beneficios { margin: 30px 0; }
  .beneficio {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    margin-bottom: 15px;
    font-size: 1.05rem;
  }

  /* VIDEO */
  .video {
    position: relative;
    width: 100%;
    max-width: 600px;
    height: 350px;
    margin: 30px auto;
    border-radius: 20px;
    overflow: hidden;
    box-shadow: 0 20px 50px rgba(0,0,0,0.3);
  }
  .video iframe {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    border: none;
  }

  /* BOTONES */
  .boton-principal, .boton-oferta {
    background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
    color: white;
    border: none;
    padding: 20px 40px;
    border-radius: 12px;
    font-size: 1.2rem;
    font-weight: 900;
    cursor: pointer;
    width: 100%;
    margin: 20px 0;
    transition: all 0.3s ease;
    box-shadow: 0 8px 25px rgba(230, 168, 0, 0.4);
    text-transform: uppercase;
  }
  .boton-principal:hover, .boton-oferta:hover {
    transform: translateY(-3px);
    box-shadow: 0 12px 35px rgba(230, 168, 0, 0.6);
  }
  .boton-oferta {
    flex-direction: column;
    gap: 8px;
    font-size: 1.3rem;
    padding: 25px 50px;
  }
  .boton-oferta small { font-size: 0.9rem; font-weight: 400; }

  /* PRECIOS */
  .precios {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 15px;
    margin: 20px 0;
  }
  .precio-antes {
    font-size: 1.2rem;
    text-decoration: line-through;
    opacity: 0.7;
  }
  .precio-ahora {
    font-size: 2.5rem;
    font-weight: 900;
    color: var(--primary);
  }
  .ahorro {
    font-size: 1rem;
    color: var(--green);
    font-weight: 600;
  }

  /* MÉTODOS DE PAGO */
  .metodos-pago {
    margin: 25px 0;
    text-align: center;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }
  .metodos-pago img {
    max-width: 400px;
    width: 100%;
    border-radius: 12px;
    box-shadow: 0 8px 25px rgba(0,0,0,0.3);
    margin-bottom: 12px;
    display: block;
    margin-left: auto;
    margin-right: auto;
  }
  .metodos-pago p {
    color: #e2e8f0;
    font-weight: 500;
    opacity: 0.9;
  }

  /* SOCIAL PROOF */
  .social {
    display: flex;
    justify-content: space-between;
    margin-top: 30px;
    padding-top: 20px;
    border-top: 1px solid rgba(255,255,255,0.3);
  }
  .numero {
    font-size: 1.3rem;
    font-weight: 900;
    color: var(--primary);
  }

  /* SECCIONES GENERALES */
  .problemas { padding: 60px 0; background: #f8fafc; }
  .solucion { padding: 60px 0; background: linear-gradient(135deg, #1e293b 0%, #334155 100%); color: white; }
  .testimonios { padding: 60px 0; background: #f8fafc; }
  .oferta { padding: 60px 0; background: linear-gradient(135deg, var(--red), #991b1b); color: white; }

  /* TÍTULOS DE SECCIÓN */
  .titulo {
    font-size: 2.2rem;
    text-align: center;
    margin-bottom: 50px;
    font-weight: 800;
  }
  .solucion .titulo { color: #10b981; font-weight: 900; margin-bottom: 15px; }
  .subtitulo { font-size: 1.3rem; color: #e2e8f0; margin-bottom: 25px; font-weight: 600; }

  /* GRIDS */
  .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 30px; }
  .grid-dos { display: grid; grid-template-columns: 1fr 1fr; gap: 50px; align-items: center; }
  .grid-tres { display: grid; grid-template-columns: repeat(3, 1fr); gap: 25px; }

  /* TARJETAS */
  .tarjeta {
    background: white;
    padding: 25px;
    border-radius: 15px;
    text-align: center;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    transition: transform 0.3s ease;
  }
  .tarjeta:hover { transform: translateY(-5px); }
  .emoji { font-size: 2.5rem; margin-bottom: 15px; }
  .tarjeta h3 { font-size: 1.2rem; margin-bottom: 12px; font-weight: 700; }
  .tarjeta p { color: var(--text-light); line-height: 1.5; font-style: italic; margin-bottom: 15px; }
  .autor { font-weight: 600; color: var(--text-light); font-size: 0.9rem; }
  .rating { color: var(--primary); font-size: 1.1rem; margin-bottom: 10px; }

  /* FOTO MAESTRO */
  .foto {
    width: 100%;
    height: 400px;
    object-fit: cover;
    border-radius: 20px;
    box-shadow: 0 20px 50px rgba(0,0,0,0.2);
  }

  /* INFO CURSO */
  .curso-info {
    background: rgba(16, 185, 129, 0.1);
    padding: 25px;
    border-radius: 15px;
    margin-bottom: 25px;
    border-left: 5px solid #10b981;
  }
  .badge {
    background: linear-gradient(135deg, #f59e0b, #d97706);
    color: white;
    padding: 6px 15px;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 700;
    margin-bottom: 15px;
    display: inline-block;
    animation: pulse 2s infinite;
  }
  .nuevas-clases {
    margin-top: 20px;
    padding: 15px;
    background: rgba(16, 185, 129, 0.05);
    border-left: 4px solid #10b981;
    border-radius: 8px;
  }
  .nuevas-clases strong { color: #10b981; display: block; margin-bottom: 10px; }
  .nuevas-clases ul { margin-left: 20px; }
  .nuevas-clases li { margin-bottom: 8px; line-height: 1.5; }

  /* INSTRUCTOR */
  .instructor {
    background: rgba(230, 168, 0, 0.15);
    padding: 20px;
    border-radius: 15px;
    border-left: 5px solid var(--primary);
  }
  .instructor h4 { color: var(--primary); font-weight: 700; margin-bottom: 15px; }

  /* OFERTA ESPECIAL */
  .precios-comparacion { display: flex; justify-content: center; gap: 50px; margin: 40px 0; }
  .precio-normal, .precio-oferta { text-align: center; padding: 25px; border-radius: 15px; }
  .precio-normal { background: rgba(0,0,0,0.2); }
  .precio-oferta { background: rgba(255,255,255,0.1); border: 3px solid var(--primary); }
  .label { font-size: 1.1rem; font-weight: 600; margin-bottom: 5px; }
  .valor { font-size: 2.5rem; font-weight: 900; margin: 10px 0; }
  .especial { color: var(--primary); }

  /* URGENCIA */
  .urgencia {
    text-align: center;
    margin: 30px 0;
    background: rgba(0,0,0,0.1);
    padding: 25px;
    border-radius: 15px;
  }
  .cupos {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    margin: 20px 0;
    font-size: 1.2rem;
  }
  .cupos .numero {
    background: white;
    color: var(--red);
    padding: 10px 20px;
    border-radius: 50px;
    font-weight: 900;
    font-size: 1.4rem;
  }

  /* GARANTÍA */
  .garantia {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 15px;
    background: rgba(255,255,255,0.1);
    padding: 20px 30px;
    border-radius: 15px;
    margin-top: 30px;
  }
  .icono { font-size: 1.8rem; }

  /* FOOTER */
  .footer { background: #1e293b; color: white; padding: 30px 0; text-align: center; }
  .footer p { opacity: 0.8; }

  /* ANIMACIONES */
  @keyframes pulse { 0%, 100% { transform: scale(1); } 50% { transform: scale(1.05); } }
  @keyframes glow {
    0%, 100% { box-shadow: 0 4px 15px rgba(16, 185, 129, 0.3); }
    50% { box-shadow: 0 4px 20px rgba(16, 185, 129, 0.6), 0 0 30px rgba(16, 185, 129, 0.3); }
  }

  /* RESPONSIVO */
  @media (max-width: 768px) {
    .grid, .grid-tres { grid-template-columns: 1fr; }
    .grid-dos { grid-template-columns: 1fr; gap: 30px; }
    .precios-comparacion { flex-direction: column; gap: 20px; align-items: center; }
    .titulo-principal .solucion { font-size: 1.8rem; }
    .video { height: 250px; }
    .metodos-pago img { max-width: 300px; }
    .precio-ahora { font-size: 2rem; }
    .contenedor { padding: 0 15px; }
    .titulo { font-size: 1.8rem; }
    .insignia.actualizado { font-size: 0.8rem; padding: 8px 15px; }
  }
</style> 

<!-- Modal de Pago Inteligente -->
<ModalPagoInteligente 
  bind:mostrar={mostrarModalPago} 
  contenido={cursoAcordeion}
  tipoContenido="curso"
/> 