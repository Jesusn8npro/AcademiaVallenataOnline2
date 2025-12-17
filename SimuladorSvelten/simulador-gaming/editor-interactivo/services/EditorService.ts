import { get } from 'svelte/store';
import { editorStore, editorActions, validarTodoElContenido, puedeAvanzarPaso } from '../stores/editorStore.js';
import type { 
  TipoContenido, 
  PasoEditor, 
  RespuestaServidor,
  ContenidoUnion,
  MetadatosContenido 
} from '../types/tiposEditor.js';
import { VALIDACIONES_CONTENIDO } from '../types/configuraciones.js';
import { supabase } from '$lib/supabase/clienteSupabase';
import { usuario } from '$lib/UsuarioActivo/usuario';
import CancionesService from '$lib/services/cancionesService';

export class EditorService {
  private procesandoOperacion = false;

  /**
   * Cambia el tipo de contenido y configura el editor
   */
  async cambiarTipoContenido(tipo: TipoContenido): Promise<void> {
    if (this.procesandoOperacion) {
      throw new Error('Ya se está procesando una operación');
    }

    this.procesandoOperacion = true;

    try {
      // Validar prerrequisitos
      const estadoActual = get(editorStore);
      if (estadoActual.tipoContenido === tipo) {
        return; // Ya está seleccionado
      }

      // Confirmar si hay cambios sin guardar
      if (estadoActual.tipoContenido && !estadoActual.guardado) {
        const confirmar = window.confirm('¿Deseas cambiar el tipo de contenido? Se perderán los cambios no guardados.');
        if (!confirmar) {
          return;
        }
      }

      // Establecer nuevo tipo
      editorActions.establecerTipoContenido(tipo);

      // Log de auditoría
      console.log(`Tipo de contenido cambiado a: ${tipo}`);

    } catch (error) {
      console.error('Error al cambiar tipo de contenido:', error);
      throw error;
    } finally {
      this.procesandoOperacion = false;
    }
  }

  /**
   * Navega a un paso específico
   */
  async navegarPaso(paso: PasoEditor): Promise<void> {
    if (this.procesandoOperacion) {
      throw new Error('Ya se está procesando una operación');
    }

    this.procesandoOperacion = true;

    try {
      const estadoActual = get(editorStore);
      
      if (!estadoActual.configuracion) {
        throw new Error('No hay configuración disponible');
      }

      // Validar que el paso existe
      const pasoConfig = estadoActual.configuracion.pasos.find(p => p.numero === paso);
      if (!pasoConfig) {
        throw new Error(`Paso ${paso} no encontrado`);
      }

      // Si se está avanzando, validar el paso actual
      if (paso > estadoActual.pasoActual) {
        const puedeAvanzar = puedeAvanzarPaso();
        if (!puedeAvanzar) {
          throw new Error('Complete el paso actual antes de avanzar');
        }
      }

      // Cambiar al nuevo paso
      editorActions.cambiarPaso(paso);

      // Log de auditoría
      console.log(`Navegación a paso ${paso}: ${pasoConfig.titulo}`);

    } catch (error) {
      console.error('Error al navegar al paso:', error);
      throw error;
    } finally {
      this.procesandoOperacion = false;
    }
  }

  /**
   * Actualiza el contenido actual
   */
  async actualizarContenido(contenido: Partial<ContenidoUnion>): Promise<void> {
    try {
      const estadoActual = get(editorStore);
      
      if (!estadoActual.tipoContenido) {
        throw new Error('No hay tipo de contenido seleccionado');
      }

      // Validar contenido según el tipo
      await this.validarContenido(estadoActual.tipoContenido, contenido);

      // Actualizar contenido
      editorActions.actualizarContenido(contenido);

      // Validar paso actual y actualizar progreso
      const validacion = editorActions.validarPasoActual();
      if (validacion.valido) {
        editorActions.completarPaso(estadoActual.pasoActual);
      }

    } catch (error) {
      console.error('Error al actualizar contenido:', error);
      throw error;
    }
  }

