-- =====================================================
-- 🎮 PARTE 4: TRIGGERS DE INTEGRACIÓN Y DATOS INICIALES
-- =====================================================
-- Ejecutar después de la PARTE 3

-- =====================================================
-- 🔄 TRIGGERS PARA PUBLICACIONES
-- =====================================================

DROP TRIGGER IF EXISTS trigger_nueva_publicacion ON public.comunidad_publicaciones;
CREATE TRIGGER trigger_nueva_publicacion
    AFTER INSERT ON public.comunidad_publicaciones
    FOR EACH ROW
    EXECUTE FUNCTION procesar_actividad_usuario('publicacion_creada');

-- =====================================================
-- 🔄 TRIGGERS PARA LIKES
-- =====================================================

DROP TRIGGER IF EXISTS trigger_nuevo_like ON public.comunidad_publicaciones_likes;
CREATE TRIGGER trigger_nuevo_like
    AFTER INSERT ON public.comunidad_publicaciones_likes
    FOR EACH ROW
    EXECUTE FUNCTION procesar_actividad_usuario('like_recibido');

-- =====================================================
-- 🔄 TRIGGERS PARA COMENTARIOS (si existe la tabla)
-- =====================================================

-- Este trigger se creará solo si la tabla existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comunidad_comentarios') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_nuevo_comentario ON public.comunidad_comentarios';
        EXECUTE 'CREATE TRIGGER trigger_nuevo_comentario
            AFTER INSERT ON public.comunidad_comentarios
            FOR EACH ROW
            EXECUTE FUNCTION procesar_actividad_usuario(''comentario_creado'')';
        RAISE NOTICE '✅ Trigger para comentarios creado';
    ELSE
        RAISE NOTICE '⚠️  Tabla comunidad_comentarios no existe, trigger omitido';
    END IF;
END $$;

-- =====================================================
-- 🔄 TRIGGERS PARA CURSOS Y TUTORIALES - SEPARADOS INSERT/UPDATE
-- =====================================================

-- Trigger para progreso en lección - INSERT (nueva lección completada)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_lecciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_progreso_leccion_insert ON public.progreso_lecciones';
        EXECUTE 'CREATE TRIGGER trigger_progreso_leccion_insert
            AFTER INSERT ON public.progreso_lecciones
            FOR EACH ROW
            WHEN (NEW.estado = ''completada'')
            EXECUTE FUNCTION procesar_actividad_usuario(''leccion_completada'')';
        RAISE NOTICE '✅ Trigger INSERT para progreso lecciones creado';
    ELSE
        RAISE NOTICE '⚠️  Tabla progreso_lecciones no existe, trigger INSERT omitido';
    END IF;
END $$;

-- Trigger para progreso en lección - UPDATE (lección actualizada a completada)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_lecciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_progreso_leccion_update ON public.progreso_lecciones';
        EXECUTE 'CREATE TRIGGER trigger_progreso_leccion_update
            AFTER UPDATE ON public.progreso_lecciones
            FOR EACH ROW
            WHEN (NEW.estado = ''completada'' AND OLD.estado != ''completada'')
            EXECUTE FUNCTION procesar_actividad_usuario(''leccion_completada'')';
        RAISE NOTICE '✅ Trigger UPDATE para progreso lecciones creado';
    ELSE
        RAISE NOTICE '⚠️  Tabla progreso_lecciones no existe, trigger UPDATE omitido';
    END IF;
END $$;

-- Trigger para curso completado - INSERT
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inscripciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_curso_completado_insert ON public.inscripciones';
        EXECUTE 'CREATE TRIGGER trigger_curso_completado_insert
            AFTER INSERT ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.curso_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario(''curso_completado'')';
        RAISE NOTICE '✅ Trigger INSERT para cursos completados creado';
    ELSE
        RAISE NOTICE '⚠️  Tabla inscripciones no existe, trigger INSERT omitido';
    END IF;
END $$;

-- Trigger para curso completado - UPDATE
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inscripciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_curso_completado_update ON public.inscripciones';
        EXECUTE 'CREATE TRIGGER trigger_curso_completado_update
            AFTER UPDATE ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND OLD.completado = FALSE AND NEW.curso_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario(''curso_completado'')';
        RAISE NOTICE '✅ Trigger UPDATE para cursos completados creado';
    ELSE
        RAISE NOTICE '⚠️  Tabla inscripciones no existe, trigger UPDATE omitido';
    END IF;
