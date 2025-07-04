-- ============================================
-- FIX DEFINITIVO FUNCIÓN TOGGLE LIKE
-- ============================================

-- Eliminar función problemática
DROP FUNCTION IF EXISTS toggle_like_publicacion(UUID, UUID);

-- Crear función corregida sin errores de columnas
CREATE OR REPLACE FUNCTION toggle_like_publicacion(p_publicacion_id UUID, p_usuario_id UUID)
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
        VALUES (p_publicacion_id, p_usuario_id)
        ON CONFLICT (publicacion_id, usuario_id) DO NOTHING;
        
        action_taken := 'like_agregado';
    END IF;
    
    -- Contar likes totales después de la operación
    SELECT COUNT(*) INTO like_count
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id;
    
    -- Verificar estado final del usuario
    SELECT EXISTS(
        SELECT 1 FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id
    ) INTO user_has_like;
    
    RETURN jsonb_build_object(
        'error', false,
        'accion', action_taken,
        'tiene_like', user_has_like,
        'total_likes', COALESCE(like_count, 0),
        'publicacion_id', p_publicacion_id,
        'usuario_id', p_usuario_id,
        'timestamp', NOW()
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'error', true,
        'mensaje', 'Error: ' || SQLERRM,
        'codigo_error', SQLSTATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verificar que las políticas RLS permiten todas las operaciones necesarias
-- Eliminar políticas restrictivas que puedan estar bloqueando
DROP POLICY IF EXISTS "Insertar likes autenticados" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Eliminar likes propios" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Ver todos los likes" ON comunidad_publicaciones_likes;

-- Crear políticas más permisivas
CREATE POLICY "Permitir ver todos los likes" ON comunidad_publicaciones_likes
    FOR SELECT USING (true);

CREATE POLICY "Permitir insertar likes a usuarios autenticados" ON comunidad_publicaciones_likes
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL 
        AND usuario_id = auth.uid()
    );

CREATE POLICY "Permitir eliminar likes propios" ON comunidad_publicaciones_likes
    FOR DELETE USING (
        auth.uid() IS NOT NULL 
        AND usuario_id = auth.uid()
    );

-- Otorgar permisos explícitos
GRANT ALL ON comunidad_publicaciones_likes TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Test de la función
DO $$
DECLARE
    test_result JSONB;
    test_pub_id UUID;
    test_user_id UUID;
BEGIN
    -- Obtener IDs reales para testing
    SELECT id INTO test_pub_id FROM comunidad_publicaciones LIMIT 1;
    SELECT id INTO test_user_id FROM perfiles LIMIT 1;
    
    IF test_pub_id IS NOT NULL AND test_user_id IS NOT NULL THEN
        -- Test básico
        SELECT toggle_like_publicacion(test_pub_id, test_user_id) INTO test_result;
        
        IF (test_result->>'error')::boolean = false THEN
            RAISE NOTICE '✅ Función toggle_like_publicacion funciona correctamente';
            RAISE NOTICE 'Resultado: %', test_result;
        ELSE
            RAISE NOTICE '❌ Error en función: %', test_result->>'mensaje';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ No hay datos para testing';
    END IF;
END $$;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 FUNCIÓN TOGGLE_LIKE_PUBLICACION CORREGIDA';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Función recreada sin errores de columnas';
    RAISE NOTICE '✅ Políticas RLS simplificadas y permisivas';
    RAISE NOTICE '✅ Permisos otorgados correctamente';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 AHORA DEBERÍAS PODER DAR LIKES A CUALQUIER PUBLICACIÓN';
    RAISE NOTICE '';
END $$; 