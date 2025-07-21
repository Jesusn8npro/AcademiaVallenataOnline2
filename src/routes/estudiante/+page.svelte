<script lang="ts">
    import { onMount } from 'svelte';
    import { usuario } from '$lib/UsuarioActivo/usuario';
    import { goto } from '$app/navigation';

  
    let currentUser;
  
    onMount(() => {
      const unsubscribe = usuario.subscribe((u) => {
        currentUser = u;
        if (!u) {
          goto('/');
        }
      });
      return unsubscribe;
    });
  </script>
  
  <svelte:head>
    <title>Panel de Estudiante - Academia Vallenata</title>
  </svelte:head>
  
  <div class="min-h-screen bg-gray-50">
    <main class="p-6">
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-gray-800">Panel de Estudiante</h1>
        <p class="text-gray-600">Bienvenido a tu panel de aprendizaje</p>
      </div>
  
      <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
          <h2 class="text-lg font-bold text-gray-800 mb-2">Mis Cursos</h2>
          <p class="text-sm text-gray-600">Continúa con tus cursos de acordeón.</p>
          <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/mis-cursos')}>Ver Mis Cursos</button>
        </div>
  
        <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
          <h2 class="text-lg font-bold text-gray-800 mb-2">Tutoriales</h2>
          <p class="text-sm text-gray-600">Explora tutoriales de canciones específicas.</p>
          <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/tutoriales')}>Ver Tutoriales</button>
        </div>
  
        <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
          <h2 class="text-lg font-bold text-gray-800 mb-2">Simulador</h2>
          <p class="text-sm text-gray-600">Practica con nuestro simulador de acordeón.</p>
          <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/simulador-gaming')}>Abrir Simulador</button>
        </div>
  
        <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
          <h2 class="text-lg font-bold text-gray-800 mb-2">Comunidad</h2>
          <p class="text-sm text-gray-600">Conecta con otros estudiantes.</p>
          <button class="mt-4 bg-purple-600 text-white px-4 py-2 rounded hover:bg-purple-700" on:click={() => goto('/comunidad')}>Ver Comunidad</button>
        </div>
  
        <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
          <h2 class="text-lg font-bold text-gray-800 mb-2">Mi Progreso</h2>
          <p class="text-sm text-gray-600">Revisa tu progreso de aprendizaje.</p>
          <button class="mt-4 bg-indigo-600 text-white px-4 py-2 rounded hover:bg-indigo-700" on:click={() => goto('/mi-perfil')}>Ver Progreso</button>
        </div>
  
        <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
          <h2 class="text-lg font-bold text-gray-800 mb-2">Blog</h2>
          <p class="text-sm text-gray-600">Lee artículos sobre acordeón vallenato.</p>
          <button class="mt-4 bg-orange-600 text-white px-4 py-2 rounded hover:bg-orange-700" on:click={() => goto('/blog')}>Leer Blog</button>
        </div>
      </section>
    </main>
  </div>
  
  <style>
    .fade-enter-active,
    .fade-leave-active {
      transition: opacity 0.25s;
    }
  
    .fade-enter,
    .fade-leave-to {
      opacity: 0;
    }
  </style>
  