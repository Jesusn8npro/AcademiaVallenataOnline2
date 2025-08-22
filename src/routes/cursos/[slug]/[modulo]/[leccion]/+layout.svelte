<script lang="ts">
  import ProteccionSuscripcion from '$lib/guards/ProteccionSuscripcion.svelte';
</script>

<ProteccionSuscripcion 
  nombreContenido="curso premium"
  tipoContenido="curso"
  mostrarPrevisualizacion={false}>
  <slot />
</ProteccionSuscripcion> 