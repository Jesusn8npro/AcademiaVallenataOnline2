<script lang="ts">
  import ProteccionAutenticacion from '$lib/guards/ProteccionAutenticacion.svelte';
</script>

<ProteccionAutenticacion 
  titulo="🎓 PANEL DE ESTUDIANTE"
  mensajePrincipal="Tu panel personal requiere que inicies sesión como estudiante">
  <slot />
</ProteccionAutenticacion> 