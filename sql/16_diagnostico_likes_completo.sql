-- ============================================
-- DIAGNÓSTICO COMPLETO DEL SISTEMA DE LIKES
-- ============================================

-- 1. Verificar que la tabla existe y tiene la estructura correcta
SELECT 'VERIFICANDO TABLA comunidad_publicaciones_likes' as paso;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'comunidad_publicaciones_likes' 
ORDER BY ordinal_position;

-- 2. Verificar constraints y índices
SELECT 'VERIFICANDO CONSTRAINTS' as paso;
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'comunidad_publicaciones_likes';

-- 3. Verificar que las funciones RPC existen
SELECT 'VERIFICANDO FUNCIONES RPC' as paso;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN ('toggle_like_publicacion', 'contar_likes_publicacion_seguro', 'usuario_tiene_like_seguro')
ORDER BY routine_name;

-- 4. Verificar políticas RLS
SELECT 'VERIFICANDO POLÍTICAS RLS' as paso;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'comunidad_publicaciones_likes';

-- 5. Verificar datos actuales en la tabla
SELECT 'VERIFICANDO DATOS ACTUALES' as paso;
SELECT 
    COUNT(*) as total_likes,
    COUNT(DISTINCT publicacion_id) as publicaciones_con_likes,
    COUNT(DISTINCT usuario_id) as usuarios_que_dieron_like
FROM comunidad_publicaciones_likes;

-- 6. Verificar datos por publicación
SELECT 'LIKES POR PUBLICACIÓN' as paso;
SELECT 
    publicacion_id,
    COUNT(*) as total_likes,
    array_agg(usuario_id::text) as usuarios_que_dieron_like
FROM comunidad_publicaciones_likes 
GROUP BY publicacion_id 
ORDER BY total_likes DESC
LIMIT 10;

-- 7. Test de la función toggle_like_publicacion
SELECT 'TESTING FUNCIÓN toggle_like_publicacion' as paso;

-- Primero, obtener una publicación existente
DO $$
DECLARE
    test_publicacion_id UUID;
    test_usuario_id UUID;
    resultado JSONB;
BEGIN
    -- Obtener una publicación existente
    SELECT id INTO test_publicacion_id 
    FROM comunidad_publicaciones 
    LIMIT 1;
    
    -- Obtener un usuario existente
    SELECT id INTO test_usuario_id 
    FROM perfiles 
    LIMIT 1;
    
    IF test_publicacion_id IS NOT NULL AND test_usuario_id IS NOT NULL THEN
        -- Test 1: Dar like
        SELECT toggle_like_publicacion(test_publicacion_id, test_usuario_id) INTO resultado;
        RAISE NOTICE 'Test 1 - Dar like: %', resultado;
        
        -- Test 2: Quitar like
        SELECT toggle_like_publicacion(test_publicacion_id, test_usuario_id) INTO resultado;
        RAISE NOTICE 'Test 2 - Quitar like: %', resultado;
        
        -- Test 3: Dar like nuevamente
        SELECT toggle_like_publicacion(test_publicacion_id, test_usuario_id) INTO resultado;
        RAISE NOTICE 'Test 3 - Dar like nuevamente: %', resultado;
        
    ELSE
        RAISE NOTICE 'No se encontraron datos para testing';
    END IF;
END $$;

-- 8. Verificar permisos de la tabla
SELECT 'VERIFICANDO PERMISOS' as paso;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'comunidad_publicaciones_likes';

-- 9. Verificar si RLS está habilitado
SELECT 'VERIFICANDO RLS' as paso;
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    forcerowsecurity
FROM pg_tables 
WHERE tablename = 'comunidad_publicaciones_likes';

-- 10. Resumen final
SELECT 'RESUMEN FINAL' as paso;
SELECT 
    'Sistema de likes' as componente,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'comunidad_publicaciones_likes') 
        THEN '✅ OK' 
        ELSE '❌ FALTA' 
    END as tabla_existe,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'toggle_like_publicacion') 
        THEN '✅ OK' 
        ELSE '❌ FALTA' 
    END as funcion_toggle_existe,
    CASE 
        WHEN EXISTS(SELECT 1 FROM pg_policies WHERE tablename = 'comunidad_publicaciones_likes') 
        THEN '✅ OK' 
        ELSE '❌ FALTA' 
    END as politicas_rls_existen; 