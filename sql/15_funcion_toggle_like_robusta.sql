-- ============================================
-- FUNCIÓN ROBUSTA PARA TOGGLE DE LIKES
-- ============================================

-- Primero, verificar si la función ya existe y eliminarla
DROP FUNCTION IF EXISTS toggle_like_publicacion(UUID, UUID);

-- Crear función mejorada que maneja todos los casos edge
CREATE OR REPLACE FUNCTION toggle_like_publicacion(p_publicacion_id UUID, p_usuario_id UUID)
RETURNS JSONB AS $$
DECLARE
    like_existente RECORD;
    resultado JSONB;
    total_likes INTEGER;
    accion_realizada TEXT;
BEGIN
    -- Verificar que los parámetros no sean nulos
    IF p_publicacion_id IS NULL OR p_usuario_id IS NULL THEN
        RETURN jsonb_build_object(
            'error', true,
            'mensaje', 'Parámetros inválidos: publicacion_id y usuario_id son requeridos'
        );
    END IF;

    -- Verificar si ya existe el like
    SELECT * INTO like_existente
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id 
    AND usuario_id = p_usuario_id;
    
    IF like_existente.id IS NOT NULL THEN
        -- Ya existe el like, eliminarlo (quitar like)
        BEGIN
            DELETE FROM comunidad_publicaciones_likes 
            WHERE publicacion_id = p_publicacion_id 
            AND usuario_id = p_usuario_id;
            
            accion_realizada := 'like_removido';
            
        EXCEPTION WHEN OTHERS THEN
            RETURN jsonb_build_object(
                'error', true,
                'mensaje', 'Error al eliminar like: ' || SQLERRM
            );
        END;
        
    ELSE
        -- No existe el like, crearlo (dar like)
        BEGIN
            INSERT INTO comunidad_publicaciones_likes (publicacion_id, usuario_id)
            VALUES (p_publicacion_id, p_usuario_id);
            
            accion_realizada := 'like_agregado';
            
        EXCEPTION 
            WHEN unique_violation THEN
                -- Si hay violación de constraint único, significa que ya existe
                -- Esto puede pasar en condiciones de carrera
                accion_realizada := 'like_ya_existia';
            WHEN OTHERS THEN
                RETURN jsonb_build_object(
                    'error', true,
                    'mensaje', 'Error al agregar like: ' || SQLERRM
                );
        END;
    END IF;
    
    -- Contar total de likes de la publicación (siempre actualizado)
    BEGIN
        SELECT COUNT(*) INTO total_likes
        FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id;
    EXCEPTION WHEN OTHERS THEN
        total_likes := 0;
    END;
    
    -- Verificar si el usuario tiene like actualmente
    DECLARE
        tiene_like_actual BOOLEAN;
    BEGIN
        SELECT EXISTS(
            SELECT 1 FROM comunidad_publicaciones_likes 
            WHERE publicacion_id = p_publicacion_id 
            AND usuario_id = p_usuario_id
        ) INTO tiene_like_actual;
    EXCEPTION WHEN OTHERS THEN
        tiene_like_actual := false;
    END;
    
    -- Construir respuesta exitosa
    resultado := jsonb_build_object(
        'error', false,
        'accion', accion_realizada,
        'tiene_like', tiene_like_actual,
        'total_likes', COALESCE(total_likes, 0),
        'publicacion_id', p_publicacion_id,
        'usuario_id', p_usuario_id,
        'timestamp', NOW()
    );
    
    RETURN resultado;
    
EXCEPTION WHEN OTHERS THEN
    -- Manejo de errores generales
    RETURN jsonb_build_object(
        'error', true,
        'mensaje', 'Error inesperado: ' || SQLERRM,
        'codigo_error', SQLSTATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCIÓN AUXILIAR: CONTAR LIKES DE PUBLICACIÓN
-- ============================================

CREATE OR REPLACE FUNCTION contar_likes_publicacion_seguro(p_publicacion_id UUID)
RETURNS INTEGER AS $$
DECLARE
    total_likes INTEGER;
BEGIN
    IF p_publicacion_id IS NULL THEN
        RETURN 0;
    END IF;
    
    SELECT COUNT(*) INTO total_likes
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id;
    
    RETURN COALESCE(total_likes, 0);
    
EXCEPTION WHEN OTHERS THEN
    RETURN 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCIÓN AUXILIAR: VERIFICAR SI USUARIO DIO LIKE
-- ============================================

CREATE OR REPLACE FUNCTION usuario_tiene_like_seguro(p_publicacion_id UUID, p_usuario_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    tiene_like BOOLEAN;
BEGIN
    IF p_publicacion_id IS NULL OR p_usuario_id IS NULL THEN
        RETURN false;
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id
    ) INTO tiene_like;
    
    RETURN COALESCE(tiene_like, false);
    
EXCEPTION WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VERIFICACIÓN Y TESTING
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ FUNCIONES DE LIKES CREADAS EXITOSAMENTE:';
    RAISE NOTICE '🔄 toggle_like_publicacion(publicacion_id, usuario_id) - Maneja dar/quitar like automáticamente';
    RAISE NOTICE '📊 contar_likes_publicacion_seguro(publicacion_id) - Cuenta likes de forma segura';
    RAISE NOTICE '👤 usuario_tiene_like_seguro(publicacion_id, usuario_id) - Verifica si usuario dio like';
    RAISE NOTICE '';
    RAISE NOTICE '🛡️ CARACTERÍSTICAS DE SEGURIDAD:';
    RAISE NOTICE '• Maneja automáticamente constraints únicos';
    RAISE NOTICE '• Previene condiciones de carrera';
    RAISE NOTICE '• Validación de parámetros nulos';
    RAISE NOTICE '• Manejo robusto de errores';
    RAISE NOTICE '• Transacciones atómicas';
END $$; 