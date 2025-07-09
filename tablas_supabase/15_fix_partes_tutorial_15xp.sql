-- =====================================================
-- 🎯 FIX CORRECTO - PARTES DE TUTORIAL 15 XP CADA UNA
-- =====================================================
-- Cambiar de 50 XP por tutorial completo a 15 XP por cada parte/clase completada

-- Paso 1: Verificar estructura de las tablas
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'partes_tutorial') THEN
        RAISE NOTICE '✅ Tabla partes_tutorial encontrada';
    ELSE
        RAISE NOTICE '❌ Tabla partes_tutorial NO existe';
        RETURN;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'progreso_tutorial') THEN
        RAISE NOTICE '✅ Tabla progreso_tutorial encontrada';
    ELSE
        RAISE NOTICE '❌ Tabla progreso_tutorial NO existe';
        RETURN;
    END IF;
END $$;

-- Paso 2: Actualizar función trigger_actualizar_xp para reconocer parte_tutorial_completada
CREATE OR REPLACE FUNCTION trigger_actualizar_xp(p_tipo_actividad TEXT)
RETURNS TRIGGER AS $$
DECLARE
    v_usuario_id UUID;
    v_xp_ganado INTEGER := 0;
    v_nivel_anterior INTEGER;
    v_nivel_nuevo INTEGER;
    v_actividad_id UUID;
BEGIN
    -- Obtener el usuario_id del registro
    v_usuario_id := COALESCE(NEW.usuario_id, NEW.user_id);
    
    IF v_usuario_id IS NULL THEN
        RAISE NOTICE '⚠️ No se pudo obtener usuario_id del registro';
        RETURN NEW;
    END IF;
    
    -- Configurar XP según el tipo de actividad
    CASE p_tipo_actividad
        WHEN 'publicacion_creada' THEN v_xp_ganado := 15;
        WHEN 'like_recibido' THEN v_xp_ganado := 2;
        WHEN 'leccion_completada' THEN v_xp_ganado := 10;
        WHEN 'parte_tutorial_completada' THEN v_xp_ganado := 15;  -- NUEVA CONFIGURACIÓN
        WHEN 'curso_completado' THEN v_xp_ganado := 100;
        WHEN 'tutorial_completado' THEN v_xp_ganado := 50;  -- MANTENER POR COMPATIBILIDAD
        ELSE 
            RAISE NOTICE '⚠️ Tipo de actividad no reconocido: %', p_tipo_actividad;
            RETURN NEW;
    END CASE;
    
    -- Obtener nivel anterior
    SELECT nivel INTO v_nivel_anterior 
    FROM experiencia_usuario 
    WHERE usuario_id = v_usuario_id;
    
    -- Actualizar experiencia del usuario
    INSERT INTO experiencia_usuario (usuario_id, xp_total, nivel)
    VALUES (v_usuario_id, v_xp_ganado, 1)
    ON CONFLICT (usuario_id) DO UPDATE SET
        xp_total = experiencia_usuario.xp_total + v_xp_ganado,
        nivel = LEAST(10, ((experiencia_usuario.xp_total + v_xp_ganado) / 100) + 1),
        xp_cursos = experiencia_usuario.xp_cursos + CASE WHEN p_tipo_actividad IN ('curso_completado', 'parte_tutorial_completada', 'leccion_completada') THEN v_xp_ganado ELSE 0 END,
        xp_comunidad = experiencia_usuario.xp_comunidad + CASE WHEN p_tipo_actividad IN ('publicacion_creada', 'like_recibido') THEN v_xp_ganado ELSE 0 END,
        fecha_ultima_actividad = NOW()
    RETURNING nivel INTO v_nivel_nuevo;
    
    -- Registrar actividad
    v_actividad_id := gen_random_uuid();
    INSERT INTO actividades_recientes (
        id, usuario_id, tipo_actividad, xp_ganado, descripcion, fecha_actividad
    ) VALUES (
        v_actividad_id, v_usuario_id, p_tipo_actividad, v_xp_ganado, 
        'XP ganado por: ' || p_tipo_actividad, NOW()
    );
    
    -- Actualizar estadísticas
    INSERT INTO estadisticas_gaming (usuario_id, total_xp, nivel_actual, actividades_completadas)
    VALUES (v_usuario_id, v_xp_ganado, COALESCE(v_nivel_nuevo, 1), 1)
    ON CONFLICT (usuario_id) DO UPDATE SET
        total_xp = estadisticas_gaming.total_xp + v_xp_ganado,
        nivel_actual = COALESCE(v_nivel_nuevo, estadisticas_gaming.nivel_actual),
        actividades_completadas = estadisticas_gaming.actividades_completadas + 1,
        fecha_ultima_actividad = NOW();
    
    -- Verificar si subió de nivel
    IF v_nivel_nuevo > COALESCE(v_nivel_anterior, 0) THEN
        INSERT INTO actividades_recientes (
            id, usuario_id, tipo_actividad, xp_ganado, descripcion, fecha_actividad
        ) VALUES (
            gen_random_uuid(), v_usuario_id, 'nivel_subido', 0, 
            'Subiste al nivel ' || v_nivel_nuevo, NOW()
        );
    END IF;
    
    RAISE NOTICE '✅ XP actualizado: usuario=%, actividad=%, xp_ganado=%', v_usuario_id, p_tipo_actividad, v_xp_ganado;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error en trigger_actualizar_xp: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Paso 3: Limpiar triggers antiguos incorrectos
