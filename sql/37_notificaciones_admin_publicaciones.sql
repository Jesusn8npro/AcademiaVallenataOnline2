-- SISTEMA DE NOTIFICACIONES PARA PUBLICACIONES DE ADMIN
-- Cuando un usuario con rol "admin" publica, notifica a todos los demás usuarios

-- 1. CREAR FUNCIÓN PARA NOTIFICAR PUBLICACIONES DE ADMIN
CREATE OR REPLACE FUNCTION notificar_publicacion_admin()
RETURNS TRIGGER AS $$
DECLARE
    usuario_admin RECORD;
    total_notificaciones INTEGER := 0;
BEGIN
    -- Verificar si el usuario que publica es admin
    SELECT p.rol, p.nombre, p.nombre_usuario
    INTO usuario_admin
    FROM perfiles p
    WHERE p.id = NEW.usuario_id;
    
    -- Solo proceder si el usuario es admin
    IF usuario_admin.rol = 'admin' THEN
        -- Insertar notificación para todos los usuarios (excepto el admin que publicó)
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            enlace,
            leida,
            fecha_creacion
        )
        SELECT 
            p.id,
            'publicacion_admin',
            'Nueva publicación del administrador',
            CASE 
                WHEN NEW.titulo IS NOT NULL AND NEW.titulo != '' THEN
                    'El administrador ' || COALESCE(usuario_admin.nombre, usuario_admin.nombre_usuario, 'Admin') || ' publicó: ' || LEFT(NEW.titulo, 50) || CASE WHEN LENGTH(NEW.titulo) > 50 THEN '...' ELSE '' END
                ELSE
                    'El administrador ' || COALESCE(usuario_admin.nombre, usuario_admin.nombre_usuario, 'Admin') || ' hizo una nueva publicación'
            END,
            '/comunidad#publicacion-' || NEW.id::text,
            false,
            NOW()
        FROM perfiles p
        WHERE p.id != NEW.usuario_id  -- Excluir al admin que publicó
        AND p.eliminado IS NOT TRUE;  -- Solo usuarios activos
        
        -- Contar notificaciones enviadas
        GET DIAGNOSTICS total_notificaciones = ROW_COUNT;
        
        RAISE NOTICE 'Notificaciones enviadas por publicación de admin: %', total_notificaciones;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Si hay error, no fallar la publicación
        RAISE WARNING 'Error al enviar notificaciones de admin: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. CREAR TRIGGER PARA PUBLICACIONES DE ADMIN
DROP TRIGGER IF EXISTS trigger_notificar_publicacion_admin ON comunidad_publicaciones;

CREATE TRIGGER trigger_notificar_publicacion_admin
    AFTER INSERT ON comunidad_publicaciones
    FOR EACH ROW
    EXECUTE FUNCTION notificar_publicacion_admin();

-- 3. VERIFICAR QUE EL TRIGGER SE CREÓ
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
AND trigger_name = 'trigger_notificar_publicacion_admin';

-- 4. HACER PRUEBA CON USUARIO ADMIN (si existe)
DO $$
DECLARE
    admin_id UUID;
    test_publicacion_id UUID;
BEGIN
    -- Buscar un usuario admin
    SELECT id INTO admin_id
    FROM perfiles 
    WHERE rol = 'admin' 
    LIMIT 1;
    
    IF admin_id IS NOT NULL THEN
        -- Crear publicación de prueba como admin
        INSERT INTO comunidad_publicaciones (
            usuario_id,
            usuario_nombre,
            usuario_avatar,
            titulo,
            descripcion,
            tipo
        ) VALUES (
            admin_id,
            (SELECT COALESCE(nombre, nombre_usuario, 'Admin') FROM perfiles WHERE id = admin_id),
            'https://ui-avatars.com/api/?name=Admin&background=ff6b6b&color=fff',
            'Prueba Admin',
            'Esta es una prueba de publicación de admin',
            'texto'
        ) RETURNING id INTO test_publicacion_id;
        
        -- Verificar notificaciones creadas
        RAISE NOTICE 'Publicación de prueba creada con ID: %', test_publicacion_id;
        RAISE NOTICE 'Notificaciones creadas: %', (
            SELECT COUNT(*) 
            FROM notificaciones 
            WHERE tipo = 'publicacion_admin' 
            AND mensaje LIKE '%Prueba Admin%'
        );
        
        -- Eliminar la publicación de prueba
        DELETE FROM comunidad_publicaciones WHERE id = test_publicacion_id;
        DELETE FROM notificaciones WHERE tipo = 'publicacion_admin' AND mensaje LIKE '%Prueba Admin%';
        
        RAISE NOTICE 'Prueba completada y limpiada';
    ELSE
        RAISE NOTICE 'No se encontró usuario admin para hacer la prueba';
    END IF;
END $$;

-- 5. MENSAJE FINAL
SELECT 'SISTEMA DE NOTIFICACIONES ADMIN CONFIGURADO' as resultado; 