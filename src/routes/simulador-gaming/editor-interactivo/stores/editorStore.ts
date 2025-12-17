import { writable, derived, get } from 'svelte/store';
import type { 
  EstadoEditorInteractivo, 
  TipoContenido, 
  PasoEditor, 
  MetadatosContenido,
  ConfiguracionContenido,
  ValidacionPaso 
} from '../types/tiposEditor.js';
import { CONFIGURACIONES_CONTENIDO, PLANTILLAS_CONTENIDO } from '../types/configuraciones.js';

// Estado inicial del editor
const estadoInicial: EstadoEditorInteractivo = {
  tipoContenido: null,
  pasoActual: 1,
  progreso: 0,
  guardado: false,
  publicado: false,
  configuracion: null,
  metadatos: null,
  contenidoActual: null,
  errores: [],
  warnings: []
};

// Store principal del editor
export const editorStore = writable<EstadoEditorInteractivo>(estadoInicial);

// Stores derivados para facilitar el acceso a propiedades específicas
export const tipoContenidoStore = derived(
  editorStore,
  ($editor) => $editor.tipoContenido
);

export const pasoActualStore = derived(
  editorStore,
  ($editor) => $editor.pasoActual
);

export const progresoStore = derived(
  editorStore,
  ($editor) => $editor.progreso
);

export const configuracionStore = derived(
  editorStore,
  ($editor) => $editor.configuracion
);

export const metadatosStore = derived(
  editorStore,
  ($editor) => $editor.metadatos
);

export const contenidoActualStore = derived(
  editorStore,
  ($editor) => $editor.contenidoActual
);

// Stores derivados para validaciones
export const esValidoStore = derived(
  editorStore,
  ($editor) => $editor.errores.length === 0
);

export const tieneWarningsStore = derived(
  editorStore,
  ($editor) => $editor.warnings.length > 0
);

export const puedeAvanzarStore = derived(
  editorStore,
  ($editor) => {
    if (!$editor.configuracion) return false;
    
    const pasoConfig = $editor.configuracion.pasos.find(p => p.numero === $editor.pasoActual);
    if (!pasoConfig) return false;
    
    return pasoConfig.validacion($editor.contenidoActual);
  }
);

export const puedePublicarStore = derived(
  editorStore,
  ($editor) => {
    return $editor.progreso >= 100 && $editor.errores.length === 0;
  }
);

// Acciones del store
export const editorActions = {
  
  // Establecer tipo de contenido
  establecerTipoContenido: (tipo: TipoContenido) => {
    editorStore.update(estado => {
      const configuracion = CONFIGURACIONES_CONTENIDO[tipo];
      const plantilla = PLANTILLAS_CONTENIDO[tipo];
      
      return {
        ...estado,
        tipoContenido: tipo,
        configuracion,
        metadatos: {
          ...plantilla,
          autor: 'Usuario', // Se obtendría del contexto de usuario
          fechaCreacion: new Date(),
          fechaActualizacion: new Date(),
          publico: false,
          destacado: false
        },
        contenidoActual: {},
        pasoActual: 1,
        progreso: 0,
        errores: [],
        warnings: []
      };
    });
  },

  // Cambiar paso actual
  cambiarPaso: (nuevoPaso: PasoEditor) => {
    editorStore.update(estado => {
      if (!estado.configuracion) return estado;
      
      const pasoConfig = estado.configuracion.pasos.find(p => p.numero === nuevoPaso);
      if (!pasoConfig) return estado;
      
      return {
        ...estado,
        pasoActual: nuevoPaso
      };
    });
  },

  // Actualizar contenido actual
  actualizarContenido: (nuevoContenido: any) => {
    editorStore.update(estado => ({
      ...estado,
      contenidoActual: {
        ...estado.contenidoActual,
        ...nuevoContenido
      },
      guardado: false
    }));
  },

  // Actualizar metadatos
  actualizarMetadatos: (nuevosMetadatos: Partial<MetadatosContenido>) => {
    editorStore.update(estado => ({
      ...estado,
      metadatos: estado.metadatos ? {
        ...estado.metadatos,
        ...nuevosMetadatos,
        fechaActualizacion: new Date()
      } : null
    }));
  },

  // Marcar paso como completado
  completarPaso: (paso: PasoEditor) => {
    editorStore.update(estado => {
      if (!estado.configuracion) return estado;
      
      const nuevaConfiguracion = {
        ...estado.configuracion,
        pasos: estado.configuracion.pasos.map(p => 
          p.numero === paso ? { ...p, completado: true } : p
        )
      };
      
      const progreso = calcularProgreso(nuevaConfiguracion);
      
      return {
        ...estado,
        configuracion: nuevaConfiguracion,
        progreso
      };
    });
  },

  // Agregar error
  agregarError: (error: string) => {
    editorStore.update(estado => ({
      ...estado,
      errores: [...estado.errores, error]
    }));
  },

  // Agregar warning
  agregarWarning: (warning: string) => {
    editorStore.update(estado => ({
      ...estado,
      warnings: [...estado.warnings, warning]
    }));
  },

  // Limpiar errores
  limpiarErrores: () => {
    editorStore.update(estado => ({
      ...estado,
      errores: []
    }));
  },

  // Limpiar warnings
  limpiarWarnings: () => {
    editorStore.update(estado => ({
      ...estado,
      warnings: []
    }));
  },

  // Marcar como guardado
  marcarGuardado: () => {
    editorStore.update(estado => ({
      ...estado,
      guardado: true
    }));
  },

  // Marcar como publicado
  marcarPublicado: () => {
    editorStore.update(estado => ({
      ...estado,
      publicado: true,
      guardado: true
    }));
  },

  // Validar paso actual
  validarPasoActual: (): ValidacionPaso => {
    const estado = get(editorStore);
    
    if (!estado.configuracion) {
      return {
        valido: false,
        errores: ['No hay configuración disponible'],
        warnings: [],
        progreso: 0
      };
    }
    
    const pasoConfig = estado.configuracion.pasos.find(p => p.numero === estado.pasoActual);
    if (!pasoConfig) {
      return {
        valido: false,
        errores: ['Paso no encontrado'],
        warnings: [],
        progreso: 0
      };
    }
    
    const esValido = pasoConfig.validacion(estado.contenidoActual);
    const errores = esValido ? [] : [`Paso ${estado.pasoActual} incompleto`];
    
    return {
      valido: esValido,
      errores,
      warnings: [],
      progreso: calcularProgreso(estado.configuracion)
    };
  }
};

