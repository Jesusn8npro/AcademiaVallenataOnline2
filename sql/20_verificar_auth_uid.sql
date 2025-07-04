-- ============================================
-- VERIFICAR FUNCIÓN auth.uid() Y PERMISOS
-- ============================================

-- 1. Verificar si la extensión auth está disponible
SELECT 'VERIFICANDO EXTENSIÓN AUTH' as paso;
SELECT 
    extname,
    extversion
FROM pg_extension 
WHERE extname = 'supabase_auth';

-- 2. Verificar función auth.uid()
SELECT 'TESTING FUNCIÓN auth.uid()' as paso;
DO $$
BEGIN
    -- Intentar llamar auth.uid()
    BEGIN
        PERFORM auth.uid();
        RAISE NOTICE '✅ Función auth.uid() disponible';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Error con auth.uid(): %', SQLERRM;
    END;
END $$;

-- 3. Crear función alternativa para testing sin auth.uid()
DROP FUNCTION IF EXISTS toggle_like_publicacion_sin_auth(UUID, UUID);

CREATE OR REPLACE FUNCTION toggle_like_publicacion_sin_auth(p_publicacion_id UUID, p_usuario_id UUID)
RETURNS JSONB AS $$
DECLARE
    like_count INTEGER;
    user_has_like BOOLEAN;
    action_taken TEXT;
BEGIN
    -- Verificar parámetros
    IF p_publicacion_id IS NULL OR p_usuario_id IS NULL THEN
        RETURN jsonb_build_object(
            'error', true,
            'mensaje', 'Parámetros inválidos'
        );
    END IF;

    -- Verificar si el usuario ya tiene like
    SELECT EXISTS(
        SELECT 1 FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id
    ) INTO user_has_like;
    
    IF user_has_like THEN
        -- Quitar like
        DELETE FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id;
        
        action_taken := 'like_removido';
    ELSE
        -- Dar like
        INSERT INTO comunidad_publicaciones_likes (publicacion_id, usuario_id)
        VALUES (p_publicacion_id, p_usuario_id);
        
        action_taken := 'like_agregado';
    END IF;
    
    -- Contar likes totales
    SELECT COUNT(*) INTO like_count
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id;
    
    -- Verificar estado final
    SELECT EXISTS(
        SELECT 1 FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id
    ) INTO user_has_like;
    
    RETURN jsonb_build_object(
        'error', false,
        'accion', action_taken,
        'tiene_like', user_has_like,
        'total_likes', like_count,
        'publicacion_id', p_publicacion_id,
        'usuario_id', p_usuario_id
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'error', true,
        'mensaje', 'Error: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Crear políticas más simples sin auth.uid()
DROP POLICY IF EXISTS "Permitir ver todos los likes" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Permitir insertar likes a usuarios autenticados" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Permitir eliminar likes propios" ON comunidad_publicaciones_likes;

-- Políticas súper permisivas para testing
CREATE POLICY "Ver likes - permisivo" ON comunidad_publicaciones_likes
    FOR SELECT USING (true);

CREATE POLICY "Insertar likes - permisivo" ON comunidad_publicaciones_likes
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Eliminar likes - permisivo" ON comunidad_publicaciones_likes
    FOR DELETE USING (true);

-- 5. Test de la función sin auth
DO $$
DECLARE
    test_result JSONB;
    test_pub_id UUID;
    test_user_id UUID;
BEGIN
    SELECT id INTO test_pub_id FROM comunidad_publicaciones LIMIT 1;
    SELECT id INTO test_user_id FROM perfiles LIMIT 1;
    
    IF test_pub_id IS NOT NULL AND test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing función sin auth con publicación: % y usuario: %', test_pub_id, test_user_id;
        
        SELECT toggle_like_publicacion_sin_auth(test_pub_id, test_user_id) INTO test_result;
        RAISE NOTICE 'Resultado: %', test_result;
        
        -- Test toggle de nuevo
        SELECT toggle_like_publicacion_sin_auth(test_pub_id, test_user_id) INTO test_result;
        RAISE NOTICE 'Segundo toggle: %', test_result;
    END IF;
END $$;

-- 6. Mensaje final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 FUNCIÓN SIN AUTH CREADA: toggle_like_publicacion_sin_auth';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Esta función no depende de auth.uid()';
    RAISE NOTICE '✅ Políticas súper permisivas aplicadas';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 USA ESTA FUNCIÓN EN EL FRONTEND TEMPORALMENTE:';
    RAISE NOTICE 'supabase.rpc("toggle_like_publicacion_sin_auth", { p_publicacion_id: id, p_usuario_id: usuario.id })';
    RAISE NOTICE '';
END $$; 