-- VERIFICAR ESTADO ACTUAL DEL SISTEMA DE NOTIFICACIONES

-- 1. VER TODOS LOS TRIGGERS EN COMUNIDAD_PUBLICACIONES
SELECT 'TRIGGERS ACTUALES EN COMUNIDAD_PUBLICACIONES:' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
ORDER BY trigger_name;

-- 2. VER TODAS LAS FUNCIONES DE NOTIFICACIONES
SELECT 'FUNCIONES DE NOTIFICACIONES EXISTENTES:' as info;
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%notificar%'
ORDER BY routine_name;

-- 3. VER ÚLTIMAS NOTIFICACIONES PARA ENTENDER QUÉ ESTÁ PASANDO
SELECT 'ÚLTIMAS 10 NOTIFICACIONES:' as info;
SELECT 
    tipo,
    titulo,
    mensaje,
    categoria,
    prioridad,
    fecha_creacion
FROM notificaciones
ORDER BY fecha_creacion DESC
LIMIT 10;

-- 4. CONTAR NOTIFICACIONES POR TIPO
SELECT 'NOTIFICACIONES POR TIPO:' as info;
SELECT 
    tipo,
    COUNT(*) as cantidad,
    MAX(fecha_creacion) as ultima_fecha
FROM notificaciones
GROUP BY tipo
ORDER BY ultima_fecha DESC;

-- 5. HACER PRUEBA DE PUBLICACIÓN SIMPLE
DO $$
DECLARE
    test_user RECORD;
    test_pub_id UUID;
    notifs_antes INTEGER;
    notifs_despues INTEGER;
BEGIN
    -- Contar notificaciones antes
    SELECT COUNT(*) INTO notifs_antes FROM notificaciones;
    
    -- Buscar cualquier usuario (no necesariamente admin)
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Usuario') as nombre, rol
    INTO test_user
    FROM perfiles 
    WHERE eliminado IS NOT TRUE
    LIMIT 1;
    
    IF test_user.id IS NOT NULL THEN
        RAISE NOTICE '🧪 HACIENDO PRUEBA CON USUARIO: % (Rol: %)', test_user.nombre, test_user.rol;
        
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
            'https://ui-avatars.com/api/?name=Test&background=ff0000&color=fff',
            'PRUEBA SISTEMA ACTUAL',
            'Verificando si algún trigger se ejecuta',
            'texto'
        ) RETURNING id INTO test_pub_id;
        
        -- Esperar que se ejecuten los triggers
        PERFORM pg_sleep(2);
        
        -- Contar notificaciones después
        SELECT COUNT(*) INTO notifs_despues FROM notificaciones;
        
        RAISE NOTICE '📊 RESULTADOS:';
        RAISE NOTICE '   - Usuario: % (Rol: %)', test_user.nombre, test_user.rol;
        RAISE NOTICE '   - Publicación creada: %', test_pub_id;
        RAISE NOTICE '   - Notificaciones antes: %', notifs_antes;
        RAISE NOTICE '   - Notificaciones después: %', notifs_despues;
        RAISE NOTICE '   - Notificaciones nuevas: %', (notifs_despues - notifs_antes);
        
        IF (notifs_despues - notifs_antes) = 0 THEN
            RAISE NOTICE '❌ NO SE GENERARON NOTIFICACIONES - EL SISTEMA ESTÁ ROTO';
        ELSE
            RAISE NOTICE '✅ SE GENERARON % NOTIFICACIONES', (notifs_despues - notifs_antes);
        END IF;
        
    ELSE
        RAISE NOTICE '❌ NO SE ENCONTRARON USUARIOS';
    END IF;
END $$; 