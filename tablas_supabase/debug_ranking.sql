-- =====================================================
-- 🔍 SCRIPT DE DEBUGGING - VERIFICAR DATOS RANKING
-- =====================================================

-- 1. Verificar que hay datos en ranking_global
SELECT '🏆 DATOS DE RANKING_GLOBAL:' as debug_info;
SELECT 
  id,
  usuario_id,
  tipo_ranking,
  puntuacion,
  posicion,
  activo,
  periodo_inicio
FROM ranking_global 
ORDER BY tipo_ranking, posicion;

-- 2. Verificar que hay datos en perfiles
SELECT '👤 DATOS DE PERFILES:' as debug_info;
SELECT 
  id,
  nombre,
  apellido,
  url_foto_perfil
FROM perfiles 
LIMIT 5;

-- 3. Probar el JOIN que usa el servicio
SELECT '🔗 PRUEBA DE JOIN:' as debug_info;
SELECT 
  r.id,
  r.usuario_id,
  r.tipo_ranking,
  r.puntuacion,
  r.posicion,
  r.activo,
  p.nombre,
  p.apellido,
  p.url_foto_perfil
FROM ranking_global r
LEFT JOIN perfiles p ON r.usuario_id = p.id
WHERE r.tipo_ranking = 'general' 
  AND r.activo = true
ORDER BY r.posicion;

-- 4. Verificar otros tipos de ranking
SELECT '📊 RANKING SIMULADOR:' as debug_info;
SELECT 
  r.tipo_ranking,
  r.puntuacion,
  r.posicion,
  p.nombre,
  p.apellido
FROM ranking_global r
LEFT JOIN perfiles p ON r.usuario_id = p.id
WHERE r.tipo_ranking = 'simulador' 
  AND r.activo = true
ORDER BY r.posicion;

-- 5. Contar total de entradas por tipo
SELECT '📈 CONTEO POR TIPO:' as debug_info;
SELECT 
  tipo_ranking,
  COUNT(*) as total_usuarios,
  COUNT(CASE WHEN activo = true THEN 1 END) as usuarios_activos
FROM ranking_global
GROUP BY tipo_ranking
ORDER BY tipo_ranking; 