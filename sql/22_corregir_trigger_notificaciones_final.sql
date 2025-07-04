-- ============================================
-- CORREGIR TRIGGER DE NOTIFICACIONES FINAL
-- ============================================

-- 1. Eliminar el trigger problemático
DROP TRIGGER IF EXISTS trigger_notificar_comentario_corregido ON comunidad_comentarios;
DROP FUNCTION IF EXISTS notificar_comentario_corregido();

-- 2. Crear función CORREGIDA que use la columna correcta
CREATE OR REPLACE FUNCTION notificar_comentario_definitivo()
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
            descripcion,
            tipo
        INTO publicacion_info
        FROM comunidad_publicaciones 
        WHERE id = NEW.publicacion_id;
        
        -- ✅ USAR LA COLUMNA CORRECTA: NEW.comentario (NO NEW.contenido)
        comentario_texto := LEFT(COALESCE(NEW.comentario, 'comentó'), 100);
        IF LENGTH(COALESCE(NEW.comentario, '')) > 100 THEN
            comentario_texto := comentario_texto || '...';
        END IF;
        
        -- Solo notificar al autor de la publicación (si no es el mismo que comenta)
        IF publicacion_info.usuario_id IS NOT NULL 
           AND publicacion_info.usuario_id != NEW.usuario_id THEN
            
            -- Insertar notificación CORREGIDA
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
                    WHEN publicacion_info.tipo = 'encuesta' THEN 'encuesta'
                    WHEN publicacion_info.tipo = 'imagen' THEN 'foto'
                    ELSE 'publicación'
                END || 
                ': "' || LEFT(COALESCE(publicacion_info.titulo, 'Sin título'), 40) || '..." → ' ||
                '"' || comentario_texto || '"',
                '💬',
                'comunidad',
                'normal',
                '/comunidad#publicacion-' || NEW.publicacion_id::text,
                false,
                false,
                NOW() + INTERVAL '15 days'
            );
            
            RAISE NOTICE '💬 Notificación enviada: % comentó en publicación %', 
                usuario_comentarista.nombre_mostrar, NEW.publicacion_id;
        END IF;
    END IF;
    
    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    -- Si hay cualquier error, no fallar el comentario, solo loggearlo
    RAISE NOTICE '❌ Error en notificación de comentario: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear el trigger CORREGIDO
CREATE TRIGGER trigger_notificar_comentario_definitivo
    AFTER INSERT ON comunidad_comentarios
    FOR EACH ROW
    EXECUTE FUNCTION notificar_comentario_definitivo();

-- ============================================
-- VERIFICAR QUE ESTÁ FUNCIONANDO
-- ============================================

-- Verificar que el trigger se creó correctamente
SELECT 
    event_object_table,
    trigger_name, 
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notificar_comentario_definitivo';

-- Verificar estructura de la tabla comunidad_comentarios
SELECT 
    'COLUMNAS DE comunidad_comentarios' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'comunidad_comentarios' 
AND column_name IN ('comentario', 'contenido')
ORDER BY column_name;

-- ============================================
-- INSTRUCCIONES
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ TRIGGER DE NOTIFICACIONES CORREGIDO:';
    RAISE NOTICE '🔧 Ahora usa NEW.comentario (columna correcta)';
    RAISE NOTICE '🔧 Ya no usa NEW.contenido (columna incorrecta)';
    RAISE NOTICE '🛡️ Incluye manejo de errores para no fallar comentarios';
    RAISE NOTICE '🎯 Prueba comentando para verificar que funciona';
    RAISE NOTICE '';
END $$; 