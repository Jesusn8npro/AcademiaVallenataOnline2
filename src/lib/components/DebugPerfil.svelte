<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { perfilStore } from '$lib/stores/perfilStore';

  let debugInfo: any = {
    userAuth: null,
    perfilDb: null,
    perfilStore: null,
    imagenes: []
  };

  let urlsInfo: any = {
    urlPortada: '',
    urlAvatar: '',
    urlPortadaValida: false,
    urlAvatarValida: false
  };

  // 🔥 FUNCIÓN PARA FORZAR RECARGA
  async function forzarRecargaStore() {
    console.log('🔄 FORZANDO RECARGA DEL STORE...');
    
    // Resetear el store
    perfilStore.resetear();
    
    // Esperar un momento
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Cargar datos frescos FORZANDO recarga
    await perfilStore.cargarDatosPerfil(true);
    
    console.log('✅ STORE RECARGADO!');
    
    // Actualizar nuestro debug también
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: perfilDb } = await supabase
        .from('perfiles')
        .select('*')
        .eq('id', user.id)
        .single();
      
      debugInfo.perfilDb = perfilDb;
      if (perfilDb) {
        urlsInfo = {
          urlPortada: perfilDb.portada_url || '',
          urlAvatar: perfilDb.url_foto_perfil || '',
          urlPortadaValida: !!(perfilDb.portada_url && perfilDb.portada_url.trim() !== ''),
          urlAvatarValida: !!(perfilDb.url_foto_perfil && perfilDb.url_foto_perfil.trim() !== ''),
          urlPortadaTipo: typeof perfilDb.portada_url,
          urlAvatarTipo: typeof perfilDb.url_foto_perfil,
          urlPortadaLength: perfilDb.portada_url ? perfilDb.portada_url.length : 0,
          urlAvatarLength: perfilDb.url_foto_perfil ? perfilDb.url_foto_perfil.length : 0
        };
      }
    }
  }

  // 🔥 FUNCIÓN PARA RECARGAR PÁGINA COMPLETA
  function recargarPaginaCompleta() {
    window.location.reload();
  }

  onMount(async () => {
    console.log('🔍 INICIANDO DEBUG DEL PERFIL...');
    
    try {
      // 1. Verificar autenticación
      const { data: { user } } = await supabase.auth.getUser();
      debugInfo.userAuth = user;
      console.log('👤 Usuario autenticado:', user);

      if (user) {
        // 2. Consultar directamente la base de datos
        const { data: perfilDb, error: errorPerfil } = await supabase
          .from('perfiles')
          .select('*')
          .eq('id', user.id)
          .single();
        
        debugInfo.perfilDb = perfilDb;
        console.log('📊 Datos del perfil en DB:', perfilDb);
        console.log('❌ Error del perfil:', errorPerfil);

        // 🎯 ANALIZAR URLs ESPECÍFICAMENTE
        if (perfilDb) {
          urlsInfo = {
            urlPortada: perfilDb.portada_url || '',
            urlAvatar: perfilDb.url_foto_perfil || '',
            urlPortadaValida: !!(perfilDb.portada_url && perfilDb.portada_url.trim() !== ''),
            urlAvatarValida: !!(perfilDb.url_foto_perfil && perfilDb.url_foto_perfil.trim() !== ''),
            urlPortadaTipo: typeof perfilDb.portada_url,
            urlAvatarTipo: typeof perfilDb.url_foto_perfil,
            urlPortadaLength: perfilDb.portada_url ? perfilDb.portada_url.length : 0,
            urlAvatarLength: perfilDb.url_foto_perfil ? perfilDb.url_foto_perfil.length : 0
          };

          console.log('🖼️ ANÁLISIS DE URLs:');
          console.log('- urlPortada:', perfilDb.portada_url);
          console.log('- urlAvatar:', perfilDb.url_foto_perfil);
          console.log('- urlPortadaValida:', urlsInfo.urlPortadaValida);
          console.log('- urlAvatarValida:', urlsInfo.urlAvatarValida);
        }

        // 3. Verificar imágenes en usuario_imagenes
        const { data: imagenes } = await supabase
          .from('usuario_imagenes')
          .select('*')
          .eq('usuario_id', user.id)
          .order('fecha_subida', { ascending: false })
          .limit(5);
        
        debugInfo.imagenes = imagenes || [];
        console.log('🖼️ Imágenes del usuario:', imagenes);

        // 4. Verificar store
        debugInfo.perfilStore = $perfilStore.perfil;
        console.log('🏪 Datos en el store:', $perfilStore);
      }
    } catch (error) {
      console.error('💥 Error en debug:', error);
    }
  });

  $: {
    // Actualizar URLs del store en tiempo real
    if ($perfilStore.perfil) {
      urlsInfo = {
        ...urlsInfo,
        storePortada: $perfilStore.perfil.portada_url || '',
        storeAvatar: $perfilStore.perfil.url_foto_perfil || '',
        storePortadaValida: !!($perfilStore.perfil.portada_url && $perfilStore.perfil.portada_url.trim() !== ''),
        storeAvatarValida: !!($perfilStore.perfil.url_foto_perfil && $perfilStore.perfil.url_foto_perfil.trim() !== '')
      };
    }
    console.log('🔄 Store actualizado:', $perfilStore);
    console.log('🔄 URLs actualizadas:', urlsInfo);
  }
