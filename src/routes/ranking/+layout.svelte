<script lang="ts">
  import ProteccionAutenticacion from '$lib/guards/ProteccionAutenticacion.svelte';
</script>

<ProteccionAutenticacion 
  titulo="🏆 RANKING EXCLUSIVO"
  mensajePrincipal="El ranking de la Academia es solo para estudiantes registrados">
  <slot />
</ProteccionAutenticacion> 