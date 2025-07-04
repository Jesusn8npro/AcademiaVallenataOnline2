-- ELIMINAR TRIGGER GENÉRICO QUE ESTÁ ENVIANDO NOTIFICACIONES A TODOS
-- Solo queremos que funcione el trigger de admin específico

-- 1. BUSCAR TODOS LOS TRIGGERS PROBLEMÁTICOS
SELECT 'TRIGGERS ACTUALES EN COMUNIDAD_PUBLICACIONES:' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
ORDER BY trigger_name;

-- 2. ELIMINAR TRIGGERS GENÉRICOS
DROP TRIGGER IF EXISTS trigger_nueva_publicacion ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_notificar_nueva_publicacion ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_notificaciones_publicaciones ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_publicacion_generica ON comunidad_publicaciones;

-- 3. ELIMINAR FUNCIONES GENÉRICAS
DROP FUNCTION IF EXISTS notificar_nueva_publicacion();
DROP FUNCTION IF EXISTS notificar_publicacion_generica();
DROP FUNCTION IF EXISTS trigger_nueva_publicacion();

-- 4. VERIFICAR QUE SOLO QUEDE EL TRIGGER DE ADMIN
SELECT 'TRIGGERS DESPUÉS DE LIMPIEZA:' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
ORDER BY trigger_name;

-- 5. VERIFICAR QUE EL TRIGGER DE ADMIN SIGUE ACTIVO
SELECT 'VERIFICANDO TRIGGER DE ADMIN:' as info;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'notificar_publicacion_admin_corregida';

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
        RAISE NOTICE '🧪 PRUEBA FINAL CON ADMIN: %', admin_user.nombre;
        
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
            'https://ui-avatars.com/api/?name=AdminFinal&background=00ff00&color=000',
            'PRUEBA FINAL SIN TRIGGER GENÉRICO',
            'Esta debería ser la única notificación que aparezca',
            'texto'
        ) RETURNING id INTO test_pub_id;
        
        -- Esperar que se ejecute el trigger
        PERFORM pg_sleep(2);
        
        -- Contar notificaciones después
        SELECT COUNT(*) INTO notifs_despues FROM notificaciones;
        
        RAISE NOTICE '📊 RESULTADOS FINALES:';
        RAISE NOTICE '   - Publicación creada: %', test_pub_id;
        RAISE NOTICE '   - Notificaciones antes: %', notifs_antes;
        RAISE NOTICE '   - Notificaciones después: %', notifs_despues;
        RAISE NOTICE '   - Notificaciones nuevas: %', (notifs_despues - notifs_antes);
        
        -- Mostrar las últimas notificaciones
        RAISE NOTICE '📱 ÚLTIMAS 5 NOTIFICACIONES:';
        FOR admin_user IN (
            SELECT tipo, titulo, mensaje, fecha_creacion
            FROM notificaciones 
            ORDER BY fecha_creacion DESC
            LIMIT 5
        ) LOOP
            RAISE NOTICE '   - [%] %: %', admin_user.tipo, admin_user.titulo, LEFT(admin_user.mensaje, 50);
        END LOOP;
        
    ELSE
        RAISE NOTICE '❌ NO SE ENCONTRÓ ADMIN';
    END IF;
END $$; 