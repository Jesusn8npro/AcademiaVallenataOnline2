-- ============================================
-- HABILITAR REALTIME PARA NOTIFICACIONES
-- ============================================

-- 1. Habilitar realtime en la tabla notificaciones
ALTER PUBLICATION supabase_realtime ADD TABLE notificaciones;

-- 2. Verificar que realtime está habilitado (CORREGIDO)
SELECT 'VERIFICANDO REALTIME' as paso;
SELECT 
    schemaname,
    tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'notificaciones';

-- 3. Verificar estructura de la tabla notificaciones
SELECT 'ESTRUCTURA DE TABLA NOTIFICACIONES' as paso;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notificaciones' 
ORDER BY ordinal_position;

-- 4. Crear función para notificar cambios en tiempo real (opcional)
CREATE OR REPLACE FUNCTION notificar_cambio_notificacion()
RETURNS TRIGGER AS $$
BEGIN
    -- Notificar cambio para que los clientes se actualicen
    PERFORM pg_notify(
        'notificacion_cambio', 
        json_build_object(
            'evento', TG_OP,
            'usuario_id', COALESCE(NEW.usuario_id, OLD.usuario_id),
            'notificacion_id', COALESCE(NEW.id, OLD.id)
        )::text
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 5. Crear trigger para notificar cambios
DROP TRIGGER IF EXISTS trigger_notificar_cambio_notificacion ON notificaciones;

CREATE TRIGGER trigger_notificar_cambio_notificacion
    AFTER INSERT OR UPDATE OR DELETE ON notificaciones
    FOR EACH ROW
    EXECUTE FUNCTION notificar_cambio_notificacion();

-- 6. Verificar que la configuración está correcta
SELECT 'CONFIGURACIÓN REALTIME COMPLETADA' as estado;

-- Mostrar información sobre la publicación
SELECT 
    'TABLAS CON REALTIME HABILITADO' as info,
    schemaname,
    tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename; 