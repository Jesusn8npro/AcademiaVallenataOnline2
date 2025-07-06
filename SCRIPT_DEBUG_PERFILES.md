# 🔍 DIAGNÓSTICO: Problema con Imágenes de Perfil

## 🚨 **Problema Identificado:**
Las publicaciones automáticas se crean correctamente, pero las imágenes de perfil/portada no se muestran. Esto indica que el problema está en la carga de datos desde la tabla `perfiles`.

## 📊 **Scripts de Diagnóstico:**

### **1. Verificar datos en tabla perfiles:**
```sql
-- Ver los datos del perfil actual
SELECT 
    id, 
    nombre_completo, 
    url_foto_perfil, 
    portada_url,
    fecha_actualizacion
FROM perfiles 
WHERE email = 'TU_EMAIL_ACTUAL'  -- Reemplaza con tu email
LIMIT 1;
```

### **2. Verificar datos en tabla usuario_imagenes:**
```sql
-- Ver las imágenes guardadas recientemente
SELECT 
    id,
    usuario_id,
    url_imagen,
    tipo,
    es_actual,
    fecha_subida
FROM usuario_imagenes 
WHERE tipo IN ('avatar', 'portada')
ORDER BY fecha_subida DESC
LIMIT 10;
```

### **3. Script para sincronizar datos:**
```sql
-- Actualizar tabla perfiles con las últimas imágenes de usuario_imagenes
-- PARA AVATAR
UPDATE perfiles 
SET url_foto_perfil = (
    SELECT url_imagen 
    FROM usuario_imagenes 
    WHERE usuario_id = perfiles.id 
      AND tipo = 'avatar' 
      AND es_actual = true 
    ORDER BY fecha_subida DESC 
    LIMIT 1
)
WHERE id IN (
    SELECT DISTINCT usuario_id 
    FROM usuario_imagenes 
    WHERE tipo = 'avatar' AND es_actual = true
);

-- PARA PORTADA
UPDATE perfiles 
SET portada_url = (
    SELECT url_imagen 
    FROM usuario_imagenes 
    WHERE usuario_id = perfiles.id 
      AND tipo = 'portada' 
      AND es_actual = true 
    ORDER BY fecha_subida DESC 
    LIMIT 1
)
WHERE id IN (
    SELECT DISTINCT usuario_id 
    FROM usuario_imagenes 
    WHERE tipo = 'portada' AND es_actual = true
);

-- Confirmación
SELECT '✅ Perfiles sincronizados con las últimas imágenes' as resultado;
```

## 🔧 **Pasos a seguir:**

1. **Ejecuta el script de verificación** para ver si hay datos
2. **Si no hay datos en `perfiles`**: ejecuta el script de sincronización
3. **Recarga la página** del perfil para ver si aparecen las imágenes
4. **Si sigue sin funcionar**: hay un problema en el código JavaScript

## 💡 **Probable causa:**
- Las imágenes se guardaron en `usuario_imagenes` pero no se actualizaron en `perfiles`
- El store está cargando datos de `perfiles` que están vacíos 