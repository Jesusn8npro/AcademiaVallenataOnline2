-- =====================================================
-- 🏆 FUNCIÓN PARA RANKING PAGINADO - SCROLL INFINITO
-- =====================================================
-- Esta función permite obtener usuarios del ranking 
-- de forma paginada para implementar scroll infinito
-- =====================================================

CREATE OR REPLACE FUNCTION obtener_ranking_hibrido_paginado(
    p_tipo_ranking TEXT DEFAULT 'general',
    p_limite INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    usuario_id UUID,
    posicion INTEGER,
    puntuacion INTEGER,
    nombre TEXT,
    apellido TEXT,
    url_foto_perfil TEXT,
    nivel INTEGER,
    xp_total INTEGER,
    cursos_completados INTEGER,
    tutoriales_completados INTEGER,
    publicaciones_creadas INTEGER,
    likes_recibidos INTEGER,
    comentarios_hechos INTEGER,
    racha_actual_dias INTEGER,
    logros_totales INTEGER,
    es_gaming BOOLEAN,
    total_sesiones INTEGER,
    tiempo_total_minutos INTEGER,
    precision_promedio DECIMAL,
    racha_maxima INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Obtener usuarios con ranking paginado
    RETURN QUERY
    WITH usuarios_ordenados AS (
        SELECT DISTINCT
            COALESCE(eu.usuario_id, p.id) as usuario_id,
            COALESCE(p.nombre, 'Usuario') as nombre,
            COALESCE(p.apellido, '') as apellido,
            p.url_foto_perfil,
            COALESCE(eu.nivel, 1) as nivel,
            COALESCE(eu.xp_total, 0) as xp_total,
            COALESCE(est.cursos_completados, 0) as cursos_completados,
            COALESCE(est.tutoriales_completados, 0) as tutoriales_completados,
            COALESCE(est.publicaciones_creadas, 0) as publicaciones_creadas,
            COALESCE(est.likes_recibidos, 0) as likes_recibidos,
            COALESCE(est.comentarios_hechos, 0) as comentarios_hechos,
            COALESCE(est.racha_actual_dias, 0) as racha_actual_dias,
            COALESCE(est.logros_totales, 0) as logros_totales,
            COALESCE(est.racha_maxima_dias, 0) as racha_maxima,
            COALESCE(est.total_sesiones, 0) as total_sesiones,
            COALESCE(est.tiempo_total_minutos, 0) as tiempo_total_minutos,
            COALESCE(est.precision_promedio, 0) as precision_promedio,
            CASE 
                WHEN eu.usuario_id IS NOT NULL THEN TRUE
                ELSE FALSE
            END as es_gaming,
            
            -- Calcular puntuación según tipo de ranking
            CASE 
                WHEN p_tipo_ranking = 'cursos' THEN 
                    COALESCE(eu.xp_cursos, 0) + 
                    (COALESCE(est.cursos_completados, 0) * 100) + 
                    (COALESCE(est.tutoriales_completados, 0) * 50)
                WHEN p_tipo_ranking = 'comunidad' THEN 
                    COALESCE(eu.xp_comunidad, 0) + 
                    (COALESCE(est.publicaciones_creadas, 0) * 15) + 
                    (COALESCE(est.likes_recibidos, 0) * 2) + 
                    (COALESCE(est.comentarios_hechos, 0) * 5)
                WHEN p_tipo_ranking = 'simulador' THEN 
                    COALESCE(eu.xp_simulador, 0) + 
                    (COALESCE(est.precision_promedio, 0) * 10) + 
                    (COALESCE(est.total_sesiones, 0) * 20)
                WHEN p_tipo_ranking = 'constancia' THEN 
                    (COALESCE(est.racha_actual_dias, 0) * 50) + 
                    (COALESCE(est.racha_maxima_dias, 0) * 10) + 
                    (COALESCE(est.dias_activos_total, 0) * 5)
                ELSE 
                    COALESCE(eu.xp_total, 0) + 
                    (COALESCE(est.cursos_completados, 0) * 100) + 
                    (COALESCE(est.publicaciones_creadas, 0) * 15) + 
                    (COALESCE(est.likes_recibidos, 0) * 2)
            END as puntuacion_calculada
            
        FROM perfiles p
        LEFT JOIN experiencia_usuario eu ON eu.usuario_id = p.id
        LEFT JOIN estadisticas_usuario est ON est.usuario_id = p.id
        WHERE p.eliminado = FALSE OR p.eliminado IS NULL
    ),
    usuarios_con_posicion AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (ORDER BY puntuacion_calculada DESC, nombre ASC) as posicion_calculada
        FROM usuarios_ordenados
        WHERE puntuacion_calculada > 0
    )
    SELECT 
        u.usuario_id,
        u.posicion_calculada::INTEGER as posicion,
        u.puntuacion_calculada::INTEGER as puntuacion,
        u.nombre,
        u.apellido,
        u.url_foto_perfil,
        u.nivel,
        u.xp_total,
        u.cursos_completados,
        u.tutoriales_completados,
        u.publicaciones_creadas,
        u.likes_recibidos,
        u.comentarios_hechos,
        u.racha_actual_dias,
        u.logros_totales,
        u.es_gaming,
        u.total_sesiones,
        u.tiempo_total_minutos,
        u.precision_promedio,
        u.racha_maxima
    FROM usuarios_con_posicion u
    ORDER BY u.posicion_calculada ASC
    LIMIT p_limite OFFSET p_offset;
END;
$$;

-- =====================================================
-- 🎯 COMENTARIO EXPLICATIVO
-- =====================================================
-- Esta función permite:
-- 1. Obtener usuarios del ranking de forma paginada
-- 2. Soportar diferentes tipos de ranking (general, cursos, comunidad, etc.)
-- 3. Incluir información completa del perfil (nombre, imagen, etc.)
-- 4. Calcular puntuación según el tipo de ranking
-- 5. Implementar scroll infinito eficiente
-- ===================================================== 