<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  
  let usuario: any = null;
  let perfil: any = null;
  let todosRoles: any[] = [];
  let cargando = true;
  
  onMount(async () => {
    try {
      // Obtener usuario actual
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      
      if (userError) {
        console.error('Error obteniendo usuario:', userError);
        return;
      }
      
      usuario = user;
      
      if (user) {
        // Verificar perfil
        const { data: perfilData, error: perfilError } = await supabase
          .from('perfiles')
          .select('*')
          .eq('id', user.id)
          .single();
        
        if (perfilError) {
          console.error('Error obteniendo perfil:', perfilError);
        } else {
          perfil = perfilData;
        }
        
        // Obtener todos los roles no-user
        const { data: roles, error: rolesError } = await supabase
          .from('perfiles')
          .select('id, nombre, rol, correo_electronico')
          .not('rol', 'eq', 'user')
          .limit(20);
        
        if (!rolesError) {
          todosRoles = roles || [];
        }
      }
      
    } catch (error) {
      console.error('Error:', error);
    } finally {
      cargando = false;
    }
  });
  
  async function cambiarRolAAdmin() {
    if (!usuario) return;
    
    try {
      const { data, error } = await supabase
        .from('perfiles')
        .update({ rol: 'admin' })
        .eq('id', usuario.id);
      
      if (error) {
        console.error('Error actualizando rol:', error);
        alert('Error actualizando rol: ' + error.message);
      } else {
        alert('¡Rol actualizado a admin exitosamente!');
        location.reload();
      }
    } catch (error) {
      console.error('Error:', error);
      alert('Error inesperado: ' + error);
    }
  }
</script>

<div class="container">
  <h1>🔍 Verificador de Rol de Usuario</h1>
  
  {#if cargando}
    <p>Cargando...</p>
  {:else if !usuario}
    <p>❌ No hay usuario autenticado</p>
  {:else}
    <div class="info-section">
      <h2>👤 Tu Usuario</h2>
      <div class="info-card">
        <p><strong>ID:</strong> {usuario.id}</p>
        <p><strong>Email:</strong> {usuario.email}</p>
        <p><strong>Nombre:</strong> {perfil?.nombre || 'No definido'}</p>
        <p><strong>Rol actual:</strong> <span class="rol-badge" class:admin={perfil?.rol === 'admin'}>{perfil?.rol || 'No definido'}</span></p>
      </div>
      
      {#if perfil?.rol !== 'admin'}
        <button on:click={cambiarRolAAdmin} class="admin-btn">
          🔑 Cambiar mi rol a Admin
        </button>
      {:else}
        <p class="success">✅ ¡Ya eres administrador!</p>
      {/if}
    </div>
    
    <div class="info-section">
      <h2>👥 Todos los Roles Especiales</h2>
      {#if todosRoles.length === 0}
        <p>No hay usuarios con roles especiales</p>
      {:else}
        <div class="roles-list">
          {#each todosRoles as rol}
            <div class="rol-card">
              <p><strong>Nombre:</strong> {rol.nombre}</p>
              <p><strong>Email:</strong> {rol.correo_electronico}</p>
              <p><strong>Rol:</strong> <span class="rol-badge" class:admin={rol.rol === 'admin'}>{rol.rol}</span></p>
            </div>
          {/each}
        </div>
      {/if}
    </div>
  {/if}
</div>

<style>
  .container {
    max-width: 800px;
    margin: 2rem auto;
    padding: 2rem;
    font-family: Arial, sans-serif;
  }
  
  .info-section {
    margin: 2rem 0;
    padding: 1.5rem;
    border: 1px solid #ddd;
    border-radius: 8px;
    background: #f9f9f9;
  }
  
  .info-card, .rol-card {
    background: white;
    padding: 1rem;
    margin: 1rem 0;
    border-radius: 6px;
    border: 1px solid #eee;
  }
  
  .rol-badge {
    background: #e0e0e0;
    padding: 0.2rem 0.5rem;
    border-radius: 4px;
    font-weight: bold;
  }
  
  .rol-badge.admin {
    background: #4CAF50;
    color: white;
  }
  
  .admin-btn {
    background: #2196F3;
    color: white;
    border: none;
    padding: 0.8rem 1.5rem;
    border-radius: 6px;
    cursor: pointer;
    font-size: 1rem;
    margin-top: 1rem;
  }
  
  .admin-btn:hover {
    background: #1976D2;
  }
  
  .success {
    color: #4CAF50;
    font-weight: bold;
  }
  
  .roles-list {
    display: grid;
    gap: 1rem;
  }
</style> 