END $$;

-- Trigger para tutorial completado - INSERT
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inscripciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.inscripciones';
        EXECUTE 'CREATE TRIGGER trigger_tutorial_completado_insert
            AFTER INSERT ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.tutorial_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario(''tutorial_completado'')';
        RAISE NOTICE '✅ Trigger INSERT para tutoriales completados creado';
    ELSE
        RAISE NOTICE '⚠️  Tabla inscripciones no existe, trigger INSERT omitido';
    END IF;
END $$;

-- Trigger para tutorial completado - UPDATE
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inscripciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.inscripciones';
        EXECUTE 'CREATE TRIGGER trigger_tutorial_completado_update
            AFTER UPDATE ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND OLD.completado = FALSE AND NEW.tutorial_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario(''tutorial_completado'')';
        RAISE NOTICE '✅ Trigger UPDATE para tutoriales completados creado';
    ELSE
        RAISE NOTICE '⚠️  Tabla inscripciones no existe, trigger UPDATE omitido';
    END IF;
END $$;

-- =====================================================
-- 🏆 INSERTAR LOGROS PREDEFINIDOS
-- =====================================================

-- Limpiar logros existentes (opcional)
-- DELETE FROM public.logros_sistema;

-- Logros de cursos
INSERT INTO public.logros_sistema (id, nombre, descripcion, descripcion_corta, icono, categoria, dificultad, xp_recompensa, monedas_recompensa, condiciones, orden_mostrar) VALUES
('primer_curso_completado', 'Primer Paso', 'Has completado tu primer curso completo', 'Completa 1 curso', '🎓', 'cursos', 'facil', 100, 50, '{"cursos_completados": 1}', 1),
('tres_cursos_completados', 'Estudiante Dedicado', 'Has completado 3 cursos completos', 'Completa 3 cursos', '📚', 'cursos', 'medio', 300, 150, '{"cursos_completados": 3}', 2),
('cinco_cursos_completados', 'Académico', 'Has completado 5 cursos completos', 'Completa 5 cursos', '🎯', 'cursos', 'medio', 500, 250, '{"cursos_completados": 5}', 3),
('diez_cursos_completados', 'Maestro Estudiante', 'Has completado 10 cursos completos', 'Completa 10 cursos', '🏆', 'cursos', 'dificil', 1000, 500, '{"cursos_completados": 10}', 4),
('estudiante_dedicado', 'Dedicación Total', 'Has estudiado más de 10 horas en total', '10+ horas de estudio', '⏰', 'cursos', 'medio', 400, 200, '{"tiempo_total_minutos": 600}', 5),
('maratonista_conocimiento', 'Maratonista del Conocimiento', 'Has estudiado más de 50 horas en total', '50+ horas de estudio', '🏃', 'cursos', 'legendario', 2000, 1000, '{"tiempo_total_minutos": 3000}', 6);

-- Logros de tutoriales
INSERT INTO public.logros_sistema (id, nombre, descripcion, descripcion_corta, icono, categoria, dificultad, xp_recompensa, monedas_recompensa, condiciones, orden_mostrar) VALUES
('primer_tutorial_completado', 'Primeros Pasos', 'Has completado tu primer tutorial', 'Completa 1 tutorial', '📖', 'cursos', 'facil', 50, 25, '{"tutoriales_completados": 1}', 10),
('cinco_tutoriales_completados', 'Aprendiz', 'Has completado 5 tutoriales', 'Completa 5 tutoriales', '🎵', 'cursos', 'facil', 250, 125, '{"tutoriales_completados": 5}', 11),
('diez_tutoriales_completados', 'Estudiante Activo', 'Has completado 10 tutoriales', 'Completa 10 tutoriales', '🎶', 'cursos', 'medio', 500, 250, '{"tutoriales_completados": 10}', 12),
('veinticinco_tutoriales_completados', 'Entusiasta', 'Has completado 25 tutoriales', 'Completa 25 tutoriales', '🎹', 'cursos', 'dificil', 1250, 625, '{"tutoriales_completados": 25}', 13),
('maestro_acordeon', 'Maestro del Acordeón', 'Has completado 50 tutoriales', 'Completa 50 tutoriales', '🎼', 'cursos', 'legendario', 2500, 1250, '{"tutoriales_completados": 50}', 14),
('progreso_excelente', 'Excelencia Académica', 'Mantienes un promedio de progreso del 90%', '90%+ promedio', '⭐', 'progreso', 'dificil', 800, 400, '{"progreso_promedio": 90}', 15);

