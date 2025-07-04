-- FIX PARA USAR USUARIO_ID REAL
-- Este script prueba con un usuario que SÍ existe

-- 1. BUSCAR UN USUARIO REAL QUE EXISTA
SELECT id, nombre, nombre_usuario 
FROM perfiles 
LIMIT 3;

-- 2. HACER PRUEBA CON USUARIO REAL
-- (Reemplaza 'TU_USUARIO_ID_REAL' con uno de los IDs de arriba)
INSERT INTO comunidad_publicaciones (
    usuario_id,
    usuario_nombre,
    usuario_avatar,
    titulo,
    descripcion,
    tipo,
    fecha_creacion
) VALUES (
    (SELECT id FROM perfiles LIMIT 1),  -- Usar el primer usuario real
    (SELECT COALESCE(nombre, nombre_usuario, 'Usuario') FROM perfiles LIMIT 1),
    'https://ui-avatars.com/api/?name=Test&background=667eea&color=fff',
    'Test Post Real',
    'Esta es una prueba con usuario real',
    'texto',
    NOW()
);

-- 3. VERIFICAR QUE SE INSERTÓ
SELECT * FROM comunidad_publicaciones 
WHERE titulo = 'Test Post Real'
ORDER BY fecha_creacion DESC;

-- 4. ELIMINAR LA PRUEBA
DELETE FROM comunidad_publicaciones 
WHERE titulo = 'Test Post Real';

-- 5. MENSAJE FINAL
SELECT 'PRUEBA COMPLETADA - PUBLICACIONES FUNCIONAN CON USUARIO REAL' as resultado; 