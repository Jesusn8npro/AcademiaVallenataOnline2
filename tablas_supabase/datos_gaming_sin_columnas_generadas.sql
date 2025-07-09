-- ===================================================
-- 🎮 DATOS DE PRUEBA GAMING - SIN COLUMNAS GENERADAS
-- ===================================================

-- ⚠️ EXCLUYENDO monedas_disponibles (columna generada automáticamente)

-- ===================================================
-- 📊 DATOS DE EXPERIENCIA
-- ===================================================

INSERT INTO experiencia_usuario (
    usuario_id, nivel, xp_actual, xp_total, xp_siguiente_nivel, 
    xp_cursos, xp_simulador, xp_comunidad, xp_logros, 
    racha_dias, racha_maxima, ultima_sesion
) VALUES 
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 15, 2500, 12500, 3000, 3000, 6000, 2000, 1500, 7, 15, NOW() - INTERVAL '2 hours'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 8, 800, 4800, 1200, 1500, 2000, 800, 500, 3, 8, NOW() - INTERVAL '1 day'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 3, 150, 650, 400, 200, 300, 100, 50, 1, 4, NOW() - INTERVAL '3 days')
ON CONFLICT (usuario_id) DO UPDATE SET
    nivel = EXCLUDED.nivel,
    xp_actual = EXCLUDED.xp_actual,
    xp_total = EXCLUDED.xp_total,
    xp_siguiente_nivel = EXCLUDED.xp_siguiente_nivel,
    xp_cursos = EXCLUDED.xp_cursos,
    xp_simulador = EXCLUDED.xp_simulador,
    xp_comunidad = EXCLUDED.xp_comunidad,
    xp_logros = EXCLUDED.xp_logros,
    racha_dias = EXCLUDED.racha_dias,
    racha_maxima = EXCLUDED.racha_maxima,
    ultima_sesion = EXCLUDED.ultima_sesion,
    updated_at = NOW();

-- ===================================================
-- 📈 DATOS DE ESTADÍSTICAS  
-- ===================================================

INSERT INTO estadisticas_usuario (
    usuario_id, total_sesiones, tiempo_total_minutos, primer_sesion, ultima_sesion,
    precision_maxima, precision_promedio, notas_totales_tocadas, notas_correctas_totales,
    cursos_completados, tutoriales_completados, lecciones_completadas,
    publicaciones_creadas, likes_recibidos, comentarios_hechos,
    logros_totales, logros_faciles, logros_medios, logros_dificiles, logros_legendarios,
    racha_actual_dias, racha_maxima_dias, dias_activos_total,
    mejor_posicion_global, mejor_posicion_semanal, semanas_en_top_10, calculado_en
) VALUES 
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 45, 1200, NOW() - INTERVAL '3 months', NOW() - INTERVAL '2 hours', 98, 95, 3000, 2850, 5, 12, 45, 15, 125, 45, 8, 3, 3, 2, 0, 7, 15, 45, 1, 1, 8, NOW()),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 28, 600, NOW() - INTERVAL '2 months', NOW() - INTERVAL '1 day', 92, 87, 1800, 1566, 3, 8, 28, 8, 45, 22, 4, 2, 2, 0, 0, 3, 8, 28, 2, 3, 4, NOW()),
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 12, 180, NOW() - INTERVAL '1 month', NOW() - INTERVAL '3 days', 85, 72, 800, 576, 1, 3, 12, 3, 12, 8, 1, 1, 0, 0, 0, 1, 4, 12, 5, null, 0, NOW())
ON CONFLICT (usuario_id) DO UPDATE SET
    total_sesiones = EXCLUDED.total_sesiones,
    tiempo_total_minutos = EXCLUDED.tiempo_total_minutos,
    precision_maxima = EXCLUDED.precision_maxima,
    precision_promedio = EXCLUDED.precision_promedio,
    notas_totales_tocadas = EXCLUDED.notas_totales_tocadas,
    notas_correctas_totales = EXCLUDED.notas_correctas_totales,
    cursos_completados = EXCLUDED.cursos_completados,
    tutoriales_completados = EXCLUDED.tutoriales_completados,
    lecciones_completadas = EXCLUDED.lecciones_completadas,
    publicaciones_creadas = EXCLUDED.publicaciones_creadas,
    likes_recibidos = EXCLUDED.likes_recibidos,
    comentarios_hechos = EXCLUDED.comentarios_hechos,
    logros_totales = EXCLUDED.logros_totales,
    logros_faciles = EXCLUDED.logros_faciles,
    logros_medios = EXCLUDED.logros_medios,
    logros_dificiles = EXCLUDED.logros_dificiles,
    logros_legendarios = EXCLUDED.logros_legendarios,
    racha_actual_dias = EXCLUDED.racha_actual_dias,
    racha_maxima_dias = EXCLUDED.racha_maxima_dias,
    dias_activos_total = EXCLUDED.dias_activos_total,
    mejor_posicion_global = EXCLUDED.mejor_posicion_global,
    mejor_posicion_semanal = EXCLUDED.mejor_posicion_semanal,
    semanas_en_top_10 = EXCLUDED.semanas_en_top_10,
    calculado_en = EXCLUDED.calculado_en,
    updated_at = NOW();

