-- DIAGNÓSTICO COMPLETO DE NOTIFICACIONES ADMIN
-- Este script revisa todo el sistema para encontrar el problema

-- 1. VERIFICAR QUE EL TRIGGER EXISTE Y ESTÁ ACTIVO
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
AND trigger_name = 'trigger_notificar_publicacion_admin';

-- 2. VERIFICAR QUE LA FUNCIÓN EXISTE
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'notificar_publicacion_admin'
AND routine_type = 'FUNCTION';

-- 3. VERIFICAR TU ROL DE USUARIO (reemplaza con tu usuario_id real)
SELECT 
    id,
    nombre,
    nombre_usuario,
    rol,
    correo_electronico
FROM perfiles 
WHERE rol = 'admin'
ORDER BY fecha_creacion DESC;

-- 4. VERIFICAR PUBLICACIONES RECIENTES
SELECT 
    id,
    usuario_id,
    usuario_nombre,
    titulo,
    fecha_creacion,
    (SELECT rol FROM perfiles WHERE id = cp.usuario_id) as rol_usuario
FROM comunidad_publicaciones cp
ORDER BY fecha_creacion DESC
LIMIT 5;

-- 5. VERIFICAR NOTIFICACIONES RECIENTES
SELECT 
    id,
    usuario_id,
    tipo,
    titulo,
    mensaje,
    fecha_creacion,
    leida
FROM notificaciones
WHERE tipo = 'publicacion_admin'
ORDER BY fecha_creacion DESC
LIMIT 10;

-- 6. CONTAR USUARIOS ACTIVOS (que deberían recibir notificaciones)
SELECT 
    COUNT(*) as total_usuarios_activos,
    COUNT(CASE WHEN rol = 'admin' THEN 1 END) as total_admins,
    COUNT(CASE WHEN rol != 'admin' THEN 1 END) as usuarios_no_admin
FROM perfiles 
WHERE eliminado IS NOT TRUE;

-- 7. HACER PRUEBA MANUAL PASO A PASO
DO $$
DECLARE
    admin_id UUID;
    admin_info RECORD;
    test_publicacion_id UUID;
    notificaciones_enviadas INTEGER;
BEGIN
    -- Buscar el primer admin
    SELECT id, nombre, nombre_usuario, rol
    INTO admin_info
    FROM perfiles 
    WHERE rol = 'admin' 
    LIMIT 1;
    
    IF admin_info.id IS NOT NULL THEN
        RAISE NOTICE 'ADMIN ENCONTRADO: % (%), Rol: %', 
            COALESCE(admin_info.nombre, admin_info.nombre_usuario), 
            admin_info.id, 
            admin_info.rol;
        
        -- Crear publicación de prueba
        INSERT INTO comunidad_publicaciones (
            usuario_id,
            usuario_nombre,
            usuario_avatar,
            titulo,
            descripcion,
            tipo
        ) VALUES (
            admin_info.id,
            COALESCE(admin_info.nombre, admin_info.nombre_usuario, 'Admin'),
            'https://ui-avatars.com/api/?name=AdminTest&background=ff6b6b&color=fff',
            'PRUEBA DIAGNÓSTICO ADMIN',
            'Esta es una prueba para diagnosticar notificaciones',
            'texto'
        ) RETURNING id INTO test_publicacion_id;
        
        RAISE NOTICE 'PUBLICACIÓN CREADA: %', test_publicacion_id;
        
        -- Esperar un momento para que se ejecute el trigger
        PERFORM pg_sleep(1);
        
        -- Verificar notificaciones creadas
        SELECT COUNT(*)
        INTO notificaciones_enviadas
        FROM notificaciones 
        WHERE tipo = 'publicacion_admin' 
        AND mensaje LIKE '%PRUEBA DIAGNÓSTICO ADMIN%';
        
        RAISE NOTICE 'NOTIFICACIONES ENVIADAS: %', notificaciones_enviadas;
        
        -- Mostrar algunas notificaciones creadas
        RAISE NOTICE 'PRIMERAS 3 NOTIFICACIONES:';
        FOR admin_info IN (
            SELECT usuario_id, mensaje, fecha_creacion
            FROM notificaciones 
            WHERE tipo = 'publicacion_admin' 
            AND mensaje LIKE '%PRUEBA DIAGNÓSTICO ADMIN%'
            LIMIT 3
        ) LOOP
            RAISE NOTICE 'Usuario: %, Mensaje: %', admin_info.usuario_id, admin_info.mensaje;
        END LOOP;
        
        -- NO ELIMINAR - dejar para verificar
        RAISE NOTICE 'PUBLICACIÓN DE PRUEBA DEJADA PARA VERIFICACIÓN';
        
    ELSE
        RAISE NOTICE 'NO SE ENCONTRÓ USUARIO ADMIN';
    END IF;
END $$;

-- 8. VERIFICAR ESTRUCTURA DE TABLA NOTIFICACIONES
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'notificaciones'
ORDER BY ordinal_position;

-- 9. VERIFICAR SI HAY ERRORES EN LOS LOGS
-- (Esto se verá en los logs de Supabase)

-- 10. MENSAJE FINAL
SELECT 'DIAGNÓSTICO COMPLETADO - REVISA LOS RESULTADOS ARRIBA' as resultado; 