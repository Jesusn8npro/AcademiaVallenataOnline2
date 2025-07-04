-- FIX DEFINITIVO PARA AVATARES EN PUBLICACIONES
-- Este script agrega la columna usuario_avatar y actualiza publicaciones existentes

-- 1. AGREGAR COLUMNA usuario_avatar SI NO EXISTE
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'comunidad_publicaciones' 
        AND column_name = 'usuario_avatar'
    ) THEN
        ALTER TABLE comunidad_publicaciones 
        ADD COLUMN usuario_avatar TEXT;
        
        RAISE NOTICE 'Columna usuario_avatar agregada a comunidad_publicaciones';
    ELSE
        RAISE NOTICE 'La columna usuario_avatar ya existe en comunidad_publicaciones';
    END IF;
END $$;

-- 2. ACTUALIZAR PUBLICACIONES EXISTENTES SIN AVATAR
UPDATE comunidad_publicaciones 
SET usuario_avatar = 'https://ui-avatars.com/api/?name=' || 
    COALESCE(REPLACE(usuario_nombre, ' ', '+'), 'Usuario') || 
    '&background=667eea&color=fff'
WHERE usuario_avatar IS NULL OR usuario_avatar = '';

-- 3. AGREGAR COLUMNA A COMENTARIOS TAMBIÉN SI NO EXISTE
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'comunidad_comentarios' 
        AND column_name = 'usuario_avatar'
    ) THEN
        ALTER TABLE comunidad_comentarios 
        ADD COLUMN usuario_avatar TEXT;
        
        RAISE NOTICE 'Columna usuario_avatar agregada a comunidad_comentarios';
    ELSE
        RAISE NOTICE 'La columna usuario_avatar ya existe en comunidad_comentarios';
    END IF;
END $$;

-- 4. ACTUALIZAR COMENTARIOS EXISTENTES SIN AVATAR
UPDATE comunidad_comentarios 
SET usuario_avatar = 'https://ui-avatars.com/api/?name=' || 
    COALESCE(REPLACE(usuario_nombre, ' ', '+'), 'Usuario') || 
    '&background=667eea&color=fff'
WHERE usuario_avatar IS NULL OR usuario_avatar = '';

-- 5. VERIFICAR RESULTADOS
SELECT 
    'Publicaciones con avatar' as tipo,
    COUNT(*) as total
FROM comunidad_publicaciones 
WHERE usuario_avatar IS NOT NULL AND usuario_avatar != ''

UNION ALL

SELECT 
    'Comentarios con avatar' as tipo,
    COUNT(*) as total
FROM comunidad_comentarios 
WHERE usuario_avatar IS NOT NULL AND usuario_avatar != '';

-- 6. MOSTRAR ALGUNAS PUBLICACIONES COMO EJEMPLO
SELECT 
    usuario_nombre,
    usuario_avatar,
    titulo,
    LEFT(descripcion, 50) || '...' as descripcion_corta
FROM comunidad_publicaciones 
ORDER BY fecha_creacion DESC 
LIMIT 5;

COMMIT; 