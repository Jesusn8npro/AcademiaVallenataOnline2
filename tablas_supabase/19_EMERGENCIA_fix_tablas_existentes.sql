-- =====================================================
-- 🚨 SCRIPT DE EMERGENCIA - SOLO TABLAS QUE EXISTEN
-- =====================================================
-- Arreglar el problema causado por usar tablas inexistentes

-- Paso 1: Restaurar función actualizar_xp_inmediato SIN tablas inexistentes
CREATE OR REPLACE FUNCTION actualizar_xp_inmediato(
    p_usuario_id UUID,
    p_tipo_actividad TEXT
)
RETURNS VOID AS $$
DECLARE
    v_xp_ganado INTEGER := 0;
    v_nuevo_nivel INTEGER;
    v_xp_total INTEGER;
    v_xp_nivel INTEGER;
BEGIN
    -- Configurar XP por tipo de actividad
    CASE p_tipo_actividad
        WHEN 'publicacion_creada' THEN v_xp_ganado := 15;
        WHEN 'comentario_creado' THEN v_xp_ganado := 5;
        WHEN 'like_recibido' THEN v_xp_ganado := 2;
        WHEN 'leccion_completada' THEN v_xp_ganado := 10;
        WHEN 'parte_tutorial_completada' THEN v_xp_ganado := 15;  -- NUEVA CONFIGURACIÓN
        WHEN 'tutorial_completado' THEN v_xp_ganado := 50;
        WHEN 'curso_completado' THEN v_xp_ganado := 100;
        ELSE 
            RAISE NOTICE '⚠️ Tipo de actividad no reconocido: %', p_tipo_actividad;
            RETURN;
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
            CASE WHEN p_tipo_actividad IN ('curso_completado', 'parte_tutorial_completada', 'leccion_completada', 'tutorial_completado') THEN v_xp_ganado ELSE 0 END,
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
            xp_cursos = xp_cursos + CASE WHEN p_tipo_actividad IN ('curso_completado', 'parte_tutorial_completada', 'leccion_completada', 'tutorial_completado') THEN v_xp_ganado ELSE 0 END,
            xp_comunidad = xp_comunidad + CASE WHEN p_tipo_actividad IN ('publicacion_creada', 'comentario_creado', 'like_recibido') THEN v_xp_ganado ELSE 0 END,
            ultima_sesion = NOW(),
            updated_at = NOW()
        WHERE usuario_id = p_usuario_id;
    END IF;

    -- Actualizar estadísticas SOLO SI LA TABLA EXISTE
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'estadisticas_usuario') THEN
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
    END IF;

    -- Actualizar ranking global SOLO SI LA TABLA EXISTE
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ranking_global') THEN
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
    END IF;

    -- Log para debug
    RAISE NOTICE '🎯 XP actualizado: Usuario %, Actividad %, XP +%, Total %', 
        p_usuario_id, p_tipo_actividad, v_xp_ganado, v_xp_total;

END;
$$ LANGUAGE plpgsql;

-- Paso 2: Limpiar triggers problemáticos
DO $$
BEGIN
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_completada_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_completada_update ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_parte_tutorial_update ON public.progreso_tutorial;
    RAISE NOTICE '🗑️ Triggers problemáticos eliminados';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Error limpiando triggers: %', SQLERRM;
END $$;

-- Paso 3: Crear triggers seguros para partes de tutorial
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_tutorial') THEN
        -- Trigger para parte de tutorial completada - INSERT
        EXECUTE 'CREATE TRIGGER trigger_parte_tutorial_insert
            AFTER INSERT ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.parte_tutorial_id IS NOT NULL)
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''parte_tutorial_completada'')';
        
        -- Trigger para parte de tutorial completada - UPDATE
        EXECUTE 'CREATE TRIGGER trigger_parte_tutorial_update
            AFTER UPDATE ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.parte_tutorial_id IS NOT NULL AND 
                  (OLD.completado = FALSE OR OLD.completado IS NULL))
            EXECUTE FUNCTION procesar_actividad_usuario_inmediato(''parte_tutorial_completada'')';
        
        RAISE NOTICE '✅ Triggers seguros para partes de tutorial creados';
    ELSE
        RAISE NOTICE '❌ Tabla progreso_tutorial no encontrada';
    END IF;
END $$;

-- Paso 4: Verificar triggers creados
DO $$
DECLARE
    v_trigger_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_trigger_count
    FROM information_schema.triggers 
    WHERE event_object_table = 'progreso_tutorial'
    AND trigger_name LIKE '%parte_tutorial%';
    
    RAISE NOTICE '📊 Triggers de partes de tutorial: %', v_trigger_count;
END $$;

-- Paso 5: Función de prueba simple y segura
CREATE OR REPLACE FUNCTION probar_parte_tutorial_seguro(p_usuario_id UUID, p_tutorial_id UUID, p_parte_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_progreso_id UUID;
BEGIN
    -- Insertar progreso de parte completada
    INSERT INTO progreso_tutorial (
        usuario_id, tutorial_id, parte_tutorial_id, completado, 
        ultimo_acceso, fecha_inicio, fecha_actualizacion
    ) VALUES (
        p_usuario_id, p_tutorial_id, p_parte_tutorial_id, TRUE, 
        NOW(), NOW(), NOW()
    ) RETURNING id INTO v_progreso_id;
    
    RETURN 'Parte tutorial completada: ' || v_progreso_id::TEXT || '. Revisa +15 XP.';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🚨 SCRIPT DE EMERGENCIA APLICADO';
    RAISE NOTICE '';
    RAISE NOTICE '✅ ARREGLADO:';
    RAISE NOTICE '   • Eliminadas referencias a tablas inexistentes';
    RAISE NOTICE '   • Solo usa: experiencia_usuario, estadisticas_usuario, ranking_global';
    RAISE NOTICE '   • Función actualizar_xp_inmediato restaurada';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 FUNCIÓN DE PRUEBA SEGURA:';
    RAISE NOTICE '   SELECT probar_parte_tutorial_seguro(''usuario-id'', ''tutorial-id'', ''parte-id'');';
    RAISE NOTICE '';
    RAISE NOTICE '📊 CONFIGURACIÓN:';
    RAISE NOTICE '   ✅ Partes Tutorial: +15 XP cada una';
    RAISE NOTICE '   ✅ Sin errores de tablas inexistentes';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 SISTEMA RESTAURADO Y ESTABLE';
END $$; 