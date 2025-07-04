<script lang="ts">
import { goto } from '$app/navigation';

// URLs reales o de ejemplo (reemplaza por los tuyos si quieres)
const BLOG_URL = 'https://tu-blog.com';
const YOUTUBE_URL = 'https://youtube.com/@tuacademia';

function irHome() {
  goto('/');
}
function irLogin() {
  goto('/login');
}
</script>

<div class="logout-bg">
  <div class="logout-card animate-fadein">
    <div class="icon-wrap animate-pop">
      <svg width="60" height="60" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="12" fill="#e6a800"/><path d="M7 13l3 3 7-7" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
    </div>
    <h1>¡Sesión cerrada con éxito!</h1>
    <p class="msg">Gracias por aprender con nosotros.<br/>¡No pares tu progreso!</p>
    <div class="recursos">
      <span>Te invitamos a seguir aprendiendo en:</span>
      <div class="recursos-btns">
        <a href={BLOG_URL} target="_blank" rel="noopener" class="btn blog">
          <svg viewBox="0 0 24 24"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M4 4.5A2.5 2.5 0 0 1 6.5 7H20"/><rect x="2" y="2" width="20" height="20" rx="5"/></svg>
          Blog
        </a>
        <a href={YOUTUBE_URL} target="_blank" rel="noopener" class="btn youtube">
          <svg viewBox="0 0 24 24"><rect x="2" y="6" width="20" height="12" rx="4"/><polygon points="10 9 16 12 10 15 10 9"/></svg>
          YouTube
        </a>
      </div>
    </div>
    <div class="acciones">
      <button class="btn sec" on:click={irHome}>Volver al inicio</button>
      <button class="btn prim" on:click={irLogin}>Iniciar sesión</button>
    </div>
  </div>
</div>

<style>
.logout-bg {
  min-height: 100vh;
  background: linear-gradient(120deg, #fbeee6 0%, #ffe9b7 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}
.logout-card {
  background: #fff;
  border-radius: 2rem;
  box-shadow: 0 6px 32px rgba(44,44,44,0.13), 0 1.5px 8px rgba(44,44,44,0.08);
  padding: 2.8rem 2.2rem 2.2rem 2.2rem;
  max-width: 410px;
  width: 100%;
  text-align: center;
  animation: fadein 0.7s;
}
.icon-wrap {
  background: #fffbe6;
  border-radius: 50%;
  width: 82px;
  height: 82px;
  margin: 0 auto 1.2rem auto;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 12px rgba(230,168,0,0.10);
  animation: pop 0.7s;
}
.icon-wrap svg {
  display: block;
}
h1 {
  font-size: 1.6rem;
  color: #e6a800;
  margin-bottom: 0.5rem;
  font-weight: 800;
  letter-spacing: -1px;
}
.msg {
  font-size: 1.08rem;
  color: #444;
  margin-bottom: 1.5rem;
  line-height: 1.5;
}
.recursos {
  margin-bottom: 1.5rem;
}
.recursos span {
  display: block;
  color: #888;
  font-size: 1.01rem;
  margin-bottom: 0.6rem;
}
.recursos-btns {
  display: flex;
  gap: 1rem;
  justify-content: center;
}
.btn {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  font-size: 1.04rem;
  font-weight: 700;
  padding: 0.5rem 1.2rem;
  border-radius: 1.1rem;
  border: none;
  cursor: pointer;
  background: #f6f6f6;
  color: #222;
  box-shadow: 0 1px 4px rgba(0,0,0,0.07);
  transition: background 0.16s, color 0.16s, box-shadow 0.16s;
  text-decoration: none;
}
.btn svg {
  width: 22px;
  height: 22px;
  fill: none;
  stroke: #e6a800;
  stroke-width: 2;
}
.btn.blog:hover {
  background: #fffbe6;
  color: #e6a800;
  box-shadow: 0 2px 12px rgba(230,168,0,0.08);
}
.btn.youtube {
  background: #ffeaea;
  color: #d90000;
}
.btn.youtube svg {
  stroke: #d90000;
  fill: #d90000;
}
.btn.youtube:hover {
  background: #fff0f0;
  color: #b80000;
}
.acciones {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 1.6rem;
}
.btn.sec {
  background: #f6f6f6;
  color: #222;
}
.btn.sec:hover {
  background: #ececec;
}
.btn.prim {
  background: #e6a800;
  color: #fff;
}
.btn.prim:hover {
  background: #cfa100;
}
/* Animaciones */
@keyframes fadein {
  from { opacity: 0; transform: translateY(40px); }
  to { opacity: 1; transform: translateY(0); }
}
@keyframes pop {
  0% { transform: scale(0.6); opacity: 0; }
  80% { transform: scale(1.1); opacity: 1; }
  100% { transform: scale(1); }
}
.animate-fadein { animation: fadein 0.7s; }
.animate-pop { animation: pop 0.7s; }

@media (max-width: 600px) {
  .logout-card { padding: 1.3rem 0.5rem 1.2rem 0.5rem; }
  .icon-wrap { width: 60px; height: 60px; }
}
</style>
