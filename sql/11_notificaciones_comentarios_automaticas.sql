-- DESHABILITAR TODOS LOS TRIGGERS DE NOTIFICACIONES
DROP TRIGGER IF EXISTS trigger_notificar_comentarios_automatico ON comunidad_comentarios;
DROP TRIGGER IF EXISTS trigger_notificar_likes_automatico ON comunidad_comentarios_likes;
DROP TRIGGER IF EXISTS trigger_comentarios_notificacion ON comunidad_comentarios;
DROP TRIGGER IF EXISTS trigger_notificaciones_comentarios ON comunidad_comentarios;
DROP TRIGGER IF EXISTS trigger_like_delete ON comunidad_comentarios_likes;
DROP TRIGGER IF EXISTS trigger_like_insert ON comunidad_comentarios_likes;
DROP TRIGGER IF EXISTS trigger_nueva_publicacion ON comunidad_publicaciones;
DROP TRIGGER IF EXISTS trigger_notificar_comentario_corregido ON comunidad_comentarios;

-- VERIFICAR QUE NO HAY MÁS TRIGGERS
SELECT 
    event_object_table,
    trigger_name, 
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table IN ('comunidad_comentarios', 'comunidad_comentarios_likes', 'comunidad_publicaciones')
ORDER BY event_object_table;
