-- ==========================================
-- 🎯 SCRIPT ENFOCADO - SOLO TRACKING TABLES
-- ==========================================
-- Solo para sesiones_usuario y eventos_actividad

-- 📋 1. ESTRUCTURA COMPLETA: SESIONES_USUARIO
SELECT 
    '=== SESIONES_USUARIO ===' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'sesiones_usuario'
ORDER BY ordinal_position;

-- 📋 2. ESTRUCTURA COMPLETA: EVENTOS_ACTIVIDAD
SELECT 
    '=== EVENTOS_ACTIVIDAD ===' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'eventos_actividad'
ORDER BY ordinal_position;

-- 📋 3. DATOS EJEMPLO SESIONES_USUARIO (últimos 5)
SELECT 
    '=== EJEMPLO SESIONES_USUARIO ===' as info;
    
SELECT * FROM sesiones_usuario 
ORDER BY ultima_actividad DESC 
LIMIT 5;

-- 📋 4. DATOS EJEMPLO EVENTOS_ACTIVIDAD (últimos 5)
SELECT 
    '=== EJEMPLO EVENTOS_ACTIVIDAD ===' as info;
    
SELECT * FROM eventos_actividad 
ORDER BY timestamp_evento DESC 
LIMIT 5;

-- 📋 5. CONTEOS Y ESTADÍSTICAS
SELECT 
    'sesiones_usuario' as tabla,
    COUNT(*) as total,
    COUNT(CASE WHEN esta_activo = true THEN 1 END) as activos,
    MAX(ultima_actividad) as ultima_actividad_max
FROM sesiones_usuario
UNION ALL
SELECT 
    'eventos_actividad' as tabla,
    COUNT(*) as total,
    COUNT(CASE WHEN tipo_evento = 'navegacion' THEN 1 END) as navegacion,
    MAX(timestamp_evento) as ultimo_evento
FROM eventos_actividad; 