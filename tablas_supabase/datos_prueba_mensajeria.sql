-- ============================================
-- DATOS DE PRUEBA - SISTEMA DE MENSAJERÍA
-- ============================================
-- Ejecutar DESPUÉS de crear las tablas principales

-- NOTA: Reemplaza los UUIDs con los IDs reales de tus usuarios
-- Puedes obtenerlos ejecutando: SELECT id, nombre_completo FROM perfiles LIMIT 5;

-- ============================================
-- 1. CREAR ALGUNOS CHATS DE PRUEBA
-- ============================================

-- Chat grupal: "Estudiantes de Acordeón 2024"
INSERT INTO chats (
    id,
    nombre,
    descripcion,
    es_grupal,
    tipo_chat,
    creado_por,
    configuracion
) VALUES (
    gen_random_uuid(),
    'Estudiantes de Acordeón 2024',
    'Grupo para compartir tips y coordinar prácticas',
    true,
    'grupo',
    (SELECT id FROM perfiles WHERE rol = 'admin' LIMIT 1), -- El primer admin como creador
    '{"permitir_invitaciones": true, "notificaciones": true}'
) RETURNING id as chat_grupal_id;

-- Chat privado de ejemplo (se creará automáticamente cuando dos usuarios se escriban)

-- ============================================
-- 2. AGREGAR MIEMBROS AL CHAT GRUPAL
-- ============================================

-- Obtener el ID del chat grupal que acabamos de crear
DO $$
DECLARE
    chat_id UUID;
    admin_id UUID;
    user_ids UUID[];
    user_id UUID;
BEGIN
    -- Obtener el chat grupal
    SELECT id INTO chat_id FROM chats WHERE nombre = 'Estudiantes de Acordeón 2024' LIMIT 1;
    
    -- Obtener ID del admin
    SELECT id INTO admin_id FROM perfiles WHERE rol = 'admin' LIMIT 1;
    
    -- Obtener algunos usuarios para agregar al grupo
    SELECT ARRAY(SELECT id FROM perfiles WHERE rol IN ('estudiante', 'instructor') LIMIT 5) INTO user_ids;
    
    -- Agregar admin como miembro y administrador
    INSERT INTO miembros_chat (chat_id, usuario_id, es_admin, estado_miembro)
    VALUES (chat_id, admin_id, true, 'activo');
    
    -- Agregar otros usuarios como miembros
    FOREACH user_id IN ARRAY user_ids
    LOOP
        INSERT INTO miembros_chat (chat_id, usuario_id, es_admin, estado_miembro)
        VALUES (chat_id, user_id, false, 'activo');
    END LOOP;
END $$;

-- ============================================
-- 3. MENSAJES DE PRUEBA
-- ============================================

-- Insertar algunos mensajes en el chat grupal
DO $$
DECLARE
    chat_id UUID;
    admin_id UUID;
    user_ids UUID[];
    mensaje_id UUID;
BEGIN
    -- Obtener IDs necesarios
    SELECT id INTO chat_id FROM chats WHERE nombre = 'Estudiantes de Acordeón 2024' LIMIT 1;
    SELECT id INTO admin_id FROM perfiles WHERE rol = 'admin' LIMIT 1;
    SELECT ARRAY(SELECT id FROM perfiles WHERE rol IN ('estudiante', 'instructor') LIMIT 3) INTO user_ids;
    
    -- Mensaje de bienvenida del admin
    INSERT INTO mensajes (chat_id, usuario_id, contenido, tipo)
    VALUES (
        chat_id,
        admin_id,
        '¡Bienvenidos al grupo de estudiantes de acordeón! 🪗 Aquí pueden compartir dudas, tips y coordinar prácticas.',
        'texto'
    ) RETURNING id INTO mensaje_id;
    
    -- Marcar como leído por el admin
    INSERT INTO mensajes_lectura (mensaje_id, usuario_id, leido_en)
    VALUES (mensaje_id, admin_id, now());
    
    -- Algunos mensajes de otros usuarios
    INSERT INTO mensajes (chat_id, usuario_id, contenido, tipo)
    VALUES 
    (
        chat_id,
        user_ids[1],
        '¡Hola a todos! Estoy muy emocionado de estar aquí 😊',
        'texto'
    ),
    (
        chat_id,
        user_ids[2],
        '¿Alguien sabe algún ejercicio bueno para mejorar la velocidad en los dedos?',
        'texto'
    ),
    (
        chat_id,
        admin_id,
        'Te recomiendo practicar escalas cromáticas despacio y luego aumentar la velocidad gradualmente. ¡La constancia es clave!',
        'texto'
    ),
    (
        chat_id,
        user_ids[3],
        'Muchas gracias por el consejo! 🙏',
        'texto'
    );
