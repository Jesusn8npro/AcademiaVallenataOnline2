-- DIAGNÓSTICO COMPLETO DE NOTIFICACIONES
-- Verificar qué sistema está funcionando

-- 1. VERIFICAR TRIGGERS EXISTENTES
SELECT 'TRIGGERS ACTUALES EN COMUNIDAD_PUBLICACIONES:' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
ORDER BY trigger_name;

-- 2. VERIFICAR FUNCIONES EXISTENTES
SELECT 'FUNCIONES DE NOTIFICACIONES:' as info;
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%notificar%'
ORDER BY routine_name;

-- 3. VERIFICAR ÚLTIMAS NOTIFICACIONES
SELECT 'ÚLTIMAS 10 NOTIFICACIONES:' as info;
SELECT 
    tipo,
    titulo,
    mensaje,
    categoria,
    prioridad,
    fecha_creacion,
    datos_adicionales
FROM notificaciones
ORDER BY fecha_creacion DESC
LIMIT 10;

-- 4. VERIFICAR NOTIFICACIONES DE ADMIN ESPECÍFICAMENTE
SELECT 'NOTIFICACIONES DE ADMIN:' as info;
SELECT 
    tipo,
    titulo,
    mensaje,
    fecha_creacion
FROM notificaciones
WHERE tipo IN ('publicacion_admin', 'nueva_publicacion_admin')
ORDER BY fecha_creacion DESC
LIMIT 5;

-- 5. VERIFICAR NOTIFICACIONES GENÉRICAS DE COMUNIDAD
SELECT 'NOTIFICACIONES GENÉRICAS DE COMUNIDAD:' as info;
SELECT 
    tipo,
    titulo,
    mensaje,
    fecha_creacion
FROM notificaciones
WHERE tipo = 'nueva_publicacion_comunidad'
ORDER BY fecha_creacion DESC
LIMIT 5;

-- 6. HACER PRUEBA DIRECTA CON ADMIN
DO $$
DECLARE
    admin_id UUID;
    admin_nombre TEXT;
    test_pub_id UUID;
    notifs_antes INTEGER;
    notifs_despues INTEGER;
BEGIN
    -- Contar notificaciones antes
    SELECT COUNT(*) INTO notifs_antes FROM notificaciones;
    
    -- Buscar admin
    SELECT id, COALESCE(nombre_completo, nombre_usuario, 'Admin') 
    INTO admin_id, admin_nombre
    FROM perfiles 
    WHERE rol = 'admin' 
    LIMIT 1;
    
    IF admin_id IS NOT NULL THEN
        RAISE NOTICE '🧪 HACIENDO PRUEBA CON ADMIN: % (ID: %)', admin_nombre, admin_id;
        
        -- Crear publicación de prueba
        INSERT INTO comunidad_publicaciones (
            usuario_id,
            usuario_nombre,
            usuario_avatar,
            titulo,
            descripcion,
            tipo
        ) VALUES (
            admin_id,
            admin_nombre,
            'https://ui-avatars.com/api/?name=AdminTest&background=ff0000&color=fff',
            'PRUEBA DIAGNÓSTICO COMPLETO',
            'Esta es una prueba para ver qué sistema de notificaciones funciona',
            'texto'
        ) RETURNING id INTO test_pub_id;
        
        -- Esperar que se ejecuten los triggers
        PERFORM pg_sleep(2);
        
        -- Contar notificaciones después
        SELECT COUNT(*) INTO notifs_despues FROM notificaciones;
        
        RAISE NOTICE '📊 RESULTADOS:';
        RAISE NOTICE '   - Publicación creada: %', test_pub_id;
        RAISE NOTICE '   - Notificaciones antes: %', notifs_antes;
        RAISE NOTICE '   - Notificaciones después: %', notifs_despues;
        RAISE NOTICE '   - Notificaciones nuevas: %', (notifs_despues - notifs_antes);
        
        -- Mostrar notificaciones recientes
        RAISE NOTICE '📱 NOTIFICACIONES RECIENTES:';
        FOR admin_id IN (
            SELECT tipo, titulo, mensaje
            FROM notificaciones 
            WHERE fecha_creacion >= NOW() - INTERVAL '1 minute'
            ORDER BY fecha_creacion DESC
            LIMIT 5
        ) LOOP
            RAISE NOTICE '   - %: %', admin_id.tipo, admin_id.titulo;
        END LOOP;
        
    ELSE
        RAISE NOTICE '❌ NO SE ENCONTRÓ ADMIN';
    END IF;
END $$;

-- 7. VERIFICAR CONFIGURACIÓN RLS
SELECT 'POLÍTICAS RLS EN NOTIFICACIONES:' as info;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'notificaciones'; 