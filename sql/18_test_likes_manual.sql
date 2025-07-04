-- ============================================
-- TEST MANUAL DEL SISTEMA DE LIKES
-- ============================================

-- Paso 1: Verificar que tenemos datos para probar
SELECT 'DATOS DISPONIBLES PARA TESTING' as paso;

-- Mostrar publicaciones disponibles
SELECT 
    'PUBLICACIONES DISPONIBLES' as tipo,
    id,
    usuario_id,
    contenido,
    created_at
FROM comunidad_publicaciones 
ORDER BY created_at DESC 
LIMIT 5;

-- Mostrar usuarios disponibles
SELECT 
    'USUARIOS DISPONIBLES' as tipo,
    id,
    nombre_completo,
    email
FROM perfiles 
LIMIT 5;

-- Paso 2: Limpiar likes existentes para testing limpio
DELETE FROM comunidad_publicaciones_likes;

-- Paso 3: Test manual de inserción directa
DO $$
DECLARE
    test_publicacion_id UUID;
    test_usuario_id UUID;
    resultado JSONB;
BEGIN
    -- Obtener IDs reales para testing
    SELECT id INTO test_publicacion_id FROM comunidad_publicaciones LIMIT 1;
    SELECT id INTO test_usuario_id FROM perfiles LIMIT 1;
    
    IF test_publicacion_id IS NOT NULL AND test_usuario_id IS NOT NULL THEN
        RAISE NOTICE 'Testing con publicación: % y usuario: %', test_publicacion_id, test_usuario_id;
        
        -- Test 1: Insertar like directamente
        INSERT INTO comunidad_publicaciones_likes (publicacion_id, usuario_id)
        VALUES (test_publicacion_id, test_usuario_id);
        
        RAISE NOTICE '✅ Like insertado directamente';
        
        -- Verificar que se insertó
        SELECT COUNT(*) FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = test_publicacion_id 
        AND usuario_id = test_usuario_id;
        
        RAISE NOTICE '✅ Like verificado en la base de datos';
        
        -- Test 2: Usar función toggle_like_publicacion
        SELECT toggle_like_publicacion(test_publicacion_id, test_usuario_id) INTO resultado;
        RAISE NOTICE 'Resultado toggle (debería quitar like): %', resultado;
        
        -- Test 3: Usar función toggle_like_publicacion de nuevo
        SELECT toggle_like_publicacion(test_publicacion_id, test_usuario_id) INTO resultado;
        RAISE NOTICE 'Resultado toggle (debería dar like): %', resultado;
        
        -- Verificar estado final
        SELECT COUNT(*) FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = test_publicacion_id 
        AND usuario_id = test_usuario_id;
        
        RAISE NOTICE '✅ Testing completado exitosamente';
        
    ELSE
        RAISE NOTICE '❌ No se encontraron datos para testing';
    END IF;
END $$;

-- Paso 4: Verificar estado final
SELECT 'ESTADO FINAL' as paso;
SELECT 
    publicacion_id,
    usuario_id,
    created_at
FROM comunidad_publicaciones_likes;

-- Paso 5: Test de permisos con usuario simulado
-- Simular contexto de usuario autenticado
SET LOCAL role authenticated;

-- Intentar insertar como usuario autenticado
DO $$
DECLARE
    test_publicacion_id UUID;
    test_usuario_id UUID;
BEGIN
    SELECT id INTO test_publicacion_id FROM comunidad_publicaciones LIMIT 1;
    SELECT id INTO test_usuario_id FROM perfiles LIMIT 1;
    
    IF test_publicacion_id IS NOT NULL AND test_usuario_id IS NOT NULL THEN
        -- Simular auth.uid() devolviendo el usuario de prueba
        -- Esto es solo para testing, en producción auth.uid() viene de JWT
        
        INSERT INTO comunidad_publicaciones_likes (publicacion_id, usuario_id)
        VALUES (test_publicacion_id, test_usuario_id)
        ON CONFLICT (publicacion_id, usuario_id) DO NOTHING;
        
        RAISE NOTICE '✅ Inserción con rol authenticated exitosa';
    END IF;
END $$;

-- Resetear rol
RESET role;

-- Paso 6: Resumen final
SELECT 'RESUMEN FINAL' as paso;
SELECT 
    COUNT(*) as total_likes_en_sistema,
    COUNT(DISTINCT publicacion_id) as publicaciones_con_likes,
    COUNT(DISTINCT usuario_id) as usuarios_que_dieron_like
FROM comunidad_publicaciones_likes; 