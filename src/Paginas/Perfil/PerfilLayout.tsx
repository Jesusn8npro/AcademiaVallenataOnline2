import React, { useEffect, useState } from 'react'
import ProteccionAutenticacion from '../../guards/ProteccionAutenticacion'
import { PerfilProvider, usePerfilStore } from '../../stores/perfilStore'
import EncabezadoPerfil from '../../componentes/Perfil/EncabezadoPerfil'
import PestanasPerfil from '../../componentes/Perfil/PestanasPerfil'
import './perfil-layout.css'
import './perfil-ancho-completo.css'
import './perfil-responsive.css'

function InnerLayout({ children }: { children: React.ReactNode }) {
  const { perfil, stats, cargando, inicializado, cargarDatosPerfil, forzarInicializacion } = usePerfilStore()
  const [modalAbierto, setModalAbierto] = useState(false)

  // Efecto simple para cargar datos al montar
  useEffect(() => {
    cargarDatosPerfil()

    // Safety check: si después de 3 segundos sigue cargando y no hay perfil, forzar fin de carga
    const safetyTimer = setTimeout(() => {
      if (!inicializado && !perfil) {
        console.warn('⚠️ Safety check del layout disparado: Forzando inicialización')
        forzarInicializacion()
      }
    }, 3000)

    return () => clearTimeout(safetyTimer)
  }, [])

  function onModalStateChange(abierto: boolean) { setModalAbierto(abierto) }

  // Determinar si debemos mostrar el estado de carga
  // Solo mostramos carga si NO está inicializado y NO tenemos perfil
  const mostrarCarga = cargando && !perfil && !inicializado

  return (
    <div className="layout-perfil-fijo">
      <div className="encabezado-fijo">
        {perfil ? (
          <EncabezadoPerfil nombreCompleto={perfil.nombre_completo} urlAvatar={perfil.url_foto_perfil} urlPortada={perfil.portada_url} posicionPortadaY={Number(perfil.posicion_img_portada || 50)} userId={perfil.id} stats={stats} onModalStateChange={onModalStateChange} />
        ) : mostrarCarga ? (
          <div className="encabezado-cargando"><div className="spinner" /><p>Cargando información...</p></div>
        ) : (
          <div className="encabezado-error"><p>Falló la carga</p><button className="btn-reintentar" onClick={() => cargarDatosPerfil(true)}>Reintentar</button></div>
        )}
      </div>
      <div className={`pestanas-fijas ${modalAbierto ? 'ocultar-pestanas' : ''}`}><PestanasPerfil modalAbierto={modalAbierto} /></div>
      <div className="contenido-dinamico">
        {/* Siempre renderizar children si ya tenemos perfil O si ya terminó la carga (aunque fallara) */}
        {perfil || inicializado ? children : (
          <div className="contenido-cargando"><div className="spinner" /><p>Preparando tu perfil...</p></div>
        )}
      </div>
    </div>
  )
}

import { Outlet } from 'react-router-dom'

export default function PerfilLayout({ children }: { children?: React.ReactNode }) {
  return (
    <ProteccionAutenticacion titulo="🔒 PERFIL RESTRINGIDO" mensajePrincipal="Tu perfil personal requiere que inicies sesión">
      <PerfilProvider>
        <InnerLayout>{children || <Outlet />}</InnerLayout>
      </PerfilProvider>
    </ProteccionAutenticacion>
  )
}
