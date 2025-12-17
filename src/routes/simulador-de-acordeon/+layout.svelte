<script lang="ts">
  import ProteccionAutenticacion from '$lib/guards/ProteccionAutenticacion.svelte';
</script>

<ProteccionAutenticacion 
  titulo="🎮 SIMULADOR INTERACTIVO"
  mensajePrincipal="El simulador de acordeón es exclusivo para estudiantes registrados">
  <slot />
</ProteccionAutenticacion> 