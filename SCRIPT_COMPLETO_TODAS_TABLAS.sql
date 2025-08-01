-- ==========================================
-- 🔍 SCRIPT COMPLETO - TODAS LAS TABLAS DEL PANEL
-- ==========================================
-- Ejecutar en Supabase SQL Editor para obtener información COMPLETA

-- 📋 1. ESTRUCTURA COMPLETA: TABLA PERFILES
SELECT 
    '=== TABLA PERFILES ===' as seccion,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'perfiles'
ORDER BY ordinal_position;

-- 📋 2. ESTRUCTURA COMPLETA: TABLA SESIONES_USUARIO
SELECT 
    '=== TABLA SESIONES_USUARIO ===' as seccion,
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

-- 📋 3. ESTRUCTURA COMPLETA: TABLA EVENTOS_ACTIVIDAD
SELECT 
    '=== TABLA EVENTOS_ACTIVIDAD ===' as seccion,
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

-- 📋 4. ESTRUCTURA COMPLETA: TABLA INSCRIPCIONES
SELECT 
    '=== TABLA INSCRIPCIONES ===' as seccion,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'inscripciones'
ORDER BY ordinal_position;

-- 📋 5. ESTRUCTURA COMPLETA: TABLA CURSOS
SELECT 
    '=== TABLA CURSOS ===' as seccion,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'cursos'
ORDER BY ordinal_position;

-- 📋 6. ESTRUCTURA COMPLETA: TABLA TUTORIALES
SELECT 
    '=== TABLA TUTORIALES ===' as seccion,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'tutoriales'
ORDER BY ordinal_position;

-- 📋 7. LLAVES PRIMARIAS Y FOREIGN KEYS
SELECT 
    '=== CONSTRAINTS Y RELACIONES ===' as seccion,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
    AND tc.table_name IN ('perfiles', 'sesiones_usuario', 'eventos_actividad', 'inscripciones', 'cursos', 'tutoriales')
ORDER BY tc.table_name, tc.constraint_type;

-- 📋 8. ÍNDICES EXISTENTES
SELECT 
    '=== ÍNDICES OPTIMIZACIÓN ===' as seccion,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('perfiles', 'sesiones_usuario', 'eventos_actividad', 'inscripciones', 'cursos', 'tutoriales')
    AND schemaname = 'public'
ORDER BY tablename, indexname;

-- 📋 9. DATOS DE EJEMPLO - SESIONES_USUARIO (últimos 3)
SELECT 
    '=== DATOS EJEMPLO SESIONES_USUARIO ===' as seccion,
    *
FROM sesiones_usuario 
ORDER BY ultima_actividad DESC 
LIMIT 3;

-- 📋 10. DATOS DE EJEMPLO - EVENTOS_ACTIVIDAD (últimos 3)
SELECT 
    '=== DATOS EJEMPLO EVENTOS_ACTIVIDAD ===' as seccion,
    *
FROM eventos_actividad 
ORDER BY timestamp_evento DESC 
LIMIT 3;

-- 📋 11. CONTEO DE REGISTROS EN CADA TABLA
SELECT 
    'perfiles' as tabla,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN rol = 'estudiante' THEN 1 END) as estudiantes,
    COUNT(CASE WHEN rol = 'admin' THEN 1 END) as admins
FROM perfiles
UNION ALL
SELECT 
    'sesiones_usuario' as tabla,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN esta_activo = true THEN 1 END) as activos,
    COUNT(CASE WHEN esta_activo = false THEN 1 END) as inactivos
FROM sesiones_usuario
UNION ALL
SELECT 
    'eventos_actividad' as tabla,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN tipo_evento = 'navegacion' THEN 1 END) as navegacion,
    COUNT(CASE WHEN tipo_evento != 'navegacion' THEN 1 END) as otros
FROM eventos_actividad
UNION ALL
SELECT 
    'inscripciones' as tabla,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN completado = true THEN 1 END) as completadas,
    COUNT(CASE WHEN completado = false THEN 1 END) as en_progreso
FROM inscripciones;

-- 📋 12. VERIFICAR POLÍTICAS RLS (Row Level Security)
SELECT 
    '=== POLÍTICAS DE SEGURIDAD ===' as seccion,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('perfiles', 'sesiones_usuario', 'eventos_actividad', 'inscripciones', 'cursos', 'tutoriales')
ORDER BY tablename, policyname; 