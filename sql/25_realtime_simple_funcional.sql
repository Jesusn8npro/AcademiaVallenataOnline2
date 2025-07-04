-- ============================================
-- REALTIME SIMPLE Y FUNCIONAL
-- ============================================

-- 1. Habilitar realtime en notificaciones (puede dar error si ya está habilitado, eso es normal)
ALTER PUBLICATION supabase_realtime ADD TABLE notificaciones;

-- 2. Verificar que funciona
SELECT 'REALTIME HABILITADO EN:' as estado;
SELECT tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'notificaciones';

-- 3. Generar una notificación de prueba simple
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
    datos_adicionales
) 
SELECT 
    id,
    'test_realtime',
    '🔔 ¡Notificación en Tiempo Real!',
    'Esta notificación se generó automáticamente para probar el sistema en tiempo real. Si la ves aparecer sin recargar, ¡funciona!',
    '⚡',
    'sistema',
    'alta',
    false,
    false,
    jsonb_build_object(
        'test', true,
        'timestamp', now(),
        'tipo_evento', 'prueba_realtime'
    )
FROM perfiles 
ORDER BY fecha_creacion DESC 
LIMIT 1;

-- 4. Mostrar las notificaciones recientes
SELECT 'NOTIFICACIONES RECIENTES:' as info;
SELECT 
    titulo,
    mensaje,
    categoria,
    fecha_creacion,
    leida
FROM notificaciones 
ORDER BY fecha_creacion DESC 
LIMIT 5;

-- 5. Contar notificaciones no leídas
SELECT 'ESTADÍSTICAS:' as info;
SELECT 
    COUNT(*) as total_notificaciones,
    COUNT(*) FILTER (WHERE NOT leida) as no_leidas,
    COUNT(*) FILTER (WHERE categoria = 'sistema') as notificaciones_sistema
FROM notificaciones; 