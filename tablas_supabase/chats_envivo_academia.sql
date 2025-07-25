-- =====================================================
-- 💬 ACADEMIA VALLENATA ONLINE - HISTORIAL CHATS
-- =====================================================
-- Tabla para almacenar historial completo de conversaciones
-- Integrada con sistema de leads y usuarios registrados
-- =====================================================

CREATE TABLE IF NOT EXISTS public.chats_envivo_academia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id VARCHAR(100) NOT NULL,
  
  -- Identificación del usuario
  usuario_id UUID REFERENCES public.perfiles(id) ON DELETE SET NULL,
  lead_id UUID REFERENCES public.leads_chat_anonimos(id) ON DELETE SET NULL,
  es_usuario_registrado BOOLEAN DEFAULT false,
  
  -- Contenido del mensaje
  mensaje TEXT NOT NULL,
  tipo_mensaje VARCHAR(50) DEFAULT 'usuario',
  
  -- Metadatos básicos
  ruta_actual VARCHAR(255),
  respuesta_asistente TEXT,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices básicos
CREATE INDEX IF NOT EXISTS idx_chats_chat_id ON public.chats_envivo_academia(chat_id);
CREATE INDEX IF NOT EXISTS idx_chats_fecha ON public.chats_envivo_academia(created_at);

-- RLS
ALTER TABLE public.chats_envivo_academia ENABLE ROW LEVEL SECURITY;

-- Política para admins
CREATE POLICY "chats_admin_all" ON public.chats_envivo_academia
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.perfiles 
      WHERE perfiles.id = auth.uid() 
      AND perfiles.rol IN ('administrador', 'admin')
    )
  );

-- Política para insertar (sistema)
CREATE POLICY "chats_insert_system" ON public.chats_envivo_academia
  FOR INSERT WITH CHECK (true);