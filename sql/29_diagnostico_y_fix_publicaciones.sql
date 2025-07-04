-- DIAGNÓSTICO COMPLETO Y FIX DE PUBLICACIONES
-- Script para solucionar el problema de publicaciones de una vez por todas

-- 1. VERIFICAR ESTRUCTURA DE LA TABLA
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'comunidad_publicaciones' 
ORDER BY ordinal_position;

-- 2. VERIFICAR TRIGGERS EXISTENTES
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'comunidad_publicaciones';

-- 3. ELIMINAR TODOS LOS TRIGGERS PROBLEMÁTICOS
DROP TRIGGER IF EXISTS notificar_publicacion_admin ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_notificar_publicacion_admin ON comunidad_publicaciones;

-- 4. ELIMINAR FUNCIONES PROBLEMÁTICAS
DROP FUNCTION IF EXISTS notificar_publicacion_admin();
DROP FUNCTION IF EXISTS trigger_notificar_publicacion_admin();

-- 5. VERIFICAR QUE NO EXISTAN POLICIES PROBLEMÁTICAS
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies 
WHERE tablename = 'comunidad_publicaciones';

-- 6. CREAR TABLA DE RESPALDO TEMPORAL
CREATE TABLE IF NOT EXISTS comunidad_publicaciones_backup AS
SELECT * FROM comunidad_publicaciones LIMIT 0;

-- 7. TEST DE INSERCIÓN SIMPLE
DO $$
BEGIN
    -- Intentar insertar una publicación de prueba
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
        'Test de publicación',
        'Esta es una prueba',
        'texto',
        NOW()
    );
    
    RAISE NOTICE 'TEST EXITOSO: La inserción funciona correctamente';
    
    -- Limpiar el test
    DELETE FROM comunidad_publicaciones 
    WHERE titulo = 'Test de publicación' AND usuario_nombre = 'Usuario Test';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR EN TEST: %', SQLERRM;
END $$;

-- 8. VERIFICAR PERMISOS RLS
SELECT schemaname, tablename, rowsecurity
FROM pg_tables 
WHERE tablename = 'comunidad_publicaciones';

-- 9. MOSTRAR TODAS LAS POLICIES ACTIVAS
SELECT policyname, cmd, permissive, roles, qual, with_check
FROM pg_policies 
WHERE tablename = 'comunidad_publicaciones';

-- 10. VERIFICAR ESTRUCTURA FINAL
\d comunidad_publicaciones;

-- 11. CONTAR PUBLICACIONES EXISTENTES
SELECT COUNT(*) as total_publicaciones FROM comunidad_publicaciones;

COMMIT; 