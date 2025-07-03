// usuario.ts
// Store global de Svelte para guardar y compartir la información del usuario que inició sesión en toda la aplicación.
// Puedes importar y usar esta store en cualquier componente para saber quién es el usuario actual, su rol, y actualizarlo cuando cambie la sesión.

import { writable } from 'svelte/store';

// Interfaz que define la estructura básica del perfil de usuario según tu base de datos (ajusta los campos si agregas más)
export interface PerfilUsuario {
  id: string; // ID único del usuario (igual al de Supabase Auth)
  correo_electronico: string; // Correo electrónico
  nombre?: string;
  apellido?: string;
  whatsapp?: string;
  rol?: string; // Rol del usuario (admin, estudiante, etc)
  url_foto_perfil?: string; // URL de la foto de perfil
}

// Store global reactiva: aquí se guarda el usuario actualmente logueado
export const usuario = writable<PerfilUsuario | null>(null);

// Función para actualizar el usuario desde cualquier parte de la app
export function setUsuario(nuevoUsuario: PerfilUsuario | null) {
  usuario.set(nuevoUsuario);
}

// Función para limpiar el usuario (por ejemplo, al cerrar sesión)
export function limpiarUsuario() {
  usuario.set(null);
}

/*
Ejemplo de uso:

import { usuario, setUsuario, limpiarUsuario } from '$lib/UsuarioActivo/usuario';

// Para leer el usuario actual:
$usuario // (en un componente Svelte)

// Para actualizar el usuario tras login:
setUsuario({ id: '...', correo_electronico: '...', rol: 'admin' });

// Para limpiar al hacer logout:
limpiarUsuario();
*/
