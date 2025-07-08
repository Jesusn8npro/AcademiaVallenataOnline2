import { writable } from 'svelte/store';
import { browser } from '$app/environment';

// Función para obtener el tema desde localStorage o usar el preferido del sistema
function obtenerTemaInicial(): boolean {
	if (!browser) return false;
	
	const temaGuardado = localStorage.getItem('tema-oscuro');
	if (temaGuardado !== null) {
		return JSON.parse(temaGuardado);
	}
	
	// Si no hay tema guardado, usar la preferencia del sistema
	return window.matchMedia('(prefers-color-scheme: dark)').matches;
}

// Store para el modo oscuro
function crearTemaStore() {
	const { subscribe, set, update } = writable<boolean>(obtenerTemaInicial());

	return {
		subscribe,
		alternar: () => update(modoOscuro => {
			const nuevoModo = !modoOscuro;
			if (browser) {
				localStorage.setItem('tema-oscuro', JSON.stringify(nuevoModo));
				// Aplicar clase al HTML
				if (nuevoModo) {
					document.documentElement.classList.add('dark');
				} else {
					document.documentElement.classList.remove('dark');
				}
			}
			return nuevoModo;
		}),
		establecer: (valor: boolean) => {
			if (browser) {
				localStorage.setItem('tema-oscuro', JSON.stringify(valor));
				// Aplicar clase al HTML
				if (valor) {
					document.documentElement.classList.add('dark');
				} else {
					document.documentElement.classList.remove('dark');
				}
			}
			set(valor);
		}
	};
}

export const temaOscuro = crearTemaStore();

// Función para inicializar el tema en el HTML
export function inicializarTema() {
	if (!browser) return;
	
	const modoOscuro = obtenerTemaInicial();
	if (modoOscuro) {
		document.documentElement.classList.add('dark');
	} else {
		document.documentElement.classList.remove('dark');
	}
} 