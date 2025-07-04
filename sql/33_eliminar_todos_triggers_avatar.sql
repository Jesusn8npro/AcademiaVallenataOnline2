-- SCRIPT PARA ELIMINAR TODOS LOS TRIGGERS QUE USAN AVATAR_URL
-- Este script encuentra y elimina TODOS los triggers problemáticos

-- 1. BUSCAR TODOS LOS TRIGGERS EN LA TABLA
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones'
ORDER BY trigger_name;

-- 2. BUSCAR FUNCIONES QUE CONTENGAN 'avatar_url'
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_definition ILIKE '%avatar_url%'
AND routine_type = 'FUNCTION';

-- 3. ELIMINAR TODOS LOS TRIGGERS POSIBLES
DROP TRIGGER IF EXISTS notificar_publicacion_admin ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_notificar_publicacion_admin ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_avatar_url ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS update_avatar_trigger ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS insert_avatar_trigger ON comunidad_publicaciones;

-- 4. ELIMINAR FUNCIONES QUE USAN AVATAR_URL
DROP FUNCTION IF EXISTS notificar_publicacion_admin();
DROP FUNCTION IF EXISTS update_avatar_url();
DROP FUNCTION IF EXISTS insert_avatar_url();

-- 5. VERIFICAR QUE NO QUEDEN TRIGGERS
SELECT 
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones';

-- 6. HACER UNA PRUEBA DE INSERCIÓN
INSERT INTO comunidad_publicaciones (
    usuario_id,
    usuario_nombre,
    usuario_avatar,
    titulo,
    descripcion,
    tipo,
    fecha_creacion
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Test User',
    'https://ui-avatars.com/api/?name=Test&background=667eea&color=fff',
    'Test Post',
    'Esta es una prueba',
    'texto',
    NOW()
);

-- 7. ELIMINAR LA PRUEBA
DELETE FROM comunidad_publicaciones 
WHERE titulo = 'Test Post' AND usuario_nombre = 'Test User';

-- 8. MENSAJE FINAL
SELECT 'TRIGGERS ELIMINADOS - PUBLICACIONES DEBERÍAN FUNCIONAR' as resultado; 