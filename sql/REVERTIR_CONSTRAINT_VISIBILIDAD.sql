-- ===== REVERTIR CONSTRAINT DE VISIBILIDAD =====
-- Este script revierte el constraint problemático de visibilidad
-- y restaura el constraint original que funciona

-- 1. Ver el constraint actual que está causando problemas
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'comunidad_publicaciones' 
  AND n.nspname = 'public'
  AND c.contype = 'c'
  AND conname LIKE '%visibilidad%';

-- 2. ELIMINAR el constraint problemático
ALTER TABLE comunidad_publicaciones DROP CONSTRAINT IF EXISTS comunidad_publicaciones_visibilidad_check;

-- 3. RESTAURAR el constraint original (solo los valores que funcionaban)
ALTER TABLE comunidad_publicaciones 
ADD CONSTRAINT comunidad_publicaciones_visibilidad_check 
CHECK (visibilidad IN ('publico', 'privado', 'amigos'));

-- 4. Verificar que se restauró correctamente
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'comunidad_publicaciones' 
  AND n.nspname = 'public'
  AND c.contype = 'c'
  AND conname = 'comunidad_publicaciones_visibilidad_check';

-- 5. Mensaje de confirmación
SELECT '✅ Constraint de visibilidad REVERTIDO! Ahora permite: publico, privado, amigos (valores originales)' as resultado; 