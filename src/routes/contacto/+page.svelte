<script>
  let formData = { nombre: '', email: '', telefono: '', ciudad: '', nivel: '', objetivo: '', mensaje: '' };
  let isSubmitting = false, showSuccess = false, activeFaq = -1;
  const metodos = [
    { t: 'WhatsApp', d: '¡Respuesta inmediata!', i: '📱', l: 'https://wa.me/573212587616', c: '#25D366' },
    { t: 'Email', d: 'Te respondemos en minutos', i: '📧', l: 'mailto:info@academiavallenataonline.com', c: '#ff6600' },
    { t: 'Llamada', d: 'Habla con un asesor', i: '📞', l: 'tel:+573212587616', c: '#1a73e8' },
    { t: 'Video Llamada', d: 'Solicita demo en vivo', i: '📹', l: '#', c: '#8b5cf6' }
  ];
  const faqs = [
    { p: '¿Cuánto tiempo toma aprender acordeón?', r: 'En 3 meses tocas tus primeras canciones. En 6 meses, nivel intermedio.' },
    { p: '¿Necesito tener un acordeón físico?', r: 'No al inicio. Puedes usar nuestro simulador y luego te guiamos para comprar.' },
    { p: '¿Las clases son en vivo?', r: 'Hay contenido grabado 24/7, clases en vivo semanales y sesiones personalizadas.' },
    { p: '¿Qué incluye la suscripción?', r: 'Simulador, todos los cursos, clases en vivo, comunidad y soporte.' }
  ];
  function toggleFaq(i) { activeFaq = activeFaq === i ? -1 : i; }
  async function enviarFormulario() {
    if (isSubmitting) return;
    isSubmitting = true;
    setTimeout(() => {
      isSubmitting = false; showSuccess = true;
      setTimeout(() => { showSuccess = false; formData = { nombre: '', email: '', telefono: '', ciudad: '', nivel: '', objetivo: '', mensaje: '' }; }, 2000);
    }, 1500);
  }
</script>

<svelte:head>
  <title>Contacto - Academia Vallenata Online</title>
  <meta name="description" content="Contáctanos y aprende acordeón vallenato con el mejor método. Respuesta inmediata por WhatsApp, email o llamada.">
</svelte:head>