  /**
   * Valida el contenido según el tipo
   */
  private async validarContenido(tipo: TipoContenido, contenido: any): Promise<void> {
    const validaciones = VALIDACIONES_CONTENIDO[tipo];
    
    switch (tipo) {
      case 'cancion':
        const validacionesCancion = validaciones as typeof VALIDACIONES_CONTENIDO.cancion;
        if (contenido.audio) {
          const validacionAudio = validacionesCancion.validarAudio(contenido.audio);
          if (!validacionAudio.valido) {
            throw new Error(validacionAudio.error);
          }
        }
        
        if (contenido.notas) {
          const validacionNotas = validacionesCancion.validarNotas(contenido.notas);
          if (!validacionNotas.valido) {
            throw new Error(validacionNotas.error);
          }
        }
        break;

      case 'desafio':
        const validacionesDesafio = validaciones as typeof VALIDACIONES_CONTENIDO.desafio;
        if (contenido.tiempoLimite) {
          const validacionTiempo = validacionesDesafio.validarTiempo(contenido.tiempoLimite);
          if (!validacionTiempo.valido) {
            throw new Error(validacionTiempo.error);
          }
        }
        
        if (contenido.puntuacionMinima !== undefined) {
          const validacionPuntuacion = validacionesDesafio.validarPuntuacion(contenido.puntuacionMinima);
          if (!validacionPuntuacion.valido) {
            throw new Error(validacionPuntuacion.error);
          }
        }
        break;

      case 'ejercicio':
        const validacionesEjercicio = validaciones as typeof VALIDACIONES_CONTENIDO.ejercicio;
        if (contenido.instrucciones) {
          const validacionContenido = validacionesEjercicio.validarContenido(contenido.instrucciones);
          if (!validacionContenido.valido) {
            throw new Error(validacionContenido.error);
          }
        }
        
        if (contenido.ejemplos) {
          const validacionEjemplos = validacionesEjercicio.validarEjemplos(contenido.ejemplos);
          if (!validacionEjemplos.valido) {
            throw new Error(validacionEjemplos.error);
          }
        }
        break;

      case 'teoria':
        const validacionesTeoria = validaciones as typeof VALIDACIONES_CONTENIDO.teoria;
        if (contenido.contenidoTexto) {
          const validacionTexto = validacionesTeoria.validarTexto(contenido.contenidoTexto);
          if (!validacionTexto.valido) {
            throw new Error(validacionTexto.error);
          }
        }
        break;
    }
  }

  /**
   * Procesa archivos de audio
   */
  async procesarAudio(archivo: File): Promise<{ duracion: number; metadata: any }> {
    return new Promise((resolve, reject) => {
      const audio = new Audio();
      
      audio.onloadedmetadata = () => {
        resolve({
          duracion: audio.duration,
          metadata: {
            nombre: archivo.name,
            tamaño: archivo.size,
            tipo: archivo.type,
            duracion: audio.duration
          }
        });
      };
      
      audio.onerror = () => {
        reject(new Error('No se pudo procesar el archivo de audio'));
      };
      
      audio.src = URL.createObjectURL(archivo);
    });
  }

  /**
   * Guarda el contenido actual
   */
  async guardarContenido(): Promise<RespuestaServidor> {
    if (this.procesandoOperacion) {
      throw new Error('Ya se está procesando una operación');
    }

    this.procesandoOperacion = true;

    try {
      const estadoActual = get(editorStore);
      
      if (!estadoActual.tipoContenido) {
        throw new Error('No hay contenido para guardar');
      }

      // Validar contenido completo
      const validacion = validarTodoElContenido();
      if (!validacion.valido) {
        throw new Error(`Errores de validación: ${validacion.errores.join(', ')}`);
      }

      // Simular llamada al servidor
      await this.simularLlamadaServidor('guardar', {
        tipo: estadoActual.tipoContenido,
        contenido: estadoActual.contenidoActual,
        metadatos: estadoActual.metadatos
      });

      // Marcar como guardado
      editorActions.marcarGuardado();

      return {
        exito: true,
        mensaje: 'Contenido guardado exitosamente',
        datos: { id: Date.now() }
      };

    } catch (error) {
      console.error('Error al guardar contenido:', error);
      throw error;
    } finally {
      this.procesandoOperacion = false;
    }
  }

  /**
   * Publica el contenido actual
   */
  async publicarContenido(): Promise<RespuestaServidor> {
    if (this.procesandoOperacion) {
      throw new Error('Ya se está procesando una operación');
    }

    this.procesandoOperacion = true;

    try {
      const estadoActual = get(editorStore);
      
      if (!estadoActual.tipoContenido) {
        throw new Error('No hay contenido para publicar');
      }

      // Verificar autenticación con Supabase
      const { data: { session } } = await supabase.auth.getSession();
      if (!session || !session.user) {
        throw new Error('❌ Sesión expirada. Por favor, inicia sesión nuevamente.');
      }

      // Obtener usuario actual
      const usuarioActual = get(usuario);
      if (!usuarioActual) {
        throw new Error('❌ Usuario no autenticado. Por favor, inicia sesión.');
      }

      // Validar contenido completo
      const validacion = validarTodoElContenido();
      if (!validacion.valido) {
        throw new Error(`Errores de validación: ${validacion.errores.join(', ')}`);
      }

      if (validacion.progreso < 100) {
        throw new Error('El contenido no está completo');
      }

      // Publicar según el tipo de contenido
      let resultado;
      if (estadoActual.tipoContenido === 'cancion') {
        resultado = await this.publicarCancion(estadoActual.contenidoActual, usuarioActual.id);
      } else {
        // Para otros tipos de contenido, usar la simulación por ahora
        await this.simularLlamadaServidor('publicar', {
          tipo: estadoActual.tipoContenido,
          contenido: estadoActual.contenidoActual,
          metadatos: estadoActual.metadatos
        });
        resultado = {
          id: Date.now(),
          url: `/contenido/${estadoActual.tipoContenido}/${Date.now()}`
        };
      }

      // Marcar como publicado
      editorActions.marcarPublicado();

      return {
        exito: true,
        mensaje: '✅ Contenido publicado exitosamente',
        datos: resultado
      };

    } catch (error) {
      console.error('Error al publicar contenido:', error);
      throw error;
    } finally {
      this.procesandoOperacion = false;
    }
  }

