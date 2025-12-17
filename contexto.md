# Contexto del Proyecto: Academia Vallenata Online

## Descripción General
Academia Vallenata Online es una plataforma educativa especializada en la enseñanza del acordeón y música vallenata. El proyecto está desarrollado con tecnologías modernas como SvelteKit, Tailwind CSS y Supabase como backend.

## Estructura del Proyecto

### Tecnologías Principales
- **Frontend**: SvelteKit 5.0, Tailwind CSS
- **Backend**: Supabase (PostgreSQL)
- **Autenticación**: Supabase Auth
- **Pagos**: ePayco SDK
- **Multimedia**: Howler.js para audio

### Organización de Carpetas
- **/src**: Código fuente principal
  - **/lib**: Componentes, utilidades y lógica reutilizable
  - **/routes**: Páginas y rutas de la aplicación
- **/static**: Archivos estáticos (imágenes, audio, etc.)
- **/tablas_supabase**: Documentación de la estructura de la base de datos

## Funcionalidades Principales

### Educación y Cursos
- Sistema de cursos y tutoriales de acordeón
- Seguimiento de progreso de estudiantes
- Módulos y lecciones estructuradas

### Comunidad
- Publicaciones y comentarios entre usuarios
- Sistema de likes y interacciones
- Perfiles de usuario personalizables

### Gamificación
- Sistema de ranking entre estudiantes
- Monedas virtuales y recompensas
- Simulador de acordeón interactivo

### Administración
- Panel de administración para gestionar contenidos
- Estadísticas y seguimiento de estudiantes
- Gestión de eventos y notificaciones

### Pagos y Membresías
- Integración con ePayco para procesamiento de pagos
- Sistema de membresías y suscripciones
- Paquetes y ofertas especiales

## Base de Datos
El proyecto utiliza Supabase como backend, con tablas para:
- Perfiles de usuario
- Cursos, módulos y lecciones
- Progreso de estudiantes
- Publicaciones y comentarios de la comunidad
- Eventos y notificaciones
- Pagos y transacciones

## Características Técnicas
- Aplicación PWA (Progressive Web App)
- Modo oscuro implementado
- Diseño responsivo con Tailwind CSS
- Autenticación y autorización con Supabase
- Sistema de notificaciones en tiempo real

## Flujo de Usuario
1. Registro/Login con Supabase Auth
2. Exploración de cursos y contenidos disponibles
3. Inscripción en cursos (gratuitos o de pago)
4. Seguimiento del progreso en las lecciones
5. Interacción con la comunidad
6. Participación en eventos y rankings

Este proyecto representa una plataforma educativa completa enfocada en la enseñanza del acordeón vallenato, combinando contenido educativo estructurado con elementos de comunidad y gamificación para mejorar la experiencia de aprendizaje.