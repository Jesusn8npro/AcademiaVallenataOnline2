# 🎮 INSTALACIÓN DEL SISTEMA HÍBRIDO DE GAMIFICACIÓN

## 📋 **PASOS PARA INSTALAR**

### 1. 🗃️ **EJECUTAR SCRIPTS SQL EN ORDEN**

**⚠️ IMPORTANTE:** Ejecutar en este orden exacto en Supabase SQL Editor:

```sql
-- ✅ PARTE 1: Ejecutar primero
-- Archivo: tablas_supabase/01_tablas_gaming.sql
-- Contiene: Tablas principales, triggers básicos, RLS
```

```sql
-- ✅ PARTE 2: Ejecutar segundo
-- Archivo: tablas_supabase/02_ranking_estadisticas.sql
-- Contiene: Ranking global, estadísticas, sesiones, índices
```

```sql
-- ✅ PARTE 3: Ejecutar tercero
-- Archivo: tablas_supabase/03_logros_triggers.sql
-- Contiene: Notificaciones, actividades pendientes, funciones
```

```sql
-- ✅ PARTE 4: Ejecutar cuarto
-- Archivo: tablas_supabase/04_triggers_integracion.sql
-- Contiene: Triggers de integración, logros, función híbrida
```

### 2. 🔧 **VERIFICAR INSTALACIÓN**

Después de ejecutar todos los scripts, verifica que se crearon:

#### **Tablas creadas:**
- ✅ `experiencia_usuario`
- ✅ `logros_sistema`
- ✅ `logros_usuario`
- ✅ `ranking_global`
- ✅ `estadisticas_usuario`
- ✅ `sesiones_simulador`
- ✅ `notificaciones_gaming`
- ✅ `actividades_pendientes`

#### **Funciones creadas:**
- ✅ `obtener_ranking_hibrido_completo()`
- ✅ `procesar_actividad_gamificacion()`
- ✅ `obtener_actividades_pendientes()`
- ✅ `marcar_actividad_procesada()`

#### **Triggers creados:**
- ✅ `trigger_nueva_publicacion`
- ✅ `trigger_nuevo_like`
- ✅ `trigger_nuevo_comentario` (si existe la tabla)
- ✅ `trigger_progreso_leccion` (si existe la tabla)
- ✅ `trigger_curso_completado` (si existe la tabla)
- ✅ `trigger_tutorial_completado` (si existe la tabla)

#### **Logros iniciales:**
- ✅ 25 logros predefinidos insertados

### 3. 🎮 **ACTIVAR SISTEMA GAMING**

#### **Agregar al layout principal:**
```svelte
<!-- src/routes/+layout.svelte -->
<script>
  import GestorGamificacion from '$lib/components/Gaming/GestorGamificacion.svelte';
  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
</script>

<!-- Solo mostrar si el usuario está logueado -->
{#if $estadoUsuarioActual.user}
  <GestorGamificacion usuarioId={$estadoUsuarioActual.user.id} />
{/if}
```

### 4. 🔄 **SINCRONIZAR DATOS EXISTENTES**

```javascript
// Ejecutar en la consola del navegador una vez
import { GamificacionService } from '$lib/services/gamificacionService';

// Sincronizar todos los usuarios existentes
await GamificacionService.sincronizarDatosReales();
```

### 5. 📊 **VERIFICAR FUNCIONAMIENTO**

#### **Comprobar ranking híbrido:**
```sql
-- Ejecutar en Supabase SQL Editor
SELECT * FROM obtener_ranking_hibrido_completo('general', 100);
```

#### **Verificar triggers:**
```sql
-- Crear una publicación de prueba y ver si se procesa
SELECT * FROM actividades_pendientes WHERE procesado = false;
```

### 6. 🎯 **CONFIGURAR COMPONENTES**

#### **Ranking actualizado:**
- ✅ `src/lib/components/Banners/RankingComunidad.svelte` - Muestra TODOS los usuarios
- ✅ `src/routes/ranking/+page.svelte` - Límite aumentado a 1000 usuarios

