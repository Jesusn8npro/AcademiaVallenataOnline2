-- FIX DEFINITIVO PARA PROBLEMA DE AVATAR_URL
-- Este script arregla el problema específico de la columna avatar_url

-- 1. VERIFICAR SI EXISTE LA COLUMNA usuario_avatar
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'comunidad_publicaciones' 
AND column_name IN ('usuario_avatar', 'avatar_url');

-- 2. AGREGAR LA COLUMNA usuario_avatar SI NO EXISTE
DO $$
BEGIN
    -- Verificar si la columna existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'comunidad_publicaciones' 
        AND column_name = 'usuario_avatar'
    ) THEN
        -- Agregar la columna
        ALTER TABLE comunidad_publicaciones 
        ADD COLUMN usuario_avatar TEXT;
        
        RAISE NOTICE 'Columna usuario_avatar agregada exitosamente';
    ELSE
        RAISE NOTICE 'La columna usuario_avatar ya existe';
    END IF;
END $$;

-- 3. ELIMINAR CUALQUIER TRIGGER PROBLEMÁTICO
DROP TRIGGER IF EXISTS notificar_publicacion_admin ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_notificar_publicacion_admin ON comunidad_publicaciones;
DROP FUNCTION IF EXISTS notificar_publicacion_admin();
DROP FUNCTION IF EXISTS trigger_notificar_publicacion_admin();

-- 4. VERIFICAR ESTRUCTURA ACTUALIZADA
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'comunidad_publicaciones' 
AND column_name LIKE '%avatar%'
ORDER BY ordinal_position;

-- 5. TEST DE INSERCIÓN CON TODOS LOS CAMPOS
DO $$
BEGIN
    INSERT INTO comunidad_publicaciones (
        usuario_id,
        usuario_nombre,
        usuario_avatar,
        titulo,
        descripcion,
        tipo,
        fecha_creacion
    ) VALUES (
        '12345678-1234-1234-1234-123456789012',
        'Usuario Test',
        'https://example.com/avatar.jpg',
        'Test con avatar',
        'Prueba con campo avatar',
        'texto',
        NOW()
    );
    
    RAISE NOTICE 'TEST EXITOSO: Inserción con avatar funciona';
    
    -- Limpiar test
    DELETE FROM comunidad_publicaciones 
    WHERE titulo = 'Test con avatar' AND usuario_nombre = 'Usuario Test';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR EN TEST: %', SQLERRM;
END $$;

-- 6. MOSTRAR ESTADO FINAL
SELECT 
    'comunidad_publicaciones' as tabla,
    COUNT(*) as total_columnas,
    string_agg(column_name, ', ') as columnas
FROM information_schema.columns 
WHERE table_name = 'comunidad_publicaciones'
GROUP BY table_name;

COMMIT; 