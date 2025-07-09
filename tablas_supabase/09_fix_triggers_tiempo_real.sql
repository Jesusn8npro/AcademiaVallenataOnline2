-- =====================================================
-- 🔥 FIX TRIGGERS PARA ACTUALIZACIÓN EN TIEMPO REAL
-- =====================================================
-- Este script corrige los triggers para que actualicen los puntos XP INMEDIATAMENTE

-- =====================================================
-- 🔄 FUNCIÓN NUEVA - ACTUALIZAR XP EN TIEMPO REAL
-- =====================================================

CREATE OR REPLACE FUNCTION actualizar_xp_inmediato(
    p_usuario_id UUID,
    p_tipo_actividad TEXT
)
RETURNS VOID AS $$
DECLARE
    v_xp_ganado INTEGER := 0;
    v_xp_actual INTEGER := 0;
    v_xp_total INTEGER := 0;
    v_nuevo_nivel INTEGER := 1;
    v_xp_nivel INTEGER := 0;
BEGIN
    -- Calcular XP ganado según el tipo de actividad
    CASE p_tipo_actividad
        WHEN 'publicacion_creada' THEN v_xp_ganado := 15;
        WHEN 'comentario_creado' THEN v_xp_ganado := 5;
        WHEN 'like_recibido' THEN v_xp_ganado := 2;
        WHEN 'leccion_completada' THEN v_xp_ganado := 10;
        WHEN 'curso_completado' THEN v_xp_ganado := 100;
        WHEN 'tutorial_completado' THEN v_xp_ganado := 50;
        ELSE v_xp_ganado := 0;
    END CASE;

    -- Si no hay XP que dar, salir
    IF v_xp_ganado = 0 THEN
        RETURN;
    END IF;

    -- Verificar si el usuario ya tiene registro de experiencia
    SELECT xp_total INTO v_xp_total
    FROM experiencia_usuario
    WHERE usuario_id = p_usuario_id;

    -- Si no existe, crear registro
    IF v_xp_total IS NULL THEN
        INSERT INTO experiencia_usuario (
            usuario_id, nivel, xp_actual, xp_total, xp_cursos, xp_comunidad, ultima_sesion
        ) VALUES (
            p_usuario_id, 1, v_xp_ganado, v_xp_ganado, 
            CASE WHEN p_tipo_actividad IN ('curso_completado', 'tutorial_completado', 'leccion_completada') THEN v_xp_ganado ELSE 0 END,
            CASE WHEN p_tipo_actividad IN ('publicacion_creada', 'comentario_creado', 'like_recibido') THEN v_xp_ganado ELSE 0 END,
            NOW()
        );
        v_xp_total := v_xp_ganado;
    ELSE
        -- Actualizar XP existente
        v_xp_total := v_xp_total + v_xp_ganado;
        
        -- Calcular nuevo nivel (cada 100 XP = 1 nivel)
        v_nuevo_nivel := GREATEST(1, v_xp_total / 100);
        v_xp_nivel := v_xp_total % 100;
        
        -- Actualizar registro
        UPDATE experiencia_usuario SET
            xp_total = v_xp_total,
            xp_actual = v_xp_nivel,
            nivel = v_nuevo_nivel,
            xp_cursos = xp_cursos + CASE WHEN p_tipo_actividad IN ('curso_completado', 'tutorial_completado', 'leccion_completada') THEN v_xp_ganado ELSE 0 END,
            xp_comunidad = xp_comunidad + CASE WHEN p_tipo_actividad IN ('publicacion_creada', 'comentario_creado', 'like_recibido') THEN v_xp_ganado ELSE 0 END,
            ultima_sesion = NOW(),
            updated_at = NOW()
        WHERE usuario_id = p_usuario_id;
    END IF;

    -- Actualizar estadísticas
    INSERT INTO estadisticas_usuario (
        usuario_id, 
        cursos_completados, 
        tutoriales_completados, 
        publicaciones_creadas, 
        likes_recibidos,
        calculado_en
    ) VALUES (
        p_usuario_id, 
        CASE WHEN p_tipo_actividad = 'curso_completado' THEN 1 ELSE 0 END,
        CASE WHEN p_tipo_actividad = 'tutorial_completado' THEN 1 ELSE 0 END,
        CASE WHEN p_tipo_actividad = 'publicacion_creada' THEN 1 ELSE 0 END,
        CASE WHEN p_tipo_actividad = 'like_recibido' THEN 1 ELSE 0 END,
        NOW()
    )
    ON CONFLICT (usuario_id)
    DO UPDATE SET
        cursos_completados = estadisticas_usuario.cursos_completados + CASE WHEN p_tipo_actividad = 'curso_completado' THEN 1 ELSE 0 END,
        tutoriales_completados = estadisticas_usuario.tutoriales_completados + CASE WHEN p_tipo_actividad = 'tutorial_completado' THEN 1 ELSE 0 END,
        publicaciones_creadas = estadisticas_usuario.publicaciones_creadas + CASE WHEN p_tipo_actividad = 'publicacion_creada' THEN 1 ELSE 0 END,
        likes_recibidos = estadisticas_usuario.likes_recibidos + CASE WHEN p_tipo_actividad = 'like_recibido' THEN 1 ELSE 0 END,
        calculado_en = NOW();

    -- Actualizar ranking global
    INSERT INTO ranking_global (
        usuario_id, 
        tipo_ranking, 
        puntuacion, 
        posicion, 
        metricas, 
        activo, 
        calculated_at
    ) VALUES (
        p_usuario_id, 
        'general', 
        v_xp_total, 
        1, -- Se actualizará después
        jsonb_build_object('xp_total', v_xp_total, 'nivel', v_nuevo_nivel),
        true, 
        NOW()
    )
    ON CONFLICT (usuario_id, tipo_ranking)
    DO UPDATE SET
        puntuacion = v_xp_total,
        metricas = jsonb_build_object('xp_total', v_xp_total, 'nivel', v_nuevo_nivel),
        calculated_at = NOW();

    -- Actualizar posiciones en ranking
    WITH ranking_actualizado AS (
        SELECT 
            usuario_id,
            ROW_NUMBER() OVER (ORDER BY puntuacion DESC, calculated_at ASC) as nueva_posicion
        FROM ranking_global 
        WHERE tipo_ranking = 'general' AND activo = true
    )
    UPDATE ranking_global 
    SET posicion = ra.nueva_posicion
    FROM ranking_actualizado ra
    WHERE ranking_global.usuario_id = ra.usuario_id 
    AND ranking_global.tipo_ranking = 'general';

    -- Log para debug
    RAISE NOTICE '🎯 XP actualizado: Usuario %, Actividad %, XP +%, Total %', 
        p_usuario_id, p_tipo_actividad, v_xp_ganado, v_xp_total;

