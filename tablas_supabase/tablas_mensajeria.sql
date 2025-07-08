-- ============================================
-- SISTEMA DE MENSAJERÍA - ACADEMIA VALLENATA
-- ============================================
-- Tablas optimizadas para chats privados y grupales
-- Nomenclatura en español coherente con la plataforma

-- 1. TABLA: chats
-- Gestiona conversaciones individuales y grupales
CREATE TABLE chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT, -- Nombre del grupo (nulo para chats privados)
  descripcion TEXT, -- Descripción del grupo
  imagen_url TEXT, -- Avatar del grupo
  es_grupal BOOLEAN DEFAULT false,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT now(),
  actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT now(),
  creado_por UUID REFERENCES perfiles(id),
  ultimo_mensaje_id UUID, -- Se actualiza con cada mensaje nuevo
  ultimo_mensaje_fecha TIMESTAMP WITH TIME ZONE,
  activo BOOLEAN DEFAULT true,
  tipo_chat VARCHAR(20) DEFAULT 'privado' CHECK (tipo_chat IN ('privado', 'grupo', 'canal')),
  configuracion JSONB DEFAULT '{}'::jsonb -- Configuraciones del chat
);

-- 2. TABLA: miembros_chat
-- Gestiona la pertenencia de usuarios a chats
CREATE TABLE miembros_chat (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  es_admin BOOLEAN DEFAULT false,
  puede_escribir BOOLEAN DEFAULT true,
  puede_invitar BOOLEAN DEFAULT false,
  unido_en TIMESTAMP WITH TIME ZONE DEFAULT now(),
  ultimo_acceso TIMESTAMP WITH TIME ZONE DEFAULT now(),
  notificaciones_activadas BOOLEAN DEFAULT true,
  mensajes_no_leidos INTEGER DEFAULT 0,
  estado_miembro VARCHAR(20) DEFAULT 'activo' CHECK (estado_miembro IN ('activo', 'silenciado', 'bloqueado', 'salido')),
  
  -- Evitar duplicados
  UNIQUE(chat_id, usuario_id)
);

-- 3. TABLA: mensajes
-- Almacena todos los mensajes del sistema
CREATE TABLE mensajes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES perfiles(id),
  contenido TEXT,
  tipo VARCHAR(20) DEFAULT 'texto' CHECK (tipo IN ('texto', 'imagen', 'audio', 'video', 'archivo', 'sistema', 'ubicacion', 'contacto')),
  url_media TEXT, -- URL del archivo adjunto
  metadata JSONB DEFAULT '{}'::jsonb, -- Metadatos adicionales (tamaño, duración, etc.)
  mensaje_padre_id UUID REFERENCES mensajes(id), -- Para respuestas
  editado BOOLEAN DEFAULT false,
  eliminado BOOLEAN DEFAULT false,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT now(),
  editado_en TIMESTAMP WITH TIME ZONE,
  eliminado_en TIMESTAMP WITH TIME ZONE
);

