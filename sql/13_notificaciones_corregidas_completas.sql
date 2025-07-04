-- ============================================
-- NOTIFICACIONES CORREGIDAS Y COMPLETAS
-- ============================================

-- 1. Primero, eliminar los triggers anteriores
DROP TRIGGER IF EXISTS trigger_notificar_comentario_simple ON comunidad_comentarios;
DROP TRIGGER IF EXISTS trigger_notificar_like_simple ON comunidad_publicaciones_likes;

-- 2. Crear función CORREGIDA para notificar comentarios
CREATE OR REPLACE FUNCTION notificar_comentario_corregido()
RETURNS TRIGGER AS $$
DECLARE
    publicacion_info RECORD;
    usuario_comentarista RECORD;
    comentario_texto TEXT;
BEGIN
    -- Solo para nuevos comentarios (INSERT)
    IF TG_OP = 'INSERT' THEN
        
        -- Obtener información COMPLETA del usuario que comenta
        SELECT 
            nombre_completo, 
            nombre_usuario,
            COALESCE(nombre_completo, nombre_usuario, 'Usuario') as nombre_mostrar
        INTO usuario_comentarista
        FROM perfiles 
        WHERE id = NEW.usuario_id;
        
        -- Obtener información COMPLETA de la publicación
        SELECT 
            titulo, 
            usuario_id,
            contenido,
            tipo_publicacion
        INTO publicacion_info
        FROM comunidad_publicaciones 
        WHERE id = NEW.publicacion_id;
        
        -- Obtener el texto del comentario (primeros 100 caracteres)
        comentario_texto := LEFT(COALESCE(NEW.contenido, 'comentó'), 100);
        IF LENGTH(COALESCE(NEW.contenido, '')) > 100 THEN
            comentario_texto := comentario_texto || '...';
        END IF;
        
        -- Solo notificar al autor de la publicación (si no es el mismo que comenta)
        IF publicacion_info.usuario_id IS NOT NULL 
           AND publicacion_info.usuario_id != NEW.usuario_id THEN
            
            -- Insertar notificación MEJORADA
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
                '💬 Nuevo comentario de ' || usuario_comentarista.nombre_mostrar,
                usuario_comentarista.nombre_mostrar || ' comentó en tu ' || 
                CASE 
                    WHEN publicacion_info.tipo_publicacion = 'encuesta' THEN 'encuesta'
                    WHEN publicacion_info.tipo_publicacion = 'imagen' THEN 'foto'
                    ELSE 'publicación'
                END || 
                ': "' || LEFT(COALESCE(publicacion_info.titulo, 'Sin título'), 40) || '..." → ' ||
                '"' || comentario_texto || '"',
                '💬',
                'comunidad',
                'normal',
                '/comunidad#publicacion-' || NEW.publicacion_id::text,  -- ✅ URL específica
                false,
                false,
                NOW() + INTERVAL '15 days'
            );
            
            RAISE NOTICE '💬 Notificación enviada: % comentó en publicación %', 
                usuario_comentarista.nombre_mostrar, NEW.publicacion_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear función CORREGIDA para notificar likes
CREATE OR REPLACE FUNCTION notificar_like_corregido()
RETURNS TRIGGER AS $$
DECLARE
    publicacion_info RECORD;
    usuario_like RECORD;
BEGIN
    -- Solo para nuevos likes (INSERT)
    IF TG_OP = 'INSERT' THEN
        
        -- Obtener información COMPLETA del usuario que dio like
        SELECT 
            nombre_completo, 
            nombre_usuario,
            COALESCE(nombre_completo, nombre_usuario, 'Alguien') as nombre_mostrar
        INTO usuario_like
        FROM perfiles 
        WHERE id = NEW.usuario_id;
        
        -- Obtener información COMPLETA de la publicación
        SELECT 
            titulo, 
            usuario_id,
            tipo_publicacion
        INTO publicacion_info
        FROM comunidad_publicaciones 
        WHERE id = NEW.publicacion_id;
        
        -- Solo notificar al autor de la publicación (si no es el mismo que dio like)
        IF publicacion_info.usuario_id IS NOT NULL 
           AND publicacion_info.usuario_id != NEW.usuario_id THEN
            
            -- Insertar notificación MEJORADA
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
                '👍 A ' || usuario_like.nombre_mostrar || ' le gustó tu ' || 
                CASE 
                    WHEN publicacion_info.tipo_publicacion = 'encuesta' THEN 'encuesta'
                    WHEN publicacion_info.tipo_publicacion = 'imagen' THEN 'foto'
                    ELSE 'publicación'
                END,
                usuario_like.nombre_mostrar || ' le dio like a tu ' || 
                CASE 
                    WHEN publicacion_info.tipo_publicacion = 'encuesta' THEN 'encuesta'
                    WHEN publicacion_info.tipo_publicacion = 'imagen' THEN 'foto'
                    ELSE 'publicación'
                END || 
                ': "' || LEFT(COALESCE(publicacion_info.titulo, 'Sin título'), 50) || 
                CASE WHEN LENGTH(COALESCE(publicacion_info.titulo, '')) > 50 THEN '...' ELSE '' END || '"',
                '👍',
                'comunidad',
                'baja',
                '/comunidad#publicacion-' || NEW.publicacion_id::text,  -- ✅ URL específica
                false,
                false,
                NOW() + INTERVAL '7 days'
            );
            
            RAISE NOTICE '👍 Notificación enviada: % le dio like a publicación %', 
                usuario_like.nombre_mostrar, NEW.publicacion_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Crear los triggers CORREGIDOS
CREATE TRIGGER trigger_notificar_comentario_corregido
    AFTER INSERT ON comunidad_comentarios
    FOR EACH ROW
    EXECUTE FUNCTION notificar_comentario_corregido();

CREATE TRIGGER trigger_notificar_like_corregido
    AFTER INSERT ON comunidad_publicaciones_likes
    FOR EACH ROW
    EXECUTE FUNCTION notificar_like_corregido();

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Verificar que los triggers se crearon correctamente
SELECT 
    event_object_table,
    trigger_name, 
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name LIKE '%corregido%'
ORDER BY event_object_table;

-- Probar que los datos de perfiles se pueden obtener correctamente
SELECT 
    id,
    nombre_completo,
    nombre_usuario,
    COALESCE(nombre_completo, nombre_usuario, 'Usuario Anónimo') as nombre_mostrar
FROM perfiles 
LIMIT 3;

-- ============================================
-- INSTRUCCIONES
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ NOTIFICACIONES CORREGIDAS Y MEJORADAS:';
    RAISE NOTICE '👤 Ahora muestra el NOMBRE REAL del usuario (no "JESUS")';
    RAISE NOTICE '🎯 El enlace va directo a la publicación específica';
    RAISE NOTICE '📝 Muestra el CONTENIDO del comentario';
    RAISE NOTICE '🏷️ Identifica el TIPO de publicación (encuesta, foto, etc.)';
    RAISE NOTICE '🚀 Prueba comentando para verificar las mejoras';
END $$; 