-- Logros de comunidad
INSERT INTO public.logros_sistema (id, nombre, descripcion, descripcion_corta, icono, categoria, dificultad, xp_recompensa, monedas_recompensa, condiciones, orden_mostrar) VALUES
('primera_publicacion', 'Primera Voz', 'Has creado tu primera publicación', 'Crea 1 publicación', '📝', 'comunidad', 'facil', 50, 25, '{"publicaciones": 1}', 20),
('cinco_publicaciones', 'Comunicador', 'Has creado 5 publicaciones', 'Crea 5 publicaciones', '💬', 'comunidad', 'facil', 250, 125, '{"publicaciones": 5}', 21),
('diez_publicaciones', 'Creador de Contenido', 'Has creado 10 publicaciones', 'Crea 10 publicaciones', '📢', 'comunidad', 'medio', 500, 250, '{"publicaciones": 10}', 22),
('comentarista_activo', 'Comentarista Activo', 'Has hecho 20 comentarios', 'Haz 20 comentarios', '🗣️', 'social', 'medio', 400, 200, '{"comentarios": 20}', 23),
('popular', 'Popular', 'Has recibido 50 likes en total', 'Recibe 50 likes', '👍', 'social', 'medio', 500, 250, '{"likes_recibidos": 50}', 24),
('influencer', 'Influencer', 'Has recibido 100 likes en total', 'Recibe 100 likes', '🌟', 'social', 'dificil', 1000, 500, '{"likes_recibidos": 100}', 25),
('miembro_activo', 'Miembro Activo', 'Eres muy activo en la comunidad', 'Actividad combinada alta', '🤝', 'social', 'dificil', 800, 400, '{"actividad_total": 50}', 26);

-- Logros de constancia
INSERT INTO public.logros_sistema (id, nombre, descripcion, descripcion_corta, icono, categoria, dificultad, xp_recompensa, monedas_recompensa, condiciones, orden_mostrar) VALUES
('racha_tres_dias', 'Constancia Inicial', 'Has mantenido una racha de 3 días', 'Racha de 3 días', '🔥', 'constancia', 'facil', 150, 75, '{"racha_actual": 3}', 30),
('racha_siete_dias', 'Una Semana Fuerte', 'Has mantenido una racha de 7 días', 'Racha de 7 días', '🔥', 'constancia', 'medio', 350, 175, '{"racha_actual": 7}', 31),
('racha_treinta_dias', 'Un Mes Imparable', 'Has mantenido una racha de 30 días', 'Racha de 30 días', '🔥', 'constancia', 'legendario', 1500, 750, '{"racha_actual": 30}', 32),
('miembro_veterano', 'Miembro Veterano', 'Has estado activo 30 días en total', '30 días activos', '🗓️', 'constancia', 'medio', 600, 300, '{"dias_activos": 30}', 33),
('miembro_legendario', 'Miembro Legendario', 'Has estado activo 100 días en total', '100 días activos', '👑', 'constancia', 'legendario', 2000, 1000, '{"dias_activos": 100}', 34);

-- =====================================================
-- 🔧 FUNCIÓN PARA RANKING HÍBRIDO DE TODOS LOS USUARIOS
-- =====================================================

