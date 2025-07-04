-- ARREGLAR ERROR DE COLUMNA EMAIL Y HACER QUE LAS NOTIFICACIONES FUNCIONEN

-- 1. VERIFICAR ESTRUCTURA DE LA TABLA PERFILES
SELECT 'COLUMNAS DE LA TABLA PERFILES:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'perfiles'
ORDER BY ordinal_position;

-- 2. VER NOTIFICACIONES RECIENTES SIN BUSCAR EMAIL
SELECT 'NOTIFICACIONES ÚLTIMAS 24 HORAS:' as info;
SELECT 
    n.tipo,
    n.titulo,
    n.mensaje,
    n.categoria,
    n.prioridad,
    n.fecha_creacion,
    p.nombre_completo as usuario_destino,
    p.nombre_usuario as username_destino
FROM notificaciones n
JOIN perfiles p ON n.usuario_id = p.id
WHERE n.fecha_creacion >= NOW() - INTERVAL '24 hours'
ORDER BY n.fecha_creacion DESC
LIMIT 20;

-- 3. CONTAR USUARIOS ACTIVOS
SELECT 'USUARIOS ACTIVOS:' as info;
SELECT 
    COUNT(*) as total_usuarios,
    COUNT(CASE WHEN rol = 'admin' THEN 1 END) as admins,
    COUNT(CASE WHEN rol != 'admin' OR rol IS NULL THEN 1 END) as usuarios_normales
FROM perfiles 
WHERE eliminado IS NOT TRUE OR eliminado IS NULL;

-- 4. VER PUBLICACIONES RECIENTES
SELECT 'PUBLICACIONES RECIENTES:' as info;
SELECT 
    id,
    usuario_nombre,
    titulo,
    fecha_creacion,
    (SELECT rol FROM perfiles WHERE id = usuario_id) as rol_usuario
FROM comunidad_publicaciones
WHERE fecha_creacion >= NOW() - INTERVAL '24 hours'
ORDER BY fecha_creacion DESC
LIMIT 10;

-- 5. BUSCAR TU USUARIO SIN USAR EMAIL
SELECT 'BUSCAR USUARIO JESUS:' as info;
SELECT 
    id,
    nombre_completo,
    nombre_usuario,
    rol,
    eliminado
FROM perfiles 
WHERE (nombre_completo ILIKE '%jesus%' OR nombre_usuario ILIKE '%jesus%')
AND (eliminado IS NOT TRUE OR eliminado IS NULL);

-- 6. HACER PRUEBA REAL CORREGIDA
DO $$
DECLARE
    jesus_user RECORD;
    otro_user RECORD;
    test_pub_id UUID;
    notifs_antes INTEGER;
    notifs_despues INTEGER;
    usuarios_total INTEGER;
