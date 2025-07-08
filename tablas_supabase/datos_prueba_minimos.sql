-- ============================================
-- DATOS DE PRUEBA MÍNIMOS - DEBUGGING
-- ============================================

-- 1. Obtener tu ID de usuario actual
-- Ejecuta esto primero para obtener tu ID:
-- SELECT id, nombre_completo FROM perfiles WHERE nombre_completo ILIKE '%carlos%' OR nombre_completo ILIKE '%admin%' LIMIT 3;

-- 2. REEMPLAZA ESTE UUID CON TU ID REAL
-- Obtén tu ID ejecutando la consulta de arriba
DO $$
DECLARE
    mi_usuario_id UUID;
    chat_id UUID;
BEGIN
    -- Obtener el primer usuario disponible (REEMPLAZA ESTO)
    SELECT id INTO mi_usuario_id FROM perfiles LIMIT 1;
    
    IF mi_usuario_id IS NULL THEN
        RAISE NOTICE 'No se encontraron usuarios. Crea un usuario primero.';
        RETURN;
    END IF;

    -- Crear un chat de prueba
    INSERT INTO chats (
        id, 
        nombre, 
        descripcion, 
        es_grupal, 
        creado_por,
        tipo_chat
    ) VALUES (
        gen_random_uuid(),
        'Chat de Prueba',
        'Chat para testing básico',
        false,
        mi_usuario_id,
        'privado'
    ) RETURNING id INTO chat_id;

    -- Agregar al usuario como miembro
    INSERT INTO miembros_chat (
        chat_id,
        usuario_id,
        es_admin,
        puede_escribir,
        estado_miembro
    ) VALUES (
        chat_id,
        mi_usuario_id,
        true,
        true,
        'activo'
    );

    -- Crear algunos mensajes de prueba
    INSERT INTO mensajes (
        chat_id,
        usuario_id,
        contenido,
        tipo
    ) VALUES 
    (chat_id, mi_usuario_id, '¡Hola! Este es el primer mensaje de prueba 👋', 'texto'),
    (chat_id, mi_usuario_id, 'Este es el segundo mensaje para verificar que todo funciona correctamente', 'texto'),
    (chat_id, mi_usuario_id, '¿Cómo están las relaciones de la base de datos? 🔧', 'texto');

    RAISE NOTICE 'Datos de prueba creados exitosamente!';
    RAISE NOTICE 'Chat ID: %', chat_id;
    RAISE NOTICE 'Usuario ID: %', mi_usuario_id;
END $$; 