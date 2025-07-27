-- ============================================
-- FUNCIÓN PARA ELIMINAR CHATS COMPLETAMENTE
-- ============================================
-- Esta función tiene permisos elevados para omitir RLS

CREATE OR REPLACE FUNCTION eliminar_chat_completo(
    p_chat_id UUID,
    p_usuario_id UUID
)
RETURNS JSON
SECURITY DEFINER  -- ¡CLAVE! Esto omite las políticas RLS
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_chat_info RECORD;
    v_user_info RECORD;
    v_resultado JSON;
BEGIN
    -- Validar que el chat existe
    SELECT es_grupal, creado_por, activo 
    INTO v_chat_info
    FROM chats 
    WHERE id = p_chat_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'exito', false,
            'error', 'Chat no encontrado'
        );
    END IF;
    
    -- Validar que el usuario tiene permisos
    SELECT es_admin, estado_miembro
    INTO v_user_info
    FROM miembros_chat
    WHERE chat_id = p_chat_id AND usuario_id = p_usuario_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'exito', false,
            'error', 'No eres miembro de este chat'
        );
    END IF;
    
    -- Verificar permisos para grupos
    IF v_chat_info.es_grupal AND NOT v_user_info.es_admin AND v_chat_info.creado_por != p_usuario_id THEN
        RETURN json_build_object(
            'exito', false,
            'error', 'Solo los administradores pueden eliminar grupos'
        );
    END IF;
    
    -- ELIMINAR TODO (sin importar RLS)
    IF v_chat_info.es_grupal THEN
        -- Para grupos: eliminación completa
        
        -- 1. Eliminar reacciones (probando ambos nombres de tabla)
        BEGIN
            DELETE FROM reacciones_mensajes WHERE mensaje_id IN (
                SELECT id FROM mensajes WHERE chat_id = p_chat_id
            );
        EXCEPTION WHEN undefined_table THEN
            -- Si no existe, probar el otro nombre
            BEGIN
                DELETE FROM mensajes_reacciones WHERE mensaje_id IN (
                    SELECT id FROM mensajes WHERE chat_id = p_chat_id
                );
            EXCEPTION WHEN undefined_table THEN
                -- Si ninguna existe, continuar
                NULL;
            END;
        END;
        
        -- 2. Eliminar lecturas (probando ambos nombres)
        BEGIN
            DELETE FROM mensajes_lectura WHERE mensaje_id IN (
                SELECT id FROM mensajes WHERE chat_id = p_chat_id
            );
        EXCEPTION WHEN undefined_table THEN
            BEGIN
                DELETE FROM mensajes_lecturas WHERE mensaje_id IN (
                    SELECT id FROM mensajes WHERE chat_id = p_chat_id
                );
            EXCEPTION WHEN undefined_table THEN
                NULL;
            END;
        END;
        
        -- 3. Eliminar mensajes
        DELETE FROM mensajes WHERE chat_id = p_chat_id;
        
        -- 4. Eliminar miembros
        DELETE FROM miembros_chat WHERE chat_id = p_chat_id;
        
        -- 5. Eliminar chat
        DELETE FROM chats WHERE id = p_chat_id;
        
        v_resultado := json_build_object(
            'exito', true,
            'mensaje', 'Grupo eliminado completamente'
        );
        
    ELSE
        -- Para chats privados: solo marcar como salido
        UPDATE miembros_chat 
        SET estado_miembro = 'salido'
        WHERE chat_id = p_chat_id AND usuario_id = p_usuario_id;
        
        v_resultado := json_build_object(
            'exito', true,
            'mensaje', 'Has salido del chat'
        );
    END IF;
    
    RETURN v_resultado;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'exito', false,
        'error', 'Error inesperado: ' || SQLERRM
    );
END;
$$;

-- ============================================
-- PERMISOS PARA LA FUNCIÓN
-- ============================================

-- Dar permisos a usuarios autenticados
GRANT EXECUTE ON FUNCTION eliminar_chat_completo(UUID, UUID) TO authenticated;

-- Comentario para documentación
COMMENT ON FUNCTION eliminar_chat_completo(UUID, UUID) IS 
'Función para eliminar chats completamente. Para grupos elimina todo, para chats privados marca como salido. Omite políticas RLS.'; 