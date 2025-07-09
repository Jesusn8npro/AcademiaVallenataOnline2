-- ===================================================
-- 🔍 VERIFICAR TABLAS GAMING
-- ===================================================

-- Verificar si las tablas gaming existen
SELECT 
    schemaname,
    tablename,
    tableowner,
    hasindexes,
    hasrules,
    hastriggers
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'experiencia_usuario',
    'logros_sistema', 
    'logros_usuario',
    'ranking_global',
    'sesiones_simulador',
    'monedas_usuario',
    'estadisticas_usuario',
    'notificaciones_gaming'
)
ORDER BY tablename;

-- Verificar constraints únicas
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
AND tc.table_name IN (
    'experiencia_usuario',
    'logros_sistema', 
    'logros_usuario',
    'ranking_global',
    'sesiones_simulador',
    'monedas_usuario',
    'estadisticas_usuario',
    'notificaciones_gaming'
)
AND tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY')
ORDER BY tc.table_name, tc.constraint_name; 