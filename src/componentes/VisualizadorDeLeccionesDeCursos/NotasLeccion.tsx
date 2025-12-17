import React, { useState, useEffect } from 'react'
import './NotasLeccion.css'

interface NotasLeccionProps {
    leccionId: string
    usuarioActual?: any
    tipo?: 'leccion' | 'clase'
}

const NotasLeccion: React.FC<NotasLeccionProps> = ({
    leccionId,
    usuarioActual = null,
    tipo = 'clase'
}) => {
    const [nota, setNota] = useState('')
    const [guardando, setGuardando] = useState(false)
    const [ultimoGuardado, setUltimoGuardado] = useState<Date | null>(null)

    // Cargar nota existente
    useEffect(() => {
        if (!usuarioActual || !leccionId) return

        // TODO: Cargar nota desde Supabase
        // const { data } = await supabase.from('notas').select('*').eq('leccion_id', leccionId).eq('usuario_id', usuarioActual.id).single()

        // Simulación temporal - cargar desde localStorage
        const notaGuardada = localStorage.getItem(`nota-${leccionId}`)
        if (notaGuardada) {
            setNota(notaGuardada)
        }
    }, [leccionId, usuarioActual])

    async function guardarNota() {
        if (!usuarioActual) return

        setGuardando(true)

        // TODO: Guardar en Supabase
        // const { error } = await supabase.from('notas').upsert({ ... })

        // Simulación temporal - guardar en localStorage
        localStorage.setItem(`nota-${leccionId}`, nota)

        setTimeout(() => {
            setGuardando(false)
            setUltimoGuardado(new Date())
        }, 500)
    }

    return (
        <div className="notas-leccion">
            <div className="encabezado-notas">
                <h3>Mis Notas</h3>
                {ultimoGuardado && (
                    <span className="ultimo-guardado">
                        Guardado {ultimoGuardado.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })}
                    </span>
                )}
            </div>

            {usuarioActual ? (
                <>
                    <textarea
                        className="editor-notas"
                        placeholder="Escribe tus notas aquí... Puedes anotar ideas, conceptos importantes, o cualquier cosa que quieras recordar de esta lección."
                        value={nota}
                        onChange={(e) => setNota(e.target.value)}
                        rows={12}
                    />
                    <div className="acciones-notas">
                        <button
                            className="btn-guardar-nota"
                            onClick={guardarNota}
                            disabled={guardando}
                            type="button"
                        >
                            {guardando ? 'Guardando...' : 'Guardar nota'}
                        </button>
                        <span className="info-autoguardado">
                            💡 Tus notas son privadas y solo tú puedes verlas
                        </span>
                    </div>
                </>
            ) : (
                <div className="mensaje-login-notas">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                        <polyline points="14 2 14 8 20 8" />
                        <line x1="16" y1="13" x2="8" y2="13" />
                        <line x1="16" y1="17" x2="8" y2="17" />
                        <polyline points="10 9 9 9 8 9" />
                    </svg>
                    <p>Inicia sesión para tomar notas personales de esta lección</p>
                </div>
            )}
        </div>
    )
}

export default NotasLeccion
