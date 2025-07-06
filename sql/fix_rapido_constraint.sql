-- ===== SOLUCIÓN RÁPIDA: Corrección del Constraint de Tipo =====
-- Ejecuta este script completo en el SQL Editor de Supabase

-- Eliminar el constraint problemático
ALTER TABLE usuario_imagenes DROP CONSTRAINT IF EXISTS usuario_imagenes_tipo_check;

-- Crear el constraint correcto
ALTER TABLE usuario_imagenes 
ADD CONSTRAINT usuario_imagenes_tipo_check 
CHECK (tipo IN ('avatar', 'portada'));

-- Mensaje de confirmación
SELECT 'Constraint corregido exitosamente! Ahora puedes usar los valores: avatar, portada' as resultado; 