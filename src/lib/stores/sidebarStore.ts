import { writable } from 'svelte/store';

// Store para manejar el estado del sidebar (colapsado/expandido)
export const sidebarColapsado = writable(false);
