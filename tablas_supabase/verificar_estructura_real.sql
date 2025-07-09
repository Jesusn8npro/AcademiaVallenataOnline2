-- ===================================================
-- 🔍 VERIFICAR ESTRUCTURA REAL DE TABLAS GAMING
-- ===================================================

-- Verificar columnas de cada tabla gaming
SELECT 'experiencia_usuario' as tabla, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'experiencia_usuario'
ORDER BY ordinal_position;

SELECT 'estadisticas_usuario' as tabla, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'estadisticas_usuario'
ORDER BY ordinal_position;

SELECT 'monedas_usuario' as tabla, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'monedas_usuario'
ORDER BY ordinal_position;

SELECT 'ranking_global' as tabla, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'ranking_global'
ORDER BY ordinal_position;

SELECT 'sesiones_simulador' as tabla, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'sesiones_simulador'
ORDER BY ordinal_position;

SELECT 'logros_usuario' as tabla, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'logros_usuario'
ORDER BY ordinal_position;

SELECT 'logros_sistema' as tabla, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'logros_sistema'
ORDER BY ordinal_position;

SELECT 'notificaciones_gaming' as tabla, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'notificaciones_gaming'
ORDER BY ordinal_position; 