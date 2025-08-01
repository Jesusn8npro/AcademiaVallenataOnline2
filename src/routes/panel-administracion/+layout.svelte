<script lang="ts">
  import ProteccionAdministrador from '$lib/guards/ProteccionAdministrador.svelte';
</script>

<ProteccionAdministrador>
  <slot />
</ProteccionAdministrador> 