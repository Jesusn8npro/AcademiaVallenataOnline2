import React, { useState } from 'react'
import './ComentariosLeccion.css'

interface ComentariosLeccionProps {
    leccionId: string
    usuarioActual?: any
    tipo?: 'leccion' | 'clase'
}

const ComentariosLeccion: React.FC<ComentariosLeccionProps> = ({
    leccionId,
    usuarioActual = null,
    tipo = 'clase'
}) => {
    const [comentarios, setComentarios] = useState<any[]>([])
    const [nuevoComentario, setNuevoComentario] = useState('')
    const [cargando, setCargando] = useState(false)

    async function enviarComentario() {
        if (!nuevoComentario.trim() || !usuarioActual) return

        setCargando(true)
        // TODO: Integrar con Supabase
        // const { data, error } = await supabase.from('comentarios').insert({ ... })

        // Simulación temporal
        setTimeout(() => {
            const comentarioNuevo = {
                id: Date.now(),
                texto: nuevoComentario,
                usuario: usuarioActual.nombre || 'Usuario',
                fecha: new Date().toISOString(),
                leccion_id: leccionId
            }
            setComentarios([comentarioNuevo, ...comentarios])
            setNuevoComentario('')
            setCargando(false)
        }, 500)
    }

    return (
        <div className="comentarios-leccion">
            <div className="encabezado-comentarios">
                <h3>Comentarios</h3>
                <span className="contador-comentarios">{comentarios.length} comentarios</span>
            </div>

            {/* Formulario para nuevo comentario */}
            {usuarioActual ? (
                <div className="formulario-comentario">
                    <textarea
                        className="input-comentario"
                        placeholder="Escribe tu comentario..."
                        value={nuevoComentario}
                        onChange={(e) => setNuevoComentario(e.target.value)}
                        rows={3}
                    />
                    <button
                        className="btn-enviar-comentario"
                        onClick={enviarComentario}
                        disabled={cargando || !nuevoComentario.trim()}
                        type="button"
                    >
                        {cargando ? 'Enviando...' : 'Enviar comentario'}
                    </button>
                </div>
            ) : (
                <div className="mensaje-login">
                    <p>Inicia sesión para dejar un comentario</p>
                </div>
            )}

            {/* Lista de comentarios */}
            <div className="lista-comentarios">
                {comentarios.length > 0 ? (
                    comentarios.map((comentario) => (
                        <div key={comentario.id} className="comentario-item">
                            <div className="comentario-header">
                                <span className="comentario-usuario">{comentario.usuario}</span>
                                <span className="comentario-fecha">
                                    {new Date(comentario.fecha).toLocaleDateString('es-ES', {
                                        day: 'numeric',
                                        month: 'short',
                                        year: 'numeric'
                                    })}
                                </span>
                            </div>
                            <p className="comentario-texto">{comentario.texto}</p>
                        </div>
                    ))
                ) : (
                    <div className="sin-comentarios">
                        <p>Aún no hay comentarios. ¡Sé el primero en comentar!</p>
                    </div>
                )}
            </div>
        </div>
    )
}

export default ComentariosLeccion