END $$;

-- ============================================
-- 4. ALGUNAS REACCIONES DE PRUEBA
-- ============================================

-- Agregar reacciones a algunos mensajes
DO $$
DECLARE
    mensaje_ids UUID[];
    user_ids UUID[];
BEGIN
    -- Obtener algunos mensajes del grupo
    SELECT ARRAY(SELECT id FROM mensajes ORDER BY creado_en LIMIT 3) INTO mensaje_ids;
    
    -- Obtener algunos usuarios
    SELECT ARRAY(SELECT id FROM perfiles LIMIT 4) INTO user_ids;
    
    -- Agregar reacciones
    INSERT INTO mensajes_reacciones (mensaje_id, usuario_id, reaccion)
    VALUES 
    (mensaje_ids[1], user_ids[1], '👍'),
    (mensaje_ids[1], user_ids[2], '❤️'),
    (mensaje_ids[2], user_ids[3], '👍'),
    (mensaje_ids[3], user_ids[1], '💯'),
    (mensaje_ids[3], user_ids[4], '🙌');
    
END $$;

-- ============================================
-- 5. ACTUALIZAR CONTADORES Y FECHAS
-- ============================================

-- Actualizar último mensaje en chats
UPDATE chats 
SET 
    ultimo_mensaje_id = (
        SELECT id FROM mensajes 
        WHERE chat_id = chats.id 
        ORDER BY creado_en DESC 
        LIMIT 1
    ),
    ultimo_mensaje_fecha = (
        SELECT creado_en FROM mensajes 
        WHERE chat_id = chats.id 
        ORDER BY creado_en DESC 
        LIMIT 1
    ),
    actualizado_en = now()
WHERE id IN (SELECT DISTINCT chat_id FROM mensajes);

-- ============================================
-- 6. CREAR UN CHAT PRIVADO DE EJEMPLO
-- ============================================

-- Crear un chat privado entre dos usuarios
DO $$
DECLARE
    admin_id UUID;
    estudiante_id UUID;
    chat_privado_id UUID;
    mensaje_id UUID;
