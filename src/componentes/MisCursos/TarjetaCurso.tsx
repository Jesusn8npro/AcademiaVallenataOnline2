import React, { useEffect, useState } from 'react'
import { supabase } from '../../servicios/supabaseCliente'
import { generarSlug } from '../../utilidades/slug'

export default function TarjetaCurso({ inscripcion }: { inscripcion: any }) {
  const esCurso = !!inscripcion.cursos
  const esTutorial = !!inscripcion.tutoriales
  const contenido = esCurso ? inscripcion.cursos : inscripcion.tutoriales
  const titulo = contenido?.titulo || 'Sin título'
  const imagen = contenido?.imagen_url || '/images/default-curso.jpg'
  const slug = contenido?.slug || generarSlug(titulo)
  const completado = !!inscripcion.completado
  const fechaInscripcion = inscripcion.fecha_inscripcion ? new Date(inscripcion.fecha_inscripcion).toLocaleDateString('es-ES') : ''
  const contenidoId = esCurso ? inscripcion.curso_id : inscripcion.tutorial_id
  const tipoContenido = esCurso ? 'Curso' : 'Tutorial'

  const [progreso, setProgreso] = useState({ porcentaje: 0, completadas: 0, total: 0 })
  const [cargandoProgreso, setCargandoProgreso] = useState(true)
  const textoBoton = progreso.completadas > 0 ? 'Continuar' : 'Empezar'

  async function cargarProgreso() {
    setCargandoProgreso(true)
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user || !contenidoId) { setCargandoProgreso(false); return }
      if (esCurso) {
        // 1. Obtener módulos
        const { data: modulos } = await supabase.from('modulos').select('id').eq('curso_id', contenidoId)

        if (modulos && modulos.length > 0) {
          const moduloIds = modulos.map((m: any) => m.id)

          // 2. Obtener lecciones de estos módulos
          const { data: lecciones } = await supabase
            .from('lecciones')
            .select('id')
            .in('modulo_id', moduloIds)

          const leccionIds = (lecciones || []).map((l: any) => l.id)

          if (leccionIds.length > 0) {
            const { data: prog } = await supabase.from('progreso_lecciones').select('leccion_id, estado').eq('usuario_id', user.id).in('leccion_id', leccionIds)
            const completadas = (prog || []).filter((p: any) => p.estado === 'completada').length
            const total = leccionIds.length
            const porcentaje = total ? Math.round((completadas / total) * 100) : 0
            setProgreso({ porcentaje, completadas, total })
          }
        }
      } else if (esTutorial) {
        const { data: partes } = await supabase.from('partes_tutorial').select('id').eq('tutorial_id', contenidoId)
        const { data: prog } = await supabase.from('progreso_tutorial').select('parte_tutorial_id, completado').eq('usuario_id', user.id).eq('tutorial_id', contenidoId)
        const completadas = (prog || []).filter((p: any) => p.completado).length
        const total = (partes || []).length
        const porcentaje = total ? Math.round((completadas / total) * 100) : 0
        setProgreso({ porcentaje, completadas, total })
      }
    } finally { setCargandoProgreso(false) }
  }

  useEffect(() => { cargarProgreso() }, [contenidoId])

  async function navegarAContenido() {
    if (esCurso) {
      // Para cursos, ir a la página de detalles del curso
      window.location.href = `/mis-cursos/${slug}`
      return
    }

    if (esTutorial) {
      // Para tutoriales, implementar navegación inteligente como en Svelte
      try {
        // 1. Obtener el usuario actual
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) {
          window.location.href = `/tutoriales/${slug}/contenido`
          return
        }

        // 2. Cargar todas las clases del tutorial
        const { data: todasLasClases, error: clasesError } = await supabase
          .from('partes_tutorial')
          .select('id, titulo, slug, orden')
          .eq('tutorial_id', contenido.id)
          .order('orden', { ascending: true })

        if (clasesError || !todasLasClases || todasLasClases.length === 0) {
          console.error('Error cargando clases del tutorial:', clasesError)
          window.location.href = `/tutoriales/${slug}/contenido`
          return
        }

        // 3. Si el usuario tiene progreso, buscar la siguiente clase incompleta
        if (progreso.completadas > 0) {
          const { data: progresoData, error: progresoError } = await supabase
            .from('progreso_tutorial')
            .select('parte_tutorial_id, completado')
            .eq('usuario_id', user.id)
            .eq('tutorial_id', contenido.id)

          if (!progresoError) {
            const clasesCompletadas = new Set(
              (progresoData || [])
                .filter((p: any) => p.completado)
                .map((p: any) => p.parte_tutorial_id)
            )

            const proximaClase = todasLasClases.find((clase: any) => !clasesCompletadas.has(clase.id))

            if (proximaClase) {
              const claseSlug = proximaClase.slug || generarSlug(proximaClase.titulo)
              const rutaDestino = `/tutoriales/${slug}/clase/${claseSlug}`
              console.log('[TarjetaCurso][TUTORIAL][CONTINUAR] Navegando a:', rutaDestino)
              window.location.href = rutaDestino
              return
            }
          }
        }

        // 4. FALLBACK: Si no hay progreso, o todo está completo, o hubo un error
        // Navegar a la primera clase
        const primeraClase = todasLasClases[0]
        const claseSlug = primeraClase.slug || generarSlug(primeraClase.titulo)
        const rutaDestino = `/tutoriales/${slug}/clase/${claseSlug}`
        console.log('[TarjetaCurso][TUTORIAL][EMPEZAR] Navegando a:', rutaDestino)
        window.location.href = rutaDestino

      } catch (error) {
        console.error('Error en navegación de tutorial:', error)
        window.location.href = `/tutoriales/${slug}/contenido`
      }
    }
  }

  return (
    <article className="tarjeta-curso" style={styles.card}>
      <div className="imagen-contenedor" style={styles.imgCont}>
        <img src={imagen} alt={titulo} className="imagen-curso" style={styles.img} loading="lazy" />
        <div className={`badge-tipo ${esCurso ? 'curso' : 'tutorial'}`} style={{ ...styles.badgeTipo, ...(esCurso ? styles.badgeCurso : styles.badgeTutorial) }}>{tipoContenido}</div>
        {completado && (
          <div className="badge-completado" style={styles.badgeCompletado}>✔ Completado</div>
        )}
      </div>
      <div className="contenido-tarjeta" style={styles.contenido}>
        <div className="info-principal" style={{ flex: 1 }}>
          <a href={esCurso ? `/mis-cursos/${slug}` : `/tutoriales/${slug}/contenido`} className="titulo-curso-link" style={styles.tituloLink}><h3 className="titulo-curso" style={styles.titulo}>{titulo}</h3></a>
          <p className="fecha-inscripcion" style={styles.fecha}>Inscrito el {fechaInscripcion}</p>
          <div className="hint-navegacion" style={styles.hint}><span>Haz clic en el título para ver todos los {esCurso ? 'módulos' : 'clases'}</span></div>
        </div>
        <div className="progreso-seccion" style={{ margin: '8px 0' }}>
          {cargandoProgreso ? (
            <div className="cargando-progreso" style={styles.cargandoProg}><div style={styles.spinnerMini} /><span>Cargando progreso...</span></div>
          ) : (
            <div className="progreso-info" style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <div className="progreso-texto" style={styles.progresoTexto}>Progreso: {progreso.completadas} / {progreso.total} {esCurso ? 'lecciones' : 'clases'} ({progreso.porcentaje}%)</div>
              <div className="barra-progreso" style={styles.barra}><div className={`progreso-relleno ${esCurso ? 'curso' : 'tutorial'}`} style={{ ...styles.relleno, width: `${progreso.porcentaje}%`, background: esCurso ? 'linear-gradient(90deg,#2563eb,#3b82f6)' : 'linear-gradient(90deg,#a855f7,#c084fc)' }} /></div>
            </div>
          )}
        </div>
        <div className="acciones" style={{ marginTop: 'auto' }}>
          <button className={`boton-continuar ${completado ? 'completado' : ''}`} style={{ ...styles.btnContinuar, ...(completado ? styles.btnCompletado : {}) }} onClick={navegarAContenido}>
            {textoBoton} →
          </button>
        </div>
      </div>
    </article>
  )
}

