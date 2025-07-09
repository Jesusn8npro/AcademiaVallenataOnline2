-- =====================================================
-- 🔧 FIX TEMPORAL - PERMITIR RANKING PÚBLICO (MEJORADO)
-- =====================================================

-- Primero verificar políticas existentes
SELECT 'POLÍTICAS EXISTENTES:' as info;
SELECT 
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'ranking_global'
  AND schemaname = 'public';

-- Eliminar política anterior si existe
DROP POLICY IF EXISTS "ranking_publico_temporal" ON ranking_global;

-- Crear política temporal para ver ranking público
CREATE POLICY "ranking_publico_temporal" ON ranking_global
    FOR SELECT
    USING (activo = true);

-- También crear política para perfiles si no existe
DROP POLICY IF EXISTS "perfiles_publicos_temporal" ON perfiles;
CREATE POLICY "perfiles_publicos_temporal" ON perfiles
    FOR SELECT
    USING (true);

-- Verificar que las políticas se crearon
SELECT 'NUEVAS POLÍTICAS CREADAS:' as info;
SELECT 
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename IN ('ranking_global', 'perfiles')
  AND policyname LIKE '%temporal%';

-- Probar consulta completa después del fix
SELECT 'TEST DESPUÉS DEL FIX:' as info;
SELECT 
  r.tipo_ranking,
  r.puntuacion,
  r.posicion,
  p.nombre,
  p.apellido,
  p.url_foto_perfil
FROM ranking_global r
LEFT JOIN perfiles p ON r.usuario_id = p.id
WHERE r.tipo_ranking = 'general' 
  AND r.activo = true
ORDER BY r.posicion
LIMIT 5;

-- Verificar otros tipos de ranking
SELECT 'TEST SIMULADOR:' as info;
SELECT 
  r.tipo_ranking,
  r.puntuacion,
  r.posicion,
  p.nombre
FROM ranking_global r
LEFT JOIN perfiles p ON r.usuario_id = p.id
WHERE r.tipo_ranking = 'simulador' 
  AND r.activo = true
ORDER BY r.posicion
LIMIT 3;

-- Mensaje de éxito
SELECT '✅ Fix temporal aplicado correctamente!' as resultado;
SELECT '🔄 Ahora recarga la página localhost:5173/ranking' as instruccion; 