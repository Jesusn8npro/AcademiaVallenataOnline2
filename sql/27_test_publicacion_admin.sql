-- ============================================
-- TEST DE PUBLICACIONES DE ADMIN
-- ============================================

-- 1. Verificar que el trigger existe
SELECT 'VERIFICANDO TRIGGER' as paso;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
AND trigger_name = 'trigger_notificar_publicacion_admin';

-- 2. Mostrar admins disponibles
SELECT 'ADMINISTRADORES DISPONIBLES:' as info;
SELECT 
    id,
    nombre_completo,
    rol,
    correo_electronico
FROM perfiles 
WHERE rol IN ('admin', 'superadmin')
ORDER BY fecha_creacion
LIMIT 3;

-- 3. Mostrar usuarios normales (que recibirán notificaciones)
SELECT 'USUARIOS QUE RECIBIRÁN NOTIFICACIONES:' as info;
SELECT 
    id,
    nombre_completo,
    rol,
    correo_electronico
FROM perfiles 
WHERE rol NOT IN ('admin', 'superadmin')
AND eliminado = false
ORDER BY fecha_creacion
LIMIT 5;

-- 4. Crear una publicación de prueba como admin
DO $$
DECLARE
    admin_id UUID;
    admin_nombre TEXT;
    usuarios_count INTEGER;
BEGIN
    -- Obtener un admin
    SELECT id, nombre_completo INTO admin_id, admin_nombre
    FROM perfiles 
    WHERE rol IN ('admin', 'superadmin')
    ORDER BY fecha_creacion DESC
    LIMIT 1;
    
    -- Contar usuarios que recibirán notificaciones
    SELECT COUNT(*) INTO usuarios_count
    FROM perfiles 
    WHERE rol NOT IN ('admin', 'superadmin')
    AND eliminado = false;
    
    IF admin_id IS NOT NULL THEN
        RAISE NOTICE '🎯 Creando publicación de prueba como admin: %', admin_nombre;
        RAISE NOTICE '📊 Usuarios que recibirán notificación: %', usuarios_count;
        
        -- Crear publicación de prueba
        INSERT INTO comunidad_publicaciones (
            usuario_id,
            titulo,
            descripcion,
            tipo,
            visibilidad,
            estado,
            usuario_nombre,
            usuario_avatar
        ) VALUES (
            admin_id,
            '🎉 ¡Contenido Exclusivo de Academia Vallenata!',
            'Hemos publicado nuevo material educativo que te ayudará a mejorar tu técnica en el acordeón. ¡No te lo pierdas!',
            'texto',
            'publico',
            'activo',
            admin_nombre,
            null
        );
        
        RAISE NOTICE '✅ Publicación creada exitosamente. Las notificaciones deberían haberse enviado automáticamente.';
        
    ELSE
        RAISE NOTICE '❌ No se encontraron administradores en el sistema';
    END IF;
END $$;

-- 5. Verificar que se crearon las notificaciones
SELECT 'NOTIFICACIONES RECIENTES DE PUBLICACIONES ADMIN:' as info;
SELECT 
    n.titulo,
    n.mensaje,
    n.categoria,
    n.prioridad,
    p.nombre_completo as usuario_receptor,
    n.fecha_creacion
FROM notificaciones n
JOIN perfiles p ON n.usuario_id = p.id
WHERE n.tipo = 'nueva_publicacion_admin'
AND n.fecha_creacion >= NOW() - INTERVAL '10 minutes'
ORDER BY n.fecha_creacion DESC
LIMIT 10;

-- 6. Contar notificaciones enviadas
SELECT 'ESTADÍSTICAS DE NOTIFICACIONES:' as info;
SELECT 
    COUNT(*) as total_notificaciones_enviadas,
    COUNT(DISTINCT usuario_id) as usuarios_notificados
FROM notificaciones 
WHERE tipo = 'nueva_publicacion_admin'
AND fecha_creacion >= NOW() - INTERVAL '10 minutes'; 