const styles = {
  card: { background: '#fff', borderRadius: 16, overflow: 'hidden', boxShadow: '0 4px 24px rgba(0,0,0,0.06)', transition: 'all 0.3s', height: '100%', display: 'flex', flexDirection: 'column' as const },
  imgCont: { position: 'relative' as const, width: '100%', height: 200, overflow: 'hidden' },
  img: { width: '100%', height: '100%', objectFit: 'cover' as const, transition: 'transform 0.3s ease' },
  badgeTipo: { position: 'absolute' as const, top: 12, left: 12, padding: '4px 12px', borderRadius: 20, fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' },
  badgeCurso: { background: 'rgba(37,99,235,0.9)', color: '#fff' },
  badgeTutorial: { background: 'rgba(168,85,247,0.9)', color: '#fff' },
  badgeCompletado: { position: 'absolute' as const, top: 12, right: 12, background: 'rgba(34,197,94,0.9)', color: '#fff', padding: '4px 8px', borderRadius: 20, fontSize: '0.75rem', fontWeight: 600 },
  contenido: { padding: 20, display: 'flex', flexDirection: 'column' as const, gap: 16, flex: 1 },
  tituloLink: { textDecoration: 'none', color: 'inherit', display: 'block', transition: 'color 0.2s ease' },
  titulo: { fontSize: '1.25rem', fontWeight: 700, color: '#1f2937', margin: '0 0 8px 0', lineHeight: 1.3 },
  fecha: { fontSize: '0.875rem', color: '#6b7280', margin: 0 },
  hint: { display: 'flex', alignItems: 'center', gap: 6, marginTop: 8, padding: '8px 12px', background: 'linear-gradient(135deg,#f0f9ff 0%, #e0f2fe 100%)', border: '1px solid #bae6fd', borderRadius: 8, fontSize: '0.8rem', color: '#0369a1', fontWeight: 500 },
  cargandoProg: { display: 'flex', alignItems: 'center', gap: 8, color: '#6b7280', fontSize: '0.875rem' },
  spinnerMini: { width: 16, height: 16, border: '2px solid #e5e7eb', borderTop: '2px solid #2563eb', borderRadius: '50%', animation: 'spin 1s linear infinite' },
  progresoTexto: { fontSize: '0.875rem', color: '#374151', fontWeight: 500 },
  barra: { width: '100%', height: 8, background: '#e5e7eb', borderRadius: 4, overflow: 'hidden' },
  relleno: { height: '100%', transition: 'width 0.3s ease', borderRadius: 4 },
  btnContinuar: { display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, width: '100%', padding: '12px 24px', background: '#2563eb', color: '#fff', border: 'none', borderRadius: 12, fontWeight: 600, fontSize: '0.95rem', cursor: 'pointer' },
  btnCompletado: { background: '#059669' }
}