</script>

<div class="debug-panel">
  <h2>🔍 DEBUG DEL PERFIL</h2>
  
  <!-- 🔥 BOTONES DE ACCIÓN -->
  <div class="debug-section">
    <h3>🔥 ACCIONES RÁPIDAS:</h3>
    <div class="action-buttons">
      <button class="btn-fix" on:click={forzarRecargaStore}>
        🔄 RECARGAR STORE
      </button>
      <button class="btn-reload" on:click={recargarPaginaCompleta}>
        🔥 RECARGAR PÁGINA
      </button>
    </div>
  </div>
  
  <div class="debug-section">
    <h3>🎯 ANÁLISIS DE URLs:</h3>
    <div class="url-analysis">
      <div class="url-item">
        <strong>PORTADA DB:</strong>
        <span class:valid={urlsInfo.urlPortadaValida} class:invalid={!urlsInfo.urlPortadaValida}>
          {urlsInfo.urlPortadaValida ? '✅' : '❌'} 
          {urlsInfo.urlPortada || 'VACÍA'}
        </span>
        <small>({urlsInfo.urlPortadaLength} chars)</small>
      </div>
      
      <div class="url-item">
        <strong>AVATAR DB:</strong>
        <span class:valid={urlsInfo.urlAvatarValida} class:invalid={!urlsInfo.urlAvatarValida}>
          {urlsInfo.urlAvatarValida ? '✅' : '❌'} 
          {urlsInfo.urlAvatar || 'VACÍA'}
        </span>
        <small>({urlsInfo.urlAvatarLength} chars)</small>
      </div>

      <div class="url-item">
        <strong>PORTADA STORE:</strong>
        <span class:valid={urlsInfo.storePortadaValida} class:invalid={!urlsInfo.storePortadaValida}>
          {urlsInfo.storePortadaValida ? '✅' : '❌'} 
          {urlsInfo.storePortada || 'VACÍA'}
        </span>
      </div>
      
      <div class="url-item">
        <strong>AVATAR STORE:</strong>
        <span class:valid={urlsInfo.storeAvatarValida} class:invalid={!urlsInfo.storeAvatarValida}>
          {urlsInfo.storeAvatarValida ? '✅' : '❌'} 
          {urlsInfo.storeAvatar || 'VACÍA'}
        </span>
      </div>
    </div>
  </div>

  <div class="debug-section">
    <h3>👤 Usuario Autenticado:</h3>
    <pre>{JSON.stringify(debugInfo.userAuth, null, 2)}</pre>
  </div>

  <div class="debug-section">
    <h3>📊 Datos en Base de Datos (perfiles):</h3>
    <pre>{JSON.stringify(debugInfo.perfilDb, null, 2)}</pre>
  </div>

  <div class="debug-section">
    <h3>🖼️ Imágenes (usuario_imagenes):</h3>
    <pre>{JSON.stringify(debugInfo.imagenes, null, 2)}</pre>
  </div>

  <div class="debug-section">
    <h3>🏪 Datos en Store:</h3>
    <pre>{JSON.stringify(debugInfo.perfilStore, null, 2)}</pre>
  </div>
</div>

<style>
  .debug-panel {
    position: fixed;
    top: 0;
    right: 0;
    width: 500px;
    height: 100vh;
    background: black;
    color: lime;
    font-family: monospace;
    font-size: 11px;
    padding: 10px;
    overflow-y: auto;
    z-index: 999999;
    border-left: 2px solid lime;
  }

  .debug-section {
    margin-bottom: 20px;
    border-bottom: 1px solid #333;
    padding-bottom: 10px;
  }

  h2, h3 {
    color: yellow;
    margin: 0 0 10px 0;
  }

  pre {
    background: #111;
    padding: 10px;
    border-radius: 4px;
    overflow-x: auto;
    max-height: 150px;
  }

  .url-analysis {
    background: #111;
    padding: 10px;
    border-radius: 4px;
  }

  .url-item {
    margin-bottom: 8px;
    font-size: 10px;
  }

  .url-item strong {
    color: cyan;
    display: block;
  }

  .url-item .valid {
    color: lime;
  }

  .url-item .invalid {
    color: red;
  }

  .url-item small {
    color: #888;
    margin-left: 5px;
  }

  .action-buttons {
    display: flex;
    gap: 10px;
    margin-bottom: 10px;
  }

  .btn-fix, .btn-reload {
    padding: 8px 12px;
    border: none;
    border-radius: 4px;
    font-size: 10px;
    font-weight: bold;
    cursor: pointer;
    font-family: monospace;
  }

  .btn-fix {
    background: #22c55e;
    color: black;
  }

  .btn-fix:hover {
    background: #16a34a;
  }

  .btn-reload {
    background: #f59e0b;
    color: black;
  }

  .btn-reload:hover {
    background: #d97706;
  }
</style> 