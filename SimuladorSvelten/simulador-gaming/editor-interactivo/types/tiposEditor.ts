// Tipos principales del editor interactivo
export type TipoContenido = 'cancion' | 'desafio' | 'ejercicio' | 'teoria';
export type PasoEditor = 1 | 2 | 3 | 4;

// Interfaces para notas y música
export interface NotaAcordeon {
  id: string;
  tiempo: number;
  nota: string;
  duracion: number;
  tecla: string;
  octava: number;
  volumen: number;
  tipo: 'melody' | 'chord' | 'bass';
}

// Metadatos para cualquier tipo de contenido
export interface MetadatosContenido {
  titulo: string;
  descripcion: string;
  dificultad: 'facil' | 'medio' | 'dificil' | 'experto';
  categoria: string;
  tags: string[];
  autor: string;
  fechaCreacion: Date;
  fechaActualizacion: Date;
  publico: boolean;
  destacado: boolean;
}

// Configuración de gamificación
export interface ConfiguracionGamificacion {
  experiencia: number;
  monedas: number;
  logros: string[];
  multiplicadores: {
    precision: number;
    velocidad: number;
    combo: number;
  };
}

// Estado principal del editor
export interface EstadoEditorInteractivo {
  tipoContenido: TipoContenido | null;
  pasoActual: PasoEditor;
  progreso: number;
  guardado: boolean;
  publicado: boolean;
  configuracion: ConfiguracionContenido | null;
  metadatos: MetadatosContenido | null;
  contenidoActual: any;
  errores: string[];
  warnings: string[];
}

// Configuración específica por tipo de contenido
export interface ConfiguracionContenido {
  tipo: TipoContenido;
  pasos: PasoContenido[];
  restricciones: RestriccionesContenido;
  gamificacion: ConfiguracionGamificacion;
  caracteristicas: CaracteristicasContenido;
}

export interface PasoContenido {
  numero: PasoEditor;
  titulo: string;
  descripcion: string;
  requerido: boolean;
  completado: boolean;
  validacion: (datos: any) => boolean;
}

export interface RestriccionesContenido {
  duracionMinima?: number;
  duracionMaxima?: number;
  notasMinimas?: number;
  notasMaximas?: number;
  complejidadMinima?: number;
  complejidadMaxima?: number;
}

export interface CaracteristicasContenido {
  tieneAudio: boolean;
  tieneVideo: boolean;
  tienePartitura: boolean;
  tieneTexto: boolean;
  tieneEjercicios: boolean;
  tieneEvaluacion: boolean;
  tieneRetroalimentacion: boolean;
  tieneProgresion: boolean;
}

// Tipos de eventos del editor
export interface EventosEditor {
  onCambioTipo: (tipo: TipoContenido) => void;
  onCambioPaso: (paso: PasoEditor) => void;
  onGuardar: () => void;
  onPublicar: () => void;
  onValidar: () => void;
  onError: (error: string) => void;
  onWarning: (warning: string) => void;
}

// Tipos de respuesta del servidor
export interface RespuestaServidor {
  exito: boolean;
  mensaje: string;
  datos?: any;
  errores?: string[];
}

// Tipos para el contenido específico
export interface ContenidoCancion {
  audio: File | null;
  notas: NotaAcordeon[];
  bpm: number;
  compas: string;
  tonalidad: string;
  acordes: string[];
  duracion: number;
}

export interface ContenidoDesafio {
  tipoDesafio: 'velocidad' | 'precision' | 'resistencia' | 'creatividad';
  objetivo: string;
  criteriosEvaluacion: string[];
  tiempoLimite: number;
  puntuacionMinima: number;
  recompensas: ConfiguracionGamificacion;
}

export interface ContenidoEjercicio {
  tipoEjercicio: 'tecnica' | 'teoria' | 'practica' | 'evaluacion';
  instrucciones: string;
  recursos: string[];
  ejemplos: any[];
  evaluacion: {
    tipo: 'automatica' | 'manual' | 'mixta';
    criterios: string[];
  };
}

export interface ContenidoTeoria {
  capitulo: string;
  seccion: string;
  contenidoTexto: string;
  imagenes: string[];
  videos: string[];
  ejemplosInteractivos: any[];
  ejerciciosRelacionados: string[];
}

// Utilidades de tipos
export type ContenidoUnion = ContenidoCancion | ContenidoDesafio | ContenidoEjercicio | ContenidoTeoria;

export interface ValidacionPaso {
  valido: boolean;
  errores: string[];
  warnings: string[];
  progreso: number;
}

export interface HistorialCambios {
  fecha: Date;
  accion: string;
  datos: any;
  usuario: string;
}

// Tipos para UI
export interface OpcionSelector {
  valor: TipoContenido;
  titulo: string;
  descripcion: string;
  icono: string;
  color: string;
  disponible: boolean;
}

export interface EstadoUI {
  cargando: boolean;
  error: string | null;
  modalAbierto: boolean;
  panelLateralAbierto: boolean;
  modo: 'edicion' | 'preview' | 'publicacion';
} 