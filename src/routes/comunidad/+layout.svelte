<script lang="ts">
  import ProteccionAutenticacion from '$lib/guards/ProteccionAutenticacion.svelte';
</script>

<ProteccionAutenticacion 
  titulo="👥 COMUNIDAD PRIVADA"
  mensajePrincipal="La comunidad de la Academia es exclusiva para estudiantes registrados">
  <slot />
</ProteccionAutenticacion> 