CREATE OR REPLACE FUNCTION obtener_ranking_hibrido_completo(
    p_tipo_ranking TEXT DEFAULT 'general',
    p_limite INTEGER DEFAULT 1000
)
RETURNS TABLE (
    usuario_id UUID,
    nombre TEXT,
    apellido TEXT,
    url_foto_perfil TEXT,
    puntuacion INTEGER,
    posicion INTEGER,
    nivel INTEGER,
    xp_total INTEGER,
    cursos_completados INTEGER,
    tutoriales_completados INTEGER,
    publicaciones_creadas INTEGER,
    likes_recibidos INTEGER,
    comentarios_hechos INTEGER,
    racha_actual_dias INTEGER,
    logros_totales INTEGER,
    es_gaming BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH ranking_gaming AS (
        SELECT 
            rg.usuario_id,
            rg.puntuacion,
            ROW_NUMBER() OVER (ORDER BY rg.puntuacion DESC, rg.calculated_at ASC) as posicion,
            rg.metricas
        FROM public.ranking_global rg
        WHERE rg.tipo_ranking = p_tipo_ranking 
        AND rg.activo = true
    ),
    datos_perfiles AS (
        SELECT 
            p.id,
            COALESCE(p.nombre, p.nombre_usuario, 'Usuario') as nombre,
            COALESCE(p.apellido, '') as apellido,
            p.url_foto_perfil
        FROM public.perfiles p
    ),
    datos_experiencia AS (
        SELECT 
            eu.usuario_id,
            eu.nivel,
            eu.xp_total
        FROM public.experiencia_usuario eu
    ),
    datos_estadisticas AS (
        SELECT 
            est.usuario_id,
            est.cursos_completados,
            est.tutoriales_completados,
            est.publicaciones_creadas,
            est.likes_recibidos,
            est.comentarios_hechos,
            est.racha_actual_dias,
            est.logros_totales
        FROM public.estadisticas_usuario est
    )
    SELECT 
        COALESCE(rg.usuario_id, dp.id) as usuario_id,
        dp.nombre,
        dp.apellido,
        dp.url_foto_perfil,
        COALESCE(rg.puntuacion, 0) as puntuacion,
        COALESCE(rg.posicion, 9999)::INTEGER as posicion,
        COALESCE(de.nivel, 1) as nivel,
        COALESCE(de.xp_total, 0) as xp_total,
        COALESCE(dest.cursos_completados, 0) as cursos_completados,
        COALESCE(dest.tutoriales_completados, 0) as tutoriales_completados,
        COALESCE(dest.publicaciones_creadas, 0) as publicaciones_creadas,
        COALESCE(dest.likes_recibidos, 0) as likes_recibidos,
        COALESCE(dest.comentarios_hechos, 0) as comentarios_hechos,
        COALESCE(dest.racha_actual_dias, 0) as racha_actual_dias,
        COALESCE(dest.logros_totales, 0) as logros_totales,
        (rg.usuario_id IS NOT NULL) as es_gaming
    FROM datos_perfiles dp
    FULL OUTER JOIN ranking_gaming rg ON dp.id = rg.usuario_id
    LEFT JOIN datos_experiencia de ON COALESCE(rg.usuario_id, dp.id) = de.usuario_id
    LEFT JOIN datos_estadisticas dest ON COALESCE(rg.usuario_id, dp.id) = dest.usuario_id
    WHERE COALESCE(rg.usuario_id, dp.id) IS NOT NULL
    ORDER BY 
        CASE 
            WHEN rg.usuario_id IS NOT NULL THEN rg.posicion 
            ELSE 9999 
        END,
        dp.nombre
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ✅ SISTEMA COMPLETADO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 ¡SISTEMA DE GAMIFICACIÓN COMPLETADO!';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Tablas creadas: experiencia_usuario, logros_sistema, logros_usuario';
    RAISE NOTICE '✅ Tablas creadas: ranking_global, estadisticas_usuario, sesiones_simulador';
    RAISE NOTICE '✅ Tablas creadas: notificaciones_gaming, actividades_pendientes';
    RAISE NOTICE '✅ Triggers de integración: publicaciones, likes, comentarios, cursos, tutoriales';
    RAISE NOTICE '✅ Logros iniciales: 25 logros predefinidos';
    RAISE NOTICE '✅ Función de ranking híbrido: obtener_ranking_hibrido_completo()';
    RAISE NOTICE '';
    RAISE NOTICE '🎮 El sistema está listo para usar!';
    RAISE NOTICE '📋 Próximo paso: Integrar GestorGamificacion.svelte en tu layout';
END $$; 