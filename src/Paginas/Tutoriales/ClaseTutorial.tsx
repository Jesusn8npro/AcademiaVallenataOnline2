import React, { useEffect, useMemo, useState } from 'react'
import { useParams } from 'react-router-dom'
import { supabase } from '../../servicios/supabaseCliente'
import { generarSlug } from '../../utilidades/slug'
import ReproductorLecciones from '../../componentes/VisualizadorDeLeccionesDeCursos/ReproductorLecciones'
import EncabezadoLeccion from '../../componentes/VisualizadorDeLeccionesDeCursos/EncabezadoLeccion'
import BarraLateralCurso from '../../componentes/VisualizadorDeLeccionesDeCursos/BarraLateralCurso'
import PestañasLeccion from '../../componentes/VisualizadorDeLeccionesDeCursos/PestañasLeccion'
import SkeletonClase from '../../componentes/Skeletons/SkeletonClase'
import './contenido-tutorial.css'

export default function ClaseTutorial() {
  const { slug = '', claseSlug = '' } = useParams()
  const [tutorial, setTutorial] = useState<any>(null)
  const [clases, setClases] = useState<any[]>([])
  const [clase, setClase] = useState<any>(null)
  const [completada, setCompletada] = useState(false)
  const [cargandoCompletar, setCargandoCompletar] = useState(false)
  const [errorCompletar, setErrorCompletar] = useState('')
  const [cargando, setCargando] = useState(true)
  const [error, setError] = useState<string | null>(null)
  // En desktop (>= 1024px) mostrar sidebar por defecto, en móvil/tablet ocultar
  const [mostrarSidebar, setMostrarSidebar] = useState(() => {
    if (typeof window !== 'undefined') {
      return window.innerWidth >= 1024
    }
    return true
  })
  const [estadisticasProgreso, setEstadisticasProgreso] = useState({ completadas: 0, total: 0, porcentaje: 0 })

  useEffect(() => {
    document.body.classList.add('tutorial-pantalla-completa')
    return () => { document.body.classList.remove('tutorial-pantalla-completa') }
  }, [])

  useEffect(() => {
    if (mostrarSidebar) {
      document.body.classList.add('sidebar-visible-tutorial')
    } else {
      document.body.classList.remove('sidebar-visible-tutorial')
    }
  }, [mostrarSidebar])

  useEffect(() => { cargar() }, [slug, claseSlug])

  async function cargar() {
    if (!slug || !claseSlug) return
    setCargando(true); setError(null)
    try {
      const { data: tuts, error: errT } = await supabase.from('tutoriales').select('*')
      if (errT) { setError(errT.message); return }
      let tut = (tuts || []).find((t: any) => generarSlug(t.titulo) === slug) || (tuts || []).find((t: any) => t.slug === slug)
      if (!tut) { setError('Tutorial no encontrado'); return }
      setTutorial(tut)
      const { data: partes, error: errP } = await supabase.from('partes_tutorial').select('id, titulo, slug, video_url, orden, descripcion').eq('tutorial_id', tut.id).order('orden', { ascending: true })
      if (errP) { setError(errP.message); return }
      const lista = partes || []
      setClases(lista)
      const actual = lista.find((p: any) => (p.slug || generarSlug(p.titulo)) === claseSlug) || lista[0]
      setClase(actual)
      const { data: { user } } = await supabase.auth.getUser()
      if (user && actual) {
        const { data: prog } = await supabase.from('progreso_tutorial').select('completado').eq('usuario_id', user.id).eq('tutorial_id', tut.id).eq('parte_tutorial_id', actual.id).single()
        setCompletada(!!prog?.completado)
      }
      // Progreso general del tutorial
      const { data: { user: userForStats } } = await supabase.auth.getUser()
      const total = lista.length
      if (userForStats && total > 0) {
        const { data: progAll } = await supabase
          .from('progreso_tutorial')
          .select('parte_tutorial_id, completado')
          .eq('usuario_id', userForStats.id)
          .eq('tutorial_id', tut.id)
        const completadas = (progAll || []).filter((p: any) => p.completado).length
        const porcentaje = total ? Math.round((completadas / total) * 100) : 0
        setEstadisticasProgreso({ completadas, total, porcentaje })
      } else {
        setEstadisticasProgreso({ completadas: 0, total, porcentaje: 0 })
      }
    } catch (e: any) { setError(e?.message || 'Error cargando clase') } finally { setCargando(false) }
  }

  const indice = useMemo(() => clases.findIndex((p: any) => p.id === clase?.id), [clases, clase])
  const claseAnterior = indice > 0 ? clases[indice - 1] : null
  const claseSiguiente = indice >= 0 && indice < clases.length - 1 ? clases[indice + 1] : null

  async function marcarComoCompletada() {
    setCargandoCompletar(true); setErrorCompletar('')
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user || !tutorial || !clase) return
      const { error: err } = await supabase.from('progreso_tutorial').upsert({ usuario_id: user.id, tutorial_id: tutorial.id, parte_tutorial_id: clase.id, completado: true }, { onConflict: 'usuario_id,tutorial_id,parte_tutorial_id' })
      if (err) { setErrorCompletar(err.message) } else { setCompletada(true) }
    } finally { setCargandoCompletar(false) }
  }

  if (cargando) return <SkeletonClase />
  if (error || !tutorial || !clase) return (<div className="estado-error"><div className="error-icono">⚠</div><h2>¡Oops! Algo salió mal</h2><p>{error || 'No se encontró contenido'}</p><div className="botones-error"><a href={`/tutoriales/${slug}/contenido`} className="boton-volver">Volver</a></div></div>)

  return (
    <div className="contenido-detalle-tutorial">
      <EncabezadoLeccion
        cursoTitulo={tutorial.titulo}
        leccionTitulo={clase.titulo}
        cursoId={tutorial.id}
        leccionId={clase.id}
        tipo="clase"
        mostrarSidebar={mostrarSidebar}
        onToggleSidebar={() => setMostrarSidebar((v) => !v)}
        curso={{ ...tutorial, clases_tutorial: clases }}
        moduloActivo={''}
        progreso={{}}
        estadisticasProgreso={estadisticasProgreso}
        usuarioActual={null}
        leccionAnterior={claseAnterior}
        leccionSiguiente={claseSiguiente}
      />
      <div className="contenedor-clase">
        <div className="area-video">
          <ReproductorLecciones
            leccionAnterior={claseAnterior}
            leccionSiguiente={claseSiguiente}
            videoUrl={clase.video_url || ''}
            thumbnailUrl={''}
            titulo={clase.titulo}
            tipo="clase"
            completada={completada}
            cargandoCompletar={cargandoCompletar}
            marcarComoCompletada={marcarComoCompletada}
            errorCompletar={errorCompletar}
            autoplay={false}
          />
          <div className="tutorial-scroll-container">
            <PestañasLeccion
              cursoId={tutorial.id}
              leccionId={clase.id}
              tipo="clase"
              curso={{ ...tutorial, clases_tutorial: clases }}
              clases={clases}
              progreso={{}}
              mostrarSidebar={mostrarSidebar}
              usuarioActual={null}
            />
          </div>
        </div>
        <div className={`leccion-sidebar ${mostrarSidebar ? 'visible' : ''}`}>
          <BarraLateralCurso
            curso={{ ...tutorial, clases_tutorial: clases }}
            moduloActivo={''}
            leccionActiva={clase?.id}
            progreso={{}}
            tipo="tutorial"
            mostrarSidebar={mostrarSidebar}
            onCerrarSidebar={() => setMostrarSidebar(false)}
          />
        </div>
      </div>
    </div>
  )
}
