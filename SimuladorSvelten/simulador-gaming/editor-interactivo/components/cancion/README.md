# 🎵 Componentes de Canciones - Editor Interactivo

Esta carpeta contiene los componentes específicos para crear canciones en el editor interactivo.

## 📁 Componentes

### 1. `PasoSubirAudio.svelte`
**Funcionalidad:** Subir archivo de audio y configurar metadatos
- **Características:**
  - Drag & drop para archivos de audio
  - Reproductor integrado con controles
  - Formulario de metadatos (título, artista, género, etc.)
  - Validación de archivos (MP3, WAV, OGG, M4A)
  - Límite de tamaño: 50MB
  - Autocompletado de campos basado en el archivo

### 2. `PasoGrabarNotas.svelte`
**Funcionalidad:** Grabar notas del acordeón sincronizadas con el audio
- **Características:**
  - Simulador de acordeón interactivo
  - Grabación en tiempo real
  - Control de velocidad de reproducción
  - Dirección del fuelle (halar/empujar)
  - Limpieza automática de duplicados
  - Contador de notas en tiempo real

### 3. `PasoVistaPrevia.svelte`
**Funcionalidad:** Previsualizar la sincronización audio-notas
- **Características:**
  - Reproducción sincronizada
  - Visualización de notas en tiempo real
  - Línea de tiempo visual
  - Indicador de dirección del fuelle
  - Información de nota actual y siguiente
  - Controles de velocidad y volumen

### 4. `PasoPublicar.svelte`
**Funcionalidad:** Configurar y publicar la canción
- **Características:**
  - Validación final completa
  - Configuración de privacidad
  - Tags personalizados
  - Barra de progreso de publicación
  - Subida a Supabase Storage
  - Creación en base de datos

## 🔗 Integración

Los componentes se integran en el archivo principal `+page.svelte` usando eventos personalizados:

```svelte
<PasoSubirAudio 
  contenido={estado.contenidoActual}
  on:avanzar={(e) => {
    editorActions.actualizarContenido(e.detail);
    manejarCambioPaso(new CustomEvent('cambioPaso', { detail: 2 }));
  }}
  on:actualizar={(e) => {
    editorActions.actualizarContenido(e.detail);
  }}
/>
```

## 📊 Flujo de Datos

### Estructura de `contenido` para canciones:

```typescript
{
  // Paso 1: Metadatos y audio
  titulo: string;
  artista: string;
  genero: string;
  descripcion: string;
  nivel_dificultad: number;
  bpm: number;
  afinacion: string;
  audio: File;
  duracion_segundos: number;
  
  // Paso 2: Grabación
  notas: NotaGrabada[];
  velocidad_grabacion: number;
  direccion_inicial: string;
  total_notas: number;
  
  // Paso 3: Preview (sin cambios adicionales)
  
  // Paso 4: Publicación
  url_audio: string;
  cancion_id: string;
  secuencia_id: string;
}
```

### Estructura de `NotaGrabada`:

```typescript
{
  id: string;
  idBoton: string;
  nombre: string;
  tiempo: number;        // En segundos
  duracion: number;      // En segundos
  direccion: string;     // 'halar' | 'empujar'
  direccionFuelle: string;
  activa: boolean;
  tiempoInicio: number;
}
```

## 🎮 Eventos

### Eventos emitidos por cada componente:

- **`avanzar`**: Avanza al siguiente paso con datos actualizados
- **`actualizar`**: Actualiza el contenido sin cambiar de paso
- **`regresar`**: Regresa al paso anterior (excepto paso 1)
- **`finalizar`**: Finaliza el proceso (solo paso 4)

## 🛠️ Servicios Utilizados

### AudioService
- Procesamiento de archivos de audio
- Extracción de metadatos
- Reproducción sincronizada

### StorageService
- Subida de archivos a Supabase Storage
- Validación de archivos
- Generación de URLs públicas

### CancionesService
- Creación de canciones en base de datos
- Creación de secuencias de notas
- Conversión de formatos

## 🎨 Diseño Visual

### Paleta de colores:
- **Principal**: `#4ecdc4` (Verde azulado)
- **Secundario**: `#44a08d` (Verde oscuro)
- **Acentos**: `#ff6b6b` (Rojo para grabación)
- **Fondo**: Gradientes oscuros con transparencias

### Animaciones:
- Indicadores de grabación con pulso
- Transiciones suaves entre pasos
- Efectos hover en botones
- Barras de progreso animadas

## 📱 Responsividad

Todos los componentes están optimizados para:
- **Desktop**: Interfaz completa con controles avanzados
- **Tablet**: Adaptación de grids y controles
- **Mobile**: Layouts verticales y controles simplificados

## 🔧 Configuración

### Límites configurables:
- **Duración mínima**: 10 segundos
- **Duración máxima**: 10 minutos
- **Tamaño archivo**: 50MB máximo
- **Notas mínimas**: 1 nota requerida
- **Tags máximos**: 10 tags personalizados

### Formatos soportados:
- **Audio**: MP3, WAV, OGG, M4A
- **Afinaciones**: FBE, GCF, ADG
- **Velocidades**: 0.5x - 2.0x

## 🚀 Mejoras Futuras

### Funcionalidades planeadas:
1. **Editor de notas avanzado** con edición manual
2. **Importación de MIDI** para notas automáticas
3. **Efectos de audio** integrados
4. **Colaboración en tiempo real**
5. **Análisis automático de BPM**
6. **Transcripción automática**

### Optimizaciones:
1. **Lazy loading** de componentes pesados
2. **Compresión de audio** antes de subir
3. **Cache de archivos** temporales
4. **Streaming** para archivos grandes

---

*Componentes de Canciones - Editor Interactivo v1.0* 