<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { obtenerSlugUsuario, coincideSlug } from '$lib/utilidades/utilidadesSlug';
  import { goto } from '$app/navigation';

  let usuarios: any[] = [];
  let cargando = false;
  let slugTest = '';
  let resultadoBusqueda: any = null;

  onMount(async () => {
    await cargarUsuarios();
  });

  async function cargarUsuarios() {
    cargando = true;
    const { data, error } = await supabase
      .from('perfiles')
      .select('id, nombre, apellido, nombre_usuario, nombre_completo')
      .limit(10);
    
    if (!error && data) {
      usuarios = data.map((usuario: any) => ({
        ...usuario,
        slug_generado: obtenerSlugUsuario(usuario)
      }));
    }
    cargando = false;
  }

  async function buscarPorSlug() {
    if (!slugTest) return;
    
    const { data, error } = await supabase
      .from('perfiles')
      .select('*');
    
    if (!error && data) {
      const encontrado = data.find((u: any) => coincideSlug(u, slugTest));
      resultadoBusqueda = encontrado || null;
    }
  }

  function probarNavegacion(slug: string) {
    goto(`/usuarios/${slug}`);
  }
</script>

<div class="debug-container">
  <h1>🔍 Debug de Slugs de Usuario</h1>
  
  <div class="seccion">
    <h2>Usuarios y sus slugs generados</h2>
    
    {#if cargando}
      <p>Cargando usuarios...</p>
    {:else}
      <div class="tabla-usuarios">
        {#each usuarios as usuario}
          <div class="usuario-item">
            <div class="usuario-info">
              <strong>{usuario.nombre || 'Sin nombre'} {usuario.apellido || ''}</strong>
              <div class="detalles">
                <span>Usuario: {usuario.nombre_usuario || 'Sin usuario'}</span>
                <span>Completo: {usuario.nombre_completo || 'Sin nombre completo'}</span>
              </div>
            </div>
            <div class="slug-info">
              <span class="slug">Slug: <code>{usuario.slug_generado}</code></span>
              <button on:click={() => probarNavegacion(usuario.slug_generado)}>
                Probar navegación
              </button>
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </div>
  
  <div class="seccion">
    <h2>Probar búsqueda por slug</h2>
    <div class="busqueda-form">
      <input 
        type="text" 
        bind:value={slugTest} 
        placeholder="Ingresa un slug para buscar"
        class="input-slug"
      />
      <button on:click={buscarPorSlug}>Buscar</button>
    </div>
    
    {#if resultadoBusqueda}
      <div class="resultado-busqueda">
        <h3>✅ Usuario encontrado:</h3>
        <pre>{JSON.stringify(resultadoBusqueda, null, 2)}</pre>
      </div>
    {:else if resultadoBusqueda === null && slugTest}
      <div class="resultado-busqueda error">
        <h3>❌ Usuario no encontrado para el slug: {slugTest}</h3>
      </div>
    {/if}
  </div>
  
  <div class="seccion">
    <h2>Instrucciones</h2>
    <ul>
      <li>Los slugs se generan automáticamente basados en prioridades</li>
      <li>Prioridad 1: nombre_usuario</li>
      <li>Prioridad 2: nombre + apellido</li>
      <li>Prioridad 3: nombre solo</li>
      <li>Prioridad 4: nombre_completo</li>
      <li>Fallback: 'usuario'</li>
    </ul>
  </div>
</div>

<style>
  .debug-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
  }
  
  .seccion {
    margin-bottom: 30px;
    padding: 20px;
    border: 1px solid #ddd;
    border-radius: 8px;
  }
  
  .tabla-usuarios {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  
  .usuario-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 15px;
    border: 1px solid #eee;
    border-radius: 5px;
    background: #f9f9f9;
  }
  
  .usuario-info {
    flex: 1;
  }
  
  .detalles {
    display: flex;
    flex-direction: column;
    font-size: 0.9em;
    color: #666;
    margin-top: 5px;
  }
  
  .slug-info {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 5px;
  }
  
  .slug code {
    background: #e1e1e1;
    padding: 2px 6px;
    border-radius: 3px;
    font-family: monospace;
  }
  
  .busqueda-form {
    display: flex;
    gap: 10px;
    margin-bottom: 20px;
  }
  
  .input-slug {
    flex: 1;
    padding: 8px 12px;
    border: 1px solid #ddd;
    border-radius: 4px;
  }
  
  .resultado-busqueda {
    padding: 15px;
    border-radius: 5px;
    margin-top: 10px;
  }
  
  .resultado-busqueda:not(.error) {
    background: #d4edda;
    border: 1px solid #c3e6cb;
  }
  
  .resultado-busqueda.error {
    background: #f8d7da;
    border: 1px solid #f5c6cb;
  }
  
  .resultado-busqueda pre {
    background: #f8f9fa;
    padding: 10px;
    border-radius: 4px;
    overflow-x: auto;
    font-size: 0.9em;
  }
  
  button {
    padding: 8px 16px;
    background: #007bff;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }
  
  button:hover {
    background: #0056b3;
  }
  
  ul {
    padding-left: 20px;
  }
  
  li {
    margin-bottom: 5px;
  }
</style> 