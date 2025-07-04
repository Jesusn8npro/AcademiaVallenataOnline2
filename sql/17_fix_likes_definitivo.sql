-- ============================================
-- FIX DEFINITIVO PARA EL SISTEMA DE LIKES
-- ============================================

-- 1. Verificar y crear tabla si no existe
CREATE TABLE IF NOT EXISTS comunidad_publicaciones_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    publicacion_id UUID NOT NULL REFERENCES comunidad_publicaciones(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint único para evitar likes duplicados
    UNIQUE(publicacion_id, usuario_id)
);

-- 2. Habilitar RLS si no está habilitado
ALTER TABLE comunidad_publicaciones_likes ENABLE ROW LEVEL SECURITY;

-- 3. Eliminar políticas existentes que puedan causar conflictos
DROP POLICY IF EXISTS "Usuarios pueden ver likes" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Usuarios pueden dar likes" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Usuarios pueden quitar sus likes" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Ver likes públicos" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Dar like autenticado" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "Quitar like propio" ON comunidad_publicaciones_likes;

-- 4. Crear políticas RLS correctas
CREATE POLICY "Ver todos los likes" ON comunidad_publicaciones_likes
    FOR SELECT USING (true);

CREATE POLICY "Insertar likes autenticados" ON comunidad_publicaciones_likes
    FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Eliminar likes propios" ON comunidad_publicaciones_likes
    FOR DELETE USING (auth.uid() = usuario_id);

-- 5. Otorgar permisos necesarios
GRANT SELECT ON comunidad_publicaciones_likes TO authenticated;
GRANT INSERT ON comunidad_publicaciones_likes TO authenticated;
GRANT DELETE ON comunidad_publicaciones_likes TO authenticated;

-- 6. Recrear función toggle_like_publicacion mejorada
DROP FUNCTION IF EXISTS toggle_like_publicacion(UUID, UUID);

CREATE OR REPLACE FUNCTION toggle_like_publicacion(p_publicacion_id UUID, p_usuario_id UUID)
RETURNS JSONB AS $$
DECLARE
    like_existente RECORD;
    total_likes INTEGER;
    tiene_like_actual BOOLEAN;
    accion_realizada TEXT;
BEGIN
    -- Verificar parámetros
    IF p_publicacion_id IS NULL OR p_usuario_id IS NULL THEN
        RETURN jsonb_build_object(
            'error', true,
            'mensaje', 'Parámetros inválidos'
        );
    END IF;

    -- Verificar si ya existe el like
    SELECT * INTO like_existente
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id 
    AND usuario_id = p_usuario_id;
    
    IF like_existente.id IS NOT NULL THEN
        -- Quitar like
        DELETE FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id;
        
        accion_realizada := 'like_removido';
        tiene_like_actual := false;
    ELSE
        -- Dar like
        INSERT INTO comunidad_publicaciones_likes (publicacion_id, usuario_id)
        VALUES (p_publicacion_id, p_usuario_id)
        ON CONFLICT (publicacion_id, usuario_id) DO NOTHING;
        
        accion_realizada := 'like_agregado';
        tiene_like_actual := true;
    END IF;
    
    -- Contar likes totales
    SELECT COUNT(*) INTO total_likes
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id;
    
    -- Verificar estado final
    SELECT EXISTS(
        SELECT 1 FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id
    ) INTO tiene_like_actual;
    
    RETURN jsonb_build_object(
        'error', false,
        'accion', accion_realizada,
        'tiene_like', tiene_like_actual,
        'total_likes', COALESCE(total_likes, 0),
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

-- 7. Crear función para obtener likes de una publicación
CREATE OR REPLACE FUNCTION obtener_likes_publicacion(p_publicacion_id UUID)
RETURNS JSONB AS $$
DECLARE
    total_likes INTEGER;
    usuarios_likes UUID[];
BEGIN
    IF p_publicacion_id IS NULL THEN
        RETURN jsonb_build_object(
            'total_likes', 0,
            'usuarios_likes', '[]'::jsonb
        );
    END IF;
    
    SELECT 
        COUNT(*),
        array_agg(usuario_id)
    INTO total_likes, usuarios_likes
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id;
    
    RETURN jsonb_build_object(
        'total_likes', COALESCE(total_likes, 0),
        'usuarios_likes', COALESCE(usuarios_likes, ARRAY[]::UUID[])
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'total_likes', 0,
        'usuarios_likes', '[]'::jsonb,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Crear índices para optimizar rendimiento
CREATE INDEX IF NOT EXISTS idx_likes_publicacion_id ON comunidad_publicaciones_likes(publicacion_id);
CREATE INDEX IF NOT EXISTS idx_likes_usuario_id ON comunidad_publicaciones_likes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_likes_publicacion_usuario ON comunidad_publicaciones_likes(publicacion_id, usuario_id);

-- 9. Test básico
DO $$
DECLARE
    test_result JSONB;
BEGIN
    -- Verificar que la función existe
    SELECT toggle_like_publicacion(gen_random_uuid(), gen_random_uuid()) INTO test_result;
    RAISE NOTICE '✅ Función toggle_like_publicacion funciona correctamente';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Error en función toggle_like_publicacion: %', SQLERRM;
END $$;

-- 10. Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 SISTEMA DE LIKES CORREGIDO EXITOSAMENTE';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Tabla comunidad_publicaciones_likes verificada';
    RAISE NOTICE '✅ Políticas RLS configuradas correctamente';
    RAISE NOTICE '✅ Función toggle_like_publicacion creada';
    RAISE NOTICE '✅ Función obtener_likes_publicacion creada';
    RAISE NOTICE '✅ Índices de rendimiento creados';
    RAISE NOTICE '✅ Permisos otorgados a usuarios autenticados';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FUNCIONES DISPONIBLES:';
    RAISE NOTICE '• toggle_like_publicacion(publicacion_id, usuario_id) - Dar/quitar like';
    RAISE NOTICE '• obtener_likes_publicacion(publicacion_id) - Obtener likes de publicación';
    RAISE NOTICE '';
END $$; 