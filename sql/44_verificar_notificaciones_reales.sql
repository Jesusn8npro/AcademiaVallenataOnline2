-- VERIFICAR LAS NOTIFICACIONES REALES QUE SE ESTÁN GENERANDO

-- 1. VER TODAS LAS NOTIFICACIONES RECIENTES (ÚLTIMAS 24 HORAS)
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

-- 2. CONTAR CUÁNTOS USUARIOS ACTIVOS HAY
SELECT 'USUARIOS ACTIVOS:' as info;
SELECT 
    COUNT(*) as total_usuarios,
    COUNT(CASE WHEN rol = 'admin' THEN 1 END) as admins,
    COUNT(CASE WHEN rol != 'admin' THEN 1 END) as usuarios_normales
FROM perfiles 
WHERE eliminado IS NOT TRUE;

-- 3. VER PUBLICACIONES RECIENTES
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

-- 4. VERIFICAR SI HAY NOTIFICACIONES PARA TU USUARIO ESPECÍFICO
SELECT 'NOTIFICACIONES PARA JESUS (ADMIN):' as info;
SELECT 
    n.tipo,
    n.titulo,
    n.mensaje,
    n.fecha_creacion,
    n.leida
FROM notificaciones n
JOIN perfiles p ON n.usuario_id = p.id
WHERE p.nombre_completo ILIKE '%jesus%' 
   OR p.nombre_usuario ILIKE '%jesus%'
   OR p.email ILIKE '%jesus%'
ORDER BY n.fecha_creacion DESC
LIMIT 10;

-- 5. HACER UNA PRUEBA REAL CON TU USUARIO
DO $$
DECLARE
    jesus_user RECORD;
    otro_user RECORD;
    test_pub_id UUID;
    notifs_antes INTEGER;
    notifs_despues INTEGER;
BEGIN
    -- Buscar tu usuario (Jesus)
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Jesus') as nombre, rol
    INTO jesus_user
    FROM perfiles 
    WHERE (nombre_completo ILIKE '%jesus%' OR nombre_usuario ILIKE '%jesus%' OR email ILIKE '%jesus%')
    AND eliminado IS NOT TRUE
    LIMIT 1;
    
    -- Buscar otro usuario diferente
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Usuario') as nombre, rol
    INTO otro_user
    FROM perfiles 
    WHERE id != COALESCE(jesus_user.id, '00000000-0000-0000-0000-000000000000')
    AND eliminado IS NOT TRUE
    LIMIT 1;
    
    IF jesus_user.id IS NOT NULL THEN
        RAISE NOTICE '👑 USUARIO JESUS ENCONTRADO: % (ID: %, Rol: %)', jesus_user.nombre, jesus_user.id, jesus_user.rol;
        
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
            'PRUEBA REAL JESUS ADMIN',
            'Esta es una prueba real del sistema de notificaciones con Jesus como admin',
            'texto'
        ) RETURNING id INTO test_pub_id;
        
        -- Esperar que se ejecute el trigger
        PERFORM pg_sleep(2);
        
        -- Contar notificaciones después
        SELECT COUNT(*) INTO notifs_despues FROM notificaciones;
        
        RAISE NOTICE '📊 RESULTADOS PRUEBA REAL:';
        RAISE NOTICE '   - Jesus ID: %', jesus_user.id;
        RAISE NOTICE '   - Publicación creada: %', test_pub_id;
        RAISE NOTICE '   - Notificaciones antes: %', notifs_antes;
        RAISE NOTICE '   - Notificaciones después: %', notifs_despues;
        RAISE NOTICE '   - Notificaciones nuevas: %', (notifs_despues - notifs_antes);
        
        IF otro_user.id IS NOT NULL THEN
            RAISE NOTICE '👤 OTRO USUARIO ENCONTRADO: % (ID: %)', otro_user.nombre, otro_user.id;
            
            -- Verificar si el otro usuario recibió notificación
            IF EXISTS (
                SELECT 1 FROM notificaciones 
                WHERE usuario_id = otro_user.id 
                AND fecha_creacion >= NOW() - INTERVAL '5 minutes'
                AND tipo IN ('publicacion_admin', 'nueva_publicacion_comunidad')
            ) THEN
                RAISE NOTICE '✅ EL OTRO USUARIO SÍ RECIBIÓ NOTIFICACIÓN';
            ELSE
                RAISE NOTICE '❌ EL OTRO USUARIO NO RECIBIÓ NOTIFICACIÓN';
            END IF;
        ELSE
            RAISE NOTICE '❌ NO HAY OTROS USUARIOS PARA RECIBIR NOTIFICACIONES';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ NO SE ENCONTRÓ USUARIO JESUS';
    END IF;
END $$; 