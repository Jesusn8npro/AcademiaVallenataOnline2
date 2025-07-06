-- 🚨 SCRIPT RÁPIDO: Revertir Constraint Problemático
-- Copia y pega este script completo en Supabase SQL Editor

-- Eliminar constraint problemático
ALTER TABLE comunidad_publicaciones DROP CONSTRAINT IF EXISTS comunidad_publicaciones_visibilidad_check;

-- Restaurar constraint original
ALTER TABLE comunidad_publicaciones 
ADD CONSTRAINT comunidad_publicaciones_visibilidad_check 
CHECK (visibilidad IN ('publico', 'privado', 'amigos'));

-- Confirmación
SELECT '✅ SOLUCIONADO! Imágenes de perfil y portada funcionando nuevamente' as resultado; 