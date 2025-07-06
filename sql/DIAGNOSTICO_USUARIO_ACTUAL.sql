-- 🔍 DIAGNÓSTICO ESPECÍFICO DEL USUARIO ACTUAL
-- Este script identifica exactamente cuál es el problema

-- 1. IDENTIFICAR EL USUARIO ACTUAL Y SUS DATOS
SELECT 
    '=== DATOS DEL USUARIO ACTUAL ===' as seccion,
    id,
    nombre_completo,
    correo_electronico,
    url_foto_perfil,
    portada_url,
    posicion_img_portada,
    CASE 
        WHEN url_foto_perfil IS NULL OR url_foto_perfil = '' THEN '❌ SIN AVATAR'
        ELSE '✅ TIENE AVATAR'
    END as estado_avatar,
    CASE 
        WHEN portada_url IS NULL OR portada_url = '' THEN '❌ SIN PORTADA'
        ELSE '✅ TIENE PORTADA'
    END as estado_portada
FROM perfiles 
WHERE correo_electronico LIKE '%jesus%' 
   OR correo_electronico LIKE '%acordeon%'
   OR correo_electronico LIKE '%academia%'
ORDER BY fecha_actualizacion DESC
LIMIT 5;

-- 2. BUSCAR IMÁGENES EN USUARIO_IMAGENES PARA ESTOS USUARIOS
SELECT 
    '=== IMÁGENES EN USUARIO_IMAGENES ===' as seccion,
    ui.id,
    ui.usuario_id,
    ui.url_imagen,
    ui.tipo,
    ui.es_actual,
    ui.fecha_subida,
    p.correo_electronico,
    p.nombre_completo
FROM usuario_imagenes ui
LEFT JOIN perfiles p ON ui.usuario_id = p.id
WHERE p.correo_electronico LIKE '%jesus%' 
   OR p.correo_electronico LIKE '%acordeon%'
   OR p.correo_electronico LIKE '%academia%'
ORDER BY ui.fecha_subida DESC
LIMIT 10;

-- 3. COMPARAR DATOS ENTRE AMBAS TABLAS
SELECT 
    '=== COMPARACIÓN DE DATOS ===' as seccion,
    p.correo_electronico,
    p.nombre_completo,
    p.url_foto_perfil as perfil_avatar,
    p.portada_url as perfil_portada,
    ui_avatar.url_imagen as imagen_avatar,
    ui_portada.url_imagen as imagen_portada,
    CASE 
        WHEN p.url_foto_perfil != ui_avatar.url_imagen THEN '🔥 AVATAR DESINCRONIZADO'
        WHEN p.url_foto_perfil IS NULL AND ui_avatar.url_imagen IS NOT NULL THEN '🔥 AVATAR FALTANTE EN PERFIL'
        ELSE '✅ Avatar OK'
    END as estado_avatar,
    CASE 
        WHEN p.portada_url != ui_portada.url_imagen THEN '🔥 PORTADA DESINCRONIZADA'
        WHEN p.portada_url IS NULL AND ui_portada.url_imagen IS NOT NULL THEN '🔥 PORTADA FALTANTE EN PERFIL'
        ELSE '✅ Portada OK'
    END as estado_portada
FROM perfiles p
LEFT JOIN usuario_imagenes ui_avatar ON p.id = ui_avatar.usuario_id 
    AND ui_avatar.tipo = 'avatar' 
    AND ui_avatar.es_actual = true
LEFT JOIN usuario_imagenes ui_portada ON p.id = ui_portada.usuario_id 
    AND ui_portada.tipo = 'portada' 
    AND ui_portada.es_actual = true
WHERE p.correo_electronico LIKE '%jesus%' 
   OR p.correo_electronico LIKE '%acordeon%'
   OR p.correo_electronico LIKE '%academia%'
ORDER BY p.fecha_actualizacion DESC;

-- 4. SCRIPT DE SINCRONIZACIÓN ESPECÍFICO
-- Solo ejecutar si encuentra problemas arriba
UPDATE perfiles 
SET url_foto_perfil = (
    SELECT url_imagen 
    FROM usuario_imagenes 
    WHERE usuario_id = perfiles.id 
      AND tipo = 'avatar' 
      AND es_actual = true 
    LIMIT 1
)
WHERE (correo_electronico LIKE '%jesus%' 
   OR correo_electronico LIKE '%acordeon%'
   OR correo_electronico LIKE '%academia%')
  AND id IN (
    SELECT DISTINCT usuario_id 
    FROM usuario_imagenes 
    WHERE tipo = 'avatar' AND es_actual = true
  );

UPDATE perfiles 
SET portada_url = (
    SELECT url_imagen 
    FROM usuario_imagenes 
    WHERE usuario_id = perfiles.id 
      AND tipo = 'portada' 
      AND es_actual = true 
    LIMIT 1
)
WHERE (correo_electronico LIKE '%jesus%' 
   OR correo_electronico LIKE '%acordeon%'
   OR correo_electronico LIKE '%academia%')
  AND id IN (
    SELECT DISTINCT usuario_id 
    FROM usuario_imagenes 
    WHERE tipo = 'portada' AND es_actual = true
  );

-- 5. VERIFICACIÓN FINAL
SELECT 
    '=== VERIFICACIÓN FINAL ===' as seccion,
    correo_electronico,
    CASE 
        WHEN url_foto_perfil IS NOT NULL AND url_foto_perfil != '' THEN '✅ AVATAR SOLUCIONADO'
        ELSE '❌ AVATAR AÚN FALTA'
    END as estado_avatar,
    CASE 
        WHEN portada_url IS NOT NULL AND portada_url != '' THEN '✅ PORTADA SOLUCIONADA'
        ELSE '❌ PORTADA AÚN FALTA'
    END as estado_portada
FROM perfiles 
WHERE correo_electronico LIKE '%jesus%' 
   OR correo_electronico LIKE '%acordeon%'
   OR correo_electronico LIKE '%academia%'
ORDER BY fecha_actualizacion DESC; 