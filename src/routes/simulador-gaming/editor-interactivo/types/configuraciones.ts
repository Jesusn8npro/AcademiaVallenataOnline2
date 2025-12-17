import type { ConfiguracionContenido, TipoContenido } from './tiposEditor.js';

// Configuraciones predefinidas para cada tipo de contenido
export const CONFIGURACIONES_CONTENIDO: Record<TipoContenido, ConfiguracionContenido> = {
  cancion: {
    tipo: 'cancion',
    pasos: [
      {
        numero: 1,
        titulo: 'Subir Audio',
        descripcion: 'Sube el archivo de audio de tu canción',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.audio !== null
      },
      {
        numero: 2,
        titulo: 'Grabar Notas',
        descripcion: 'Graba las notas del acordeón para la canción',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.notas && datos.notas.length > 0
      },
      {
        numero: 3,
        titulo: 'Vista Previa',
        descripcion: 'Prueba tu canción antes de publicar',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.audio && datos.notas && datos.notas.length > 0
      },
      {
        numero: 4,
        titulo: 'Publicar',
        descripcion: 'Publica tu canción para que otros puedan tocarla',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.titulo && datos.descripcion && datos.audio && datos.notas
      }
    ],
    restricciones: {
      duracionMinima: 30,
      duracionMaxima: 300,
      notasMinimas: 20,
      notasMaximas: 1000,
      complejidadMinima: 1,
      complejidadMaxima: 10
    },
    gamificacion: {
      experiencia: 50,
      monedas: 10,
      logros: ['compositor', 'melodista'],
      multiplicadores: {
        precision: 1.2,
        velocidad: 1.1,
        combo: 1.3
      }
    },
    caracteristicas: {
      tieneAudio: true,
      tieneVideo: false,
      tienePartitura: true,
      tieneTexto: true,
      tieneEjercicios: false,
      tieneEvaluacion: true,
      tieneRetroalimentacion: true,
      tieneProgresion: false
    }
  },

  desafio: {
    tipo: 'desafio',
    pasos: [
      {
        numero: 1,
        titulo: 'Configurar Desafío',
        descripcion: 'Define el tipo y objetivos del desafío',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.tipoDesafio && datos.objetivo
      },
      {
        numero: 2,
        titulo: 'Establecer Criterios',
        descripcion: 'Define los criterios de evaluación y recompensas',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.criterios && datos.criterios.length > 0
      },
      {
        numero: 3,
        titulo: 'Configurar Límites',
        descripcion: 'Establece límites de tiempo y puntuación mínima',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.tiempoLimite > 0 && datos.puntuacionMinima > 0
      },
      {
        numero: 4,
        titulo: 'Activar Desafío',
        descripcion: 'Activa el desafío para que los usuarios puedan participar',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.activo === true
      }
    ],
    restricciones: {
      duracionMinima: 60,
      duracionMaxima: 600,
      complejidadMinima: 2,
      complejidadMaxima: 8
    },
    gamificacion: {
      experiencia: 100,
      monedas: 25,
      logros: ['desafiante', 'maestro_desafios'],
      multiplicadores: {
        precision: 1.5,
        velocidad: 1.4,
        combo: 1.6
      }
    },
    caracteristicas: {
      tieneAudio: true,
      tieneVideo: false,
      tienePartitura: true,
      tieneTexto: true,
      tieneEjercicios: true,
      tieneEvaluacion: true,
      tieneRetroalimentacion: true,
      tieneProgresion: true
    }
  },

  ejercicio: {
    tipo: 'ejercicio',
    pasos: [
      {
        numero: 1,
        titulo: 'Definir Ejercicio',
        descripcion: 'Establece el tipo y objetivo del ejercicio',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.tipoEjercicio && datos.objetivo
      },
      {
        numero: 2,
        titulo: 'Crear Contenido',
        descripcion: 'Desarrolla el contenido y ejemplos del ejercicio',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.contenido && datos.ejemplos && datos.ejemplos.length > 0
      },
      {
        numero: 3,
        titulo: 'Configurar Evaluación',
        descripcion: 'Define cómo se evaluará el ejercicio',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.evaluacion && datos.evaluacion.tipo
      }
    ],
    restricciones: {
      duracionMinima: 15,
      duracionMaxima: 180,
      complejidadMinima: 1,
      complejidadMaxima: 7
    },
    gamificacion: {
      experiencia: 30,
      monedas: 5,
      logros: ['estudiante', 'practicante'],
      multiplicadores: {
        precision: 1.1,
        velocidad: 1.05,
        combo: 1.2
      }
    },
    caracteristicas: {
      tieneAudio: true,
      tieneVideo: true,
      tienePartitura: true,
      tieneTexto: true,
      tieneEjercicios: true,
      tieneEvaluacion: true,
      tieneRetroalimentacion: true,
      tieneProgresion: true
    }
  },

  teoria: {
    tipo: 'teoria',
    pasos: [
      {
        numero: 1,
        titulo: 'Crear Contenido',
        descripcion: 'Desarrolla el contenido teórico del tema',
        requerido: true,
        completado: false,
        validacion: (datos) => datos.contenidoTexto && datos.contenidoTexto.length > 100
      },
      {
        numero: 2,
        titulo: 'Agregar Recursos',
        descripcion: 'Añade imágenes, videos y ejemplos interactivos',
        requerido: false,
        completado: false,
        validacion: (datos) => datos.recursos && datos.recursos.length > 0
      },
      {
        numero: 3,
        titulo: 'Vincular Ejercicios',
        descripcion: 'Conecta con ejercicios relacionados',
        requerido: false,
        completado: false,
        validacion: (datos) => datos.ejerciciosRelacionados && datos.ejerciciosRelacionados.length > 0
      }
    ],
    restricciones: {
      duracionMinima: 10,
      duracionMaxima: 120,
      complejidadMinima: 1,
      complejidadMaxima: 5
    },
    gamificacion: {
      experiencia: 25,
      monedas: 3,
      logros: ['teorico', 'conocedor'],
      multiplicadores: {
        precision: 1.0,
        velocidad: 1.0,
        combo: 1.1
      }
    },
    caracteristicas: {
      tieneAudio: true,
      tieneVideo: true,
      tienePartitura: true,
      tieneTexto: true,
      tieneEjercicios: true,
      tieneEvaluacion: false,
      tieneRetroalimentacion: false,
      tieneProgresion: true
    }
  }
};