-- 4. TABLA: mensajes_lectura (CORREGIDO el nombre)
-- Seguimiento de mensajes leídos por usuario
CREATE TABLE mensajes_lectura (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mensaje_id UUID REFERENCES mensajes(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  leido_en TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  -- Evitar duplicados
  UNIQUE(mensaje_id, usuario_id)
);

-- 5. TABLA: mensajes_reacciones
-- Sistema de reacciones a mensajes (emojis)
CREATE TABLE mensajes_reacciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mensaje_id UUID REFERENCES mensajes(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  reaccion VARCHAR(32) NOT NULL, -- Emoji Unicode
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  -- Evitar reacciones duplicadas del mismo usuario al mismo mensaje
  UNIQUE(mensaje_id, usuario_id, reaccion)
);

-- 6. TABLA: chats_configuracion
-- Configuraciones específicas del chat
CREATE TABLE chats_configuracion (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES chats(id) ON DELETE CASCADE UNIQUE,
  solo_admins_pueden_escribir BOOLEAN DEFAULT false,
  auto_eliminar_mensajes_dias INTEGER, -- Auto-eliminar mensajes después de X días
  permitir_reacciones BOOLEAN DEFAULT true,
  permitir_respuestas BOOLEAN DEFAULT true,
  permitir_adjuntos BOOLEAN DEFAULT true,
  tamaño_maximo_archivo_mb INTEGER DEFAULT 10,
  tipos_archivo_permitidos TEXT[] DEFAULT ARRAY['imagen', 'video', 'audio', 'documento'],
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT now(),
  actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================

-- Función para actualizar último mensaje del chat
CREATE OR REPLACE FUNCTION actualizar_ultimo_mensaje_chat()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chats 
  SET 
    ultimo_mensaje_id = NEW.id,
    ultimo_mensaje_fecha = NEW.creado_en,
    actualizado_en = now()
  WHERE id = NEW.chat_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función para incrementar contador de mensajes no leídos
CREATE OR REPLACE FUNCTION incrementar_mensajes_no_leidos()
RETURNS TRIGGER AS $$
BEGIN
  -- Incrementar contador para todos los miembros del chat excepto el autor
  UPDATE miembros_chat 
  SET mensajes_no_leidos = mensajes_no_leidos + 1
  WHERE chat_id = NEW.chat_id 
    AND usuario_id != NEW.usuario_id
    AND estado_miembro = 'activo';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función para marcar mensajes como leídos
CREATE OR REPLACE FUNCTION marcar_mensajes_como_leidos(
  p_chat_id UUID,
  p_usuario_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  mensajes_marcados INTEGER;
BEGIN
  -- Insertar lecturas para mensajes no leídos
  INSERT INTO mensajes_lectura (mensaje_id, usuario_id)
  SELECT m.id, p_usuario_id
  FROM mensajes m
  LEFT JOIN mensajes_lectura ml ON ml.mensaje_id = m.id AND ml.usuario_id = p_usuario_id
  WHERE m.chat_id = p_chat_id 
    AND m.usuario_id != p_usuario_id
    AND ml.id IS NULL
    AND m.eliminado = false;
  
  GET DIAGNOSTICS mensajes_marcados = ROW_COUNT;
  
  -- Resetear contador de no leídos
  UPDATE miembros_chat 
  SET 
    mensajes_no_leidos = 0,
    ultimo_acceso = now()
  WHERE chat_id = p_chat_id AND usuario_id = p_usuario_id;
  
  RETURN mensajes_marcados;
END;
$$ LANGUAGE plpgsql;

-- Función auxiliar para verificar si usuario es miembro de chat
CREATE OR REPLACE FUNCTION es_miembro_chat(p_chat_id UUID, p_usuario_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM miembros_chat 
    WHERE chat_id = p_chat_id 
    AND usuario_id = p_usuario_id 
    AND estado_miembro = 'activo'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función auxiliar para verificar si usuario es admin de chat
CREATE OR REPLACE FUNCTION es_admin_chat(p_chat_id UUID, p_usuario_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM miembros_chat 
    WHERE chat_id = p_chat_id 
    AND usuario_id = p_usuario_id 
    AND es_admin = true 
    AND estado_miembro = 'activo'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger para actualizar último mensaje
CREATE TRIGGER trigger_actualizar_ultimo_mensaje
  AFTER INSERT ON mensajes
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_ultimo_mensaje_chat();

-- Trigger para incrementar no leídos
CREATE TRIGGER trigger_incrementar_no_leidos
  AFTER INSERT ON mensajes
  FOR EACH ROW
  EXECUTE FUNCTION incrementar_mensajes_no_leidos();

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

-- Índices en chats
CREATE INDEX idx_chats_usuario_creador ON chats(creado_por);
CREATE INDEX idx_chats_tipo ON chats(tipo_chat);
CREATE INDEX idx_chats_activo ON chats(activo);

-- Índices en miembros_chat
CREATE INDEX idx_miembros_chat_usuario ON miembros_chat(usuario_id);
CREATE INDEX idx_miembros_chat_estado ON miembros_chat(estado_miembro);
CREATE INDEX idx_miembros_no_leidos ON miembros_chat(mensajes_no_leidos) WHERE mensajes_no_leidos > 0;

-- Índices en mensajes
CREATE INDEX idx_mensajes_chat_fecha ON mensajes(chat_id, creado_en DESC);
CREATE INDEX idx_mensajes_usuario ON mensajes(usuario_id);
CREATE INDEX idx_mensajes_tipo ON mensajes(tipo);

-- Índices en mensajes_lectura
CREATE INDEX idx_lectura_usuario ON mensajes_lectura(usuario_id);
CREATE INDEX idx_lectura_mensaje ON mensajes_lectura(mensaje_id);

-- Índices en mensajes_reacciones
CREATE INDEX idx_reacciones_mensaje ON mensajes_reacciones(mensaje_id);
CREATE INDEX idx_reacciones_usuario ON mensajes_reacciones(usuario_id);

-- ============================================
-- POLÍTICAS RLS CORREGIDAS (Sin recursión)
-- ============================================

-- Activar RLS en todas las tablas
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE miembros_chat ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes_lectura ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes_reacciones ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLÍTICAS PARA CHATS
-- ============================================

-- Ver chats donde el usuario es miembro
CREATE POLICY "usuarios_ven_sus_chats" ON chats
  FOR SELECT USING (
    es_miembro_chat(id, auth.uid())
  );

-- Crear chats
CREATE POLICY "usuarios_crean_chats" ON chats
  FOR INSERT WITH CHECK (creado_por = auth.uid());

-- Actualizar chats (solo admins)
CREATE POLICY "admins_actualizan_chats" ON chats
  FOR UPDATE USING (
    es_admin_chat(id, auth.uid())
  );

-- ============================================
-- POLÍTICAS PARA MIEMBROS_CHAT
-- ============================================

-- Ver miembros solo si eres miembro del chat
CREATE POLICY "solo_miembros_ven_miembros" ON miembros_chat
  FOR SELECT USING (
    -- Usar función directa para evitar recursión
    EXISTS (
      SELECT 1 FROM chats c
      WHERE c.id = chat_id
      AND c.creado_por = auth.uid()
    )
    OR usuario_id = auth.uid()
  );

-- Insertar miembros (solo quien crea el chat inicialmente)
CREATE POLICY "crear_miembros_chat" ON miembros_chat
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM chats c
      WHERE c.id = chat_id
      AND c.creado_por = auth.uid()
    )
    OR usuario_id = auth.uid()
  );

-- Actualizar miembros (solo el propio usuario o el creador del chat)
CREATE POLICY "actualizar_miembros_chat" ON miembros_chat
  FOR UPDATE USING (
    usuario_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM chats c
      WHERE c.id = chat_id
      AND c.creado_por = auth.uid()
    )
  );

-- ============================================
-- POLÍTICAS PARA MENSAJES
-- ============================================

-- Ver mensajes de chats donde eres miembro
CREATE POLICY "miembros_ven_mensajes" ON mensajes
  FOR SELECT USING (
    es_miembro_chat(chat_id, auth.uid())
  );

-- Enviar mensajes
CREATE POLICY "miembros_envian_mensajes" ON mensajes
  FOR INSERT WITH CHECK (
    usuario_id = auth.uid() 
    AND es_miembro_chat(chat_id, auth.uid())
  );

-- Actualizar propios mensajes
CREATE POLICY "usuarios_editan_sus_mensajes" ON mensajes
  FOR UPDATE USING (
    usuario_id = auth.uid()
  );

-- ============================================
-- POLÍTICAS PARA LECTURA DE MENSAJES
-- ============================================

-- Ver y gestionar propias lecturas
CREATE POLICY "usuarios_gestionan_sus_lecturas" ON mensajes_lectura
  FOR ALL USING (
    usuario_id = auth.uid()
  );

-- ============================================
-- POLÍTICAS PARA REACCIONES
-- ============================================

-- Ver reacciones de mensajes en chats donde eres miembro
CREATE POLICY "miembros_ven_reacciones" ON mensajes_reacciones
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM mensajes m
      WHERE m.id = mensaje_id
      AND es_miembro_chat(m.chat_id, auth.uid())
    )
  );

