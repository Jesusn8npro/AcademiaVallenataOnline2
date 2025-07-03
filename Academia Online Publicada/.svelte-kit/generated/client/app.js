export { matchers } from './matchers.js';

export const nodes = [
	() => import('./nodes/0'),
	() => import('./nodes/1'),
	() => import('./nodes/2'),
	() => import('./nodes/3'),
	() => import('./nodes/4'),
	() => import('./nodes/5'),
	() => import('./nodes/6'),
	() => import('./nodes/7'),
	() => import('./nodes/8'),
	() => import('./nodes/9'),
	() => import('./nodes/10'),
	() => import('./nodes/11'),
	() => import('./nodes/12'),
	() => import('./nodes/13'),
	() => import('./nodes/14'),
	() => import('./nodes/15'),
	() => import('./nodes/16'),
	() => import('./nodes/17'),
	() => import('./nodes/18'),
	() => import('./nodes/19'),
	() => import('./nodes/20'),
	() => import('./nodes/21')
];

export const server_loads = [];

export const dictionary = {
		"/": [3],
		"/administrador": [4],
		"/administrador/blog": [5],
		"/administrador/crear-contenido": [6],
		"/administrador/panel-contenido": [7],
		"/blog": [8],
		"/blog/[slug]": [9],
		"/comunidad": [10],
		"/cursos": [11],
		"/cursos/[slug]": [~12],
		"/cursos/[slug]/[modulo]/[leccion]": [~13,[2]],
		"/estudiante": [14],
		"/mi-perfil": [15],
		"/mis-cursos": [16],
		"/publicaciones": [17],
		"/sesion_cerrada": [18],
		"/simulador-de-acordeon": [19],
		"/tutoriales/[slug]": [~20],
		"/tutoriales/[slug]/clase/[claseSlug]": [~21]
	};

export const hooks = {
	handleError: (({ error }) => { console.error(error) }),
	
	reroute: (() => {}),
	transport: {}
};

export const decoders = Object.fromEntries(Object.entries(hooks.transport).map(([k, v]) => [k, v.decode]));

export const hash = false;

export const decode = (type, value) => decoders[type](value);

export { default as root } from '../root.js';