// Configuraciones de UI para cada tipo
export const CONFIGURACIONES_UI = {
  cancion: {
    color: '#4ecdc4',
    icono: '🎵',
    gradiente: 'linear-gradient(45deg, #4ecdc4, #44a08d)'
  },
  desafio: {
    color: '#ff6b6b',
    icono: '⚔️',
    gradiente: 'linear-gradient(45deg, #ff6b6b, #ee5a24)'
  },
  ejercicio: {
    color: '#667eea',
    icono: '💪',
    gradiente: 'linear-gradient(45deg, #667eea, #764ba2)'
  },
  teoria: {
    color: '#ffa726',
    icono: '📚',
    gradiente: 'linear-gradient(45deg, #ffa726, #ff9800)'
  }
};

// Validaciones específicas por tipo
export const VALIDACIONES_CONTENIDO = {
  cancion: {
    validarAudio: (archivo: File) => {
      const tiposPermitidos = ['audio/mp3', 'audio/wav', 'audio/ogg'];
      const tamañoMaximo = 10 * 1024 * 1024; // 10MB
      
      if (!tiposPermitidos.includes(archivo.type)) {
        return { valido: false, error: 'Tipo de archivo no permitido' };
      }
      
      if (archivo.size > tamañoMaximo) {
        return { valido: false, error: 'Archivo demasiado grande' };
      }
      
      return { valido: true };
    },
    
    validarNotas: (notas: any[]) => {
      if (!notas || notas.length === 0) {
        return { valido: false, error: 'Debe haber al menos una nota' };
      }
      
      if (notas.length > 1000) {
        return { valido: false, error: 'Demasiadas notas' };
      }
      
      return { valido: true };
    }
  },
  
  desafio: {
    validarTiempo: (tiempo: number) => {
      if (tiempo < 60) {
        return { valido: false, error: 'El tiempo mínimo es 60 segundos' };
      }
      
      if (tiempo > 600) {
        return { valido: false, error: 'El tiempo máximo es 600 segundos' };
      }
      
      return { valido: true };
    },
    
    validarPuntuacion: (puntuacion: number) => {
      if (puntuacion < 0) {
        return { valido: false, error: 'La puntuación no puede ser negativa' };
      }
      
      if (puntuacion > 100) {
        return { valido: false, error: 'La puntuación máxima es 100' };
      }
      
      return { valido: true };
    }
  },
  
  ejercicio: {
    validarContenido: (contenido: string) => {
      if (!contenido || contenido.length < 50) {
        return { valido: false, error: 'El contenido debe tener al menos 50 caracteres' };
      }
      
      if (contenido.length > 5000) {
        return { valido: false, error: 'El contenido es demasiado largo' };
      }
      
      return { valido: true };
    },
    
    validarEjemplos: (ejemplos: any[]) => {
      if (!ejemplos || ejemplos.length === 0) {
        return { valido: false, error: 'Debe haber al menos un ejemplo' };
      }
      
      return { valido: true };
    }
  },
  
  teoria: {
    validarTexto: (texto: string) => {
      if (!texto || texto.length < 100) {
        return { valido: false, error: 'El texto debe tener al menos 100 caracteres' };
      }
      
      if (texto.length > 10000) {
        return { valido: false, error: 'El texto es demasiado largo' };
      }
      
      return { valido: true };
    }
  }
};

// Plantillas predefinidas
export const PLANTILLAS_CONTENIDO = {
  cancion: {
    titulo: 'Mi Nueva Canción',
    descripcion: 'Una canción creada con el editor interactivo',
    dificultad: 'medio' as const,
    categoria: 'vallenato',
    tags: ['acordeon', 'vallenato', 'original']
  },
  
  desafio: {
    titulo: 'Desafío de Velocidad',
    descripcion: 'Demuestra tu velocidad tocando el acordeón',
    dificultad: 'dificil' as const,
    categoria: 'desafio',
    tags: ['velocidad', 'desafio', 'competencia']
  },
  
  ejercicio: {
    titulo: 'Ejercicio de Técnica',
    descripcion: 'Mejora tu técnica con este ejercicio',
    dificultad: 'facil' as const,
    categoria: 'tecnica',
    tags: ['ejercicio', 'tecnica', 'practica']
  },
  
  teoria: {
    titulo: 'Fundamentos del Acordeón',
    descripcion: 'Aprende los conceptos básicos del acordeón',
    dificultad: 'facil' as const,
    categoria: 'teoria',
    tags: ['teoria', 'fundamentos', 'educacion']
  }
}; 