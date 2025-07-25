-- =====================================================
-- 💬 ACADEMIA VALLENATA ONLINE - LEADS CHAT ANÓNIMOS
-- =====================================================
-- Tabla para captura de leads en chat en vivo
-- Sistema de conversión de anónimos a usuarios registrados
-- Autor: AI Assistant para Academia Vallenata
-- Fecha: Enero 2025
-- =====================================================

-- =====================================================
-- 📊 TABLA: leads_chat_anonimos
-- =====================================================
-- Almacena información de usuarios anónimos que usan el chat
-- Permite tracking de conversión a usuarios registrados
-- =====================================================

CREATE TABLE IF NOT EXISTS public.leads_chat_anonimos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id VARCHAR(100) NOT NULL UNIQUE,
  
  -- Información del lead
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  whatsapp VARCHAR(20),
  tipo_consulta VARCHAR(50) DEFAULT 'general' CHECK (tipo_consulta IN ('general', 'ventas', 'soporte', 'tecnico', 'pagos', 'cursos')),
  primer_mensaje TEXT,
  
  -- Estado de conversión
  convertido_a_usuario BOOLEAN DEFAULT false,
  usuario_id UUID REFERENCES public.perfiles(id) ON DELETE SET NULL,
  
  -- Metadatos
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints únicos para evitar duplicados por día
  CONSTRAINT unique_email_fecha UNIQUE (email, DATE(created_at))
);

-- =====================================================
-- 🔍 ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_leads_chat_email ON public.leads_chat_anonimos(email);
CREATE INDEX IF NOT EXISTS idx_leads_chat_fecha ON public.leads_chat_anonimos(created_at);
CREATE INDEX IF NOT EXISTS idx_leads_chat_convertido ON public.leads_chat_anonimos(convertido_a_usuario);
CREATE INDEX IF NOT EXISTS idx_leads_chat_chat_id ON public.leads_chat_anonimos(chat_id);

-- =====================================================
-- 🔒 ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE public.leads_chat_anonimos ENABLE ROW LEVEL SECURITY;

-- Política: Administradores pueden ver todo
CREATE POLICY "leads_admin_all" ON public.leads_chat_anonimos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE perfiles.id = auth.uid() 
      AND perfiles.rol IN ('administrador', 'admin')
    )
  );

-- Política: Usuarios pueden ver solo sus propios leads convertidos
CREATE POLICY "leads_user_own" ON public.leads_chat_anonimos
  FOR SELECT USING (
    usuario_id = auth.uid() AND convertido_a_usuario = true
  );

-- Política: Permitir inserción de nuevos leads (para el sistema)
CREATE POLICY "leads_insert_system" ON public.leads_chat_anonimos
  FOR INSERT WITH CHECK (true);

-- Política: Permitir actualización para conversión a usuario
CREATE POLICY "leads_update_conversion" ON public.leads_chat_anonimos
  FOR UPDATE USING (
    convertido_a_usuario = false OR 
    usuario_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE perfiles.id = auth.uid() 
      AND perfiles.rol IN ('administrador', 'admin')
    )
  );

-- =====================================================
-- ⚡ FUNCIÓN Y TRIGGER PARA UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_leads_chat_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_leads_chat_anonimos_updated_at
  BEFORE UPDATE ON public.leads_chat_anonimos
  FOR EACH ROW
  EXECUTE FUNCTION public.update_leads_chat_updated_at();

-- =====================================================
-- 📝 COMENTARIOS DE DOCUMENTACIÓN
-- =====================================================

COMMENT ON TABLE public.leads_chat_anonimos IS '💬 Almacena información de usuarios anónimos que usan el chat en vivo';
COMMENT ON COLUMN public.leads_chat_anonimos.chat_id IS 'ID único del chat generado basado en email y fecha';
COMMENT ON COLUMN public.leads_chat_anonimos.tipo_consulta IS 'Tipo de consulta: general, ventas, soporte, tecnico, pagos, cursos';
COMMENT ON COLUMN public.leads_chat_anonimos.convertido_a_usuario IS 'Indica si el lead se registró como usuario en la plataforma';
COMMENT ON COLUMN public.leads_chat_anonimos.usuario_id IS 'ID del usuario en perfiles si se convirtió (FK a perfiles.id)';
COMMENT ON COLUMN public.leads_chat_anonimos.primer_mensaje IS 'Primer mensaje enviado por el usuario anónimo'; 