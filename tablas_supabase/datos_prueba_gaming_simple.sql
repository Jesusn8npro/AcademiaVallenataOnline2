-- ===================================================
-- 🎮 DATOS DE PRUEBA GAMING - VERSIÓN SIMPLIFICADA
-- ===================================================

-- ⚠️ IMPORTANTE: Primero ejecutar gamificacion_completa.sql

-- ===================================================
-- 🔍 VERIFICAR TABLAS GAMING
-- ===================================================

DO $$
DECLARE
    table_count INTEGER;
BEGIN
    -- Verificar si existen las tablas gaming
    SELECT COUNT(*) INTO table_count
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
    );
    
    IF table_count < 8 THEN
        RAISE EXCEPTION '❌ ERROR: Faltan tablas gaming. Primero ejecuta gamificacion_completa.sql';
    ELSE
        RAISE NOTICE '✅ Tablas gaming encontradas: %', table_count;
    END IF;
END $$;

-- ===================================================
-- 🧹 LIMPIAR DATOS EXISTENTES
-- ===================================================

-- Limpiar datos de prueba existentes (en orden correcto por FK)
DELETE FROM notificaciones_gaming WHERE usuario_id IN (SELECT id FROM perfiles LIMIT 3);
DELETE FROM sesiones_simulador WHERE usuario_id IN (SELECT id FROM perfiles LIMIT 3);
DELETE FROM logros_usuario WHERE usuario_id IN (SELECT id FROM perfiles LIMIT 3);
DELETE FROM estadisticas_usuario WHERE usuario_id IN (SELECT id FROM perfiles LIMIT 3);
DELETE FROM monedas_usuario WHERE usuario_id IN (SELECT id FROM perfiles LIMIT 3);
DELETE FROM ranking_global WHERE usuario_id IN (SELECT id FROM perfiles LIMIT 3);
DELETE FROM experiencia_usuario WHERE usuario_id IN (SELECT id FROM perfiles LIMIT 3);

-- ===================================================
-- 📊 INSERTAR DATOS DE EXPERIENCIA
-- ===================================================

-- Usuario 1: Nivel alto
INSERT INTO experiencia_usuario (
    usuario_id, nivel, xp_actual, xp_total, xp_siguiente_nivel, 
    xp_cursos, xp_simulador, xp_comunidad, xp_logros, 
    racha_dias, racha_maxima, ultima_sesion
) VALUES (
    (SELECT id FROM perfiles LIMIT 1 OFFSET 0), 
    15, 2500, 12500, 3000, 
    3000, 6000, 2000, 1500, 
    7, 15, NOW() - INTERVAL '2 hours'
);

-- Usuario 2: Nivel medio
INSERT INTO experiencia_usuario (
    usuario_id, nivel, xp_actual, xp_total, xp_siguiente_nivel, 
    xp_cursos, xp_simulador, xp_comunidad, xp_logros, 
    racha_dias, racha_maxima, ultima_sesion
) VALUES (
    (SELECT id FROM perfiles LIMIT 1 OFFSET 1), 
    8, 800, 4800, 1200, 
    1500, 2000, 800, 500, 
    3, 8, NOW() - INTERVAL '1 day'
);

-- Usuario 3: Nivel bajo
INSERT INTO experiencia_usuario (
    usuario_id, nivel, xp_actual, xp_total, xp_siguiente_nivel, 
    xp_cursos, xp_simulador, xp_comunidad, xp_logros, 
    racha_dias, racha_maxima, ultima_sesion
) VALUES (
    (SELECT id FROM perfiles LIMIT 1 OFFSET 2), 
    3, 150, 650, 400, 
    200, 300, 100, 50, 
    1, 4, NOW() - INTERVAL '3 days'
);

-- ===================================================
-- 🏆 INSERTAR RANKING GLOBAL
-- ===================================================