-- ===================================================
-- 💰 DATOS DE MONEDAS (SIN COLUMNA GENERADA)
-- ===================================================

INSERT INTO monedas_usuario (
    usuario_id, 
    monedas_totales,        -- ✅ Total ganadas en la vida
    monedas_gastadas,       -- ✅ Total gastadas
    -- monedas_disponibles, ❌ COLUMNA GENERADA - SE CALCULA AUTO
    monedas_logros,         -- ✅ Ganadas por logros
    monedas_ranking,        -- ✅ Ganadas por ranking
    monedas_compradas,      -- ✅ Compradas con dinero real
    monedas_regaladas,      -- ✅ Regaladas por admin
    transacciones_totales,  -- ✅ Número de transacciones
    ultima_ganancia,        -- ✅ Última vez que ganó
    ultimo_gasto            -- ✅ Última vez que gastó
) VALUES 
-- Usuario avanzado: Muchas monedas (disponibles = 2500 - 1000 = 1500)
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 2500, 1000, 800, 600, 500, 600, 15, NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 days'),
-- Usuario intermedio: Monedas medias (disponibles = 1200 - 400 = 800)
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 1200, 400, 400, 200, 300, 300, 8, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 week'),
-- Usuario principiante: Pocas monedas (disponibles = 200 - 50 = 150)
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 200, 50, 100, 50, 0, 50, 3, NOW() - INTERVAL '1 week', NOW() - INTERVAL '2 weeks')
ON CONFLICT (usuario_id) DO UPDATE SET
    monedas_totales = EXCLUDED.monedas_totales,
    monedas_gastadas = EXCLUDED.monedas_gastadas,
    -- monedas_disponibles se actualizará automáticamente
    monedas_logros = EXCLUDED.monedas_logros,
    monedas_ranking = EXCLUDED.monedas_ranking,
    monedas_compradas = EXCLUDED.monedas_compradas,
    monedas_regaladas = EXCLUDED.monedas_regaladas,
    transacciones_totales = EXCLUDED.transacciones_totales,
    ultima_ganancia = EXCLUDED.ultima_ganancia,
    ultimo_gasto = EXCLUDED.ultimo_gasto,
    updated_at = NOW();

-- ===================================================
-- 🏆 DATOS DE RANKING
-- ===================================================

INSERT INTO ranking_global (usuario_id, tipo_ranking, puntuacion, posicion, posicion_anterior, metricas, periodo_inicio, activo) VALUES 
-- Ranking General
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'general', 12500, 1, 2, '{"nivel": 15, "precision_promedio": 95, "total_sesiones": 45, "tiempo_total_minutos": 1200, "logros_conseguidos": 8, "racha_maxima": 15}', '2024-01-01', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'general', 4800, 2, 1, '{"nivel": 8, "precision_promedio": 87, "total_sesiones": 28, "tiempo_total_minutos": 600, "logros_conseguidos": 4, "racha_maxima": 8}', '2024-01-01', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 'general', 650, 3, null, '{"nivel": 3, "precision_promedio": 72, "total_sesiones": 12, "tiempo_total_minutos": 180, "logros_conseguidos": 1, "racha_maxima": 4}', '2024-01-01', true),

