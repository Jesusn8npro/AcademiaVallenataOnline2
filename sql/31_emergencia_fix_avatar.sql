-- SCRIPT DE EMERGENCIA - ARREGLAR AVATAR INMEDIATAMENTE
-- Este script arregla el problema del avatar que se jodió

-- 1. VERIFICAR QUE COLUMNAS EXISTEN
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'comunidad_publicaciones' 
AND column_name IN ('usuario_avatar', 'avatar_url');

-- 2. ELIMINAR LA COLUMNA PROBLEMÁTICA QUE AGREGAMOS
DO $$
BEGIN
    -- Eliminar la columna usuario_avatar que acabamos de agregar
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'comunidad_publicaciones' 
        AND column_name = 'usuario_avatar'
    ) THEN
        ALTER TABLE comunidad_publicaciones 
        DROP COLUMN usuario_avatar;
        
        RAISE NOTICE 'Columna usuario_avatar eliminada';
    END IF;
END $$;

-- 3. VERIFICAR ESTRUCTURA ORIGINAL
SELECT column_name, data_type
FROM information_schema.columns 
WHERE table_name = 'comunidad_publicaciones' 
ORDER BY ordinal_position;

-- 4. TEST DE INSERCIÓN SIN AVATAR
DO $$
BEGIN
    INSERT INTO comunidad_publicaciones (
        usuario_id,
        usuario_nombre,
        titulo,
        descripcion,
        tipo,
        fecha_creacion
    ) VALUES (
        '12345678-1234-1234-1234-123456789012',
        'Usuario Test',
        'Test sin avatar',
        'Prueba sin campo avatar',
        'texto',
        NOW()
    );
    
    RAISE NOTICE 'TEST EXITOSO: Inserción sin avatar funciona';
    
    -- Limpiar test
    DELETE FROM comunidad_publicaciones 
    WHERE titulo = 'Test sin avatar' AND usuario_nombre = 'Usuario Test';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR EN TEST: %', SQLERRM;
END $$;

-- 5. MOSTRAR ESTADO FINAL
SELECT COUNT(*) as total_publicaciones FROM comunidad_publicaciones;

COMMIT; 