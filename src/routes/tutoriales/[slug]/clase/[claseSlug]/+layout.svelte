<script lang="ts">
  import ProteccionSuscripcion from '$lib/guards/ProteccionSuscripcion.svelte';
  import { page } from '$app/stores';

  // Obtener información del tutorial desde los parámetros
  $: tutorialSlug = $page.params.slug;
  $: claseSlug = $page.params.claseSlug;
</script>

<ProteccionSuscripcion 
  nombreContenido="{claseSlug}"
  tipoContenido="clase del tutorial">
  <slot />
</ProteccionSuscripcion> 