-- =====================================================
-- 🏆 TEST FINAL - RANKING CON MAPEO CORRECTO
-- =====================================================

-- Basado en el mapeo exacto de perfiles.md

-- 1. Probar consulta exacta que usa el servicio
SELECT 'CONSULTA EXACTA DEL SERVICIO:' as info;
SELECT 
  r.*,
  p.nombre,
  p.apellido,
  p.url_foto_perfil
FROM ranking_global r
LEFT JOIN perfiles p ON r.usuario_id = p.id
WHERE r.tipo_ranking = 'general' 
  AND r.activo = true
ORDER BY r.posicion
LIMIT 5;

-- 2. Verificar todos los tipos de ranking
SELECT 'TODOS LOS TIPOS DE RANKING:' as info;
SELECT 
  r.tipo_ranking,
  r.puntuacion,
  r.posicion,
  p.nombre,
  p.apellido,
  p.url_foto_perfil
FROM ranking_global r
LEFT JOIN perfiles p ON r.usuario_id = p.id
WHERE r.activo = true
ORDER BY r.tipo_ranking, r.posicion;

-- 3. Verificar que los campos existen
SELECT 'VERIFICANDO CAMPOS DE PERFILES:' as info;
SELECT 
  p.id,
  p.nombre,
  p.apellido,
  p.nombre_usuario,
  p.url_foto_perfil,
  p.correo_electronico
FROM perfiles p
LIMIT 3;

-- 4. Conteo final
SELECT 'CONTEO FINAL:' as info;
SELECT 
  'ranking_global' as tabla,
  COUNT(*) as total_registros,
  COUNT(CASE WHEN activo = true THEN 1 END) as activos
FROM ranking_global
UNION ALL
SELECT 
  'perfiles' as tabla,
  COUNT(*) as total_registros,
  COUNT(CASE WHEN eliminado = false OR eliminado IS NULL THEN 1 END) as activos
FROM perfiles;

-- 5. Mensaje final
SELECT '✅ Test completado - Si ves datos aquí, el ranking debería funcionar!' as resultado; 