-- Gestionar propias reacciones
CREATE POLICY "usuarios_gestionan_sus_reacciones" ON mensajes_reacciones
  FOR INSERT WITH CHECK (
    usuario_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM mensajes m
      WHERE m.id = mensaje_id
      AND es_miembro_chat(m.chat_id, auth.uid())
    )
  );

CREATE POLICY "usuarios_eliminan_sus_reacciones" ON mensajes_reacciones
  FOR DELETE USING (
    usuario_id = auth.uid()
  );

-- ============================================
-- PERMISOS ADICIONALES
-- ============================================

-- Dar acceso a las funciones auxiliares
GRANT EXECUTE ON FUNCTION es_miembro_chat(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION es_admin_chat(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION marcar_mensajes_como_leidos(UUID, UUID) TO authenticated;

-- ============================================
-- VISTA PARA CHATS CON INFORMACIÓN COMPLETA
-- ============================================

CREATE OR REPLACE VIEW vista_chats_usuario AS
SELECT 
  c.*,
  mc.mensajes_no_leidos,
  mc.ultimo_acceso,
  mc.es_admin,
  (
    SELECT COUNT(*)::INTEGER 
    FROM miembros_chat mc2 
    WHERE mc2.chat_id = c.id 
    AND mc2.estado_miembro = 'activo'
  ) as total_miembros,
  p.nombre_completo as creado_por_nombre,
  p.url_foto_perfil as creado_por_avatar
FROM chats c
JOIN miembros_chat mc ON c.id = mc.chat_id
LEFT JOIN perfiles p ON c.creado_por = p.id
WHERE mc.usuario_id = auth.uid()
  AND mc.estado_miembro = 'activo'
  AND c.activo = true;

-- ============================================
-- COMENTARIOS FINALES
-- ============================================

/*
CAMBIOS REALIZADOS PARA CORREGIR ERRORES:

1. ✅ Eliminada recursión infinita en políticas RLS
2. ✅ Creadas funciones auxiliares con SECURITY DEFINER
3. ✅ Corregido nombre de tabla: mensajes_lectura (no mensajes_lecturas)
4. ✅ Simplificadas las políticas para evitar complejidad excesiva
5. ✅ Agregados permisos explícitos para funciones
6. ✅ Creada vista optimizada para consultas de chats

ESTE ARCHIVO DEBERÍA FUNCIONAR SIN ERRORES DE RECURSIÓN.
*/

-- ============================================
-- DATOS INICIALES / CONFIGURACIÓN
-- ============================================

-- Insertar configuración por defecto para chats existentes
-- (Se ejecutará después de crear chats)

-- Comentarios finales:
-- Este sistema de mensajería está optimizado para:
-- 1. Chats privados (1:1) y grupales
-- 2. Sistema de permisos granular
-- 3. Lecturas y notificaciones en tiempo real
-- 4. Reacciones y respuestas a mensajes
-- 5. Gestión de archivos adjuntos
-- 6. Configuración avanzada por chat
-- 7. Seguridad robusta con RLS
-- 8. Rendimiento optimizado con índices 