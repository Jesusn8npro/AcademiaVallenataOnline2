-- ELIMINAR TRIGGER Y FUNCIÓN EN EL ORDEN CORRECTO
-- Primero el trigger, después la función

-- 1. BUSCAR TODOS LOS TRIGGERS EN comunidad_publicaciones
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones';

-- 2. ELIMINAR EL TRIGGER ESPECÍFICO QUE USA LA FUNCIÓN
DROP TRIGGER IF EXISTS trigger_notificar_nueva_publicacion ON comunidad_publicaciones;

-- 3. ELIMINAR OTROS TRIGGERS POSIBLES
DROP TRIGGER IF EXISTS notificar_publicacion_admin ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_notificar_publicacion_admin ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_avatar_url ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS update_avatar_trigger ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS insert_avatar_trigger ON comunidad_publicaciones;

-- 4. VERIFICAR QUE NO QUEDEN TRIGGERS
SELECT 
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones';

-- 5. AHORA SÍ ELIMINAR LA FUNCIÓN
DROP FUNCTION IF EXISTS notificar_nueva_publicacion();

-- 6. ELIMINAR OTRAS FUNCIONES PROBLEMÁTICAS
DROP FUNCTION IF EXISTS notificar_publicacion_admin();
DROP FUNCTION IF EXISTS update_avatar_url();
DROP FUNCTION IF EXISTS insert_avatar_url();

-- 7. VERIFICAR QUE NO QUEDEN FUNCIONES CON avatar_url
SELECT routine_name
FROM information_schema.routines 
WHERE routine_definition ILIKE '%avatar_url%'
AND routine_type = 'FUNCTION';

-- 8. HACER PRUEBA DE INSERCIÓN SIMPLE
INSERT INTO comunidad_publicaciones (
    usuario_id,
    usuario_nombre,
    usuario_avatar,
    titulo,
    descripcion,
    tipo
) VALUES (
    (SELECT id FROM perfiles LIMIT 1),
    'Test User',
    'https://ui-avatars.com/api/?name=Test',
    'Test Final',
    'Prueba sin triggers',
    'texto'
);

-- 9. VERIFICAR LA INSERCIÓN
SELECT id, usuario_nombre, titulo 
FROM comunidad_publicaciones 
WHERE titulo = 'Test Final';

-- 10. ELIMINAR LA PRUEBA
DELETE FROM comunidad_publicaciones 
WHERE titulo = 'Test Final';

-- 11. MENSAJE FINAL
SELECT 'TRIGGERS Y FUNCIONES ELIMINADOS - PUBLICACIONES FUNCIONAN' as resultado; 