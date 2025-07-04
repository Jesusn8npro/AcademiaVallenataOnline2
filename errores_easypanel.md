Commit: fix: simplificar configuracion nixpacks sin conflictos 
##########################################
### Download Github Archive Started...
### Thu, 03 Jul 2025 19:55:59 GMT
##########################################


╔════════ Nixpacks v1.34.1 ═══════╗
║ setup      │ nodejs_18, npm-9_x ║
║─────────────────────────────────║
║ install    │ npm install        ║
║─────────────────────────────────║
║ build      │ npm run build      ║
║─────────────────────────────────║
║ start      │ node build         ║
╚═════════════════════════════════╝


Saved output to:
  /etc/easypanel/projects/academia_vallenata_online/academia_vallenata_online/code/
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 1.52kB done
#1 DONE 0.0s

#2 [internal] load metadata for ghcr.io/railwayapp/nixpacks:ubuntu-1741046653
#2 DONE 0.1s

#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s

#4 [stage-0  1/10] FROM ghcr.io/railwayapp/nixpacks:ubuntu-1741046653@sha256:ed406b77fb751927991b8655e76c33a4521c4957c2afeab293be7c63c2a373d2
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 19.42MB 0.4s done
#5 DONE 0.4s

#6 [stage-0  2/10] WORKDIR /app/
#6 CACHED

#7 [stage-0  3/10] COPY .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix
#7 CACHED

#8 [stage-0  4/10] RUN nix-env -if .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix && nix-collect-garbage -d
#8 CACHED

#9 [stage-0  5/10] COPY . /app/.
#9 DONE 0.2s

#10 [stage-0  6/10] RUN --mount=type=cache,id=LjjLtS3G8c-/root/npm,target=/root/.npm npm install
#10 2.063 npm warn deprecated lodash.isequal@4.5.0: This package is deprecated. Use require('node:util').isDeepStrictEqual instead.
#10 2.162 npm warn deprecated formidable@1.2.6: Please upgrade to latest, formidable@v2 or formidable@v3! Check these notes: https://bit.ly/2ZEqIau
#10 2.529 npm warn deprecated superagent@3.8.3: Please upgrade to v9.0.0+ as we have fixed a public vulnerability with formidable dependency. Note that v9.0.0+ requires Node.js v14.18.0+. See https://github.com/ladjs/superagent/pull/1800 for insight. This project is supported and maintained by the team at Forward Email @ https://forwardemail.net
#10 5.268 
#10 5.268 > -nueva-academia@0.0.1 prepare
#10 5.268 > svelte-kit sync || echo ''
#10 5.268 
#10 5.907 
#10 5.907 added 254 packages, and audited 255 packages in 6s
#10 5.908 
#10 5.908 55 packages are looking for funding
#10 5.908   run `npm fund` for details
#10 5.920 
#10 5.920 3 low severity vulnerabilities
#10 5.920 
#10 5.920 To address all issues (including breaking changes), run:
#10 5.920   npm audit fix --force
#10 5.920 
#10 5.920 Run `npm audit` for details.
#10 DONE 6.1s

#11 [stage-0  7/10] COPY . /app/.
#11 DONE 0.4s

