-- ============================================
-- SISTEMA DE NOTIFICACIONES SIMPLE Y FUNCIONAL
-- ============================================

-- 1. Crear función simple para notificar comentarios
CREATE OR REPLACE FUNCTION notificar_comentario_simple()
RETURNS TRIGGER AS $$
DECLARE
    publicacion_info RECORD;
    usuario_comentarista RECORD;
BEGIN
    -- Solo para nuevos comentarios (INSERT)
    IF TG_OP = 'INSERT' THEN
        
        -- Obtener información básica del usuario que comenta
        SELECT nombre_completo, nombre_usuario
        INTO usuario_comentarista
        FROM perfiles 
        WHERE id = NEW.usuario_id;
        
        -- Obtener información básica de la publicación
        SELECT titulo, usuario_id
        INTO publicacion_info
        FROM comunidad_publicaciones 
        WHERE id = NEW.publicacion_id;
        
        -- Solo notificar al autor de la publicación (si no es el mismo que comenta)
        IF publicacion_info.usuario_id IS NOT NULL 
           AND publicacion_info.usuario_id != NEW.usuario_id THEN
            
            -- Insertar notificación simple
            INSERT INTO notificaciones (
                usuario_id,
                tipo,
                titulo,
                mensaje,
                icono,
                categoria,
                prioridad,
                url_accion,
                leida,
                archivada,
                fecha_expiracion
            )
            VALUES (
                publicacion_info.usuario_id,
                'nuevo_comentario',
                '💬 Nuevo comentario',
                COALESCE(usuario_comentarista.nombre_completo, usuario_comentarista.nombre_usuario, 'Alguien') || 
                ' comentó en tu publicación: "' || 
                LEFT(publicacion_info.titulo, 50) || 
                CASE WHEN LENGTH(publicacion_info.titulo) > 50 THEN '...' ELSE '' END || '"',
                '💬',
                'comunidad',
                'normal',  -- ✅ Usar 'normal' que sabemos que funciona
                '/comunidad',
                false,
                false,
                NOW() + INTERVAL '15 days'
            );
            
            RAISE NOTICE '💬 Notificación enviada por comentario';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Crear el trigger para comentarios
CREATE TRIGGER trigger_notificar_comentario_simple
    AFTER INSERT ON comunidad_comentarios
    FOR EACH ROW
    EXECUTE FUNCTION notificar_comentario_simple();

-- ============================================
-- FUNCIÓN SIMPLE PARA LIKES (OPCIONAL)
-- ============================================

-- 3. Crear función simple para notificar likes
CREATE OR REPLACE FUNCTION notificar_like_simple()
RETURNS TRIGGER AS $$
DECLARE
    publicacion_info RECORD;
    usuario_like RECORD;
BEGIN
    -- Solo para nuevos likes (INSERT)
    IF TG_OP = 'INSERT' THEN
        
        -- Obtener información básica del usuario que dio like
        SELECT nombre_completo, nombre_usuario
        INTO usuario_like
        FROM perfiles 
        WHERE id = NEW.usuario_id;
        
        -- Obtener información básica de la publicación
        SELECT titulo, usuario_id
        INTO publicacion_info
        FROM comunidad_publicaciones 
        WHERE id = NEW.publicacion_id;
        
        -- Solo notificar al autor de la publicación (si no es el mismo que dio like)
        IF publicacion_info.usuario_id IS NOT NULL 
           AND publicacion_info.usuario_id != NEW.usuario_id THEN
            
            -- Insertar notificación simple
            INSERT INTO notificaciones (
                usuario_id,
                tipo,
                titulo,
                mensaje,
                icono,
                categoria,
                prioridad,
                url_accion,
                leida,
                archivada,
                fecha_expiracion
            )
            VALUES (
                publicacion_info.usuario_id,
                'like_recibido',
                '👍 Te dieron like',
                'A ' || COALESCE(usuario_like.nombre_completo, usuario_like.nombre_usuario, 'alguien') || 
                ' le gustó tu publicación: "' || 
                LEFT(publicacion_info.titulo, 50) || 
                CASE WHEN LENGTH(publicacion_info.titulo) > 50 THEN '...' ELSE '' END || '"',
                '👍',
                'comunidad',
                'baja',  -- ✅ Usar 'baja' que sabemos que funciona
                '/comunidad',
                false,
                false,
                NOW() + INTERVAL '7 days'
            );
            
            RAISE NOTICE '👍 Notificación enviada por like';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Crear el trigger para likes
CREATE TRIGGER trigger_notificar_like_simple
    AFTER INSERT ON comunidad_comentarios_likes
    FOR EACH ROW
    EXECUTE FUNCTION notificar_like_simple();

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

-- Verificar que los triggers se crearon correctamente
SELECT 
    event_object_table,
    trigger_name, 
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name IN ('trigger_notificar_comentario_simple', 'trigger_notificar_like_simple')
ORDER BY event_object_table;

-- ============================================
-- INSTRUCCIONES
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ SISTEMA DE NOTIFICACIONES SIMPLE CONFIGURADO:';
    RAISE NOTICE '💬 Los autores recibirán notificaciones cuando comenten en sus publicaciones';
    RAISE NOTICE '👍 Los autores recibirán notificaciones cuando den like a sus publicaciones';
    RAISE NOTICE '🚀 Prueba comentando para verificar que llegan las notificaciones';
END $$; 