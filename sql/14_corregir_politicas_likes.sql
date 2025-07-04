-- ============================================
-- CORREGIR POLÍTICAS RLS PARA LIKES
-- ============================================

-- 1. ELIMINAR TODAS LAS POLÍTICAS DUPLICADAS DE LIKES
DROP POLICY IF EXISTS "insert_own_like" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "delete_own_like" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "select_likes" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "likes_insert_policy" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "likes_delete_policy" ON comunidad_publicaciones_likes;
DROP POLICY IF EXISTS "likes_select_policy" ON comunidad_publicaciones_likes;

-- 2. CREAR POLÍTICAS SIMPLES Y FUNCIONALES PARA LIKES
-- Política para VER likes (todos pueden ver)
CREATE POLICY "ver_todos_los_likes" ON comunidad_publicaciones_likes
    FOR SELECT USING (true);

-- Política para DAR likes (usuarios autenticados pueden dar like)
CREATE POLICY "dar_like_autenticado" ON comunidad_publicaciones_likes
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
        AND usuario_id = auth.uid()
    );

-- Política para QUITAR likes (solo quitar tus propios likes)
CREATE POLICY "quitar_propio_like" ON comunidad_publicaciones_likes
    FOR DELETE USING (
        usuario_id = auth.uid()
    );

-- ============================================
-- VERIFICAR QUE SOLO TENEMOS LAS POLÍTICAS CORRECTAS
-- ============================================

-- Mostrar las políticas actuales para likes
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'comunidad_publicaciones_likes'
ORDER BY cmd, policyname;

-- ============================================
-- VERIFICAR ESTRUCTURA DE LA TABLA LIKES
-- ============================================

-- Asegurar que la tabla tiene los campos correctos
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'comunidad_publicaciones_likes'
ORDER BY ordinal_position;

-- ============================================
-- FUNCIÓN PARA MANEJAR LIKES (TOGGLE)
-- ============================================

-- Crear función para dar/quitar like de manera inteligente
CREATE OR REPLACE FUNCTION toggle_like_publicacion(p_publicacion_id UUID, p_usuario_id UUID)
RETURNS JSONB AS $$
DECLARE
    like_existente RECORD;
    resultado JSONB;
BEGIN
    -- Verificar si ya existe el like
    SELECT * INTO like_existente
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id 
    AND usuario_id = p_usuario_id;
    
    IF like_existente.id IS NOT NULL THEN
        -- Si existe, eliminarlo (quitar like)
        DELETE FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id;
        
        resultado := jsonb_build_object(
            'accion', 'like_removido',
            'mensaje', 'Like eliminado correctamente',
            'tiene_like', false
        );
    ELSE
        -- Si no existe, crearlo (dar like)
        INSERT INTO comunidad_publicaciones_likes (publicacion_id, usuario_id)
        VALUES (p_publicacion_id, p_usuario_id);
        
        resultado := jsonb_build_object(
            'accion', 'like_agregado',
            'mensaje', 'Like agregado correctamente',
            'tiene_like', true
        );
    END IF;
    
    -- Contar total de likes de la publicación
    resultado := resultado || jsonb_build_object(
        'total_likes', (
            SELECT COUNT(*) 
            FROM comunidad_publicaciones_likes 
            WHERE publicacion_id = p_publicacion_id
        )
    );
    
    RETURN resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCIÓN PARA CONTAR LIKES DE UNA PUBLICACIÓN
-- ============================================

CREATE OR REPLACE FUNCTION contar_likes_publicacion(p_publicacion_id UUID)
RETURNS INTEGER AS $$
DECLARE
    total_likes INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_likes
    FROM comunidad_publicaciones_likes 
    WHERE publicacion_id = p_publicacion_id;
    
    RETURN COALESCE(total_likes, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCIÓN PARA VERIFICAR SI USUARIO DIO LIKE
-- ============================================

CREATE OR REPLACE FUNCTION usuario_dio_like(p_publicacion_id UUID, p_usuario_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    tiene_like BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM comunidad_publicaciones_likes 
        WHERE publicacion_id = p_publicacion_id 
        AND usuario_id = p_usuario_id
    ) INTO tiene_like;
    
    RETURN COALESCE(tiene_like, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- INSTRUCCIONES FINALES
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ POLÍTICAS DE LIKES CORREGIDAS:';
    RAISE NOTICE '👍 Todos los usuarios autenticados pueden dar like';
    RAISE NOTICE '👁️ Todos pueden ver los likes';
    RAISE NOTICE '🗑️ Solo puedes quitar tus propios likes';
    RAISE NOTICE '🔧 Funciones auxiliares creadas: toggle_like_publicacion(), contar_likes_publicacion(), usuario_dio_like()';
    RAISE NOTICE '🚀 Prueba dando like a una publicación para verificar que funciona';
END $$; 