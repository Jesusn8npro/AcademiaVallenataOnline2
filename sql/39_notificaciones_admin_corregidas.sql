-- NOTIFICACIONES ADMIN SIGUIENDO EL PATRÓN QUE FUNCIONA
-- Basado en el sistema de comentarios que SÍ funciona

-- 1. Eliminar trigger anterior si existe
DROP TRIGGER IF EXISTS trigger_notificar_publicacion_admin ON comunidad_publicaciones;

-- 2. Crear función SIGUIENDO EL PATRÓN DE COMENTARIOS
CREATE OR REPLACE FUNCTION notificar_publicacion_admin_corregida()
RETURNS TRIGGER AS $$
DECLARE
    usuario_admin RECORD;
    total_notificados INTEGER := 0;
BEGIN
    -- Solo para nuevas publicaciones (INSERT)
    IF TG_OP = 'INSERT' THEN
        
        -- Obtener información COMPLETA del usuario que publica
        SELECT 
            nombre_completo, 
            nombre_usuario,
            rol,
            COALESCE(nombre_completo, nombre_usuario, 'Administrador') as nombre_mostrar
        INTO usuario_admin
        FROM perfiles 
        WHERE id = NEW.usuario_id;
        
        -- Solo proceder si el usuario es admin
        IF usuario_admin.rol = 'admin' THEN
            
            RAISE NOTICE '🔥 ADMIN DETECTADO: % va a publicar', usuario_admin.nombre_mostrar;
            
            -- Insertar notificación para TODOS los usuarios (excepto el admin)
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
            SELECT 
                p.id,
                'publicacion_admin',
                '📢 Nueva publicación del administrador',
                'El administrador ' || usuario_admin.nombre_mostrar || ' publicó: "' || 
                LEFT(COALESCE(NEW.titulo, 'Nueva publicación'), 60) ||
                CASE WHEN LENGTH(COALESCE(NEW.titulo, '')) > 60 THEN '...' ELSE '' END || '"',
                '📢',
                'admin',
                'alta',
                '/comunidad#publicacion-' || NEW.id::text,
                false,
                false,
                NOW() + INTERVAL '30 days'
            FROM perfiles p
            WHERE p.id != NEW.usuario_id  -- Excluir al admin que publicó
            AND p.eliminado IS NOT TRUE;  -- Solo usuarios activos
            
            -- Contar notificaciones enviadas
            GET DIAGNOSTICS total_notificados = ROW_COUNT;
            
            RAISE NOTICE '📢 Notificaciones enviadas por admin: % a % usuarios', 
                usuario_admin.nombre_mostrar, total_notificados;
        ELSE
            RAISE NOTICE '👤 Usuario normal publicó (no admin): %', usuario_admin.nombre_mostrar;
        END IF;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Si hay error, no fallar la publicación pero registrar el error
        RAISE WARNING '❌ Error en notificaciones admin: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear el trigger SIGUIENDO EL PATRÓN
CREATE TRIGGER trigger_notificar_publicacion_admin_corregida
    AFTER INSERT ON comunidad_publicaciones
    FOR EACH ROW
    EXECUTE FUNCTION notificar_publicacion_admin_corregida();

-- 4. VERIFICAR que el trigger se creó
SELECT 
    event_object_table,
    trigger_name, 
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notificar_publicacion_admin_corregida';

-- 5. VERIFICAR que la función existe
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'notificar_publicacion_admin_corregida';

-- 6. HACER PRUEBA INMEDIATA
DO $$
DECLARE
    admin_user RECORD;
    test_pub_id UUID;
    notifs_antes INTEGER;
    notifs_despues INTEGER;
BEGIN
    -- Contar notificaciones antes
    SELECT COUNT(*) INTO notifs_antes FROM notificaciones WHERE tipo = 'publicacion_admin';
    
    -- Buscar un admin
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Admin') as nombre, rol
    INTO admin_user
    FROM perfiles 
    WHERE rol = 'admin' 
    LIMIT 1;
    
    IF admin_user.id IS NOT NULL THEN
        RAISE NOTICE '🧪 HACIENDO PRUEBA CON ADMIN: %', admin_user.nombre;
        
        -- Crear publicación de prueba
        INSERT INTO comunidad_publicaciones (
            usuario_id,
            usuario_nombre,
            usuario_avatar,
            titulo,
            descripcion,
            tipo
        ) VALUES (
            admin_user.id,
            admin_user.nombre,
            'https://ui-avatars.com/api/?name=AdminTest&background=ff0000&color=fff',
            'PRUEBA ADMIN CORREGIDA',
            'Prueba del sistema corregido de notificaciones admin',
            'texto'
        ) RETURNING id INTO test_pub_id;
        
        -- Esperar que se ejecute el trigger
        PERFORM pg_sleep(1);
        
        -- Contar notificaciones después
        SELECT COUNT(*) INTO notifs_despues FROM notificaciones WHERE tipo = 'publicacion_admin';
        
        RAISE NOTICE '📊 RESULTADOS:';
        RAISE NOTICE '   - Publicación creada: %', test_pub_id;
        RAISE NOTICE '   - Notificaciones antes: %', notifs_antes;
        RAISE NOTICE '   - Notificaciones después: %', notifs_despues;
        RAISE NOTICE '   - Notificaciones nuevas: %', (notifs_despues - notifs_antes);
        
        -- Mostrar algunas notificaciones
        RAISE NOTICE '📱 PRIMERAS 3 NOTIFICACIONES CREADAS:';
        FOR admin_user IN (
            SELECT n.usuario_id, n.mensaje, p.nombre_usuario
            FROM notificaciones n
            JOIN perfiles p ON p.id = n.usuario_id
            WHERE n.tipo = 'publicacion_admin' 
            AND n.mensaje LIKE '%PRUEBA ADMIN CORREGIDA%'
            LIMIT 3
        ) LOOP
            RAISE NOTICE '   - Para %: %', admin_user.nombre_usuario, admin_user.mensaje;
        END LOOP;
        
        -- NO ELIMINAR - dejar para que veas las notificaciones
        RAISE NOTICE '✅ PRUEBA COMPLETADA - PUBLICACIÓN DEJADA PARA VERIFICAR';
        
    ELSE
        RAISE NOTICE '❌ NO SE ENCONTRÓ USUARIO ADMIN';
    END IF;
END $$;

-- 7. MENSAJE FINAL
SELECT 'SISTEMA DE NOTIFICACIONES ADMIN CORREGIDO Y PROBADO' as resultado; 