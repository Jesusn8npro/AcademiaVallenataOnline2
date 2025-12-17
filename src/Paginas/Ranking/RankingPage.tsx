import React, { useEffect, useMemo, useRef, useState, useCallback } from 'react'
import { supabase } from '../../servicios/supabaseCliente'
import GamificacionServicio from '../../servicios/gamificacionServicio'
import type { RankingGlobal } from '../../servicios/gamificacionServicio'
import './ranking.css'



const Ranking: React.FC = () => {
  // Estado local
  const [rankingCompleto, setRankingCompleto] = useState<RankingGlobal[]>([]);
  const [rankingMostrado, setRankingMostrado] = useState<RankingGlobal[]>([]);
  const [cargando, setCargando] = useState(true);
  const [cargandoMas, setCargandoMas] = useState(false);
  const [error, setError] = useState('');
  const [categoriaActiva, setCategoriaActiva] = useState('general');
  const [busqueda, setBusqueda] = useState('');
  const [miPosicion, setMiPosicion] = useState<RankingGlobal | null>(null);
  const [mostrarSoloTop, setMostrarSoloTop] = useState(false);
  const [filtroNivel, setFiltroNivel] = useState('todos');

  // Scroll infinito
  const [usuariosMostrados, setUsuariosMostrados] = useState(6);
  const incrementoPorScroll = 4;
  const elementoTriggerRef = useRef<HTMLDivElement>(null);

  // Configuración de categorías
  const categorias = [
    {
      id: 'general',
      nombre: 'General',
      descripcion: 'Ranking global de la academia',
      icono: '🏆',
      color: 'from-yellow-500 to-orange-600'
    },
    {
      id: 'simulador',
      nombre: 'Simulador',
      descripcion: 'Mejores en el simulador de acordeón',
      icono: '🎮',
      color: 'from-blue-500 to-purple-600'
    },
    {
      id: 'cursos',
      nombre: 'Cursos',
      descripcion: 'Progreso en cursos y tutoriales',
      icono: '📚',
      color: 'from-green-500 to-blue-600'
    },
    {
      id: 'precision',
      nombre: 'Precisión',
      descripcion: 'Mejor precisión en interpretación',
      icono: '🎯',
      color: 'from-red-500 to-pink-600'
    },
    {
      id: 'constancia',
      nombre: 'Constancia',
      descripcion: 'Usuarios más constantes',
      icono: '🔥',
      color: 'from-orange-500 to-red-600'
    },
    {
      id: 'comunidad',
      nombre: 'Comunidad',
      descripcion: 'Participación en la comunidad',
      icono: '👥',
      color: 'from-purple-500 to-indigo-600'
    }
  ];

  // Cargar ranking
  const cargarRanking = useCallback(async () => {
    try {
      setCargando(true);
      setError('');
      setUsuariosMostrados(6); // Reset a 6 usuarios

      console.log(`🎮 Cargando ranking completo: ${categoriaActiva}`);

      // Cargar ranking completo (hasta 200 usuarios)
      const ranking = await GamificacionServicio.obtenerRanking(categoriaActiva, 200);

      // Asignar datos completos
      setRankingCompleto(ranking);

      // Mostrar solo los primeros 6
      actualizarUsuariosMostrados(ranking, 6);

      // TODO: Cargar mi posición si estoy logueado
      // if (usuarioActual?.id) {
      //   const posicion = await GamificacionServicio.obtenerPosicionUsuario(
      //     usuarioActual.id,
      //     categoriaActiva
      //   );
      //   setMiPosicion(posicion);
      // }

      console.log(`✅ Ranking cargado: ${ranking.length} usuarios total, mostrando ${usuariosMostrados}`);
      
    } catch (err) {
      console.error('💥 Error cargando ranking:', err);
      setError('Error al cargar el ranking: ' + ((err as any)?.message || 'Error desconocido'));
    } finally {
      setCargando(false);
    }
  }, [categoriaActiva]);

  // Actualizar usuarios mostrados
  const actualizarUsuariosMostrados = useCallback((ranking?: RankingGlobal[], cantidad?: number) => {
    const rankingFiltrado = filtrarRanking(ranking || rankingCompleto);
    const cantidadMostrar = cantidad || usuariosMostrados;
    setRankingMostrado(rankingFiltrado.slice(0, cantidadMostrar));
  }, [rankingCompleto, usuariosMostrados, busqueda, filtroNivel, mostrarSoloTop]);

  // Cargar más usuarios
  const cargarMasUsuarios = useCallback(() => {
    const rankingFiltrado = filtrarRanking();
    
    if (usuariosMostrados >= rankingFiltrado.length) {
      return;
    }
    
    setCargandoMas(true);
    
    setTimeout(() => {
      const nuevaCantidad = usuariosMostrados + incrementoPorScroll;
      setUsuariosMostrados(nuevaCantidad);
      actualizarUsuariosMostrados(rankingCompleto, nuevaCantidad);
      setCargandoMas(false);
    }, 300);
  }, [usuariosMostrados, rankingCompleto, actualizarUsuariosMostrados]);

  // Cambiar categoría
  const cambiarCategoria = (categoria: string) => {
    if (categoria === categoriaActiva) return;
    setCategoriaActiva(categoria);
  };

  // Filtrar ranking
  const filtrarRanking = (ranking?: RankingGlobal[]): RankingGlobal[] => {
    const datos = ranking || rankingCompleto;
    
    if (!datos || !Array.isArray(datos) || datos.length === 0) {
      return [];
    }
    
    let rankingFiltrado = datos;
    
    // Filtro por búsqueda
    if (busqueda) {
      rankingFiltrado = rankingFiltrado.filter(item => 
        item.perfiles?.nombre?.toLowerCase().includes(busqueda.toLowerCase()) ||
        item.perfiles?.apellido?.toLowerCase().includes(busqueda.toLowerCase())
      );
    }
    
    // Filtro por nivel
    if (filtroNivel !== 'todos') {
      rankingFiltrado = rankingFiltrado.filter(item => 
        item.metricas?.nivel?.toString().toLowerCase() === filtroNivel.toLowerCase()
      );
    }
    
    // Mostrar solo top 10 si está activado
    if (mostrarSoloTop) {
      rankingFiltrado = rankingFiltrado.slice(0, 10);
    }
    
    return rankingFiltrado;
  };

  // Utilidades de estilo
  const obtenerColorPosicion = (posicion: number): string => {
    if (posicion === 1) return 'text-yellow-400';
    if (posicion === 2) return 'text-gray-400';
    if (posicion === 3) return 'text-orange-400';
    if (posicion <= 10) return 'text-blue-400';
    if (posicion <= 50) return 'text-green-400';
    return 'text-gray-500';
  };

  const obtenerIconoPosicion = (posicion: number): string => {
    if (posicion === 1) return '🥇';
    if (posicion === 2) return '🥈';
    if (posicion === 3) return '🥉';
    if (posicion <= 10) return '🏅';
    return '📊';
  };

  const obtenerEstiloTarjeta = (posicion: number): string => {
    if (posicion === 1) return 'tarjeta-oro';
    if (posicion === 2) return 'tarjeta-plata';
    if (posicion === 3) return 'tarjeta-bronce';
    if (posicion <= 10) return 'tarjeta-top10';
    return 'tarjeta-normal';
  };

  const formatearPuntuacion = (puntos: number): string => {
    if (puntos >= 1000000) return `${(puntos / 1000000).toFixed(1)}M`;
    if (puntos >= 1000) return `${(puntos / 1000).toFixed(1)}K`;
    return puntos.toString();
  };

  // Scroll progresivo basado en ventana (evita disparos instantáneos)
  useEffect(() => {
    function onScroll() {
      const nearBottom = (window.scrollY + window.innerHeight) >= (document.documentElement.scrollHeight - 120)
      if (nearBottom && !cargandoMas && !cargando) {
        cargarMasUsuarios()
      }
    }
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [cargarMasUsuarios, cargandoMas, cargando])

  // Cargar datos iniciales
  useEffect(() => {
    cargarRanking();
  }, [cargarRanking]);

  // Actualizar cuando cambien los filtros
  useEffect(() => {
    actualizarUsuariosMostrados();
  }, [actualizarUsuariosMostrados]);

  const navegarAInicio = () => {
    window.history.pushState({}, '', '/');
    window.dispatchEvent(new PopStateEvent('popstate'));
  };

  return (
    <>
      <title>Ranking Gaming - Academia Vallenata Online</title>
      <meta name="description" content="Ranking de estudiantes de Academia Vallenata Online. Compite, mejora y alcanza la cima del ranking musical." />

      <div className="ranking-container">
        <header className="ranking-header">
          <h1 className="ranking-titulo">🏆 Ranking Gaming</h1>
          <p className="ranking-descripcion">
            Selecciona una categoría, usa la búsqueda y desplázate para cargar más resultados. 
            La puntuación refleja tu actividad, progreso y XP en la academia; el listado se 
            actualiza de forma progresiva y muestra el nivel y los puntos de cada usuario.
          </p>
        </header>

        {/* CATEGORÍAS */}
        <section className="categorias-section">
          <div className="categorias-grid">
            {categorias.map((categoria) => (
              <button
                key={categoria.id}
                onClick={() => cambiarCategoria(categoria.id)}
                className={`categoria-btn ${categoriaActiva === categoria.id ? 'activa' : ''}`}
              >
                <span className="categoria-icono">{categoria.icono}</span>
                <div className="categoria-info">
                  <h3>{categoria.nombre}</h3>
                  <p>{categoria.descripcion}</p>
                </div>
              </button>
            ))}
          </div>
        </section>

        {/* FILTROS */}
        <section className="filtros-section">
          <div className="filtros-container">
            <div className="busqueda-container">
              <input
                type="text"
                placeholder="Buscar usuario..."
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                className="busqueda-input"
              />
            </div>
            
            <div className="filtros-opciones">
              <select
                value={filtroNivel}
                onChange={(e) => setFiltroNivel(e.target.value)}
                className="filtro-select"
              >
                <option value="todos">Todos los niveles</option>
                <option value="principiante">Principiante</option>
                <option value="intermedio">Intermedio</option>
                <option value="avanzado">Avanzado</option>
                <option value="experto">Experto</option>
              </select>
              
              <label className="toggle-container">
                <input
                  type="checkbox"
                  checked={mostrarSoloTop}
                  onChange={(e) => setMostrarSoloTop(e.target.checked)}
                />
                <span className="toggle-text">Solo Top 10</span>
              </label>
            </div>
          </div>
        </section>

        {/* RANKING */}
        <section className="ranking-section">
          {cargando ? (
            <div className="loading-container">
              <div className="spinner"></div>
              <p>Cargando ranking...</p>
            </div>
          ) : error ? (
            <div className="error-container">
              <p>{error}</p>
              <button onClick={cargarRanking} className="retry-btn">Reintentar</button>
            </div>
          ) : (
            <>
              <div className="ranking-lista">
                {rankingMostrado.map((usuario, index) => (
                  <div
                    key={usuario.id}
                    className={`usuario-card ${obtenerEstiloTarjeta(usuario.posicion)}`}
                  >
                    <div className="usuario-posicion">
                      <span className={`posicion-numero ${obtenerColorPosicion(usuario.posicion)}`}>
                        #{usuario.posicion}
                      </span>
                      <span className="posicion-icono">
                        {obtenerIconoPosicion(usuario.posicion)}
                      </span>
                    </div>
                    
                    <div className="usuario-avatar">
                      <img
                        src={usuario.perfiles?.url_foto_perfil || `https://api.dicebear.com/7.x/avataaars/svg?seed=${usuario.usuario_id}`}
                        alt={`Avatar de ${usuario.perfiles?.nombre}`}
                        className="avatar-img"
                      />
                    </div>
                    
                    <div className="usuario-info">
                      <h3 className="usuario-nombre">
                        {usuario.perfiles?.nombre} {usuario.perfiles?.apellido}
                      </h3>
                      <p className="usuario-nivel">Nivel {usuario.metricas?.nivel || 1}</p>
                    </div>
                    
                    <div className="usuario-stats">
                      <div className="stat-item">
                        <span className="stat-label">Puntos</span>
                        <span className="stat-value">
                          {formatearPuntuacion(usuario.puntuacion)}
                        </span>
                      </div>
                      <div className="stat-item">
                        <span className="stat-label">XP</span>
                        <span className="stat-value">
                          {formatearPuntuacion(usuario.metricas?.xp_total || 0)}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* TRIGGER PARA SCROLL INFINITO */}
              <div ref={elementoTriggerRef} className="scroll-trigger">
                {cargandoMas && (
                  <div className="loading-mas">
                    <div className="spinner-small"></div>
                    <p>Cargando más usuarios...</p>
                  </div>
                )}
              </div>
            </>
          )}
        </section>
      </div>
    </>
  );
};

export default Ranking; 
