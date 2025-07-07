<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';

  let ranking = [];
  let cargando = true;
  let error = null;
  let mostrarTodos = false;

  // Consulta el top 10 de usuarios con más publicaciones
  let intervaloRanking;

onMount(() => {
  cargarRanking();
  intervaloRanking = setInterval(cargarRanking, 30000); // Actualiza cada 30 segundos
  return () => {
    clearInterval(intervaloRanking);
  };
});

async function cargarRanking() {
  cargando = true;
  error = null;
  try {
    // Consulta el ranking combinado
    const { data, error: err } = await supabase.rpc('ranking_comunidad_total');
    if (err) throw err;
    // data: [{ usuario_id, publicaciones, comentarios, likes, tutoriales_completados, puntaje_total }]
    const top10 = (data || []).slice(0, 10);
    // Buscar perfiles para mostrar nombre/avatar
    const ids = top10.map(u => u.usuario_id);
    let perfiles = [];
    if (ids.length > 0) {
      const { data: perfilesData, error: errPerfil } = await supabase
        .from('perfiles')
        .select('id, nombre, nombre_usuario, url_foto_perfil')
        .in('id', ids);
      if (errPerfil) throw errPerfil;
      perfiles = perfilesData;
    }
    // Une los datos de ranking y perfil
    ranking = top10.map((r, i) => {
      const perfil = perfiles.find(p => p.id === r.usuario_id) || {};
      return {
        posicion: i + 1,
        id: r.usuario_id,
        nombre: perfil.nombre || perfil.nombre_usuario || 'Usuario',
                  avatar: perfil.url_foto_perfil || `https://ui-avatars.com/api/?name=${encodeURIComponent(perfil.nombre || 'Usuario')}&background=667eea&color=fff`,
        publicaciones: r.publicaciones,
        comentarios: r.comentarios,
        likes: r.likes,
        tutoriales: r.tutoriales_completados,
        puntaje: r.puntaje_total
      };
    });
  } catch (e) {
    error = 'Error al cargar el ranking: ' + (e.message || e);
  } finally {
    cargando = false;
  }
}

</script>

