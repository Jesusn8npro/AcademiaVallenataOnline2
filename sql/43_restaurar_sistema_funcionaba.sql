-- RESTAURAR EL SISTEMA DE NOTIFICACIONES QUE SÍ FUNCIONABA
-- Basado en el patrón de comentarios que sabemos que funciona

-- 1. CREAR FUNCIÓN PARA NOTIFICAR CUANDO CUALQUIER USUARIO PUBLICA
CREATE OR REPLACE FUNCTION notificar_nueva_publicacion_comunidad()
RETURNS TRIGGER AS $$
DECLARE
    usuario_publicador RECORD;
    total_notificados INTEGER := 0;
BEGIN
    -- Solo para nuevas publicaciones (INSERT)
    IF TG_OP = 'INSERT' THEN
        
        -- Obtener información del usuario que publica
        SELECT 
            nombre_completo, 
            nombre_usuario,
            rol,
            COALESCE(nombre_completo, nombre_usuario, 'Usuario') as nombre_mostrar
        INTO usuario_publicador
        FROM perfiles 
        WHERE id = NEW.usuario_id;
        
        RAISE NOTICE '📢 NUEVA PUBLICACIÓN DE: % (Rol: %)', usuario_publicador.nombre_mostrar, usuario_publicador.rol;
        
        -- Determinar el tipo de notificación según el rol
        IF usuario_publicador.rol = 'admin' THEN
            -- NOTIFICACIÓN ESPECIAL PARA ADMIN
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
                'El administrador ' || usuario_publicador.nombre_mostrar || ' publicó: "' || 
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
            
            GET DIAGNOSTICS total_notificados = ROW_COUNT;
            RAISE NOTICE '👑 Notificaciones ADMIN enviadas a % usuarios', total_notificados;
            
        ELSE
            -- NOTIFICACIÓN NORMAL PARA USUARIOS REGULARES
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
                'nueva_publicacion_comunidad',
                '👥 Nueva publicación en la comunidad',
                usuario_publicador.nombre_mostrar || ' compartió: "' || 
                LEFT(COALESCE(NEW.titulo, 'Nueva publicación'), 60) ||
                CASE WHEN LENGTH(COALESCE(NEW.titulo, '')) > 60 THEN '...' ELSE '' END || '"',
                '👥',
                'comunidad',
                'normal',
                '/comunidad#publicacion-' || NEW.id::text,
                false,
                false,
                NOW() + INTERVAL '15 days'
            FROM perfiles p
            WHERE p.id != NEW.usuario_id  -- Excluir al usuario que publicó
            AND p.eliminado IS NOT TRUE;  -- Solo usuarios activos
            
            GET DIAGNOSTICS total_notificados = ROW_COUNT;
            RAISE NOTICE '👥 Notificaciones COMUNIDAD enviadas a % usuarios', total_notificados;
        END IF;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Si hay error, no fallar la publicación pero registrar el error
        RAISE WARNING '❌ Error en notificaciones: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. CREAR EL TRIGGER PARA TODAS LAS PUBLICACIONES
DROP TRIGGER IF EXISTS trigger_notificar_nueva_publicacion_comunidad ON comunidad_publicaciones;

CREATE TRIGGER trigger_notificar_nueva_publicacion_comunidad
    AFTER INSERT ON comunidad_publicaciones
    FOR EACH ROW
    EXECUTE FUNCTION notificar_nueva_publicacion_comunidad();

-- 3. VERIFICAR QUE EL TRIGGER SE CREÓ
SELECT 'TRIGGER RESTAURADO:' as info;
SELECT 
    event_object_table,
    trigger_name, 
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notificar_nueva_publicacion_comunidad';

-- 4. VERIFICAR QUE LA FUNCIÓN EXISTE
SELECT 'FUNCIÓN RESTAURADA:' as info;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'notificar_nueva_publicacion_comunidad';

