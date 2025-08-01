<script lang="ts">
  import ProteccionSuscripcion from '$lib/guards/ProteccionSuscripcion.svelte';
  import { page } from '$app/stores';

  // Obtener información del curso desde los parámetros
  $: cursoSlug = $page.params.slug;
  $: moduloSlug = $page.params.modulo;
  $: leccionSlug = $page.params.leccion;
</script>

<ProteccionSuscripcion 
  nombreContenido="{leccionSlug}"
  tipoContenido="lección del curso">
  <slot />
</ProteccionSuscripcion>
