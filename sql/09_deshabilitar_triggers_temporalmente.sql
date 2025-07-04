-- ============================================
-- DESHABILITAR TRIGGERS TEMPORALMENTE
-- ============================================

-- Verificar si hay algún trigger en comunidad_comentarios
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_comentarios';

-- Verificar si hay funciones que referencien entidad_id
SELECT 
    routine_name, 
    routine_definition
FROM information_schema.routines 
WHERE routine_definition ILIKE '%entidad_id%'
AND routine_type = 'FUNCTION';

-- Si encuentras algún trigger problemático, puedes deshabilitarlo con:
-- DROP TRIGGER IF EXISTS nombre_del_trigger ON comunidad_comentarios;

-- También verificar si hay alguna función RPC que se ejecute automáticamente
SELECT 
    proname as function_name,
    prosrc as source_code
FROM pg_proc 
WHERE prosrc ILIKE '%entidad_id%' 
AND proname NOT LIKE 'pg_%';

-- Verificar si hay algún webhook configurado (esto aparecería en los logs de Supabase)
-- No se puede verificar desde SQL, pero revisa en Dashboard > Database > Webhooks

-- SOLUCIÓN TEMPORAL: Si hay algún trigger problemático, lo deshabilitamos
-- Ejemplo (ajusta según lo que encuentres):
-- ALTER TABLE comunidad_comentarios DISABLE TRIGGER ALL;

-- Para volver a habilitar después:
-- ALTER TABLE comunidad_comentarios ENABLE TRIGGER ALL; 