#12 [stage-0  8/10] RUN --mount=type=cache,id=LjjLtS3G8c-node_modules/cache,target=/app/node_modules/.cache npm run build
#12 0.582 
#12 0.582 > -nueva-academia@0.0.1 build
#12 0.582 > vite build
#12 0.582 
#12 1.345 vite v6.3.5 building SSR bundle for production...
#12 1.384 transforming...
#12 1.685 7:56:11 PM [vite-plugin-svelte] src/routes/administrador/eventos/+page.svelte:546:11 Buttons and links should either contain text or have an `aria-label` or `aria-labelledby` attribute
#12 1.685 https://svelte.dev/e/a11y_consider_explicit_label
#12 1.685 544:                   <td class="px-6 py-4 text-right text-sm font-medium">
#12 1.685 545:                     <div class="flex justify-end gap-2">
#12 1.685 546:                       <a 
#12 1.685                               ^
#12 1.685 547:                         href="/eventos/{evento.slug}"
#12 1.685 548:                         target="_blank"
#12 1.685 7:56:11 PM [vite-plugin-svelte] src/routes/administrador/eventos/+page.svelte:558:11 Buttons and links should either contain text or have an `aria-label` or `aria-labelledby` attribute
#12 1.685 https://svelte.dev/e/a11y_consider_explicit_label
#12 1.685 556:                       </a>
#12 1.685 557:                       
#12 1.685 558:                       <button
#12 1.685                                   ^
#12 1.685 559:                         on:click={() => eliminarEvento(evento.id)}
#12 1.685 560:                         class="text-red-600 hover:text-red-900 p-1 rounded"
#12 2.052 7:56:11 PM [vite-plugin-svelte] src/lib/components/PlantillasLandingCursos/VideoHeroView.svelte:111:10 `<video>` elements must have a `<track kind="captions">`
#12 2.052 https://svelte.dev/e/a11y_media_has_caption
#12 2.053 109:           ></iframe>
#12 2.053 110:         {:else if isValidVideoUrl(videoUrl)}
#12 2.053 111:           <video 
#12 2.053                       ^
#12 2.053 112:             class="absolute top-0 left-0 w-full h-full"
#12 2.053 113:             controls
#12 2.181 7:56:11 PM [vite-plugin-svelte] src/lib/components/Membresias/SelectorMembresias.svelte:279:5 Buttons and links should either contain text or have an `aria-label` or `aria-labelledby` attribute
#12 2.181 https://svelte.dev/e/a11y_consider_explicit_label
#12 2.181 277:             <p class="text-gray-600 mt-1">Elige el plan que mejor se adapte a tu aprendizaje</p>
#12 2.181 278:           </div>
#12 2.181 279:           <button 
#12 2.181                        ^
#12 2.181 280:             on:click={() => mostrarModal = false}
#12 2.181 281:             class="text-gray-400 hover:text-gray-600 transition-colors"
#12 2.181 7:56:11 PM [vite-plugin-svelte] src/lib/components/Membresias/SelectorMembresias.svelte:14:12 Component has unused export property 'planSeleccionado'. If it is for external reference only, please consider using `export const planSeleccionado`
#12 2.181 https://svelte.dev/e/export_let_unused
#12 2.181 12:   // Props
#12 2.181 13:   export let mostrarModal = false;
#12 2.181 14:   export let planSeleccionado: string | null = null;
#12 2.181                                                 ^
#12 2.181 15: 
#12 2.181 16:   // Estado del componente
#12 3.533 ✓ 196 modules transformed.
#12 3.534 ✗ Build failed in 2.19s
#12 3.534 error during build:
#12 3.534 [vite:css] [postcss] Cannot find module '@tailwindcss/forms'
#12 3.534 Require stack:
#12 3.534 - /app/tailwind.config.js
#12 3.534 file: /app/src/app.css:undefined:NaN
#12 3.534     at Module._resolveFilename (node:internal/modules/cjs/loader:1140:15)
#12 3.534     at Function.resolve (node:internal/modules/helpers:188:19)
#12 3.534     at _resolve (/app/node_modules/jiti/dist/jiti.js:1:246378)
#12 3.534     at jiti (/app/node_modules/jiti/dist/jiti.js:1:249092)
#12 3.534     at /app/tailwind.config.js:23:5
#12 3.534     at evalModule (/app/node_modules/jiti/dist/jiti.js:1:251913)
#12 3.534     at jiti (/app/node_modules/jiti/dist/jiti.js:1:249841)
#12 3.534     at /app/node_modules/tailwindcss/lib/lib/load-config.js:52:26
#12 3.534     at loadConfig (/app/node_modules/tailwindcss/lib/lib/load-config.js:62:6)
#12 3.534     at getTailwindConfig (/app/node_modules/tailwindcss/lib/lib/setupTrackingContext.js:71:116)
#12 3.556 npm notice
#12 3.556 npm notice New major version of npm available! 10.8.2 -> 11.4.2
#12 3.556 npm notice Changelog: https://github.com/npm/cli/releases/tag/v11.4.2
#12 3.556 npm notice To update run: npm install -g npm@11.4.2
#12 3.556 npm notice
#12 ERROR: process "/bin/bash -ol pipefail -c npm run build" did not complete successfully: exit code: 1
------
 > [stage-0  8/10] RUN --mount=type=cache,id=LjjLtS3G8c-node_modules/cache,target=/app/node_modules/.cache npm run build:
3.534     at evalModule (/app/node_modules/jiti/dist/jiti.js:1:251913)
3.534     at jiti (/app/node_modules/jiti/dist/jiti.js:1:249841)
3.534     at /app/node_modules/tailwindcss/lib/lib/load-config.js:52:26
3.534     at loadConfig (/app/node_modules/tailwindcss/lib/lib/load-config.js:62:6)
3.534     at getTailwindConfig (/app/node_modules/tailwindcss/lib/lib/setupTrackingContext.js:71:116)
3.556 npm notice
3.556 npm notice New major version of npm available! 10.8.2 -> 11.4.2
3.556 npm notice Changelog: https://github.com/npm/cli/releases/tag/v11.4.2
3.556 npm notice To update run: npm install -g npm@11.4.2
3.556 npm notice
------
Dockerfile:24
--------------------
  22 |     # build phase
  23 |     COPY . /app/.
  24 | >>> RUN --mount=type=cache,id=LjjLtS3G8c-node_modules/cache,target=/app/node_modules/.cache npm run build
  25 |     
  26 |     
--------------------
ERROR: failed to solve: process "/bin/bash -ol pipefail -c npm run build" did not complete successfully: exit code: 1
##########################################
### Error
### Thu, 03 Jul 2025 19:56:12 GMT
##########################################

Command failed with exit code 1: docker buildx build --network host -f /etc/easypanel/projects/academia_vallenata_online/academia_vallenata_online/code/.nixpacks/Dockerfile -t easypanel/academia_vallenata_online/academia_vallenata_online --label 'keep=true' --build-arg 'NODE_ENV=production' --build-arg 'VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co' --build-arg 'VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NTQyNjIsImV4cCI6MjA1ODUzMDI2Mn0.P09L8OpLpcrm5XzTLAN0oQllhl_bePk5bxbUUpoG-cQ' --build-arg 'VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb' --build-arg 'VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1' --build-arg 'VITE_EPAYCO_CUSTOMER_ID=37257' --build-arg 'VITE_EPAYCO_TEST_MODE=false' --build-arg 'VITE_APP_URL=https://academia-online-academia-vallenata-online.lnrubg.easypanel.host' --build-arg 'GIT_SHA=1a762e4553ddc822328bcec0f3cbf0937061e018' /etc/easypanel/projects/academia_vallenata_online/academia_vallenata_online/code/