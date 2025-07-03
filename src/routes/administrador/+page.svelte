<script lang="ts">
  import { onMount } from 'svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { goto } from '$app/navigation';

  let currentUser;

  onMount(() => {
    const unsubscribe = usuario.subscribe((u) => {
      currentUser = u;
      if (!u || u.rol !== 'admin') {
        goto('/');
      }
    });
    return unsubscribe;
  });
</script>

<svelte:head>
  <title>Panel de Administrador</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">


  <main class="p-6">
    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
      </div>
    </section>
    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
      </div>
    </section>
    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
      </div>
    </section>
    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
      </div>
    </section>
    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
      </div>
    </section>
    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
      </div>
    </section>
    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
      </div>
    </section>

    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
      </div>
    </section>
    <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Usuarios</h2>
        <p class="text-sm text-gray-600">Administra todos los usuarios registrados.</p>
        <button class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" on:click={() => goto('/admin/usuarios')}>Ver Usuarios</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Cursos</h2>
        <p class="text-sm text-gray-600">Gestiona los cursos, módulos y clases.</p>
        <button class="mt-4 bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" on:click={() => goto('/admin/cursos')}>Gestionar Cursos</button>
      </div>

      <div class="bg-white rounded-xl p-6 shadow hover:shadow-md transition">
        <h2 class="text-lg font-bold text-gray-800 mb-2">Ventas y Suscripciones</h2>
        <p class="text-sm text-gray-600">Visualiza estadísticas de ventas y membresías activas.</p>
        <button class="mt-4 bg-yellow-500 text-white px-4 py-2 rounded hover:bg-yellow-600" on:click={() => goto('/admin/suscripciones')}>Ver Reportes</button>
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

  .fade-enter-active,
    .fade-leave-active {
      transition: opacity 0.25s;
    }
  
    .fade-enter,
    .fade-leave-to {
      opacity: 0;
    }
</style>

