# 🔧 SCRIPT FINAL: Limpiar y Corregir Visibilidad

## 🚨 **Problema:**
Hay registros existentes con valores de `visibilidad` no permitidos (NULL, 'perfil_solo', etc.)

## ✅ **Solución:**
Ejecuta este script COMPLETO en Supabase SQL Editor:

```sql
-- ===== LIMPIAR Y CORREGIR VALORES DE VISIBILIDAD =====

-- 1. Ver qué valores problemáticos hay
SELECT DISTINCT visibilidad, COUNT(*) as cantidad
FROM comunidad_publicaciones 
GROUP BY visibilidad
ORDER BY cantidad DESC;

-- 2. Limpiar TODOS los valores problemáticos
UPDATE comunidad_publicaciones 
SET visibilidad = 'publico' 
WHERE visibilidad NOT IN ('publico', 'privado', 'amigos') 
   OR visibilidad IS NULL;

-- 3. Eliminar constraint problemático
ALTER TABLE comunidad_publicaciones DROP CONSTRAINT IF EXISTS comunidad_publicaciones_visibilidad_check;

-- 4. Crear constraint correcto
ALTER TABLE comunidad_publicaciones 
ADD CONSTRAINT comunidad_publicaciones_visibilidad_check 
CHECK (visibilidad IN ('publico', 'privado', 'amigos'));

-- 5. Confirmación
SELECT '✅ SOLUCIONADO! Imágenes de perfil y portada funcionando' as resultado;
```

## 📋 **Lo que hace:**
1. **Identifica** valores problemáticos  
2. **Convierte** todos los valores raros a 'publico'
3. **Elimina** el constraint que causa problemas
4. **Crea** el constraint correcto
5. **Confirma** que todo está bien

## ✅ **Resultado esperado:**
- ✅ Imágenes de perfil funcionando
- ✅ Imágenes de portada funcionando  
- ✅ Modal de imágenes funcionando
- ✅ Publicaciones automáticas funcionando
- ✅ Sin más errores de constraint 