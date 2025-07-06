# 🚨 SOLUCIÓN: Revertir Constraint de Visibilidad

## ❌ **Problema:**
El script que ejecutaste modificó el constraint de `visibilidad` en la tabla `comunidad_publicaciones` y ahora no puedes ver las imágenes de perfil ni portada.

## ✅ **Solución Inmediata:**

### **1. Ve a Supabase Dashboard**
- Abre tu proyecto de Academia Vallenata en Supabase
- Ve a **SQL Editor**

### **2. Ejecuta este script de reversión:**
```sql
-- ===== REVERTIR CONSTRAINT DE VISIBILIDAD =====
-- Este script revierte el constraint problemático

-- 1. ELIMINAR el constraint problemático
ALTER TABLE comunidad_publicaciones DROP CONSTRAINT IF EXISTS comunidad_publicaciones_visibilidad_check;

-- 2. RESTAURAR el constraint original (valores que funcionan)
ALTER TABLE comunidad_publicaciones 
ADD CONSTRAINT comunidad_publicaciones_visibilidad_check 
CHECK (visibilidad IN ('publico', 'privado', 'amigos'));

-- 3. Mensaje de confirmación
SELECT '✅ SOLUCIONADO! Constraint revertido a los valores originales' as resultado;
```

### **3. Verificar que funciona:**
- Guarda el script (clic en **RUN**)
- Ve a tu aplicación
- Intenta ver las imágenes de perfil y portada
- Deberían funcionar normalmente

## 🔍 **¿Qué pasó?**
- El script anterior agregó `'perfil_solo'` como valor permitido
- Pero tu aplicación usa solo: `'publico'`, `'privado'`, `'amigos'`
- Al modificar el constraint se rompió la funcionalidad existente

## ✅ **Después de ejecutar:**
- ✅ Imágenes de perfil funcionando
- ✅ Imágenes de portada funcionando  
- ✅ Publicaciones automáticas funcionando
- ✅ Modal de imágenes funcionando
- ✅ Sin filtro adicional necesario

## 📝 **Nota importante:**
Las publicaciones automáticas de fotos ya funcionan correctamente y se filtran en el código (no en la base de datos), así que no necesitas el valor `'perfil_solo'`. 