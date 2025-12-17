<script lang="ts">
  import ProteccionAutenticacion from '$lib/guards/ProteccionAutenticacion.svelte';
</script>

<ProteccionAutenticacion 
  titulo="💬 MENSAJES PRIVADOS"
  mensajePrincipal="Tus mensajes personales requieren que inicies sesión">
  <slot />
</ProteccionAutenticacion> 