-- Agregar campo membresia_id a la tabla pagos_epayco
-- Para soportar pagos de membresías

ALTER TABLE pagos_epayco 
ADD COLUMN IF NOT EXISTS membresia_id UUID REFERENCES membresias(id);

-- Crear índice para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_pagos_epayco_membresia_id 
ON pagos_epayco(membresia_id);

-- Verificar que se agregó correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'pagos_epayco' 
AND column_name = 'membresia_id';

COMMENT ON COLUMN pagos_epayco.membresia_id IS 'ID de la membresía asociada al pago (para pagos de suscripciones)'; 