<!-- HERO VENDEDOR Y MÉTODOS DE CONTACTO -->
<section class="hero">
  <h1>¡Da el primer paso para tocar acordeón como siempre soñaste!</h1>
  <p class="sub">Resuelve tus dudas, recibe asesoría personalizada y accede a la mejor comunidad de acordeoneros. <b>¡Contáctanos ahora y transforma tu vida musical!</b></p>
  <div class="metodos-hero-grid">
    {#each metodos as m}
      <a href={m.l} class="m-btn-grid" style="--c: {m.c}" target="_blank" rel="noopener">
        <span class="m-ico">{m.i}</span>
        <span class="m-info">
          <b>{m.t}</b>
          <small>{m.d}</small>
        </span>
      </a>
    {/each}
  </div>
</section>

<!-- FORMULARIO -->
<section class="formulario">
  <form on:submit|preventDefault={enviarFormulario}>
    <div class="row">
      <input placeholder="Nombre" bind:value={formData.nombre} required>
      <input placeholder="Teléfono / WhatsApp" bind:value={formData.telefono} required>
    </div>
    <div class="row">
      <input placeholder="Email" type="email" bind:value={formData.email} required>
      <input placeholder="Ciudad" bind:value={formData.ciudad} required>
    </div>
    <div class="row">
      <select bind:value={formData.nivel} required>
        <option value="">Nivel actual</option>
        <option>Principiante</option><option>Básico</option><option>Intermedio</option><option>Avanzado</option>
      </select>
      <select bind:value={formData.objetivo} required>
        <option value="">¿Qué quieres lograr?</option>
        <option>Hobby</option><option>Profesional</option><option>Canciones específicas</option><option>Mejorar técnica</option>
      </select>
    </div>
    <textarea placeholder="Cuéntanos tus metas o dudas" bind:value={formData.mensaje}></textarea>
    <button type="submit" disabled={isSubmitting}>
      {#if isSubmitting}<span class="spin"></span>Enviando...{:else if showSuccess}✓ ¡Enviado!{:else}Recibir Plan Personalizado{/if}
    </button>
    <div class="beneficios">
      <span>✓ Evaluación gratuita</span>
      <span>✓ Plan personalizado</span>
      <span>✓ Acceso simulador 7 días</span>
      <span>✓ Sesión de prueba</span>
      <span class="garantia">🛡️ Garantía 100% satisfacción</span>
    </div>
  </form>
</section>

<!-- PREGUNTAS FRECUENTES -->
<section class="faq-section">
  <h2>Preguntas Frecuentes</h2>
  <div class="faq-list">
    {#each faqs as f, i}
      <div class="faq-card {activeFaq===i?'open':''}">
        <button type="button" class="faq-q" on:click={() => toggleFaq(i)}>
          <span class="faq-icon">❓</span>
          <span class="faq-text">{f.p}</span>
          <span class="faq-arrow {activeFaq===i?'rot':''}">▶</span>
        </button>
        <div class="faq-a" style="max-height:{activeFaq===i?'200px':'0'}">
          <p>{f.r}</p>
        </div>
      </div>
    {/each}
  </div>
</section>

<style>
/* === HERO === */
.hero {
  background: linear-gradient(135deg,#1a1a1a,#2d2d2d);
  color:#fff;
  text-align:center;
  padding:3rem 1rem 2.5rem;
}
.hero h1 { font-size:2.2rem; font-weight:900; margin-bottom:1.2rem; line-height:1.15; }
.hero .sub { color:#ffd6b3; margin-bottom:2.2rem; font-size:1.15rem; max-width:600px; margin-left:auto; margin-right:auto; }

.metodos-hero-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  max-width: 600px;
  margin: 0 auto;
}
.m-btn-grid {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #fff;
  color: #222;
  border-radius: 16px;
  padding: 2rem 1rem;
  font-weight: 600;
  font-size: 1.08rem;
  text-decoration: none;
  box-shadow: 0 2px 12px #0001;
  border-bottom: 3px solid var(--c);
  border: 1.5px solid #eee;
  transition: .2s;
  min-height: 160px;
  min-width: 0;
  height: 100%;
}
.m-btn-grid:hover { background: #fffbf7; border-color: var(--c); box-shadow: 0 6px 24px #ff660033; }
.m-ico { font-size: 2.2rem; background: rgba(255,102,0,0.08); border-radius: 12px; padding: .5rem 1rem; margin-bottom: .7rem; }
.m-info { display: flex; flex-direction: column; align-items: center; }
.m-btn-grid b { color: var(--c); font-size: 1.1rem; }
.m-btn-grid small { color: #666; font-size: .97rem; font-weight: 400; }
@media(max-width:900px){.metodos-hero-grid{gap:1rem;} .m-btn-grid{padding:1.2rem .7rem;} }

/* === FORMULARIO === */
.formulario {
  background:#fff; padding:2.5rem 1rem; border-radius:18px; max-width:600px; margin:2.5rem auto 2rem; box-shadow:0 8px 32px #0001;
}
form { display:flex; flex-direction:column; gap:1rem; }
.row { display:grid; grid-template-columns:1fr 1fr; gap:1rem; }
@media(max-width:600px){.row{grid-template-columns:1fr;} }
input,select,textarea {
  padding:.9rem; border:1.5px solid #e1e5e9; border-radius:8px; font-size:1rem;
}
input:focus, select:focus, textarea:focus {
  outline: none !important;
  border: none !important;
  box-shadow: none !important;
}
button[type=submit] {
  background:linear-gradient(135deg,#ff6600,#ff8c42); color:#fff; border:none; border-radius:30px; padding:1rem;
  font-size:1.1rem; font-weight:600; cursor:pointer; transition:.2s;
}
button[disabled]{opacity:.7;cursor:not-allowed;}
.spin{display:inline-block;width:18px;height:18px;border:2px solid #fff3;border-top:2px solid #fff;border-radius:50%;margin-right:8px;vertical-align:middle;animation:spin 1s linear infinite;}@keyframes spin{to{transform:rotate(360deg);} }
.beneficios{display:flex;flex-wrap:wrap;gap:.7rem .9rem;margin-top:.7rem;font-size:.95rem;color:#555;justify-content:center;}
.garantia{color:#ff6600;font-weight:600;margin-left:1rem;}

/* === FAQ === */
.faq-section { background: #f8f9fa; padding: 3rem 0 4rem; }
.faq-section h2 { font-size:1.7rem; font-weight:800; color:#222; margin-bottom:2rem; text-align:center; }
.faq-list { max-width:700px; margin:0 auto; display:flex; flex-direction:column; gap:1.2rem; }
.faq-card {
  background: #fff; border-radius: 16px; box-shadow: 0 4px 24px #0001; border: 1.5px solid #eee;
  overflow: hidden; transition: box-shadow .2s, border-color .2s;
}
.faq-card.open { border-color: #ff6600; box-shadow: 0 8px 32px #ff660033; }
.faq-q {
  width: 100%; background: none; border: none; text-align: left; font-size: 1.08rem; font-weight: 600;
  padding: 1.2rem 1.5rem; cursor: pointer; display: flex; align-items: center; gap: 1rem; color: #222;
  transition: background .2s;
}
.faq-q:hover { background: #fff3e6; }
.faq-icon { font-size: 1.5rem; color: #ff6600; }
.faq-text { flex: 1; }
.faq-arrow {
  font-size: 1.3rem; color: #ff6600; transition: transform .3s cubic-bezier(.4,0,.2,1);
}
.faq-arrow.rot { transform: rotate(90deg); }
.faq-a {
  background: #fff8f2; color: #444; font-size: 1rem; padding: 0 1.5rem; transition: max-height .3s cubic-bezier(.4,0,.2,1);
  max-height: 0; overflow: hidden;
}
.faq-card.open .faq-a { padding-bottom: 1.2rem; }
.faq-a p { margin: 0; padding-top: .7rem; }
@media(max-width:600px){.faq-q{padding:1rem .7rem;}.faq-a{padding:0 .7rem;} }
</style> 