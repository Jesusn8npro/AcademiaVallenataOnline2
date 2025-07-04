// Store reactivo para el usuario autenticado con Supabase
import { writable } from 'svelte/store';
import { supabase } from '$lib/supabase/clienteSupabase';

// Store que contiene el usuario actual (null si no está autenticado)
export const estadoUsuarioActual = writable({ user: null });

// Inicializa el store con la sesión actual
supabase.auth.getSession().then(({ data }) => {
  estadoUsuarioActual.set({ user: data.session?.user || null });
});

// Escucha cambios de autenticación y actualiza el store
supabase.auth.onAuthStateChange((_event, session) => {
  estadoUsuarioActual.set({ user: session?.user || null });
});
