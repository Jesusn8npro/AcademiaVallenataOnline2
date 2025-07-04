-- ============================================
-- VERIFICAR Y CORREGIR TRIGGERS PROBLEMÁTICOS
-- ============================================

-- 1. Verificar si hay triggers en comunidad_comentarios
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement,
    action_timing,
    action_condition
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_comentarios';

-- 2. Verificar si hay funciones que usen entidad_id incorrectamente
SELECT 
    routine_name, 
    routine_definition
FROM information_schema.routines 
WHERE routine_definition ILIKE '%entidad_id%'
AND routine_type = 'FUNCTION'
AND routine_schema = 'public';

-- 3. Verificar si hay funciones RPC que puedan estar causando el problema
SELECT 
    proname as function_name,
    prosrc as source_code
FROM pg_proc 
WHERE prosrc ILIKE '%entidad_id%'
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================
-- DESHABILITAR TRIGGERS PROBLEMÁTICOS TEMPORALMENTE
-- ============================================

-- Si encuentras algún trigger que esté causando problemas, deshabilitarlo:
-- (Ejecuta solo si identificas el trigger problemático)

-- Ejemplo de cómo deshabilitar un trigger:
-- ALTER TABLE comunidad_comentarios DISABLE TRIGGER nombre_del_trigger;

-- O eliminar completamente si no es necesario:
-- DROP TRIGGER IF EXISTS nombre_del_trigger ON comunidad_comentarios;

-- ============================================
-- VERIFICAR POLÍTICAS RLS QUE PUEDAN INTERFERIR
-- ============================================

-- Verificar políticas en notificaciones
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

-- ============================================
-- SOLUCIÓN TEMPORAL: DESHABILITAR RLS EN NOTIFICACIONES
-- ============================================

-- Si las políticas RLS están causando problemas, deshabilitar temporalmente:
-- ALTER TABLE notificaciones DISABLE ROW LEVEL SECURITY;

-- ============================================
-- VERIFICAR ESTRUCTURA DE TABLA NOTIFICACIONES
-- ============================================

-- Confirmar que la tabla notificaciones tiene la estructura correcta
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notificaciones'
ORDER BY ordinal_position;

-- ============================================
-- CREAR FUNCIÓN SEGURA PARA NOTIFICACIONES
-- ============================================

-- Crear una función que maneje correctamente las notificaciones sin entidad_id obligatorio
CREATE OR REPLACE FUNCTION crear_notificacion_segura(
    p_usuario_id UUID,
    p_tipo TEXT,
    p_titulo TEXT,
    p_mensaje TEXT,
    p_categoria TEXT DEFAULT 'sistema',
    p_prioridad TEXT DEFAULT 'normal',
    p_url_accion TEXT DEFAULT NULL,
    p_icono TEXT DEFAULT '🔔',
    p_entidad_id UUID DEFAULT NULL,
    p_entidad_tipo TEXT DEFAULT NULL,
    p_datos_adicionales JSONB DEFAULT '{}'::jsonb
) RETURNS UUID AS $$
DECLARE
    nueva_notificacion_id UUID;
BEGIN
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        categoria,
        prioridad,
        url_accion,
        icono,
        entidad_id,
        entidad_tipo,
        datos_adicionales,
        leida,
        archivada,
        fecha_expiracion
    ) VALUES (
        p_usuario_id,
        p_tipo,
        p_titulo,
        p_mensaje,
        p_categoria,
        p_prioridad,
        p_url_accion,
        p_icono,
        p_entidad_id,  -- Puede ser NULL
        p_entidad_tipo,
        p_datos_adicionales,
        false,
        false,
        NOW() + INTERVAL '30 days'
    ) RETURNING id INTO nueva_notificacion_id;
    
    RETURN nueva_notificacion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- INSTRUCCIONES FINALES
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '🔍 EJECUTA ESTAS CONSULTAS PARA IDENTIFICAR EL PROBLEMA:';
    RAISE NOTICE '1. Revisa los triggers en comunidad_comentarios';
    RAISE NOTICE '2. Busca funciones que usen entidad_id';
    RAISE NOTICE '3. Verifica las políticas RLS en notificaciones';
    RAISE NOTICE '4. Si encuentras triggers problemáticos, deshabílalos temporalmente';
    RAISE NOTICE '5. Usa la función crear_notificacion_segura() en lugar de inserts directos';
END $$; 