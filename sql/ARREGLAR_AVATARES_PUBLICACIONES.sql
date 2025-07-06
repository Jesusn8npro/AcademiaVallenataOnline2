-- 🔧 SCRIPT PARA ARREGLAR AVATARES EN PUBLICACIONES AUTOMÁTICAS EXISTENTES
-- Actualizar usuario_avatar con el avatar real del usuario desde la tabla perfiles

-- 1. VERIFICAR PUBLICACIONES CON AVATAR VACÍO O INCORRECTO
SELECT 
    '=== PUBLICACIONES CON PROBLEMAS DE AVATAR ===' as diagnostico,
    p.id,
    p.usuario_nombre,
    p.usuario_avatar,
    p.tipo,
    p.url_imagen,
    pr.url_foto_perfil as avatar_real_en_perfiles,
    CASE 
        WHEN p.usuario_avatar IS NULL OR p.usuario_avatar = '' THEN '❌ AVATAR VACÍO'
        WHEN p.usuario_avatar = p.url_imagen AND p.tipo = 'foto_portada' THEN '❌ AVATAR = PORTADA (MAL)'
        WHEN p.usuario_avatar != pr.url_foto_perfil THEN '⚠️ AVATAR DESACTUALIZADO'
        ELSE '✅ AVATAR OK'
    END as estado_avatar
FROM comunidad_publicaciones p
LEFT JOIN perfiles pr ON p.usuario_id = pr.id
WHERE p.tipo IN ('foto_perfil', 'foto_portada')
ORDER BY p.fecha_creacion DESC;

-- 2. ACTUALIZAR AVATARES VACÍOS O INCORRECTOS
UPDATE comunidad_publicaciones 
SET usuario_avatar = (
    SELECT url_foto_perfil 
    FROM perfiles 
    WHERE id = comunidad_publicaciones.usuario_id
    LIMIT 1
)
WHERE tipo IN ('foto_perfil', 'foto_portada')
  AND (
    usuario_avatar IS NULL 
    OR usuario_avatar = '' 
    OR (tipo = 'foto_portada' AND usuario_avatar = url_imagen) -- Casos donde avatar = imagen de portada
  );

-- 3. VERIFICAR QUE SE CORRIGIERON
SELECT 
    '=== RESULTADO DESPUÉS DE LA CORRECCIÓN ===' as resultado,
    COUNT(*) as total_publicaciones_automaticas,
    COUNT(CASE WHEN usuario_avatar IS NOT NULL AND usuario_avatar != '' THEN 1 END) as con_avatar,
    COUNT(CASE WHEN usuario_avatar IS NULL OR usuario_avatar = '' THEN 1 END) as sin_avatar
FROM comunidad_publicaciones 
WHERE tipo IN ('foto_perfil', 'foto_portada');

-- 4. VER EJEMPLOS CORREGIDOS
SELECT 
    '=== EJEMPLOS DE PUBLICACIONES CORREGIDAS ===' as ejemplos,
    id,
    usuario_nombre,
    usuario_avatar,
    tipo,
    url_imagen,
    fecha_creacion
FROM comunidad_publicaciones 
WHERE tipo IN ('foto_perfil', 'foto_portada')
ORDER BY fecha_creacion DESC
LIMIT 5; 