-- Ranking Simulador
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'simulador', 8500, 1, 1, '{"precision_promedio": 95, "total_sesiones": 30, "tiempo_total_minutos": 900, "notas_correctas": 2850}', '2024-01-01', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'simulador', 3200, 2, 3, '{"precision_promedio": 87, "total_sesiones": 18, "tiempo_total_minutos": 450, "notas_correctas": 1566}', '2024-01-01', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 'simulador', 720, 3, 2, '{"precision_promedio": 72, "total_sesiones": 8, "tiempo_total_minutos": 120, "notas_correctas": 576}', '2024-01-01', true),

-- Ranking Cursos
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'cursos', 4500, 1, null, '{"cursos_completados": 5, "lecciones_completadas": 45, "promedio_calificaciones": 4.8}', '2024-01-01', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'cursos', 2400, 2, null, '{"cursos_completados": 3, "lecciones_completadas": 28, "promedio_calificaciones": 4.2}', '2024-01-01', true),

-- Ranking Precisión
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'precision', 9500, 1, 1, '{"precision_maxima": 98, "precision_promedio": 95, "notas_perfectas": 850}', '2024-01-01', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'precision', 4350, 2, 2, '{"precision_maxima": 92, "precision_promedio": 87, "notas_perfectas": 450}', '2024-01-01', true),

-- Ranking Constancia
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'constancia', 1500, 1, 2, '{"racha_actual": 7, "racha_maxima": 15, "dias_activos": 45}', '2024-01-01', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'constancia', 800, 2, 1, '{"racha_actual": 3, "racha_maxima": 8, "dias_activos": 28}', '2024-01-01', true),

-- Ranking Comunidad
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 'comunidad', 2000, 1, null, '{"publicaciones_creadas": 15, "likes_recibidos": 125, "comentarios_hechos": 45}', '2024-01-01', true),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 'comunidad', 800, 2, null, '{"publicaciones_creadas": 8, "likes_recibidos": 45, "comentarios_hechos": 22}', '2024-01-01', true)

ON CONFLICT (usuario_id, tipo_ranking, periodo_inicio) DO UPDATE SET
    puntuacion = EXCLUDED.puntuacion,
    posicion = EXCLUDED.posicion,
    posicion_anterior = EXCLUDED.posicion_anterior,
    metricas = EXCLUDED.metricas,
    activo = EXCLUDED.activo,
    calculated_at = NOW(),
    updated_at = NOW();

-- ===================================================
-- 🎮 DATOS DE SESIONES SIMULADOR
-- ===================================================

INSERT INTO sesiones_simulador (
    usuario_id, duracion_minutos, duracion_segundos, tiempo_inicio, tiempo_fin,
    notas_tocadas, notas_correctas, notas_incorrectas, bpm_promedio,
    escalas_practicadas, acordes_practicados, canciones_intentadas, afinacion_usada,
    tipo_practica, xp_ganado, logros_desbloqueados, nivel_antes, nivel_despues, datos_sesion
) VALUES 
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), 30, 1800, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '90 minutes', 120, 114, 6, 120, ARRAY['C Major', 'G Major'], ARRAY['C', 'F', 'G'], ARRAY['La Gota Fría'], 'FBE', 'cancion', 250, ARRAY[]::UUID[], 15, 15, '{"modo_practica": "cancion_completa", "dificultad": "avanzado"}'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), 20, 1200, NOW() - INTERVAL '1 day', NOW() - INTERVAL '23 hours', 80, 70, 10, 100, ARRAY['C Major'], ARRAY['C', 'F'], ARRAY['El Provinciano'], 'FBE', 'leccion', 180, ARRAY[]::UUID[], 8, 8, '{"modo_practica": "leccion_guiada", "dificultad": "intermedio"}'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), 15, 900, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '15 minutes', 50, 36, 14, 80, ARRAY['C Major'], ARRAY['C'], ARRAY[]::TEXT[], 'FBE', 'escala', 120, ARRAY[]::UUID[], 3, 3, '{"modo_practica": "ejercicios_basicos", "dificultad": "principiante"}');

-- ===================================================
-- 🎯 DATOS DE LOGROS USUARIO
-- ===================================================