BEGIN
    -- Obtener IDs
    SELECT id INTO admin_id FROM perfiles WHERE rol = 'admin' LIMIT 1;
    SELECT id INTO estudiante_id FROM perfiles WHERE rol = 'estudiante' LIMIT 1;
    
    -- Solo crear si tenemos ambos usuarios
    IF admin_id IS NOT NULL AND estudiante_id IS NOT NULL THEN
        -- Crear chat privado
        INSERT INTO chats (
            nombre,
            es_grupal,
            tipo_chat,
            creado_por,
            configuracion
        ) VALUES (
            NULL, -- Los chats privados no tienen nombre
            false,
            'privado',
            admin_id,
            '{}'
        ) RETURNING id INTO chat_privado_id;
        
        -- Agregar miembros
        INSERT INTO miembros_chat (chat_id, usuario_id, es_admin, estado_miembro)
        VALUES 
        (chat_privado_id, admin_id, false, 'activo'),
        (chat_privado_id, estudiante_id, false, 'activo');
        
        -- Mensaje inicial
        INSERT INTO mensajes (chat_id, usuario_id, contenido, tipo)
        VALUES (
            chat_privado_id,
            admin_id,
            'Hola! ¿Cómo va tu progreso con las lecciones de acordeón?',
            'texto'
        ) RETURNING id INTO mensaje_id;
        
        -- Marcar como leído por el remitente
        INSERT INTO mensajes_lectura (mensaje_id, usuario_id, leido_en)
        VALUES (mensaje_id, admin_id, now());
        
        -- Respuesta del estudiante
        INSERT INTO mensajes (chat_id, usuario_id, contenido, tipo)
        VALUES (
            chat_privado_id,
            estudiante_id,
            '¡Muy bien! Ya puedo tocar algunas canciones básicas. ¿Tienes alguna recomendación para continuar?',
            'texto'
        );
        
        -- Actualizar el chat con el último mensaje
        UPDATE chats 
        SET 
            ultimo_mensaje_id = (SELECT id FROM mensajes WHERE chat_id = chat_privado_id ORDER BY creado_en DESC LIMIT 1),
            ultimo_mensaje_fecha = (SELECT creado_en FROM mensajes WHERE chat_id = chat_privado_id ORDER BY creado_en DESC LIMIT 1),
            actualizado_en = now()
        WHERE id = chat_privado_id;
    END IF;
END $$;

-- ============================================
-- 7. VERIFICACIÓN DE DATOS
-- ============================================

-- Consulta para verificar que todo se insertó correctamente
SELECT 
    'Resumen de datos de prueba:' as info,
    (SELECT COUNT(*) FROM chats WHERE activo = true) as total_chats,
    (SELECT COUNT(*) FROM miembros_chat WHERE estado_miembro = 'activo') as total_miembros,
    (SELECT COUNT(*) FROM mensajes) as total_mensajes,
    (SELECT COUNT(*) FROM mensajes_reacciones) as total_reacciones;

-- Mostrar los chats creados
SELECT 
    c.id,
    c.nombre,
    c.es_grupal,
    c.tipo_chat,
    COUNT(mc.usuario_id) as num_miembros,
    COUNT(m.id) as num_mensajes
FROM chats c
LEFT JOIN miembros_chat mc ON c.id = mc.chat_id AND mc.estado_miembro = 'activo'
LEFT JOIN mensajes m ON c.id = m.chat_id
WHERE c.activo = true
GROUP BY c.id, c.nombre, c.es_grupal, c.tipo_chat
ORDER BY c.creado_en DESC;

-- ============================================
-- INSTRUCCIONES PARA PERSONALIZAR
-- ============================================

/*
PARA PERSONALIZAR CON TUS USUARIOS REALES:

1. Ejecuta esta consulta para ver tus usuarios:
   SELECT id, nombre_completo, rol FROM perfiles ORDER BY created_at;

2. Si quieres agregar usuarios específicos a chats:
   
   -- Ejemplo: Agregar usuario específico a un chat grupal
   INSERT INTO miembros_chat (chat_id, usuario_id, es_admin, estado_miembro)
   VALUES (
       'ID_DEL_CHAT_AQUÍ',
       'ID_DEL_USUARIO_AQUÍ',
       false,
       'activo'
   );

3. Para crear más mensajes de prueba:
   
   INSERT INTO mensajes (chat_id, usuario_id, contenido, tipo)
   VALUES (
       'ID_DEL_CHAT',
       'ID_DEL_USUARIO',
       'Contenido del mensaje aquí',
       'texto'
   );

4. Para limpiar datos de prueba si es necesario:
   
   DELETE FROM mensajes_reacciones;
   DELETE FROM mensajes_lectura;
   DELETE FROM mensajes;
   DELETE FROM miembros_chat;
   DELETE FROM chats;
*/ 