DO $$
BEGIN
    -- Limpiar todos los triggers antiguos relacionados con tutoriales
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.inscripciones;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_insert ON public.progreso_tutorial;
    DROP TRIGGER IF EXISTS trigger_tutorial_completado_update ON public.progreso_tutorial;
    RAISE NOTICE '🗑️ Triggers antiguos de tutoriales eliminados';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Error limpiando triggers antiguos: %', SQLERRM;
END $$;

-- Paso 4: Crear triggers CORRECTOS para partes de tutorial
DO $$
BEGIN
    -- Trigger para parte de tutorial completada - INSERT
    BEGIN
        CREATE TRIGGER trigger_parte_tutorial_completada_insert
            AFTER INSERT ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.parte_tutorial_id IS NOT NULL)
            EXECUTE FUNCTION trigger_actualizar_xp('parte_tutorial_completada');
        RAISE NOTICE '✅ Trigger INSERT para partes de tutorial creado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error creando trigger INSERT: %', SQLERRM;
    END;
    
    -- Trigger para parte de tutorial completada - UPDATE
    BEGIN
        CREATE TRIGGER trigger_parte_tutorial_completada_update
            AFTER UPDATE ON public.progreso_tutorial
            FOR EACH ROW
            WHEN (NEW.completado = TRUE AND NEW.parte_tutorial_id IS NOT NULL AND 
                  (OLD.completado = FALSE OR OLD.completado IS NULL))
            EXECUTE FUNCTION trigger_actualizar_xp('parte_tutorial_completada');
        RAISE NOTICE '✅ Trigger UPDATE para partes de tutorial creado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Error creando trigger UPDATE: %', SQLERRM;
    END;
END $$;

-- Paso 5: Verificar configuración
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

-- Paso 6: Función de prueba para parte de tutorial
CREATE OR REPLACE FUNCTION probar_parte_tutorial_xp(p_usuario_id UUID, p_tutorial_id UUID, p_parte_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_progreso_id UUID;
BEGIN
    -- Crear progreso de parte completada
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

-- Paso 7: Función para marcar parte existente como completada
CREATE OR REPLACE FUNCTION completar_parte_tutorial(p_usuario_id UUID, p_parte_tutorial_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_rows INTEGER;
    v_tutorial_id UUID;
BEGIN
    -- Obtener tutorial_id de la parte
    SELECT tutorial_id INTO v_tutorial_id
    FROM partes_tutorial
    WHERE id = p_parte_tutorial_id;
    
    IF v_tutorial_id IS NULL THEN
        RETURN 'Error: Parte de tutorial no encontrada';
    END IF;
    
    -- Actualizar progreso existente
    UPDATE progreso_tutorial 
    SET 
        completado = TRUE,
        fecha_actualizacion = NOW(),
        ultimo_acceso = NOW()
    WHERE usuario_id = p_usuario_id 
    AND parte_tutorial_id = p_parte_tutorial_id
    AND (completado = FALSE OR completado IS NULL);
    
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    
    IF v_rows > 0 THEN
        RETURN 'Parte marcada como completada. Revisa +15 XP.';
    ELSE
        RETURN 'No se encontró progreso pendiente o ya estaba completada.';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 SISTEMA DE PARTES DE TUTORIAL ARREGLADO';
    RAISE NOTICE '';
    RAISE NOTICE '📝 CAMBIOS REALIZADOS:';
    RAISE NOTICE '   ❌ Antes: 50 XP por tutorial completo';
    RAISE NOTICE '   ✅ Ahora: 15 XP por cada parte/clase completada';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FUNCIONAMIENTO:';
    RAISE NOTICE '   • Cada parte de tutorial = +15 XP';
    RAISE NOTICE '   • Trigger se dispara cuando completado = TRUE';
    RAISE NOTICE '   • Debe tener parte_tutorial_id (no NULL)';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 FUNCIONES DE PRUEBA:';
    RAISE NOTICE '   SELECT probar_parte_tutorial_xp(''usuario-id'', ''tutorial-id'', ''parte-id'');';
    RAISE NOTICE '   SELECT completar_parte_tutorial(''usuario-id'', ''parte-id'');';
    RAISE NOTICE '';
    RAISE NOTICE '📊 SISTEMA GAMING ACTUALIZADO:';
    RAISE NOTICE '   ✅ Publicaciones: +15 XP';
    RAISE NOTICE '   ✅ Likes: +2 XP';
    RAISE NOTICE '   ✅ Lecciones: +10 XP';
    RAISE NOTICE '   ✅ Partes Tutorial: +15 XP (NUEVO)';
    RAISE NOTICE '   ✅ Cursos: +100 XP';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 AHORA CADA CLASE/PARTE COMPLETADA SUMA 15 XP';
END $$; 