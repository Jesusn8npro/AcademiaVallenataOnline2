-- =====================================================
-- 🛡️ VERIFICAR POLÍTICAS RLS - DEBUGGING (CORREGIDO)
-- =====================================================

-- 1. Verificar si RLS está habilitado (CORREGIDO)
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables 
WHERE tablename IN ('ranking_global', 'perfiles')
  AND schemaname = 'public';

-- 2. Verificar políticas existentes
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd as tipo_comando,
  qual as condicion
FROM pg_policies
WHERE tablename IN ('ranking_global', 'perfiles')
  AND schemaname = 'public';

-- 3. Probar consulta directa (simplificada)
SELECT 
  'TEST RANKING DIRECTO:' as info;

SELECT 
  r.tipo_ranking,
  r.puntuacion,
  r.posicion,
  r.activo,
  p.nombre,
  p.apellido
FROM ranking_global r
LEFT JOIN perfiles p ON r.usuario_id = p.id
WHERE r.tipo_ranking = 'general' 
  AND r.activo = true
ORDER BY r.posicion
LIMIT 5;

-- 4. Verificar usuario actual (si existe)
SELECT 
  'Usuario actual:' as info,
  current_user as usuario_db,
  session_user as usuario_sesion;

-- 5. Verificar total de datos sin filtros
SELECT 
  'TOTAL SIN FILTROS:' as info;
  
SELECT 
  COUNT(*) as total_ranking,
  COUNT(CASE WHEN activo = true THEN 1 END) as total_activos
FROM ranking_global;

SELECT 
  COUNT(*) as total_perfiles
FROM perfiles; 