-- Ranking General
INSERT INTO ranking_global (usuario_id, tipo_ranking, puntuacion, posicion, posicion_anterior, metricas, periodo_inicio, activo) VALUES
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'general', 12500, 1, 2, '{"nivel": 15, "precision_promedio": 95, "total_sesiones": 45, "tiempo_total_minutos": 1200, "logros_conseguidos": 8, "racha_maxima": 15}', CURRENT_DATE - INTERVAL '7 days', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'general', 4800, 2, 1, '{"nivel": 8, "precision_promedio": 87, "total_sesiones": 28, "tiempo_total_minutos": 600, "logros_conseguidos": 4, "racha_maxima": 8}', CURRENT_DATE - INTERVAL '7 days', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 'general', 650, 3, null, '{"nivel": 3, "precision_promedio": 72, "total_sesiones": 12, "tiempo_total_minutos": 180, "logros_conseguidos": 1, "racha_maxima": 4}', CURRENT_DATE - INTERVAL '7 days', true);

-- Ranking Simulador
INSERT INTO ranking_global (usuario_id, tipo_ranking, puntuacion, posicion, posicion_anterior, metricas, periodo_inicio, activo) VALUES
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'simulador', 8500, 1, 1, '{"precision_promedio": 95, "total_sesiones": 30, "tiempo_total_minutos": 900, "notas_correctas": 2850}', CURRENT_DATE - INTERVAL '7 days', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'simulador', 3200, 2, 3, '{"precision_promedio": 87, "total_sesiones": 18, "tiempo_total_minutos": 450, "notas_correctas": 1566}', CURRENT_DATE - INTERVAL '7 days', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 'simulador', 720, 3, 2, '{"precision_promedio": 72, "total_sesiones": 8, "tiempo_total_minutos": 120, "notas_correctas": 576}', CURRENT_DATE - INTERVAL '7 days', true);

-- Ranking Cursos
INSERT INTO ranking_global (usuario_id, tipo_ranking, puntuacion, posicion, posicion_anterior, metricas, periodo_inicio, activo) VALUES
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'cursos', 4500, 1, null, '{"cursos_completados": 5, "lecciones_completadas": 45, "promedio_calificaciones": 4.8}', CURRENT_DATE - INTERVAL '7 days', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'cursos', 2400, 2, null, '{"cursos_completados": 3, "lecciones_completadas": 28, "promedio_calificaciones": 4.2}', CURRENT_DATE - INTERVAL '7 days', true);

-- Ranking Precisión
INSERT INTO ranking_global (usuario_id, tipo_ranking, puntuacion, posicion, posicion_anterior, metricas, periodo_inicio, activo) VALUES
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'precision', 9500, 1, 1, '{"precision_maxima": 98, "precision_promedio": 95, "notas_perfectas": 850}', CURRENT_DATE - INTERVAL '7 days', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'precision', 4350, 2, 2, '{"precision_maxima": 92, "precision_promedio": 87, "notas_perfectas": 450}', CURRENT_DATE - INTERVAL '7 days', true);

-- Ranking Constancia
INSERT INTO ranking_global (usuario_id, tipo_ranking, puntuacion, posicion, posicion_anterior, metricas, periodo_inicio, activo) VALUES
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'constancia', 1500, 1, 2, '{"racha_actual": 7, "racha_maxima": 15, "dias_activos": 45}', CURRENT_DATE - INTERVAL '7 days', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'constancia', 800, 2, 1, '{"racha_actual": 3, "racha_maxima": 8, "dias_activos": 28}', CURRENT_DATE - INTERVAL '7 days', true);

-- Ranking Comunidad
INSERT INTO ranking_global (usuario_id, tipo_ranking, puntuacion, posicion, posicion_anterior, metricas, periodo_inicio, activo) VALUES
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'comunidad', 2000, 1, null, '{"publicaciones_creadas": 15, "likes_recibidos": 125, "comentarios_hechos": 45}', CURRENT_DATE - INTERVAL '7 days', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'comunidad', 800, 2, null, '{"publicaciones_creadas": 8, "likes_recibidos": 45, "comentarios_hechos": 22}', CURRENT_DATE - INTERVAL '7 days', true);

-- ===================================================
-- 📈 INSERTAR ESTADÍSTICAS
-- ===================================================

