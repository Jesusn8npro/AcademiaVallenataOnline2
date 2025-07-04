-- ============================================
-- NOTIFICACIONES DE PUBLICACIONES DE ADMIN
-- ============================================

-- 1. Crear función para notificar nueva publicación de admin
CREATE OR REPLACE FUNCTION notificar_publicacion_admin()
RETURNS TRIGGER AS $$
DECLARE
    admin_info RECORD;
    usuario_receptor RECORD;
    total_notificados INTEGER := 0;
BEGIN
    -- Solo para nuevas publicaciones (INSERT)
    IF TG_OP = 'INSERT' THEN
        
        -- Obtener información del usuario que publica
        SELECT 
            p.nombre_completo,
            p.rol,
            p.url_foto_perfil
        INTO admin_info
        FROM perfiles p 
        WHERE p.id = NEW.usuario_id;
        
        -- Solo procesar si es admin o superadmin
        IF admin_info.rol IN ('admin', 'superadmin') THEN
            
            -- Notificar a todos los usuarios (excepto al que publica)
            FOR usuario_receptor IN 
                SELECT id, nombre_completo 
                FROM perfiles 
                WHERE id != NEW.usuario_id 
                AND eliminado = false
                AND rol != 'admin'  -- No notificar a otros admins
                AND rol != 'superadmin'
            LOOP
                BEGIN
                    -- Crear notificación para cada usuario
                    INSERT INTO notificaciones (
                        usuario_id,
                        tipo,
                        titulo,
                        mensaje,
                        icono,
                        categoria,
                        prioridad,
                        leida,
                        archivada,
                        url_accion,
                        entidad_id,
                        entidad_tipo,
                        datos_adicionales
                    ) VALUES (
                        usuario_receptor.id,
                        'nueva_publicacion_admin',
                        '📢 Nueva publicación de ' || COALESCE(admin_info.nombre_completo, 'Administrador'),
                        '¡Hay contenido nuevo en la comunidad! "' || LEFT(NEW.titulo, 100) || '"',
                        '🎯',
                        'comunidad',
                        'alta',
                        false,
                        false,
                        '/comunidad#publicacion-' || NEW.id::text,
                        NEW.id,
                        'publicacion',
                        jsonb_build_object(
                            'publicacion_id', NEW.id,
                            'admin_nombre', admin_info.nombre_completo,
                            'admin_avatar', admin_info.url_foto_perfil,
                            'tipo_publicacion', NEW.tipo,
                            'timestamp', NOW()
                        )
                    );
                    
                    total_notificados := total_notificados + 1;
                    
                EXCEPTION WHEN OTHERS THEN
                    -- Si falla una notificación, continuar con las demás
                    RAISE NOTICE 'Error al crear notificación para usuario %: %', usuario_receptor.id, SQLERRM;
                END;
            END LOOP;
            
            RAISE NOTICE '✅ Notificación de publicación admin enviada a % usuarios', total_notificados;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Crear trigger para publicaciones de admin
DROP TRIGGER IF EXISTS trigger_notificar_publicacion_admin ON comunidad_publicaciones;

CREATE TRIGGER trigger_notificar_publicacion_admin
    AFTER INSERT ON comunidad_publicaciones
    FOR EACH ROW
    EXECUTE FUNCTION notificar_publicacion_admin();

-- 3. Verificar que el trigger se creó correctamente
SELECT 'TRIGGER CREADO EXITOSAMENTE' as estado;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
AND trigger_name = 'trigger_notificar_publicacion_admin';

-- 4. Mostrar información sobre admins existentes
SELECT 'ADMINISTRADORES EN EL SISTEMA:' as info;
SELECT 
    nombre_completo,
    rol,
    correo_electronico,
    fecha_creacion
FROM perfiles 
WHERE rol IN ('admin', 'superadmin')
ORDER BY fecha_creacion; 