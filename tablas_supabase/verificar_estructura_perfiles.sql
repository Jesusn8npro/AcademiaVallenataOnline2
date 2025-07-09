-- =====================================================
-- 🔍 VERIFICAR ESTRUCTURA EXACTA DE PERFILES
-- =====================================================

-- 1. Ver todas las columnas de la tabla perfiles
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'perfiles' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Ver algunos datos de ejemplo
SELECT 
  id,
  nombre,
  apellido,
  correo_electronico
FROM perfiles 
LIMIT 3;

-- 3. Buscar campos que contengan 'foto' o 'imagen'
SELECT 
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_name = 'perfiles' 
  AND table_schema = 'public'
  AND (column_name ILIKE '%foto%' OR column_name ILIKE '%imagen%' OR column_name ILIKE '%avatar%' OR column_name ILIKE '%picture%');

-- 4. Probar consulta simple de ranking sin el campo problemático
SELECT 
  r.tipo_ranking,
  r.puntuacion,
  r.posicion,
  p.nombre,
  p.apellido
FROM ranking_global r
LEFT JOIN perfiles p ON r.usuario_id = p.id
WHERE r.tipo_ranking = 'general' 
  AND r.activo = true
ORDER BY r.posicion
LIMIT 5; 