END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 🔄 FUNCIÓN NUEVA - TRIGGERS MEJORADOS
-- =====================================================

CREATE OR REPLACE FUNCTION procesar_actividad_usuario_inmediato()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar XP inmediatamente
    PERFORM actualizar_xp_inmediato(NEW.usuario_id, TG_ARGV[0]);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 🔄 RECREAR TODOS LOS TRIGGERS CON FUNCIÓN NUEVA
-- =====================================================

-- Triggers para publicaciones
DROP TRIGGER IF EXISTS trigger_nueva_publicacion ON public.comunidad_publicaciones;
CREATE TRIGGER trigger_nueva_publicacion
    AFTER INSERT ON public.comunidad_publicaciones
    FOR EACH ROW
    EXECUTE FUNCTION procesar_actividad_usuario_inmediato('publicacion_creada');

-- Triggers para likes
DROP TRIGGER IF EXISTS trigger_nuevo_like ON public.comunidad_publicaciones_likes;
CREATE TRIGGER trigger_nuevo_like
    AFTER INSERT ON public.comunidad_publicaciones_likes
    FOR EACH ROW
    EXECUTE FUNCTION procesar_actividad_usuario_inmediato('like_recibido');

-- Triggers para comentarios (si existe la tabla)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'comunidad_comentarios') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_nuevo_comentario ON public.comunidad_comentarios';
        EXECUTE 'CREATE TRIGGER trigger_nuevo_comentario
            AFTER INSERT ON public.comunidad_comentarios
            FOR EACH ROW
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''comentario_creado'')';
        RAISE NOTICE '✅ Trigger comentarios recreado';
    END IF;
END $$;

-- Triggers para progreso de lecciones
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_lecciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_progreso_leccion_insert ON public.progreso_lecciones';
        EXECUTE 'CREATE TRIGGER trigger_progreso_leccion_insert
            AFTER INSERT ON public.progreso_lecciones
            FOR EACH ROW
            WHEN (NEW.estado = ''completada'')
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''leccion_completada'')';
        
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_progreso_leccion_update ON public.progreso_lecciones';
        EXECUTE 'CREATE TRIGGER trigger_progreso_leccion_update
            AFTER UPDATE ON public.progreso_lecciones
            FOR EACH ROW
            WHEN (NEW.estado = ''completada'' AND OLD.estado != ''completada'')
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''leccion_completada'')';
        
        RAISE NOTICE '✅ Triggers progreso lecciones recreados';
    END IF;
END $$;

-- Triggers para cursos completados
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inscripciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_curso_completado_insert ON public.inscripciones';
        EXECUTE 'CREATE TRIGGER trigger_curso_completado_insert
            AFTER INSERT ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.curso_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''curso_completado'')';
        
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_curso_completado_update ON public.inscripciones';
        EXECUTE 'CREATE TRIGGER trigger_curso_completado_update
            AFTER UPDATE ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND OLD.completado = FALSE AND NEW.curso_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''curso_completado'')';
        
        RAISE NOTICE '✅ Triggers cursos completados recreados';
    END IF;
END $$;

-- Triggers para tutoriales completados
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inscripciones') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.inscripciones';
        EXECUTE 'CREATE TRIGGER trigger_tutorial_completado_insert
            AFTER INSERT ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.tutorial_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''tutorial_completado'')';
        
        EXECUTE 'DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.inscripciones';
        EXECUTE 'CREATE TRIGGER trigger_tutorial_completado_update
            AFTER UPDATE ON public.inscripciones
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND OLD.completado = FALSE AND NEW.tutorial_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''tutorial_completado'')';
        
        RAISE NOTICE '✅ Triggers tutoriales completados recreados';
    END IF;
END $$;

-- =====================================================
-- ✅ COMPLETADO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔥 TRIGGERS CORREGIDOS - AHORA ACTUALIZAN XP EN TIEMPO REAL';
    RAISE NOTICE '📊 Puntos se actualizarán inmediatamente:';
    RAISE NOTICE '   • Publicación: +15 XP';
    RAISE NOTICE '   • Comentario: +5 XP';
    RAISE NOTICE '   • Like recibido: +2 XP';
    RAISE NOTICE '   • Lección completada: +10 XP';
    RAISE NOTICE '   • Curso completado: +100 XP';
    RAISE NOTICE '   • Tutorial completado: +50 XP';
END $$; 