#### **Nuevos componentes gaming:**
- ✅ `src/lib/components/Gaming/GestorGamificacion.svelte` - Gestor principal
- ✅ `src/lib/components/Gaming/BarraXP.svelte` - Barra de experiencia
- ✅ `src/lib/components/Gaming/GestorNotificaciones.svelte` - Notificaciones

### 7. 🔧 **RESOLUCIÓN DE PROBLEMAS**

#### **Si hay errores de deadlock:**
- Ejecutar los scripts uno por uno
- Esperar 10 segundos entre cada ejecución
- Verificar que no hay transacciones activas

#### **Si los triggers no funcionan:**
```sql
-- Verificar triggers existentes
SELECT trigger_name, event_object_table, action_statement 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

#### **Si no hay datos en el ranking:**
```sql
-- Verificar datos de experiencia
SELECT * FROM experiencia_usuario LIMIT 10;

-- Verificar datos de ranking
SELECT * FROM ranking_global WHERE activo = true LIMIT 10;
```

### 8. 🚀 **CARACTERÍSTICAS DEL SISTEMA HÍBRIDO**

#### **Datos automáticos:**
- ✅ XP por completar lecciones
- ✅ XP por completar cursos/tutoriales
- ✅ XP por publicaciones en comunidad
- ✅ XP por recibir likes
- ✅ XP por hacer comentarios
- ✅ Logros automáticos por progreso

#### **Ranking híbrido:**
- ✅ Muestra TODOS los usuarios registrados
- ✅ Combina datos gaming con datos reales
- ✅ Usuarios sin gamificación aparecen con datos básicos
- ✅ Usuarios con gamificación aparecen con datos completos

#### **Notificaciones:**
- ✅ Notificaciones al conseguir logros
- ✅ Notificaciones al subir de nivel
- ✅ Notificaciones de ranking
- ✅ Notificaciones de racha perdida

### 9. 🎮 **CONFIGURACIÓN AVANZADA**

#### **Personalizar XP por actividad:**
```sql
-- Modificar valores en gamificacionService.ts
const XP_POR_ACTIVIDAD = {
    leccion_completada: 10,
    curso_completado: 100,
    tutorial_completado: 50,
    publicacion_creada: 15,
    like_recibido: 2,
    comentario_creado: 5
};
```

#### **Agregar nuevos logros:**
```sql
INSERT INTO logros_sistema (id, nombre, descripcion, categoria, dificultad, xp_recompensa, condiciones) 
VALUES ('mi_logro_custom', 'Mi Logro', 'Descripción del logro', 'especial', 'medio', 200, '{"condicion": "valor"}');
```

### 10. ✅ **VERIFICACIÓN FINAL**

#### **Lista de verificación:**
- [ ] Todos los scripts ejecutados sin errores
- [ ] Tablas creadas correctamente
- [ ] Triggers funcionando
- [ ] Logros insertados
- [ ] Ranking mostrando todos los usuarios
- [ ] Componentes gaming funcionando
- [ ] Notificaciones apareciendo
- [ ] Sincronización automática activa

---

## 🎉 **¡SISTEMA HÍBRIDO INSTALADO!**

El sistema ahora:
- 🏆 **Muestra TODOS los usuarios** en el ranking
- 🎮 **Combina datos gaming con datos reales**
- 📊 **Motiva mayor participación** con logros automáticos
- 🔄 **Se sincroniza automáticamente** con actividades reales
- 🎯 **Premia constancia y progreso** real en la plataforma

### 📞 **Soporte:**
Si tienes problemas, revisa:
1. Logs de la consola del navegador
2. Logs de Supabase
3. Verificar que todas las tablas existen
4. Comprobar que los triggers se ejecutan

---

**¡Disfruta del nuevo sistema híbrido de gamificación!** 🎮🎵 