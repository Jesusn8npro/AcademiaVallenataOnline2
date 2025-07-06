-- Script para verificar y corregir el constraint de tipo en usuario_imagenes

-- 1. Verificar el constraint actual
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'usuario_imagenes' 
  AND n.nspname = 'public'
  AND c.contype = 'c';

-- 2. Eliminar el constraint existente si existe
ALTER TABLE usuario_imagenes DROP CONSTRAINT IF EXISTS usuario_imagenes_tipo_check;

-- 3. Crear el nuevo constraint con los valores correctos
ALTER TABLE usuario_imagenes 
ADD CONSTRAINT usuario_imagenes_tipo_check 
CHECK (tipo IN ('avatar', 'portada'));

-- 4. Verificar que el constraint se aplicó correctamente
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'usuario_imagenes' 
  AND n.nspname = 'public'
  AND c.contype = 'c';

-- 5. Verificar datos existentes (si los hay)
SELECT tipo, COUNT(*) as cantidad
FROM usuario_imagenes
GROUP BY tipo; 