INSERT INTO logros_usuario (usuario_id, logro_id, conseguido, progreso_actual, progreso_objetivo, datos_logro, conseguido_en, primer_progreso, ultimo_progreso) VALUES 
-- Usuario 1: Logros conseguidos
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), (SELECT id FROM logros_sistema WHERE nombre = 'Primer Paso' LIMIT 1), true, 100, 100, '{"sesiones_completadas": 45}', NOW() - INTERVAL '3 months', NOW() - INTERVAL '3 months', NOW() - INTERVAL '2 hours'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), (SELECT id FROM logros_sistema WHERE nombre = 'Dedicación' LIMIT 1), true, 100, 100, '{"racha_dias": 7}', NOW() - INTERVAL '1 month', NOW() - INTERVAL '2 months', NOW() - INTERVAL '2 hours'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 0), (SELECT id FROM logros_sistema WHERE nombre = 'Manos Firmes' LIMIT 1), true, 100, 100, '{"precision_maxima": 95}', NOW() - INTERVAL '2 weeks', NOW() - INTERVAL '1 month', NOW() - INTERVAL '2 hours'),

-- Usuario 2: Algunos logros
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), (SELECT id FROM logros_sistema WHERE nombre = 'Primer Paso' LIMIT 1), true, 100, 100, '{"sesiones_completadas": 28}', NOW() - INTERVAL '2 months', NOW() - INTERVAL '2 months', NOW() - INTERVAL '1 day'),
((SELECT id FROM perfiles LIMIT 1 OFFSET 1), (SELECT id FROM logros_sistema WHERE nombre = 'Dedicación' LIMIT 1), true, 100, 100, '{"racha_dias": 3}', NOW() - INTERVAL '1 month', NOW() - INTERVAL '1 month', NOW() - INTERVAL '1 day'),

-- Usuario 3: Logro básico
((SELECT id FROM perfiles LIMIT 1 OFFSET 2), (SELECT id FROM logros_sistema WHERE nombre = 'Primer Paso' LIMIT 1), true, 100, 100, '{"sesiones_completadas": 12}', NOW() - INTERVAL '1 month', NOW() - INTERVAL '1 month', NOW() - INTERVAL '3 days')

ON CONFLICT (usuario_id, logro_id) DO UPDATE SET
    conseguido = EXCLUDED.conseguido,
    progreso_actual = EXCLUDED.progreso_actual,
    datos_logro = EXCLUDED.datos_logro,
    conseguido_en = EXCLUDED.conseguido_en,
    ultimo_progreso = EXCLUDED.ultimo_progreso,
    updated_at = NOW();

-- ===================================================
-- ✅ VERIFICACIÓN FINAL
-- ===================================================

DO $$
BEGIN
    RAISE NOTICE '🎮 ¡DATOS GAMING INSERTADOS SIN COLUMNAS GENERADAS!';
    RAISE NOTICE '📊 Usuarios con experiencia: %', (SELECT COUNT(*) FROM experiencia_usuario);
    RAISE NOTICE '🏆 Entradas de ranking: %', (SELECT COUNT(*) FROM ranking_global);
    RAISE NOTICE '📈 Usuarios con estadísticas: %', (SELECT COUNT(*) FROM estadisticas_usuario);
    RAISE NOTICE '💰 Usuarios con monedas: %', (SELECT COUNT(*) FROM monedas_usuario);
    RAISE NOTICE '🎮 Sesiones registradas: %', (SELECT COUNT(*) FROM sesiones_simulador);
    RAISE NOTICE '🏅 Logros conseguidos: %', (SELECT COUNT(*) FROM logros_usuario WHERE conseguido = true);
    RAISE NOTICE '🎯 ¡Ve a localhost:5173/ranking para ver la magia!';
    RAISE NOTICE '💰 Verificando monedas disponibles calculadas automáticamente...';
    RAISE NOTICE 'Usuario 1 monedas disponibles: %', (SELECT monedas_disponibles FROM monedas_usuario WHERE usuario_id = (SELECT id FROM perfiles LIMIT 1 OFFSET 0));
    RAISE NOTICE 'Usuario 2 monedas disponibles: %', (SELECT monedas_disponibles FROM monedas_usuario WHERE usuario_id = (SELECT id FROM perfiles LIMIT 1 OFFSET 1));
    RAISE NOTICE 'Usuario 3 monedas disponibles: %', (SELECT monedas_disponibles FROM monedas_usuario WHERE usuario_id = (SELECT id FROM perfiles LIMIT 1 OFFSET 2));
END $$; 