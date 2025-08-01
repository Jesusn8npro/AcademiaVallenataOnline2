<script lang="ts">
  import ProteccionAutenticacion from '$lib/guards/ProteccionAutenticacion.svelte';
</script>

<ProteccionAutenticacion 
  titulo="🔔 NOTIFICACIONES PERSONALES"
  mensajePrincipal="Tus notificaciones requieren que inicies sesión">
  <slot />
</ProteccionAutenticacion> 