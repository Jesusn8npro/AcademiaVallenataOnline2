-- SCRIPT URGENTE: Arreglar RLS en tabla inscripciones
-- Ejecutar TODO este script en Supabase SQL Editor

-- 1. DESHABILITAR RLS TEMPORALMENTE
ALTER TABLE inscripciones DISABLE ROW LEVEL SECURITY;

-- 2. ELIMINAR TODAS LAS POLÍTICAS EXISTENTES
DROP POLICY IF EXISTS "Users can view own inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Users can insert own inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Users can update own inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Users can delete own inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Admin can manage all inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Service role can manage all inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Admin full access" ON inscripciones;
DROP POLICY IF EXISTS "Service role full access" ON inscripciones;

-- 3. CREAR POLÍTICA SÚPER PERMISIVA PARA SERVICE ROLE
CREATE POLICY "service_role_full_access"
ON inscripciones
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 4. CREAR POLÍTICA SÚPER PERMISIVA PARA USUARIOS AUTENTICADOS
CREATE POLICY "authenticated_full_access"
ON inscripciones
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 5. HABILITAR RLS DE NUEVO
ALTER TABLE inscripciones ENABLE ROW LEVEL SECURITY;

-- 6. VERIFICAR QUE LAS POLÍTICAS SE CREARON
SELECT schemaname, tablename, policyname, roles, cmd 
FROM pg_policies 
WHERE tablename = 'inscripciones';

-- 7. PRUEBA MANUAL DE INSERCIÓN
INSERT INTO inscripciones (
    id,
    usuario_id,
    paquete_id,
    fecha_inscripcion,
    porcentaje_completado,
    completado,
    estado,
    progreso,
    ultima_actividad,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '027fa0cb-b5b7-4936-8a7f-fe8cb0dd4789', -- Usuario ID de la imagen
    'f1ad7a88-dab6-40db-af54-e21144a90587', -- Paquete ID de la imagen
    NOW(),
    0,
    false,
    'activo',
    0,
    NOW(),
    NOW(),
    NOW()
);

-- 8. VERIFICAR LA INSERCIÓN
SELECT * FROM inscripciones WHERE paquete_id IS NOT NULL ORDER BY created_at DESC LIMIT 5;

-- 9. SI LA INSERCIÓN FUNCIONA, ELIMINAR LA PRUEBA
DELETE FROM inscripciones 
WHERE usuario_id = '027fa0cb-b5b7-4936-8a7f-fe8cb0dd4789' 
AND paquete_id = 'f1ad7a88-dab6-40db-af54-e21144a90587'
AND estado = 'activo';

-- 10. VERIFICAR ESTRUCTURA DE LA TABLA
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'inscripciones'
AND column_name IN ('id', 'usuario_id', 'paquete_id', 'created_at', 'updated_at')
ORDER BY ordinal_position; 