# 📸 Funcionalidad: Publicaciones Automáticas de Fotos

## 🎯 **¿Qué hace?**
Cuando un usuario cambia su **foto de perfil** o **foto de portada**, se crea automáticamente una publicación estilo Facebook que aparece en la página de **Publicaciones del Perfil** (NO en la comunidad general).

## 🔧 **Cómo funciona**

### **1. Flujo automático:**
- Usuario cambia foto de perfil/portada en `EncabezadoPerfil.svelte`
- Se guarda la imagen en Supabase Storage y tabla `perfiles`
- Se crea registro en tabla `usuario_imagenes` 
- **🎯 NUEVO:** Se crea publicación automática en tabla `comunidad_publicaciones`
- La publicación aparece solo en `/publicaciones` del usuario

### **2. Tipos de publicación:**
- `tipo: 'foto_perfil'` → "Actualizó su foto de perfil"
- `tipo: 'foto_portada'` → "Actualizó su foto de portada"

### **3. Protección anti-spam:**
- ✅ Solo 1 publicación por tipo cada 5 minutos
- ✅ Si cambia varias veces seguidas, no spamea publicaciones

## 📁 **Archivos modificados:**

### **Servicio principal:**
- `src/lib/services/publicacionesAutoService.ts` - Lógica de creación

### **Componente integrado:**
- `src/lib/components/PanelPrincipal/EncabezadoPerfil.svelte` - Llama al servicio después del guardado

### **Visualización mejorada:**
- `src/lib/components/Comunidad/FeedPublicaciones.svelte` - Muestra texto especial

## 🎨 **Diferencias visuales:**

### **Publicación normal:**
```
Usuario escribió: "Este es mi texto..."
[imagen opcional]
```

### **Publicación automática:**
```
Usuario [Actualizó su foto de perfil]
[imagen de la nueva foto]
```

## 🔍 **Dónde aparecen:**

### **✅ SÍ aparece en:**
- `/mi-perfil` → pestaña Publicaciones
- `/publicaciones` (página del perfil del usuario)

### **❌ NO aparece en:**
- `/comunidad` (feed principal) - **FILTRADO automáticamente**
- Timeline de otros usuarios
- Búsquedas públicas de publicaciones

## 🚫 **Filtrado automático:**
```sql
-- En /comunidad se excluyen con este filtro:
.not('tipo', 'in', '("foto_perfil","foto_portada")')

-- En /publicaciones se incluyen TODAS las del usuario:
.eq('usuario_id', $usuario.id) // Sin filtro de tipo
```

## 💡 **Ventajas:**

1. **Comportamiento familiar:** Como Facebook/Instagram
2. **No invasivo:** Solo en perfil personal
3. **Anti-spam:** Protección automática
4. **Sin romper nada:** Usa componentes existentes
5. **Eficiente:** Mínimo código agregado

## 🛠️ **Estructura de datos:**

```sql
-- Tabla: comunidad_publicaciones
{
  "id": "uuid-auto",
  "usuario_id": "user-id", 
  "titulo": "Actualizó su foto de perfil",
  "descripcion": "",
  "tipo": "foto_perfil", // o "foto_portada"
  "url_imagen": "nueva-url-de-la-foto",
  "usuario_nombre": "Nombre Usuario",
  "usuario_avatar": "url-avatar-actual",
  "fecha_creacion": "2024-timestamp",
  "visibilidad": "publico",
  "estado": "activo"
}
```

## 🚀 **Próximas mejoras posibles:**
- Reacciones específicas para cambios de foto
- Notificaciones a seguidores cercanos
- Historias de cambios de foto
- Comparación antes/después

---

*Esta funcionalidad mejora la experiencia del usuario sin afectar la funcionalidad existente, manteniendo la academia profesional y familiar como las redes sociales populares.* 