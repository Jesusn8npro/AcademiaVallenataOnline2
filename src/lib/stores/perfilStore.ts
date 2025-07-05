import { writable } from 'svelte/store';
import { supabase } from '$lib/supabase/clienteSupabase';

interface PerfilData {
  id: string;
  nombre_completo: string;
  correo_electronico: string;
  url_foto_perfil: string;
  portada_url: string;
  posicion_img_portada: number;
  notificaciones_email?: boolean;
  notificaciones_push?: boolean;
  modo_oscuro?: boolean;
  idioma?: string;
  publico_perfil?: boolean;
}

interface StatsData {
  publicaciones: number;
  cursos: number;
  tutoriales: number;
  ranking: number;
}

interface PerfilStore {
  perfil: PerfilData | null;
  stats: StatsData;
  cargando: boolean;
  inicializado: boolean;
}

const estadoInicial: PerfilStore = {
  perfil: null,
  stats: { publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 },
  cargando: false,
  inicializado: false
};

function crearPerfilStore() {
  const { subscribe, set, update } = writable<PerfilStore>(estadoInicial);

  return {
    subscribe,
    
    async cargarDatosPerfil(forzarRecarga = false) {
      // Si ya está inicializado y no es recarga forzada, no hacer nada
      if (this.get().inicializado && !forzarRecarga) {
        return;
      }

      update(state => ({ ...state, cargando: true }));

      try {
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) {
          throw new Error('Usuario no autenticado');
        }

        const [perfilResult, statsResult] = await Promise.all([
          supabase.from('perfiles').select('*').eq('id', user.id).single(),
          this.cargarEstadisticasComunidad(user.id)
        ]);

        const perfilData = perfilResult.data || {
          id: user.id,
          nombre_completo: user.email || 'Usuario',
          correo_electronico: user.email || '',
          url_foto_perfil: '',
          portada_url: '',
          posicion_img_portada: 0
        };

        update(state => ({
          ...state,
          perfil: perfilData,
          stats: statsResult,
          cargando: false,
          inicializado: true
        }));

      } catch (error) {
        console.error('Error cargando datos del perfil:', error);
        update(state => ({ 
          ...state, 
          cargando: false,
          inicializado: true // Marcamos como inicializado para evitar bucles
        }));
      }
    },

    async cargarEstadisticasComunidad(userId: string): Promise<StatsData> {
      try {
        const [publicacionesResult, cursosResult, tutorialesResult, rankingResult] = await Promise.all([
          supabase.from('comunidad_publicaciones').select('*', { count: 'exact', head: true }).eq('usuario_id', userId),
          supabase.from('inscripciones').select('*', { count: 'exact', head: true }).eq('usuario_id', userId),
          supabase.from('progreso_tutorial').select('*', { count: 'exact', head: true }).eq('usuario_id', userId).eq('completado', true),
          supabase.from('perfiles').select('id').order('puntos_comunidad', { ascending: false })
        ]);

        const posicionRanking = rankingResult.data ? 
          rankingResult.data.findIndex((p: any) => p.id === userId) + 1 : 0;

        return {
          publicaciones: publicacionesResult.count || 0,
          cursos: cursosResult.count || 0,
          tutoriales: tutorialesResult.count || 0,
          ranking: posicionRanking || 0
        };
      } catch (error) {
        console.error('Error cargando estadísticas:', error);
        return { publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 };
      }
    },

    actualizarPerfil(nuevoPerfil: Partial<PerfilData>) {
      update(state => ({
        ...state,
        perfil: state.perfil ? { ...state.perfil, ...nuevoPerfil } : null
      }));
    },

    actualizarStats(nuevasStats: Partial<StatsData>) {
      update(state => ({
        ...state,
        stats: { ...state.stats, ...nuevasStats }
      }));
    },

    resetear() {
      set(estadoInicial);
    },

    // Método helper para obtener el estado actual
    get() {
      let currentState: PerfilStore;
      subscribe(state => currentState = state)();
      return currentState!;
    }
  };
}

export const perfilStore = crearPerfilStore(); 