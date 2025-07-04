-- FIX DEFINITIVO PARA LA FUNCIÓN notificar_nueva_publicacion
-- Esta función está usando 'avatar_url' cuando debería usar 'url_foto_perfil'

-- 1. BUSCAR LA FUNCIÓN PROBLEMÁTICA
SELECT routine_name, routine_definition
FROM information_schema.routines 
WHERE routine_name = 'notificar_nueva_publicacion'
AND routine_type = 'FUNCTION';

-- 2. ELIMINAR LA FUNCIÓN PROBLEMÁTICA
DROP FUNCTION IF EXISTS notificar_nueva_publicacion();

-- 3. BUSCAR OTRAS FUNCIONES QUE USEN avatar_url
SELECT routine_name, routine_definition
FROM information_schema.routines 
WHERE routine_definition ILIKE '%avatar_url%'
AND routine_type = 'FUNCTION';

-- 4. ELIMINAR TODAS LAS FUNCIONES QUE USEN avatar_url
DO $$
DECLARE
    func_name text;
BEGIN
    FOR func_name IN 
        SELECT routine_name
        FROM information_schema.routines 
        WHERE routine_definition ILIKE '%avatar_url%'
        AND routine_type = 'FUNCTION'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_name || '()';
        RAISE NOTICE 'Función eliminada: %', func_name;
    END LOOP;
END $$;

-- 5. VERIFICAR QUE NO QUEDEN FUNCIONES CON avatar_url
SELECT COUNT(*) as funciones_con_avatar_url
FROM information_schema.routines 
WHERE routine_definition ILIKE '%avatar_url%'
AND routine_type = 'FUNCTION';

-- 6. HACER PRUEBA DE INSERCIÓN CON USUARIO REAL
INSERT INTO comunidad_publicaciones (
    usuario_id,
    usuario_nombre,
    usuario_avatar,
    titulo,
    descripcion,
    tipo,
    fecha_creacion
) VALUES (
    (SELECT id FROM perfiles LIMIT 1),
    (SELECT COALESCE(nombre, nombre_usuario, 'Usuario') FROM perfiles LIMIT 1),
    (SELECT COALESCE(
        'https://ui-avatars.com/api/?name=' || COALESCE(nombre, nombre_usuario, 'Usuario'),
        'https://ui-avatars.com/api/?name=Usuario'
    ) FROM perfiles LIMIT 1),
    'Test Post Final',
    'Prueba final después de eliminar funciones problemáticas',
    'texto',
    NOW()
);

-- 7. VERIFICAR LA INSERCIÓN
SELECT id, usuario_nombre, titulo, fecha_creacion 
FROM comunidad_publicaciones 
WHERE titulo = 'Test Post Final';

-- 8. ELIMINAR LA PRUEBA
DELETE FROM comunidad_publicaciones 
WHERE titulo = 'Test Post Final';

-- 9. MENSAJE FINAL
SELECT 'FUNCIONES PROBLEMÁTICAS ELIMINADAS - PUBLICACIONES DEBERÍAN FUNCIONAR' as resultado; 