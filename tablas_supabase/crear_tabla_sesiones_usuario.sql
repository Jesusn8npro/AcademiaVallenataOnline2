-- 🕒 Tabla para tracking de tiempo de usuarios en la plataforma
-- Ejecutar este SQL en Supabase para habilitar el tracking de tiempo

CREATE TABLE IF NOT EXISTS sesiones_usuario (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  tiempo_total_minutos INTEGER DEFAULT 0,
  ultima_actividad TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ruta_actual TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Un registro por usuario por día
  UNIQUE(usuario_id, fecha)
);

-- Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_sesiones_usuario_fecha ON sesiones_usuario(usuario_id, fecha);
CREATE INDEX IF NOT EXISTS idx_sesiones_ultima_actividad ON sesiones_usuario(ultima_actividad);
CREATE INDEX IF NOT EXISTS idx_sesiones_ruta ON sesiones_usuario(ruta_actual);

-- RLS (Row Level Security) para que los usuarios solo vean sus datos
ALTER TABLE sesiones_usuario ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo pueden ver/editar sus propias sesiones
CREATE POLICY "Usuarios pueden ver sus propias sesiones" 
ON sesiones_usuario FOR SELECT 
USING (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden insertar sus propias sesiones" 
ON sesiones_usuario FOR INSERT 
WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden actualizar sus propias sesiones" 
ON sesiones_usuario FOR UPDATE 
USING (auth.uid() = usuario_id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION actualizar_updated_at_sesiones_usuario()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
CREATE TRIGGER trigger_actualizar_updated_at_sesiones_usuario
  BEFORE UPDATE ON sesiones_usuario
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_updated_at_sesiones_usuario();

-- Comentarios para documentación
COMMENT ON TABLE sesiones_usuario IS 'Tabla para tracking de tiempo que los usuarios pasan en la plataforma';
COMMENT ON COLUMN sesiones_usuario.tiempo_total_minutos IS 'Tiempo total en minutos que el usuario ha estado activo en la plataforma ese día';
COMMENT ON COLUMN sesiones_usuario.ruta_actual IS 'Última ruta/página visitada por el usuario';
COMMENT ON COLUMN sesiones_usuario.ultima_actividad IS 'Timestamp de la última actividad registrada del usuario';

-- Verificar que la tabla se creó correctamente
SELECT 'Tabla sesiones_usuario creada exitosamente' as resultado; 