# Corrección del Constraint de Tipo - usuario_imagenes

## Problema
El constraint `usuario_imagenes_tipo_check` en la base de datos no permite los valores 'avatar' y 'portada' que estamos enviando desde el código.

## Solución
Ejecutar el script SQL para corregir el constraint.

## Instrucciones

### 1. Acceder a Supabase
- Ve a tu dashboard de Supabase
- Selecciona tu proyecto de Academia Vallenata
- Ve a la sección **SQL Editor**

### 2. Ejecutar el Script
- Abre el archivo `sql/fix_tipo_constraint.sql`
- Copia todo el contenido
- Pégalo en el SQL Editor de Supabase
- Haz clic en **RUN** o **EXECUTE**

### 3. Verificar Resultados
El script mostrará:
1. El constraint actual (si existe)
2. Eliminará el constraint problemático
3. Creará el nuevo constraint correcto
4. Verificará que se aplicó correctamente
5. Mostrará los datos existentes (si los hay)

### 4. Resultado Esperado
Después de ejecutar el script, deberías ver que el constraint permite los valores:
- 'avatar'
- 'portada'

## Verificación
Una vez ejecutado el script, prueba nuevamente hacer clic en las imágenes del perfil. El modal debería abrirse sin errores.

## Código del Script
```sql
-- Script para verificar y corregir el constraint de tipo en usuario_imagenes

-- 1. Verificar el constraint actual
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'usuario_imagenes' 
  AND n.nspname = 'public'
  AND c.contype = 'c';

-- 2. Eliminar el constraint existente si existe
ALTER TABLE usuario_imagenes DROP CONSTRAINT IF EXISTS usuario_imagenes_tipo_check;

-- 3. Crear el nuevo constraint con los valores correctos
ALTER TABLE usuario_imagenes 
ADD CONSTRAINT usuario_imagenes_tipo_check 
CHECK (tipo IN ('avatar', 'portada'));

-- 4. Verificar que el constraint se aplicó correctamente
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'usuario_imagenes' 
  AND n.nspname = 'public'
  AND c.contype = 'c';

-- 5. Verificar datos existentes (si los hay)
SELECT tipo, COUNT(*) as cantidad
FROM usuario_imagenes
GROUP BY tipo;
```

## Notas Adicionales
- Este script es seguro de ejecutar, solo corrige el constraint
- No elimina datos existentes
- Si hay datos con tipos diferentes, el script te lo mostrará
- Puedes ejecutar el script múltiples veces sin problemas 