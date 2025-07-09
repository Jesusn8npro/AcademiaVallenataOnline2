-- =====================================================
-- 🔄 SINCRONIZACIÓN SIMPLE DE DATOS REALES
-- =====================================================
-- Script simplificado que funciona sin errores

-- Paso 1: Crear registros de experiencia para usuarios con actividad
INSERT INTO experiencia_usuario (
    usuario_id, 
    nivel, 
    xp_actual, 
    xp_total, 
    xp_cursos, 
    xp_comunidad,
    ultima_sesion
)
SELECT 
    p.id as usuario_id,
    GREATEST(1, (
        -- Calcular nivel basado en actividad
        COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.curso_id IS NOT NULL), 0) * 100 +
        COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.tutorial_id IS NOT NULL), 0) * 50 +
        COALESCE((SELECT COUNT(*) FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id), 0) * 15
    ) / 100) as nivel,
    
    -- XP actual (resto de división por 100)
    (
        COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.curso_id IS NOT NULL), 0) * 100 +
        COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.tutorial_id IS NOT NULL), 0) * 50 +
        COALESCE((SELECT COUNT(*) FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id), 0) * 15
    ) % 100 as xp_actual,
    
    -- XP total
    COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.curso_id IS NOT NULL), 0) * 100 +
    COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.tutorial_id IS NOT NULL), 0) * 50 +
    COALESCE((SELECT COUNT(*) FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id), 0) * 15 as xp_total,
    
    -- XP de cursos
    COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.curso_id IS NOT NULL), 0) * 100 +
    COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.tutorial_id IS NOT NULL), 0) * 50 as xp_cursos,
    
    -- XP de comunidad
    COALESCE((SELECT COUNT(*) FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id), 0) * 15 as xp_comunidad,
    
    NOW() as ultima_sesion

FROM perfiles p
WHERE (p.eliminado = false OR p.eliminado IS NULL)
AND p.id NOT IN (SELECT usuario_id FROM experiencia_usuario)
AND (
    -- Solo usuarios con alguna actividad
    EXISTS (SELECT 1 FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true) OR
    EXISTS (SELECT 1 FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id)
);

-- Paso 2: Crear estadísticas para usuarios con actividad
INSERT INTO estadisticas_usuario (
    usuario_id,
    cursos_completados,
    tutoriales_completados,
    publicaciones_creadas,
    likes_recibidos,
    calculado_en
)
SELECT 
    p.id as usuario_id,
    COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.curso_id IS NOT NULL), 0) as cursos_completados,
    COALESCE((SELECT COUNT(*) FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true AND i.tutorial_id IS NOT NULL), 0) as tutoriales_completados,
    COALESCE((SELECT COUNT(*) FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id), 0) as publicaciones_creadas,
    COALESCE((
        SELECT COUNT(*) 
        FROM comunidad_publicaciones_likes cpl 
        JOIN comunidad_publicaciones cp ON cp.id = cpl.publicacion_id
        WHERE cp.usuario_id = p.id
    ), 0) as likes_recibidos,
    NOW() as calculado_en
FROM perfiles p
WHERE (p.eliminado = false OR p.eliminado IS NULL)
AND p.id NOT IN (SELECT usuario_id FROM estadisticas_usuario)
AND (
    EXISTS (SELECT 1 FROM inscripciones i WHERE i.usuario_id = p.id AND i.completado = true) OR
    EXISTS (SELECT 1 FROM comunidad_publicaciones cp WHERE cp.usuario_id = p.id)
);

-- Paso 3: Crear ranking global
INSERT INTO ranking_global (
    usuario_id,
    tipo_ranking,
    puntuacion,
    posicion,
    metricas,
    activo,
    calculated_at
)
SELECT 
    eu.usuario_id,
    'general' as tipo_ranking,
    eu.xp_total as puntuacion,
    ROW_NUMBER() OVER (ORDER BY eu.xp_total DESC, eu.created_at ASC) as posicion,
    jsonb_build_object(
        'nivel', eu.nivel,
        'xp_total', eu.xp_total,
        'cursos_completados', COALESCE(est.cursos_completados, 0),
        'tutoriales_completados', COALESCE(est.tutoriales_completados, 0),
        'publicaciones_creadas', COALESCE(est.publicaciones_creadas, 0),
        'likes_recibidos', COALESCE(est.likes_recibidos, 0),
        'es_gaming', true
    ) as metricas,
    true as activo,
    NOW() as calculated_at
FROM experiencia_usuario eu
LEFT JOIN estadisticas_usuario est ON est.usuario_id = eu.usuario_id
WHERE eu.usuario_id NOT IN (
    SELECT usuario_id FROM ranking_global WHERE tipo_ranking = 'general'
);

-- Paso 4: Mostrar resultados
SELECT 
    'Sincronización simple completada' as mensaje,
    (SELECT COUNT(*) FROM experiencia_usuario) as usuarios_con_xp,
    (SELECT COUNT(*) FROM estadisticas_usuario) as usuarios_con_estadisticas,
    (SELECT COUNT(*) FROM ranking_global WHERE tipo_ranking = 'general') as usuarios_en_ranking; 