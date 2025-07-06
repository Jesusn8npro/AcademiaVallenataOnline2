-- ===== VERIFICACIÓN: Constraint de Tipo Corregido =====
-- Ejecuta este script para verificar que el constraint está funcionando correctamente

-- 1. Verificar el constraint actual
SELECT 
    conname as nombre_constraint,
    pg_get_constraintdef(c.oid) as definicion_constraint
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'usuario_imagenes' 
  AND n.nspname = 'public'
  AND c.contype = 'c'
  AND conname = 'usuario_imagenes_tipo_check';

-- 2. Probar insertando un registro de prueba (avatar)
INSERT INTO usuario_imagenes (
    id,
    usuario_id,
    url_imagen,
    tipo,
    fecha_subida,
    es_actual
) VALUES (
    gen_random_uuid(),
    gen_random_uuid(),
    'https://test.com/avatar.jpg',
    'avatar',
    NOW(),
    true
);

-- 3. Probar insertando un registro de prueba (portada)
INSERT INTO usuario_imagenes (
    id,
    usuario_id,
    url_imagen,
    tipo,
    fecha_subida,
    es_actual
) VALUES (
    gen_random_uuid(),
    gen_random_uuid(),
    'https://test.com/portada.jpg',
    'portada',
    NOW(),
    true
);

-- 4. Verificar que los registros se insertaron correctamente
SELECT 
    tipo,
    COUNT(*) as cantidad,
    'Insertado correctamente' as estado
FROM usuario_imagenes 
WHERE url_imagen LIKE '%test.com%'
GROUP BY tipo;

-- 5. Limpiar registros de prueba
DELETE FROM usuario_imagenes WHERE url_imagen LIKE '%test.com%';

-- 6. Mensaje final
SELECT 
    'SUCCESS: El constraint está funcionando correctamente!' as resultado,
    'Los valores avatar y portada son válidos' as detalle; 