  /**
   * Publica una canción usando el servicio de canciones
   */
  private async publicarCancion(contenidoCancion: any, usuarioId: string): Promise<any> {
    if (!contenidoCancion.audio || !contenidoCancion.notas) {
      throw new Error('La canción debe tener audio y notas grabadas');
    }

    try {
      // Crear datos de la canción
      const datosCancion = {
        titulo: contenidoCancion.titulo || 'Canción sin título',
        artista: contenidoCancion.artista || 'Artista desconocido',
        genero: contenidoCancion.genero || 'vallenato',
        nivel_dificultad: contenidoCancion.nivel_dificultad || 1,
        duracion_segundos: contenidoCancion.duracion_segundos || 0,
        bpm: contenidoCancion.bpm || 120,
        afinacion: contenidoCancion.afinacion || 'FBE',
        url_audio: contenidoCancion.url_audio || '',
        descripcion: contenidoCancion.descripcion || '',
        tags: contenidoCancion.tags || [],
        dificultad_tecnica: contenidoCancion.dificultad_tecnica || 'principiante',
        requiere_cambios_fuelle: true,
        requiere_acordes: false,
        requiere_bajos: true,
        xp_recompensa: 50,
        monedas_recompensa: 10,
        puntos_precision: 100,
        tiempo_maximo_minutos: 10,
        precision_minima_requerida: 75,
        intentos_maximos: 3,
        estado: 'activa' as const,
        es_publica: true,
        es_premium: false,
        orden_mostrar: 0,
        creador_id: usuarioId,
        activa: true
      };

      // Crear datos de secuencia
      const datosSecuencia = {
        nombre_secuencia: 'Secuencia principal',
        descripcion: 'Creada en Editor Interactivo',
        tolerancia_timing_ms: 150,
        auto_cuantizar: false,
        usar_metronomo: false,
        notas_secuencia: contenidoCancion.notas,
        marcadores_tiempo: {},
        es_secuencia_principal: true,
        nivel_dificultad: 1,
        estado: 'activa'
      };

      // Publicar usando el servicio de canciones
      const cancionCreada = await CancionesService.crearCancion(datosCancion);
      
      if (!cancionCreada) {
        throw new Error('No se pudo crear la canción');
      }

      return {
        id: cancionCreada.id,
        url: `/simulador-gaming/cancion/${cancionCreada.id}`,
        cancion: cancionCreada,
        notas: contenidoCancion.notas
      };

    } catch (error) {
      console.error('Error al publicar canción:', error);
      const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
      throw new Error(`Error al publicar canción: ${errorMessage}`);
    }
  }

  /**
   * Obtiene el historial de contenido
   */
  async obtenerHistorial(): Promise<any[]> {
    try {
      // Simular llamada al servidor
      await this.simularLlamadaServidor('obtener-historial', {});
      
      return [
        {
          id: 1,
          titulo: 'Mi Primera Canción',
          tipo: 'cancion',
          fechaCreacion: new Date('2024-01-01'),
          estado: 'publicado'
        },
        {
          id: 2,
          titulo: 'Desafío de Velocidad',
          tipo: 'desafio',
          fechaCreacion: new Date('2024-01-02'),
          estado: 'borrador'
        }
      ];
    } catch (error) {
      console.error('Error al obtener historial:', error);
      throw error;
    }
  }

  /**
   * Simula una llamada al servidor
   */
  private async simularLlamadaServidor(operacion: string, datos: any): Promise<void> {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        // Simular ocasionales errores de servidor
        if (Math.random() < 0.1) {
          reject(new Error(`Error simulado en ${operacion}`));
        } else {
          console.log(`Operación ${operacion} exitosa:`, datos);
          resolve();
        }
      }, 1000 + Math.random() * 2000); // 1-3 segundos de delay
    });
  }

  /**
   * Obtiene estadísticas del editor
   */
  async obtenerEstadisticas(): Promise<any> {
    try {
      await this.simularLlamadaServidor('obtener-estadisticas', {});
      
      return {
        contenidoCreado: 25,
        contenidoPublicado: 18,
        tiempoTotal: 3600, // segundos
        tipoMasCreado: 'cancion',
        puntuacionPromedio: 85
      };
    } catch (error) {
      console.error('Error al obtener estadísticas:', error);
      throw error;
    }
  }

  /**
   * Resetea el editor
   */
  resetear(): void {
    editorActions.limpiarErrores();
    editorActions.limpiarWarnings();
  }
} 