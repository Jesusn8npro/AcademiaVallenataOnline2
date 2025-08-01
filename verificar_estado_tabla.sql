-- 🔍 VERIFICAR ESTADO REAL DE LA TABLA GEOLOCALIZACION
-- =====================================================

-- 1. Contar registros totales
SELECT COUNT(*) as total_registros FROM geolocalizacion_usuarios;

-- 2. Ver todos los registros actuales (si los hay)
SELECT 
    g.usuario_id,
    g.ip,
    g.pais,
    g.ciudad,
    g.ultima_visita,
    g.visitas_totales,
    p.nombre_completo,
    u.email
FROM geolocalizacion_usuarios g
LEFT JOIN perfiles p ON g.usuario_id = p.id
LEFT JOIN auth.users u ON g.usuario_id = u.id
ORDER BY g.ultima_visita DESC;

-- 3. Ver usuarios registrados en el sistema
SELECT 
    u.id,
    u.email,
    p.nombre,
    p.apellido,
    p.nombre_completo,
    u.created_at
FROM auth.users u
LEFT JOIN perfiles p ON u.id = p.id
ORDER BY u.created_at DESC;

-- 4. Verificar si existen las funciones necesarias
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name IN ('upsert_geolocalizacion_usuario', 'obtener_estadisticas_geograficas');

-- 5. LIMPIAR COMPLETAMENTE LA TABLA (eliminar datos falsos)
DELETE FROM geolocalizacion_usuarios;

-- 6. Verificar que se limpiaron
SELECT COUNT(*) as registros_despues_limpiar FROM geolocalizacion_usuarios;

SELECT '🎯 Tabla limpiada - Ahora deberías ver "Sin datos" en lugar de datos falsos' as resultado; 