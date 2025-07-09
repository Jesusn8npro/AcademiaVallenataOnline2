-- =====================================================
-- 🔍 DIAGNÓSTICO CORREGIDO - Con nombres correctos de columnas
-- =====================================================

-- Paso 1: Verificar que las tablas gaming tienen datos
SELECT 'EXPERIENCIA_USUARIO' as tabla, COUNT(*) as registros FROM experiencia_usuario
UNION ALL
SELECT 'ESTADISTICAS_USUARIO' as tabla, COUNT(*) as registros FROM estadisticas_usuario
UNION ALL
SELECT 'RANKING_GLOBAL' as tabla, COUNT(*) as registros FROM ranking_global;

-- Paso 2: Ver datos reales en experiencia_usuario
SELECT 'Datos en experiencia_usuario:' as info;
SELECT usuario_id, nivel, xp_total, xp_cursos, xp_comunidad, created_at 
FROM experiencia_usuario 
ORDER BY xp_total DESC 
LIMIT 5;

-- Paso 3: Ver datos reales en estadisticas_usuario  
SELECT 'Datos en estadisticas_usuario:' as info;
SELECT usuario_id, cursos_completados, tutoriales_completados, publicaciones_creadas, likes_recibidos
FROM estadisticas_usuario 
ORDER BY cursos_completados DESC 
LIMIT 5;

-- Paso 4: Verificar IDs de usuarios en perfiles (CORREGIDO)
SELECT 'Primeros 5 usuarios en perfiles:' as info;
SELECT id, nombre, correo_electronico, eliminado 
FROM perfiles 
WHERE (eliminado = false OR eliminado IS NULL)
ORDER BY fecha_creacion DESC 
LIMIT 5;

-- Paso 5: CONSULTA CORREGIDA - Verificar JOIN con nombres correctos
SELECT 
    p.nombre,
    p.id as perfil_id,
    eu.usuario_id as gaming_user_id,
    eu.nivel,
    eu.xp_total,
    est.cursos_completados,
    est.tutoriales_completados,
    est.publicaciones_creadas,
    est.likes_recibidos
FROM perfiles p
LEFT JOIN experiencia_usuario eu ON eu.usuario_id = p.id
LEFT JOIN estadisticas_usuario est ON est.usuario_id = p.id
WHERE (p.eliminado = false OR p.eliminado IS NULL)
ORDER BY eu.xp_total DESC NULLS LAST
LIMIT 10;

-- Paso 6: Verificación de conteos
SELECT 
    'Verificación de IDs:' as info,
    (SELECT COUNT(*) FROM perfiles WHERE (eliminado = false OR eliminado IS NULL)) as usuarios_perfiles,
    (SELECT COUNT(*) FROM experiencia_usuario) as usuarios_gaming,
    (SELECT COUNT(*) FROM estadisticas_usuario) as usuarios_estadisticas;

-- Paso 7: Mostrar usuarios que SÍ tienen datos gaming
SELECT 
    'Usuarios CON datos gaming:' as info;
SELECT 
    p.nombre,
    p.id,
    eu.nivel,
    eu.xp_total,
    est.cursos_completados,
    est.tutoriales_completados
FROM perfiles p
INNER JOIN experiencia_usuario eu ON eu.usuario_id = p.id
INNER JOIN estadisticas_usuario est ON est.usuario_id = p.id
WHERE (p.eliminado = false OR p.eliminado IS NULL)
ORDER BY eu.xp_total DESC;

-- Paso 8: Mostrar usuarios que NO tienen datos gaming
SELECT 
    'Usuarios SIN datos gaming:' as info;
SELECT 
    p.nombre,
    p.id,
    p.eliminado,
    CASE 
        WHEN EXISTS(SELECT 1 FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true) THEN 'SÍ'
        ELSE 'NO'
    END as tiene_inscripciones,
    CASE 
        WHEN EXISTS(SELECT 1 FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id) THEN 'SÍ'
        ELSE 'NO'
    END as tiene_publicaciones
FROM perfiles p
LEFT JOIN experiencia_usuario eu ON eu.usuario_id = p.id
WHERE eu.usuario_id IS NULL
AND (p.eliminado = false OR p.eliminado IS NULL)
LIMIT 10;

-- Paso 9: Verificar actividad real de usuarios específicos
SELECT 'Actividad real por usuario:' as info;
SELECT 
    p.nombre,
    p.id,
    (SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.curso_id IS NOT NULL) as cursos_completados,
    (SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.tutorial_id IS NOT NULL) as tutoriales_completados,
    (SELECT COUNT(*) FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id) as publicaciones_creadas,
    (SELECT COUNT(*) FROM comunidad_publicaciones_likes cpl 
     JOIN comunidad_publicaciones cp ON cp.id = cpl.publicacion_id
     WHERE cp.usuario_id = p.id) as likes_recibidos
FROM perfiles p
WHERE (p.eliminado = false OR p.eliminado IS NULL)
ORDER BY p.nombre
LIMIT 10; 