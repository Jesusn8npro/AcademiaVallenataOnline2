<script lang="ts">
import { onMount } from 'svelte';
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

onMount(() => {
  // Redirigir al login después de 3 segundos
  setTimeout(() => {
    goto('/');
  }, 3000);
});
</script>

<svelte:head>
  <title>Sesión Cerrada - Academia Vallenata</title>
</svelte:head>

<div class="contenedor-sesion-cerrada">
  <div class="tarjeta-sesion-cerrada">
    <div class="icono-exito">
      ✅
    </div>
    <h1>Sesión Cerrada Exitosamente</h1>
    <p>Tu sesión se ha cerrado correctamente. Serás redirigido al inicio en unos segundos.</p>
    
    <div class="acciones">
      <a href="/" class="boton-inicio">Ir al Inicio</a>
      <a href="/login" class="boton-login">Iniciar Sesión</a>
    </div>
  </div>
</div>

<style>
.contenedor-sesion-cerrada {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
}

.tarjeta-sesion-cerrada {
  background: white;
  border-radius: 16px;
  padding: 3rem;
  text-align: center;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  max-width: 500px;
  width: 100%;
}

.icono-exito {
  font-size: 4rem;
  margin-bottom: 1.5rem;
}

h1 {
  font-size: 2rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 1rem;
}

p {
  color: #6b7280;
  font-size: 1.1rem;
  margin-bottom: 2.5rem;
  line-height: 1.6;
}

.acciones {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.boton-inicio,
.boton-login {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  text-decoration: none;
  font-weight: 500;
  transition: all 0.2s;
  min-width: 120px;
}

.boton-inicio {
  background: #3b82f6;
  color: white;
}

.boton-inicio:hover {
  background: #2563eb;
  transform: translateY(-1px);
}

.boton-login {
  background: transparent;
  color: #3b82f6;
  border: 2px solid #3b82f6;
}

.boton-login:hover {
  background: #3b82f6;
  color: white;
  transform: translateY(-1px);
}

@media (max-width: 640px) {
  .contenedor-sesion-cerrada {
    padding: 1rem;
  }
  
  .tarjeta-sesion-cerrada {
    padding: 2rem;
  }
  
  .acciones {
    flex-direction: column;
  }
}
</style>
