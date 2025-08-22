<script lang="ts">
  import ProteccionSuscripcion from '$lib/guards/ProteccionSuscripcion.svelte';
</script>

<ProteccionSuscripcion 
  nombreContenido="tutorial premium"
  tipoContenido="tutorial"
  mostrarPrevisualizacion={false}>
  <slot />
</ProteccionSuscripcion> 