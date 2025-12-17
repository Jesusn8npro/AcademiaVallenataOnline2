import React, { useState, useEffect } from 'react'
import { usePerfilStore } from '../../stores/perfilStore'
import { eventosService, type EventoCompleto } from '../../servicios/eventosService'
import './MisEventos.css'

export default function MisEventos() {
    const { perfil } = usePerfilStore()
    const [eventos, setEventos] = useState<EventoCompleto[]>([])
    const [cargando, setCargando] = useState(true)
    const [error, setError] = useState('')
    const [filtroActivo, setFiltroActivo] = useState('todos')
    const [busqueda, setBusqueda] = useState('')

    const filtros = [
        { valor: 'todos', etiqueta: 'Todos', icono: '📅' },
        { valor: 'proximos', etiqueta: 'Próximos', icono: '🔮' },
        { valor: 'pasados', etiqueta: 'Finalizados', icono: '✅' }
    ]

    useEffect(() => {
        cargarEventos()
    }, [perfil])

    async function cargarEventos() {
        if (!perfil?.id) return
        try {
            setCargando(true)
            setError('')
            const resultado = await eventosService.obtenerEventosUsuario(perfil.id)
            setEventos(resultado || [])
        } catch (err) {
            console.error('Error cargando eventos:', err)
            setError('Error al cargar los eventos. Intenta de nuevo.')
            setEventos([])
        } finally {
            setCargando(false)
        }
    }

    function filtrarEventos(todosEventos: EventoCompleto[], filtro: string, termino: string) {
        let resultado = [...todosEventos]
        const ahora = new Date()

        if (filtro === 'proximos') {
            resultado = resultado.filter(e => new Date(e.fecha_inicio) > ahora)
        } else if (filtro === 'pasados') {
            resultado = resultado.filter(e => new Date(e.fecha_inicio) <= ahora)
        }

        if (termino.trim()) {
            const buscar = termino.toLowerCase()
            resultado = resultado.filter(e =>
                e.titulo.toLowerCase().includes(buscar) ||
                (e.descripcion && e.descripcion.toLowerCase().includes(buscar)) ||
                (e.categoria && e.categoria.toLowerCase().includes(buscar))
            )
        }

        return resultado
    }

    const eventosFiltrados = filtrarEventos(eventos, filtroActivo, busqueda)

    function formatearFecha(fecha: string): string {
        return new Date(fecha).toLocaleDateString('es-CO', {
            weekday: 'short',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        })
    }

    function formatearPrecio(precio: number, moneda: string = 'COP'): string {
        if (precio === 0) return 'Gratis'
        return new Intl.NumberFormat('es-CO', {
            style: 'currency',
            currency: moneda
        }).format(precio)
    }

    function obtenerEstadoEvento(fecha: string, estado: string = 'activo') {
        const ahora = new Date()
        const fechaEvento = new Date(fecha)

        if (estado === 'cancelado') return { texto: 'Cancelado', clase: 'estado-cancelado' }
        if (fechaEvento < ahora) return { texto: 'Finalizado', clase: 'estado-finalizado' }
        if (fechaEvento > ahora) return { texto: 'Próximo', clase: 'estado-proximo' }
        return { texto: 'En vivo', clase: 'estado-envivo' }
    }

    return (
        <div className="contenido-mis-eventos">
            <div className="encabezado">
                <div className="titulo-seccion">
                    <h1>📅 Mis Eventos</h1>
                    <p>Administra tus eventos inscritos</p>
                </div>
            </div>

            <div className="barra-herramientas">
                <div className="filtros">
                    {filtros.map(filtro => (
                        <button
                            key={filtro.valor}
                            className={`btn-filtro ${filtroActivo === filtro.valor ? 'activo' : ''}`}
                            onClick={() => setFiltroActivo(filtro.valor)}
                        >
                            <span className="icono">{filtro.icono}</span>
                            <span className="texto">{filtro.etiqueta}</span>
                        </button>
                    ))}
                </div>

                <div className="busqueda">
                    <div className="input-busqueda">
                        <svg className="icono-busqueda" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <circle cx="11" cy="11" r="8" />
                            <path d="m21 21-4.35-4.35" />
                        </svg>
                        <input
                            type="text"
                            placeholder="Buscar eventos..."
                            value={busqueda}
                            onChange={(e) => setBusqueda(e.target.value)}
                            className="campo-busqueda"
                        />
                    </div>
                </div>
            </div>

            <div className="contenido-principal">
                {cargando ? (
                    <div className="estado-carga">
                        <div className="spinner"></div>
                        <p>Cargando tus eventos...</p>
                    </div>
                ) : error ? (
                    <div className="estado-error">
                        <div className="icono-error">⚠️</div>
                        <h3>Error al cargar eventos</h3>
                        <p>{error}</p>
                        <button className="btn-reintentar" onClick={cargarEventos}>
                            🔄 Intentar de nuevo
                        </button>
                    </div>
                ) : eventosFiltrados.length === 0 ? (
                    <div className="estado-vacio">
                        <div className="icono-vacio">🎭</div>
                        <h3>
                            {filtroActivo === 'todos' ? 'No tienes eventos inscritos' :
                                filtroActivo === 'proximos' ? 'No tienes eventos próximos' :
                                    'No tienes eventos finalizados'}
                        </h3>
                        <p>
                            {filtroActivo === 'todos' ? 'Explora nuestro catálogo y apúntate a eventos increíbles' :
                                filtroActivo === 'proximos' ? 'Los eventos que reserves aparecerán aquí' :
                                    'Aquí verás tu historial de eventos'}
                        </p>
                        <a href="/eventos" className="btn-explorar">
                            🌟 Explorar Eventos
                        </a>
                    </div>
                ) : (
                    <div className="lista-eventos">
                        {eventosFiltrados.map(evento => {
                            const estado = obtenerEstadoEvento(evento.fecha_inicio, evento.estado)
                            return (
                                <div key={evento.id} className="tarjeta-evento">
                                    <div className="imagen-evento">
                                        {evento.imagen_portada ? (
                                            <img src={evento.imagen_portada} alt={evento.titulo} />
                                        ) : (
                                            <div className="placeholder-imagen">🎭</div>
                                        )}
                                        <div className={`estado-badge ${estado.clase}`}>
                                            {estado.texto}
                                        </div>
                                    </div>

                                    <div className="info-evento">
                                        <div className="encabezado-evento">
                                            <h3 className="titulo-evento">{evento.titulo}</h3>
                                            <div className="precio-evento">
                                                {formatearPrecio(evento.precio, evento.moneda)}
                                            </div>
                                        </div>

                                        <div className="detalles-evento">
                                            <div className="fecha-hora">
                                                <svg className="icono" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                                                    <line x1="16" y1="2" x2="16" y2="6" />
                                                    <line x1="8" y1="2" x2="8" y2="6" />
                                                    <line x1="3" y1="10" x2="21" y2="10" />
                                                </svg>
                                                <span>{formatearFecha(evento.fecha_inicio)}</span>
                                            </div>

                                            {evento.modalidad && (
                                                <div className="modalidad">
                                                    <svg className="icono" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                                                        <circle cx="12" cy="10" r="3" />
                                                    </svg>
                                                    <span>{evento.modalidad}</span>
                                                </div>
                                            )}

                                            {evento.instructor_nombre && (
                                                <div className="instructor">
                                                    <svg className="icono" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                                                        <circle cx="12" cy="7" r="4" />
                                                    </svg>
                                                    <span>{evento.instructor_nombre}</span>
                                                </div>
                                            )}
                                        </div>

                                        {evento.descripcion_corta && (
                                            <p className="descripcion-evento">{evento.descripcion_corta}</p>
                                        )}

                                        <div className="acciones-evento">
                                            <a href={`/eventos/${evento.slug}`} className="btn-ver-evento">
                                                👁️ Ver Detalles
                                            </a>

                                            {estado.texto === 'En vivo' ? (
                                                <a href={`/eventos/${evento.slug}/sala`} className="btn-unirse">
                                                    🔴 Unirse Ahora
                                                </a>
                                            ) : estado.texto === 'Finalizado' && evento.enlace_grabacion ? (
                                                <a href={evento.enlace_grabacion} className="btn-ver-grabacion" target="_blank" rel="noreferrer">
                                                    📹 Ver Grabación
                                                </a>
                                            ) : null}
                                        </div>
                                    </div>
                                </div>
                            )
                        })}
                    </div>
                )}
            </div>
        </div>
    )
}