-- Usuario 1: Estadísticas avanzadas
INSERT INTO estadisticas_usuario (
    usuario_id, total_sesiones, tiempo_total_minutos, primer_sesion, ultima_sesion,
    precision_maxima, precision_promedio, notas_totales_tocadas, notas_correctas_totales,
    cursos_completados, tutoriales_completados, lecciones_completadas,
    publicaciones_creadas, likes_recibidos, comentarios_hechos,
    logros_totales, logros_faciles, logros_medios, logros_dificiles, logros_legendarios,
    racha_actual_dias, racha_maxima_dias, dias_activos_total,
    mejor_posicion_global, mejor_posicion_semanal, semanas_en_top_10, calculado_en
) VALUES (
    (SELECT id FROM perfiles LIMIT 1 OFFSET 0), 
    45, 1200, NOW() - INTERVAL '3 months', NOW() - INTERVAL '2 hours',
    98, 95, 3000, 2850, 5, 12, 45,
    15, 125, 45, 8, 3, 3, 2, 0,
    7, 15, 45, 1, 1, 8, NOW()
);

-- Usuario 2: Estadísticas intermedias
INSERT INTO estadisticas_usuario (
    usuario_id, total_sesiones, tiempo_total_minutos, primer_sesion, ultima_sesion,
    precision_maxima, precision_promedio, notas_totales_tocadas, notas_correctas_totales,
    cursos_completados, tutoriales_completados, lecciones_completadas,
    publicaciones_creadas, likes_recibidos, comentarios_hechos,
    logros_totales, logros_faciles, logros_medios, logros_dificiles, logros_legendarios,
    racha_actual_dias, racha_maxima_dias, dias_activos_total,
    mejor_posicion_global, mejor_posicion_semanal, semanas_en_top_10, calculado_en
) VALUES (
    (SELECT id FROM perfiles LIMIT 1 OFFSET 1), 
    28, 600, NOW() - INTERVAL '2 months', NOW() - INTERVAL '1 day',
    92, 87, 1800, 1566, 3, 8, 28,
    8, 45, 22, 4, 2, 2, 0, 0,
    3, 8, 28, 2, 3, 4, NOW()
);

-- Usuario 3: Estadísticas básicas
INSERT INTO estadisticas_usuario (
    usuario_id, total_sesiones, tiempo_total_minutos, primer_sesion, ultima_sesion,
    precision_maxima, precision_promedio, notas_totales_tocadas, notas_correctas_totales,
    cursos_completados, tutoriales_completados, lecciones_completadas,
    publicaciones_creadas, likes_recibidos, comentarios_hechos,
    logros_totales, logros_faciles, logros_medios, logros_dificiles, logros_legendarios,
    racha_actual_dias, racha_maxima_dias, dias_activos_total,
    mejor_posicion_global, mejor_posicion_semanal, semanas_en_top_10, calculado_en
) VALUES (
    (SELECT id FROM perfiles LIMIT 1 OFFSET 2), 
    12, 180, NOW() - INTERVAL '1 month', NOW() - INTERVAL '3 days',
    85, 72, 800, 576, 1, 3, 12,
    3, 12, 8, 1, 1, 0, 0, 0,
    1, 4, 12, 5, null, 0, NOW()
);

-- ===================================================
-- 💰 INSERTAR MONEDAS
-- ===================================================

INSERT INTO monedas_usuario (usuario_id, monedas_actuales, monedas_totales_ganadas, monedas_gastadas, ultima_transaccion) VALUES
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 1500, 2500, 1000, NOW() - INTERVAL '1 day'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 800, 1200, 400, NOW() - INTERVAL '2 days'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 150, 200, 50, NOW() - INTERVAL '1 week');

-- ===================================================
-- ✅ VERIFICACIÓN FINAL
-- ===================================================

DO $$
BEGIN
    RAISE NOTICE '🎮 ¡DATOS DE PRUEBA GAMING CREADOS EXITOSAMENTE!';
    RAISE NOTICE '📊 Usuarios con experiencia: %', (SELECT COUNT(*) FROM experiencia_usuario);
    RAISE NOTICE '🏆 Entradas de ranking: %', (SELECT COUNT(*) FROM ranking_global);
    RAISE NOTICE '📈 Usuarios con estadísticas: %', (SELECT COUNT(*) FROM estadisticas_usuario);
    RAISE NOTICE '💰 Usuarios con monedas: %', (SELECT COUNT(*) FROM monedas_usuario);
    RAISE NOTICE '🎯 ¡Ahora puedes ir a /ranking y ver la magia!';
END $$; 