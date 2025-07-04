-- ============================================
-- TEST DE NOTIFICACIONES EN TIEMPO REAL
-- ============================================

-- 1. Verificar que realtime está habilitado (CORREGIDO)
SELECT 'VERIFICANDO REALTIME' as paso;
SELECT 
    schemaname,
    tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'notificaciones';

-- 2. Obtener un usuario para testing
DO $$
DECLARE
    test_user_id UUID;
    test_user_name TEXT;
BEGIN
    -- Obtener un usuario existente
    SELECT id, nombre_completo INTO test_user_id, test_user_name
    FROM perfiles 
    ORDER BY fecha_creacion DESC 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE '✅ Usuario de prueba encontrado: % (ID: %)', test_user_name, test_user_id;
        
        -- 3. Generar notificaciones de prueba
        RAISE NOTICE '🔔 Generando notificaciones de prueba...';
        
        -- Notificación de bienvenida
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            icono,
            categoria,
            prioridad,
            leida,
            archivada,
            url_accion,
            datos_adicionales
        ) VALUES (
            test_user_id,
            'bienvenida',
            '¡Bienvenido a las notificaciones en tiempo real!',
            'Tu sistema de notificaciones está funcionando correctamente. Recibirás actualizaciones instantáneas.',
            '🎉',
            'sistema',
            'alta',
            false,
            false,
            '/dashboard',
            jsonb_build_object(
                'tipo_evento', 'test_realtime',
                'timestamp', now()
            )
        );
        
        -- Notificación de comunidad
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            icono,
            categoria,
            prioridad,
            leida,
            archivada,
            url_accion,
            datos_adicionales
        ) VALUES (
            test_user_id,
            'nuevo_comentario',
            'Nuevo comentario en tu publicación',
            'Alguien ha comentado en tu publicación de la comunidad. ¡Ve a verlo!',
            '💬',
            'comunidad',
            'normal',
            false,
            false,
            '/comunidad',
            jsonb_build_object(
                'tipo_evento', 'test_comentario',
                'timestamp', now()
            )
        );
        
        -- Notificación de progreso
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            icono,
            categoria,
            prioridad,
            leida,
            archivada,
            url_accion,
            datos_adicionales
        ) VALUES (
            test_user_id,
            'progreso_curso',
            '¡Felicitaciones por tu progreso!',
            'Has completado el 75% del curso. ¡Sigue así!',
            '🎯',
            'progreso',
            'normal',
            false,
            false,
            '/cursos',
            jsonb_build_object(
                'tipo_evento', 'test_progreso',
                'porcentaje', 75,
                'timestamp', now()
            )
        );
        
        RAISE NOTICE '✅ Notificaciones de prueba generadas exitosamente';
        
        -- 4. Mostrar estadísticas actuales
        RAISE NOTICE '📊 Estadísticas actuales:';
        
        -- Contar notificaciones por usuario
        PERFORM (
            SELECT 
                COUNT(*) as total_notificaciones,
                COUNT(*) FILTER (WHERE NOT leida) as no_leidas
            FROM notificaciones 
            WHERE usuario_id = test_user_id
        );
        
    ELSE
        RAISE NOTICE '❌ No se encontraron usuarios para testing';
    END IF;
END $$;

-- 5. Mostrar resumen de notificaciones recientes
SELECT 'NOTIFICACIONES RECIENTES' as info;
SELECT 
    n.titulo,
    n.mensaje,
    n.categoria,
    n.prioridad,
    n.leida,
    p.nombre_completo as usuario,
    n.fecha_creacion
FROM notificaciones n
JOIN perfiles p ON n.usuario_id = p.id
WHERE n.fecha_creacion >= NOW() - INTERVAL '1 hour'
ORDER BY n.fecha_creacion DESC
LIMIT 10;

-- 6. Verificar triggers
SELECT 'TRIGGERS ACTIVOS' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'notificaciones'
ORDER BY trigger_name; 