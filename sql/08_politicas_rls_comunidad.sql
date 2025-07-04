-- ============================================
-- POLÍTICAS RLS PARA SISTEMA DE COMUNIDAD (CORREGIDAS)
-- ============================================

-- Primero, eliminar las políticas existentes si existen
DROP POLICY IF EXISTS "publicaciones_select_policy" ON comunidad_publicaciones;
DROP POLICY IF EXISTS "publicaciones_insert_policy" ON comunidad_publicaciones;
DROP POLICY IF EXISTS "publicaciones_update_policy" ON comunidad_publicaciones;
DROP POLICY IF EXISTS "publicaciones_delete_policy" ON comunidad_publicaciones;

DROP POLICY IF EXISTS "comentarios_select_policy" ON comunidad_comentarios;
DROP POLICY IF EXISTS "comentarios_insert_policy" ON comunidad_comentarios;
DROP POLICY IF EXISTS "comentarios_update_policy" ON comunidad_comentarios;
DROP POLICY IF EXISTS "comentarios_delete_policy" ON comunidad_comentarios;

DROP POLICY IF EXISTS "likes_select_policy" ON comunidad_comentarios_likes;
DROP POLICY IF EXISTS "likes_insert_policy" ON comunidad_comentarios_likes;
DROP POLICY IF EXISTS "likes_delete_policy" ON comunidad_comentarios_likes;

-- Habilitar RLS en las tablas de comunidad
ALTER TABLE comunidad_publicaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE comunidad_comentarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE comunidad_comentarios_likes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLÍTICAS PARA COMUNIDAD_PUBLICACIONES (CORREGIDAS)
-- ============================================

-- Ver publicaciones: TODOS pueden ver publicaciones activas
CREATE POLICY "publicaciones_select_policy" ON comunidad_publicaciones
    FOR SELECT USING (
        estado = 'activo'
        OR auth.uid() IS NOT NULL
    );

-- Crear publicaciones: TODOS los usuarios autenticados pueden publicar
CREATE POLICY "publicaciones_insert_policy" ON comunidad_publicaciones
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
        AND usuario_id = auth.uid()
    );

-- Actualizar publicaciones: solo el autor o admin
CREATE POLICY "publicaciones_update_policy" ON comunidad_publicaciones
    FOR UPDATE USING (
        usuario_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
    );

-- Eliminar publicaciones: solo el autor o admin
CREATE POLICY "publicaciones_delete_policy" ON comunidad_publicaciones
    FOR DELETE USING (
        usuario_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
    );

-- ============================================
-- POLÍTICAS PARA COMUNIDAD_COMENTARIOS (CORREGIDAS)
-- ============================================

-- Ver comentarios: TODOS pueden ver comentarios de publicaciones activas
CREATE POLICY "comentarios_select_policy" ON comunidad_comentarios
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM comunidad_publicaciones cp
            WHERE cp.id = publicacion_id
            AND cp.estado = 'activo'
        )
    );

-- Crear comentarios: TODOS los usuarios autenticados pueden comentar en publicaciones activas
CREATE POLICY "comentarios_insert_policy" ON comunidad_comentarios
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
        AND usuario_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM comunidad_publicaciones cp
            WHERE cp.id = publicacion_id
            AND cp.estado = 'activo'
        )
    );

-- Actualizar comentarios: solo el autor o admin
CREATE POLICY "comentarios_update_policy" ON comunidad_comentarios
    FOR UPDATE USING (
        usuario_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
    );

-- Eliminar comentarios: solo el autor o admin
CREATE POLICY "comentarios_delete_policy" ON comunidad_comentarios
    FOR DELETE USING (
        usuario_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM perfiles 
            WHERE id = auth.uid() 
            AND rol = 'admin'
        )
    );

-- ============================================
-- POLÍTICAS PARA COMUNIDAD_COMENTARIOS_LIKES (CORREGIDAS)
-- ============================================

-- Ver likes: TODOS pueden ver
CREATE POLICY "likes_select_policy" ON comunidad_comentarios_likes
    FOR SELECT USING (true);

-- Crear likes: usuarios autenticados
CREATE POLICY "likes_insert_policy" ON comunidad_comentarios_likes
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
        AND usuario_id = auth.uid()
    );

-- Eliminar likes: solo el usuario que lo creó
CREATE POLICY "likes_delete_policy" ON comunidad_comentarios_likes
    FOR DELETE USING (
        usuario_id = auth.uid()
    );

-- ============================================
-- CORREGIR LA FUNCIÓN crearNotificacion
-- ============================================

-- Verificar si existe la tabla notificaciones y sus columnas
DO $$ 
BEGIN
    -- Verificar si la columna entidad_id existe en notificaciones
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notificaciones' 
        AND column_name = 'entidad_id'
    ) THEN
        -- Si no existe, agregarla como opcional
        ALTER TABLE notificaciones ADD COLUMN entidad_id UUID NULL;
    END IF;
END $$;

-- ============================================
-- FUNCIONES ÚTILES PARA COMUNIDAD (ACTUALIZADAS)
-- ============================================

-- Función para obtener comentarios de una publicación (sin restricciones adicionales)
CREATE OR REPLACE FUNCTION obtener_comentarios_publicacion(p_publicacion_id UUID)
RETURNS TABLE (
    id UUID,
    publicacion_id UUID,
    usuario_id UUID,
    usuario_nombre TEXT,
    usuario_avatar TEXT,
    comentario TEXT,
    fecha_creacion TIMESTAMP WITH TIME ZONE,
    comentario_padre_id UUID
) 
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cc.id,
        cc.publicacion_id,
        cc.usuario_id,
        cc.usuario_nombre,
        cc.usuario_avatar,
        cc.comentario,
        cc.fecha_creacion,
        cc.comentario_padre_id
    FROM comunidad_comentarios cc
    JOIN comunidad_publicaciones cp ON cp.id = cc.publicacion_id
    WHERE cc.publicacion_id = p_publicacion_id
    AND cp.estado = 'activo'
    ORDER BY cc.fecha_creacion ASC;
END;
$$ LANGUAGE plpgsql;

-- Función para contar comentarios de una publicación
CREATE OR REPLACE FUNCTION contar_comentarios_publicacion(p_publicacion_id UUID)
RETURNS INTEGER 
SECURITY DEFINER
AS $$
DECLARE
    total_comentarios INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO total_comentarios
    FROM comunidad_comentarios cc
    JOIN comunidad_publicaciones cp ON cp.id = cc.publicacion_id
    WHERE cc.publicacion_id = p_publicacion_id
    AND cp.estado = 'activo';
    
    RETURN COALESCE(total_comentarios, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VERIFICAR CONFIGURACIÓN
-- ============================================

-- Verificar que las políticas estén activas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('comunidad_publicaciones', 'comunidad_comentarios', 'comunidad_comentarios_likes')
ORDER BY tablename, policyname; 