// Función para calcular el progreso
function calcularProgreso(configuracion: ConfiguracionContenido): number {
  const pasosCompletados = configuracion.pasos.filter(p => p.completado).length;
  const totalPasos = configuracion.pasos.length;
  
  return Math.round((pasosCompletados / totalPasos) * 100);
}

// Función para resetear el editor
export const resetearEditor = () => {
  editorStore.set(estadoInicial);
};

// Función para obtener el estado actual
export const obtenerEstadoActual = () => {
  return get(editorStore);
};

// Función para validar todo el contenido
export const validarTodoElContenido = (): ValidacionPaso => {
  const estado = get(editorStore);
  
  if (!estado.configuracion) {
    return {
      valido: false,
      errores: ['No hay configuración disponible'],
      warnings: [],
      progreso: 0
    };
  }
  
  const errores: string[] = [];
  const warnings: string[] = [];
  
  // Validar cada paso
  estado.configuracion.pasos.forEach(paso => {
    if (paso.requerido && !paso.completado) {
      errores.push(`Paso ${paso.numero} (${paso.titulo}) es requerido`);
    }
    
    if (!paso.validacion(estado.contenidoActual)) {
      errores.push(`Paso ${paso.numero} no es válido`);
    }
  });
  
  // Validar metadatos
  if (!estado.metadatos) {
    errores.push('Faltan metadatos');
  } else {
    if (!estado.metadatos.titulo) {
      errores.push('El título es requerido');
    }
    
    if (!estado.metadatos.descripcion) {
      errores.push('La descripción es requerida');
    }
    
    if (estado.metadatos.titulo && estado.metadatos.titulo.length < 5) {
      warnings.push('El título es muy corto');
    }
    
    if (estado.metadatos.descripcion && estado.metadatos.descripcion.length < 20) {
      warnings.push('La descripción es muy corta');
    }
  }
  
  const progreso = calcularProgreso(estado.configuracion);
  const valido = errores.length === 0 && progreso >= 100;
  
  return {
    valido,
    errores,
    warnings,
    progreso
  };
};

// Función para obtener información del paso actual
export const obtenerInfoPasoActual = () => {
  const estado = get(editorStore);
  
  if (!estado.configuracion) return null;
  
  return estado.configuracion.pasos.find(p => p.numero === estado.pasoActual);
};

// Función para verificar si se puede avanzar al siguiente paso
export const puedeAvanzarPaso = (): boolean => {
  const estado = get(editorStore);
  
  if (!estado.configuracion) return false;
  
  const pasoActual = estado.configuracion.pasos.find(p => p.numero === estado.pasoActual);
  if (!pasoActual) return false;
  
  return pasoActual.validacion(estado.contenidoActual);
};

// Función para obtener el siguiente paso disponible
export const obtenerSiguientePaso = (): PasoEditor | null => {
  const estado = get(editorStore);
  
  if (!estado.configuracion) return null;
  
  const siguientePaso = estado.pasoActual + 1;
  const existeSiguientePaso = estado.configuracion.pasos.some(p => p.numero === siguientePaso);
  
  return existeSiguientePaso ? siguientePaso as PasoEditor : null;
};

// Función para obtener el paso anterior disponible
export const obtenerPasoAnterior = (): PasoEditor | null => {
  const estado = get(editorStore);
  
  if (estado.pasoActual <= 1) return null;
  
  return (estado.pasoActual - 1) as PasoEditor;
}; 