<script lang="ts">
  import { onMount } from 'svelte';
  interface Noticia {
    texto: string;
    colorFondo?: string;
    colorTexto?: string;
    link?: string;
  }
  let noticias: Noticia[] = [
    {
      texto: '🎉 ¡Bienvenido a la nueva comunidad! Descubre las novedades y participa en los retos semanales.',
      colorFondo: 'linear-gradient(90deg, #23234b 60%, #ffd700 100%)',
      colorTexto: '#fff'
    },
    {
      texto: '📢 Nueva funcionalidad: Ahora puedes dar like y comentar en publicaciones en tiempo real.',
      colorFondo: 'linear-gradient(90deg, #ffd700 60%, #23234b 100%)',
      colorTexto: '#23234e'
    },
    {
      texto: '🚀 Próximamente: Cursos en vivo y masterclasses exclusivas para miembros activos.',
      colorFondo: 'linear-gradient(90deg, #23234b 60%, #29ffc6 100%)',
      colorTexto: '#fff'
    }
  ];
  let actual = 0;
  let intervalo: ReturnType<typeof setInterval>;

  onMount(() => {
    intervalo = setInterval(() => {
      actual = (actual + 1) % noticias.length;
    }, 5000);
    return () => clearInterval(intervalo);
  });

  function irA(idx: number) {
    actual = idx;
  }
</script>

<div class="banner-slider-simple" style="background: {noticias[actual].colorFondo}; color: {noticias[actual].colorTexto}">
  <div class="noticia-texto fade-in">
    {#if noticias[actual].link}
      <a href={noticias[actual].link} class="noticia-link">{noticias[actual].texto}</a>
    {:else}
      {noticias[actual].texto}
    {/if}
  </div>
  <div class="banner-dots">
    {#each noticias as _, idx}
      <button class:dots-active={idx === actual} on:click={() => irA(idx)} aria-label={`Noticia ${idx+1}`}></button>
    {/each}
  </div>
</div>

<style>
.banner-slider-simple {
  width: 100%;
  max-width: 440px;
  margin: 2.2rem auto 0 auto;
  border-radius: 16px;
  box-shadow: 0 4px 18px 0 rgba(0,0,0,0.11);
  overflow: hidden;
  position: relative;
  min-height: 64px;
  transition: background 0.4s;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}
.noticia-texto {
  font-size: 1.13rem;
  font-family: 'Segoe UI', Arial, sans-serif;
  font-weight: 600;
  padding: 1.1rem 1.7rem 1.1rem 1.4rem;
  text-align: center;
  line-height: 1.45;
  letter-spacing: 0.2px;
  color: inherit;
  min-height: 50px;
}
.noticia-link {
  color: inherit;
  text-decoration: underline;
  transition: color 0.18s;
}
.noticia-link:hover {
  color: #ffd700;
}
.banner-dots {
  display: flex;
  justify-content: center;
  gap: 0.4rem;
  margin: 0.2rem 0 0.7rem 0;
}
.banner-dots button {
  width: 11px;
  height: 11px;
  border-radius: 50%;
  border: none;
  background: #fff5;
  cursor: pointer;
  transition: background 0.18s, transform 0.13s;
}
.banner-dots button.dots-active {
  background: #ffd700;
  transform: scale(1.18);
  box-shadow: 0 0 6px #ffd70099;
}
.fade-in {
  animation: fadeIn 0.6s;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: none; }
}
@media (max-width: 700px) {
  .banner-slider-simple {
    max-width: 98vw;
    min-height: 48px;
    border-radius: 9px;
  }
  .noticia-texto {
    font-size: 0.98rem;
    padding: 0.7rem 0.7rem 0.7rem 0.7rem;
  }
}
</style>
