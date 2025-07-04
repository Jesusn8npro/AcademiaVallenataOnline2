<script>
  import { onMount } from 'svelte';
  let banners = [
  {
    titulo: '¡Nueva funcionalidad!',
    descripcion: 'Ahora puedes compartir videos y audios directamente en tus publicaciones. ¡Pruébalo en la comunidad!',
    link: '/comunidad'
  },
  {
    titulo: 'Novedad: Ranking actualizado',
    descripcion: 'El ranking de la comunidad ahora se actualiza en tiempo real con tus logros y participaciones.',
    link: '/comunidad/ranking'
  },
  {
    titulo: 'Evento especial de junio',
    descripcion: 'Participa en el reto musical de junio y gana una mentoría exclusiva. Más info en la sección de eventos.',
    link: '/eventos'
  }
];
  let actual = 0;
  let intervalo;

  onMount(() => {
    intervalo = setInterval(() => {
      actual = (actual + 1) % banners.length;
    }, 5000);
    return () => clearInterval(intervalo);
  });

  function irA(idx) {
    actual = idx;
  }
</script>

<div class="banner-slider">
  <div class="banner-contenido fade-in">
    <div class="banner-texto solo-texto">
      <h3>{banners[actual].titulo}</h3>
      <p>{banners[actual].descripcion}</p>
      {#if banners[actual].link}
        <a class="banner-btn" href={banners[actual].link}>Ver más</a>
      {/if}
    </div>
  </div>
  <div class="banner-dots">
    {#each banners as _, idx}
      <button class:dots-active={idx === actual} on:click={() => irA(idx)} aria-label={`Banner ${idx+1}`}></button>
    {/each}
  </div>
</div>

<style>
.banner-slider {
  width: 100%;
  max-width: 480px;
  margin: 2rem auto 0 auto;
  background: linear-gradient(135deg, #23234b 70%, #ffd700 100%);
  border-radius: 18px;
  box-shadow: 0 4px 18px 0 #00000022;
  overflow: hidden;
  position: relative;
  min-height: 180px;
}
.banner-contenido {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.2rem 1.4rem 1.2rem 1.2rem;
}
.banner-texto {
  flex: 1;
  text-align: center;
}
.banner-texto.solo-texto {
  margin: 0 auto;
  max-width: 90%;
}
.banner-texto h3 {
  margin: 0 0 0.2rem 0;
  font-size: 1.18rem;
  color: #ffd700;
  font-family: 'Orbitron', Arial, sans-serif;
  font-weight: 900;
}
.banner-texto p {
  margin: 0 0 0.7rem 0;
  color: #fff;
  font-size: 1rem;
  font-weight: 500;
}
.banner-btn {
  background: #ffd700;
  color: #23234e;
  font-weight: bold;
  border: none;
  border-radius: 7px;
  padding: 0.37rem 1.2rem;
  text-decoration: none;
  font-size: 1em;
  box-shadow: 0 1px 6px #ffd70033;
  transition: background 0.15s, color 0.15s;
}
.banner-btn:hover {
  background: #23234b;
  color: #ffd700;
}
.banner-dots {
  display: flex;
  justify-content: center;
  gap: 0.4rem;
  margin: 0.5rem 0 0.7rem 0;
}
.banner-dots button {
  width: 13px;
  height: 13px;
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
  from { opacity: 0; transform: translateY(16px); }
  to { opacity: 1; transform: none; }
}
</style>