-- 5. HACER PRUEBA INMEDIATA CON USUARIO NORMAL
DO $$
DECLARE
    test_user RECORD;
    test_pub_id UUID;
    notifs_antes INTEGER;
    notifs_despues INTEGER;
BEGIN
    -- Contar notificaciones antes
    SELECT COUNT(*) INTO notifs_antes FROM notificaciones;
    
    -- Buscar un usuario normal (no admin)
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Usuario') as nombre, rol
    INTO test_user
    FROM perfiles 
    WHERE rol != 'admin' 
    AND eliminado IS NOT TRUE
    LIMIT 1;
    
    IF test_user.id IS NOT NULL THEN
        RAISE NOTICE '🧪 PRUEBA CON USUARIO NORMAL: % (Rol: %)', test_user.nombre, test_user.rol;
        
        -- Crear publicación de prueba
        INSERT INTO comunidad_publicaciones (
            usuario_id,
            usuario_nombre,
            usuario_avatar,
            titulo,
            descripcion,
            tipo
        ) VALUES (
            test_user.id,
            test_user.nombre,
            'https://ui-avatars.com/api/?name=TestNormal&background=0066cc&color=fff',
            'PRUEBA USUARIO NORMAL RESTAURADO',
            'Verificando que las notificaciones funcionen para usuarios normales',
            'texto'
        ) RETURNING id INTO test_pub_id;
        
        -- Esperar que se ejecute el trigger
        PERFORM pg_sleep(2);
        
        -- Contar notificaciones después
        SELECT COUNT(*) INTO notifs_despues FROM notificaciones;
        
        RAISE NOTICE '📊 RESULTADOS USUARIO NORMAL:';
        RAISE NOTICE '   - Publicación creada: %', test_pub_id;
        RAISE NOTICE '   - Notificaciones antes: %', notifs_antes;
        RAISE NOTICE '   - Notificaciones después: %', notifs_despues;
        RAISE NOTICE '   - Notificaciones nuevas: %', (notifs_despues - notifs_antes);
        
    ELSE
        RAISE NOTICE '❌ NO SE ENCONTRÓ USUARIO NORMAL';
    END IF;
END $$;

-- 6. HACER PRUEBA CON ADMIN
DO $$
DECLARE
    admin_user RECORD;
    test_pub_id UUID;
    notifs_antes INTEGER;
    notifs_despues INTEGER;
BEGIN
    -- Contar notificaciones antes
    SELECT COUNT(*) INTO notifs_antes FROM notificaciones;
    
    -- Buscar un admin
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Admin') as nombre, rol
    INTO admin_user
    FROM perfiles 
    WHERE rol = 'admin' 
    LIMIT 1;
    
    IF admin_user.id IS NOT NULL THEN
        RAISE NOTICE '🧪 PRUEBA CON ADMIN: %', admin_user.nombre;
        
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
            'https://ui-avatars.com/api/?name=TestAdmin&background=ff0000&color=fff',
            'PRUEBA ADMIN RESTAURADO',
            'Verificando que las notificaciones de admin funcionen',
            'texto'
        ) RETURNING id INTO test_pub_id;
        
        -- Esperar que se ejecute el trigger
        PERFORM pg_sleep(2);
        
        -- Contar notificaciones después
        SELECT COUNT(*) INTO notifs_despues FROM notificaciones;
        
        RAISE NOTICE '📊 RESULTADOS ADMIN:';
        RAISE NOTICE '   - Publicación creada: %', test_pub_id;
        RAISE NOTICE '   - Notificaciones antes: %', notifs_antes;
        RAISE NOTICE '   - Notificaciones después: %', notifs_despues;
        RAISE NOTICE '   - Notificaciones nuevas: %', (notifs_despues - notifs_antes);
        
    ELSE
        RAISE NOTICE '❌ NO SE ENCONTRÓ ADMIN';
    END IF;
END $$; 