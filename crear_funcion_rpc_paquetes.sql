-- Función RPC para inscribir usuarios en paquetes
-- Esta función bypassa las políticas RLS

-- 1. Crear función para inscribir usuario en paquete
CREATE OR REPLACE FUNCTION inscribir_usuario_en_paquete_admin(
    p_usuario_id UUID,
    p_paquete_id UUID
) RETURNS JSON AS $$
DECLARE
    v_inscripcion_id UUID;
    v_paquete_titulo TEXT;
    v_result JSON;
BEGIN
    -- Verificar si el paquete existe
    SELECT titulo INTO v_paquete_titulo
    FROM paquetes_tutoriales
    WHERE id = p_paquete_id;
    
    IF v_paquete_titulo IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Paquete no encontrado'
        );
    END IF;
    
    -- Verificar si ya está inscrito
    SELECT id INTO v_inscripcion_id
    FROM inscripciones
    WHERE usuario_id = p_usuario_id AND paquete_id = p_paquete_id;
    
    IF v_inscripcion_id IS NOT NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'El usuario ya está inscrito en este paquete'
        );
    END IF;
    
    -- Generar nuevo ID
    v_inscripcion_id := gen_random_uuid();
    
    -- Insertar inscripción (sin restricciones RLS)
    INSERT INTO inscripciones (
        id,
        usuario_id,
        paquete_id,
        fecha_inscripcion,
        porcentaje_completado,
        completado,
        estado,
        progreso,
        ultima_actividad,
        created_at,
        updated_at
    ) VALUES (
        v_inscripcion_id,
        p_usuario_id,
        p_paquete_id,
        NOW(),
        0,
        false,
        'activo',
        0,
        NOW(),
        NOW(),
        NOW()
    );
    
    -- Retornar resultado exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'id', v_inscripcion_id,
            'usuario_id', p_usuario_id,
            'paquete_id', p_paquete_id,
            'paquete_titulo', v_paquete_titulo
        ),
        'message', 'Usuario inscrito en paquete exitosamente'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- Manejo de errores
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Dar permisos a la función
GRANT EXECUTE ON FUNCTION inscribir_usuario_en_paquete_admin(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION inscribir_usuario_en_paquete_admin(UUID, UUID) TO service_role;

-- 3. Probar la función
SELECT inscribir_usuario_en_paquete_admin(
    '027fa0cb-b5b7-4936-8a7f-fe8cb0dd4789'::UUID,
    'f1ad7a88-dab6-40db-af54-e21144a90587'::UUID
);

-- 4. Verificar resultado
SELECT * FROM inscripciones WHERE paquete_id IS NOT NULL ORDER BY created_at DESC LIMIT 3;

-- 5. Limpiar prueba si es necesario
DELETE FROM inscripciones 
WHERE usuario_id = '027fa0cb-b5b7-4936-8a7f-fe8cb0dd4789'::UUID 
AND paquete_id = 'f1ad7a88-dab6-40db-af54-e21144a90587'::UUID;

-- 6. Función adicional para obtener paquetes de un usuario
CREATE OR REPLACE FUNCTION obtener_paquetes_usuario(p_usuario_id UUID)
RETURNS TABLE(
    inscripcion_id UUID,
    paquete_id UUID,
    titulo TEXT,
    fecha_inscripcion TIMESTAMP WITH TIME ZONE,
    porcentaje_completado INTEGER,
    estado TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.paquete_id,
        p.titulo,
        i.fecha_inscripcion,
        i.porcentaje_completado,
        i.estado
    FROM inscripciones i
    JOIN paquetes_tutoriales p ON i.paquete_id = p.id
    WHERE i.usuario_id = p_usuario_id
    AND i.paquete_id IS NOT NULL
    ORDER BY i.fecha_inscripcion DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dar permisos a la función de consulta
GRANT EXECUTE ON FUNCTION obtener_paquetes_usuario(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION obtener_paquetes_usuario(UUID) TO service_role; 