BEGIN
    -- Contar total de usuarios
    SELECT COUNT(*) INTO usuarios_total 
    FROM perfiles 
    WHERE eliminado IS NOT TRUE OR eliminado IS NULL;
    
    RAISE NOTICE '👥 TOTAL DE USUARIOS EN LA PLATAFORMA: %', usuarios_total;
    
    -- Buscar tu usuario (Jesus) SIN EMAIL
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Jesus') as nombre, rol
    INTO jesus_user
    FROM perfiles 
    WHERE (nombre_completo ILIKE '%jesus%' OR nombre_usuario ILIKE '%jesus%')
    AND (eliminado IS NOT TRUE OR eliminado IS NULL)
    LIMIT 1;
    
    -- Buscar otro usuario diferente
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Usuario') as nombre, rol
    INTO otro_user
    FROM perfiles 
    WHERE id != COALESCE(jesus_user.id, '00000000-0000-0000-0000-000000000000')
    AND (eliminado IS NOT TRUE OR eliminado IS NULL)
    LIMIT 1;
    
    IF jesus_user.id IS NOT NULL THEN
        RAISE NOTICE '👑 USUARIO JESUS ENCONTRADO: % (ID: %, Rol: %)', jesus_user.nombre, jesus_user.id, jesus_user.rol;
        
        IF otro_user.id IS NOT NULL THEN
            RAISE NOTICE '👤 OTRO USUARIO ENCONTRADO: % (ID: %, Rol: %)', otro_user.nombre, otro_user.id, otro_user.rol;
            
            -- Contar notificaciones antes
            SELECT COUNT(*) INTO notifs_antes FROM notificaciones;
            
            -- Crear publicación como Jesus (admin)
            INSERT INTO comunidad_publicaciones (
                usuario_id,
                usuario_nombre,
                usuario_avatar,
                titulo,
                descripcion,
                tipo
            ) VALUES (
                jesus_user.id,
                jesus_user.nombre,
                'https://ui-avatars.com/api/?name=Jesus&background=ff0000&color=fff',
                'PRUEBA REAL JESUS ADMIN - NOTIFICACIONES',
                'Esta es una prueba real del sistema de notificaciones con Jesus como admin',
                'texto'
            ) RETURNING id INTO test_pub_id;
            
            -- Esperar que se ejecute el trigger
            PERFORM pg_sleep(3);
            
            -- Contar notificaciones después
            SELECT COUNT(*) INTO notifs_despues FROM notificaciones;
            
            RAISE NOTICE '📊 RESULTADOS PRUEBA REAL:';
            RAISE NOTICE '   - Jesus ID: %', jesus_user.id;
            RAISE NOTICE '   - Otro usuario ID: %', otro_user.id;
            RAISE NOTICE '   - Publicación creada: %', test_pub_id;
            RAISE NOTICE '   - Notificaciones antes: %', notifs_antes;
            RAISE NOTICE '   - Notificaciones después: %', notifs_despues;
            RAISE NOTICE '   - Notificaciones nuevas: %', (notifs_despues - notifs_antes);
            
            -- Verificar si el otro usuario recibió notificación
            IF EXISTS (
                SELECT 1 FROM notificaciones 
                WHERE usuario_id = otro_user.id 
                AND fecha_creacion >= NOW() - INTERVAL '5 minutes'
                AND tipo IN ('publicacion_admin', 'nueva_publicacion_comunidad')
            ) THEN
                RAISE NOTICE '✅ EL OTRO USUARIO SÍ RECIBIÓ NOTIFICACIÓN DE ADMIN';
                
                -- Mostrar la notificación específica
                SELECT 
                    tipo, titulo, mensaje, fecha_creacion
                FROM notificaciones 
                WHERE usuario_id = otro_user.id 
                AND fecha_creacion >= NOW() - INTERVAL '5 minutes'
                ORDER BY fecha_creacion DESC 
                LIMIT 1;
                
            ELSE
                RAISE NOTICE '❌ EL OTRO USUARIO NO RECIBIÓ NOTIFICACIÓN';
            END IF;
            
        ELSE
            RAISE NOTICE '❌ NO HAY OTROS USUARIOS PARA RECIBIR NOTIFICACIONES';
            RAISE NOTICE '🔧 NECESITAS CREAR OTRO USUARIO PARA PROBAR LAS NOTIFICACIONES';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ NO SE ENCONTRÓ USUARIO JESUS';
        RAISE NOTICE '📝 USUARIOS DISPONIBLES:';
        
        -- Mostrar todos los usuarios disponibles
        FOR jesus_user IN 
            SELECT id, nombre_completo, nombre_usuario, rol 
            FROM perfiles 
            WHERE eliminado IS NOT TRUE OR eliminado IS NULL
            LIMIT 5
        LOOP
            RAISE NOTICE '   - %: % (Rol: %)', jesus_user.nombre_completo, jesus_user.nombre_usuario, jesus_user.rol;
        END LOOP;
    END IF;
END $$;

-- 7. VERIFICAR QUE EL TRIGGER ESTÉ FUNCIONANDO
SELECT 'VERIFICAR TRIGGER ACTIVO:' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
AND trigger_name = 'trigger_notificar_nueva_publicacion_comunidad';

-- 8. MOSTRAR ÚLTIMAS NOTIFICACIONES GENERADAS
SELECT 'ÚLTIMAS NOTIFICACIONES GENERADAS:' as info;
SELECT 
    n.tipo,
    n.titulo,
    LEFT(n.mensaje, 100) as mensaje_corto,
    n.fecha_creacion,
    p.nombre_completo as para_usuario
FROM notificaciones n
JOIN perfiles p ON n.usuario_id = p.id
WHERE n.fecha_creacion >= NOW() - INTERVAL '1 hour'
ORDER BY n.fecha_creacion DESC
LIMIT 10; 