<div class="ranking-gamer">
  <h2>🏆 Ranking de la Comunidad</h2>
  {#if cargando}
    <div class="loading">Cargando ranking...</div>
  {:else if error}
    <div class="error">{error}</div>
  {:else}
    <ol>
  {#each (mostrarTodos ? ranking : ranking.slice(0, 5)) as user}
    <li class="item-ranking {user.posicion === 1 ? 'top1' : ''} {user.posicion === 2 ? 'top2' : ''} {user.posicion === 3 ? 'top3' : ''}">
      <span class="posicion">#{user.posicion}</span>
      <img class="avatar" src={user.avatar} alt={user.nombre} />
      <span class="nombre" title={user.nombre}>
        {user.nombre.length > 10 ? user.nombre.slice(0, 9) + '…' : user.nombre}
      </span>
      <span 
        class="puntaje {user.posicion === 1 ? 'top1-badge' : user.posicion === 2 ? 'top2-badge' : user.posicion === 3 ? 'top3-badge' : 'resto-badge'}"
        title={`Participación: ${(user.publicaciones ?? 0)} publicaciones, ${(user.comentarios ?? 0)} comentarios, ${(user.likes ?? 0)} likes, ${(user.tutoriales ?? 0)} tutoriales completados`}
      >
        {user.puntaje} pts
      </span>
    </li>
  {/each}
</ol>
{#if ranking.length > 5}
  <div class="ver-mas-container">
    {#if !mostrarTodos}
      <button class="btn-ver-mas" on:click={() => mostrarTodos = true}>
        Ver más posiciones
        <svg width="20" height="20" fill="none" viewBox="0 0 24 24"><path fill="#FFD700" d="M12 16.5a1 1 0 0 1-.7-.29l-5-5a1 1 0 0 1 1.4-1.42L12 13.59l4.3-4.3a1 1 0 1 1 1.4 1.42l-5 5A1 1 0 0 1 12 16.5Z"/></svg>
      </button>
    {:else}
      <button class="btn-ver-menos" on:click={() => mostrarTodos = false}>
        Ver menos
        <svg width="20" height="20" fill="none" viewBox="0 0 24 24"><path fill="#FFD700" d="M12 7.5a1 1 0 0 1 .7.29l5 5a1 1 0 0 1-1.4 1.42L12 10.41l-4.3 4.3a1 1 0 1 1-1.4-1.42l5-5A1 1 0 0 1 12 7.5Z"/></svg>
      </button>
    {/if}
  </div>
{/if}

  {/if}
</div>

<style>
.ranking-gamer {
  background: linear-gradient(135deg, #1a1a2e 60%, #16213e 100%);
  border-radius: 22px;
  box-shadow: 0 6px 24px 0 rgba(0,0,0,0.45);
  padding: 2rem 1.2rem 1.2rem 1.2rem;
  color: #fff;
  font-family: 'Orbitron', 'Segoe UI', Arial, sans-serif;
  margin-bottom: 2rem;
  border: 2.5px solid #ffd700;
  width: 320px;
}
.ranking-gamer h2 {
  text-align: center;
  font-size: 1.5rem;
  letter-spacing: 2px;
  margin-bottom: 1.3rem;
  font-weight: 900;
  color: #ffd700;
  text-shadow: 0 2px 8px #000;
}
ol {
  list-style: none;
  margin: 0;
  padding: 0;
}
.item-ranking {
  display: flex;
  align-items: center;
  background: rgba(255,255,255,0.06);
  border-radius: 12px;
  margin-bottom: 0.7rem;
  padding: 0.5rem 1.2rem 0.5rem 1rem;
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.18);
  position: relative;
  transition: transform 0.18s;
  border: 1.5px solid #23234e;
}

.item-ranking:hover {
  transform: scale(1.04);
  border-color: #ffd700;
}
.item-ranking.top1 {
  background: linear-gradient(90deg, #ffd700 60%, #fffbe6 100%);
  color: #23234e;
  font-weight: bold;
  box-shadow: 0 4px 18px 0 #ffd70077;
}
.item-ranking.top2 {
  background: linear-gradient(90deg, #c0c0c0 60%, #f5f6fa 100%);
  color: #23234e;
}
.item-ranking.top3 {
  background: linear-gradient(90deg, #cd7f32 60%, #f5e6da 100%);
  color: #23234e;
}
.posicion {
  font-size: 1.3rem;
  font-weight: 900;
  margin-right: 0.3rem;
  width: 2.2rem;
  text-align: center;
  color: #ffd700;
  text-shadow: 0 1px 4px #000;
}
.avatar {
  width: 42px;
  height: 42px;
  border-radius: 50%;
  margin-right: 0.5rem;
  border: 2.5px solid #ffd700;
  box-shadow: 0 0 8px #000a;
  background: #fff;
}
.nombre {
  display: inline-block;
  width: 110px;
  min-width: 80px;
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  vertical-align: middle;
  font-weight: bold;
  font-size: 1.08em;
  text-align: left;
  margin-left: 0.3rem;
  margin-right: 0.3rem;
}

.comentarios, .likes, .tutoriales, .puntaje {
  display: inline-block;
  margin-left: 2px;
  background: #23234b;
  border-radius: 8px;
  padding: 2px 4px;
  font-size: 0.97em;
  color: #ffd700;
  font-weight: 600;
}
.puntaje {
  background: #ffb300;
  color: #222;
  margin-left: auto;
  width: 70px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
}

     

.ver-mas-container {
  display: flex;
  justify-content: center;
  margin-top: 0.7rem;
}
.btn-ver-mas, .btn-ver-menos {
  background: linear-gradient(90deg, #23234b 60%, #ffd700 100%);
  color: #f4f4f5;
  font-size: 1.07em;
  font-weight: bold;
  border: none;
  border-radius: 10px;
  padding: 0.45rem 1.3rem 0.45rem 1.1rem;
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.18);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: background 0.18s, transform 0.13s;
}
.btn-ver-mas:hover, .btn-ver-menos:hover {
  background: linear-gradient(90deg, #ffd700 60%, #23234b 100%);
  color: #fff;
  transform: scale(1.05);
}
</style>
