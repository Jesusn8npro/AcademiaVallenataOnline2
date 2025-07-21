-- Script para arreglar políticas de RLS en tabla inscripciones
-- Ejecutar en el SQL Editor de Supabase

-- 1. Primero verificar si RLS está habilitado
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'inscripciones';

-- 2. Deshabilitar RLS temporalmente para debugging
ALTER TABLE inscripciones DISABLE ROW LEVEL SECURITY;

-- 3. Eliminar políticas existentes que puedan estar causando problemas
DROP POLICY IF EXISTS "Users can view own inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Users can insert own inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Users can update own inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Admin can manage all inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Service role can manage all inscripciones" ON inscripciones;

-- 4. Crear políticas nuevas más permisivas
CREATE POLICY "Admin can manage all inscripciones"
ON inscripciones
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 5. Crear política específica para service role
CREATE POLICY "Service role can manage all inscripciones"
ON inscripciones
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 6. Política para que usuarios autenticados puedan ver sus propias inscripciones
CREATE POLICY "Users can view own inscripciones"
ON inscripciones
FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());

-- 7. Política para que usuarios autenticados puedan insertar sus propias inscripciones
CREATE POLICY "Users can insert own inscripciones"
ON inscripciones
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid());

-- 8. Política para que usuarios autenticados puedan actualizar sus propias inscripciones
CREATE POLICY "Users can update own inscripciones"
ON inscripciones
FOR UPDATE
TO authenticated
USING (usuario_id = auth.uid())
WITH CHECK (usuario_id = auth.uid());

-- 9. Habilitar RLS de nuevo
ALTER TABLE inscripciones ENABLE ROW LEVEL SECURITY;

-- 10. Verificar las políticas creadas
SELECT schemaname, tablename, policyname, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'inscripciones';

-- 11. Verificar la estructura de la tabla
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'inscripciones'
ORDER BY ordinal_position;

-- 12. Verificar las relaciones foreign key
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name='inscripciones';

-- 13. Probar inserción manual para verificar funcionamiento
-- INSERT INTO inscripciones (
--     id,
--     usuario_id,
--     paquete_id,
--     fecha_inscripcion,
--     porcentaje_completado,
--     completado,
--     estado,
--     progreso,
--     ultima_actividad,
--     created_at,
--     updated_at
-- ) VALUES (
--     gen_random_uuid(),
--     'USER_ID_AQUI',
--     'PAQUETE_ID_AQUI',
--     NOW(),
--     0,
--     false,
--     'activo',
--     0,
--     NOW(),
--     NOW(),
--     NOW()
-- ); 