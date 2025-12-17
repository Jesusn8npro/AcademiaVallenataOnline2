Commit: fix: downgrade @vitejs/plugin-react to 4.3.4 for node compatibility 
##########################################
### Download Github Archive Started...
### Wed, 17 Dec 2025 06:39:20 GMT
##########################################


╔═════════════════════ Nixpacks v1.34.1 ═════════════════════╗
║ setup      │ nodejs_22, npm-9_x                            ║
║────────────────────────────────────────────────────────────║
║ caddy      │ pkgs: caddy                                   ║
║            │ cmds: caddy fmt --overwrite /assets/Caddyfile ║
║────────────────────────────────────────────────────────────║
║ install    │ npm install                                   ║
║────────────────────────────────────────────────────────────║
║ build      │ npm run build                                 ║
║────────────────────────────────────────────────────────────║
║ start      │ npm run preview                               ║
╚════════════════════════════════════════════════════════════╝


Saved output to:
  /etc/easypanel/projects/academia_online_gamificacion/app_academia_vallenata_online/code/
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 2.07kB done
#1 DONE 0.0s

#2 [internal] load metadata for ghcr.io/railwayapp/nixpacks:ubuntu-1741046653
#2 DONE 0.1s

#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s

#4 [stage-0  1/15] FROM ghcr.io/railwayapp/nixpacks:ubuntu-1741046653@sha256:ed406b77fb751927991b8655e76c33a4521c4957c2afeab293be7c63c2a373d2
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 49.93MB 0.5s done
#5 DONE 0.5s

#6 [stage-0  6/15] RUN nix-env -if .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix && nix-collect-garbage -d
#6 CACHED

#7 [stage-0  2/15] WORKDIR /app/
#7 CACHED

#8 [stage-0  3/15] COPY .nixpacks/nixpkgs-ba913eda2df8eb72147259189d55932012df6301.nix .nixpacks/nixpkgs-ba913eda2df8eb72147259189d55932012df6301.nix
#8 CACHED

#9 [stage-0  4/15] RUN nix-env -if .nixpacks/nixpkgs-ba913eda2df8eb72147259189d55932012df6301.nix && nix-collect-garbage -d
#9 CACHED

#10 [stage-0  5/15] COPY .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix
#10 CACHED

#11 [stage-0  7/15] COPY .nixpacks/assets /assets/
#11 CACHED

#12 [stage-0  8/15] COPY . /app/.
#12 DONE 0.5s

#13 [stage-0  9/15] RUN  caddy fmt --overwrite /assets/Caddyfile
#13 DONE 0.1s

#14 [stage-0 10/15] COPY . /app/.
#14 DONE 1.1s

#15 [stage-0 11/15] RUN --mount=type=cache,id=sjRK13XGAVQ-/root/npm,target=/root/.npm npm install
#15 246.4 npm error code EBADENGINE
#15 246.4 npm error engine Unsupported engine
#15 246.4 npm error engine Not compatible with your version of node/npm: vite@7.2.7
#15 246.4 npm error notsup Not compatible with your version of node/npm: vite@7.2.7
#15 246.4 npm error notsup Required: {"node":"^20.19.0 || >=22.12.0"}
#15 246.4 npm error notsup Actual:   {"npm":"10.9.0","node":"v22.11.0"}
#15 246.4 npm error A complete log of this run can be found in: /root/.npm/_logs/2025-12-17T06_39_29_391Z-debug-0.log
#15 ERROR: process "/bin/bash -ol pipefail -c npm install" did not complete successfully: exit code: 1
------
 > [stage-0 11/15] RUN --mount=type=cache,id=sjRK13XGAVQ-/root/npm,target=/root/.npm npm install:
246.4 npm error code EBADENGINE
246.4 npm error engine Unsupported engine
246.4 npm error engine Not compatible with your version of node/npm: vite@7.2.7
246.4 npm error notsup Not compatible with your version of node/npm: vite@7.2.7
246.4 npm error notsup Required: {"node":"^20.19.0 || >=22.12.0"}
246.4 npm error notsup Actual:   {"npm":"10.9.0","node":"v22.11.0"}
246.4 npm error A complete log of this run can be found in: /root/.npm/_logs/2025-12-17T06_39_29_391Z-debug-0.log
------

 9 warnings found (use docker --debug to expand):
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_SUPABASE_SERVICE_ROLE_KEY") (line 14)
 - UndefinedVar: Usage of undefined variable '$NIXPACKS_PATH' (line 24)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_SERVICE_ROLE_KEY") (line 13)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_SUPABASE_ANON_KEY") (line 14)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_EPAYCO_PRIVATE_KEY") (line 13)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_GIPHY_API_KEY") (line 13)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_ANON_KEY") (line 13)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_EPAYCO_PRIVATE_KEY") (line 14)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_GIPHY_API_KEY") (line 14)
Dockerfile:26
--------------------
  24 |     ENV NIXPACKS_PATH=/app/node_modules/.bin:$NIXPACKS_PATH
  25 |     COPY . /app/.
  26 | >>> RUN --mount=type=cache,id=sjRK13XGAVQ-/root/npm,target=/root/.npm npm install
  27 |     
  28 |     # build phase
--------------------
ERROR: failed to build: failed to solve: process "/bin/bash -ol pipefail -c npm install" did not complete successfully: exit code: 1
##########################################
### Error
### Wed, 17 Dec 2025 06:43:35 GMT
##########################################

Command failed with exit code 1: docker buildx build --network host -f /etc/easypanel/projects/academia_online_gamificacion/app_academia_vallenata_online/code/.nixpacks/Dockerfile -t easypanel/academia_online_gamificacion/app_academia_vallenata_online --label 'keep=true' --build-arg 'VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co' --build-arg 'VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NTQyNjIsImV4cCI6MjA1ODUzMDI2Mn0.P09L8OpLpcrm5XzTLAN0oQllhl_bePk5bxbUUpoG-cQ' --build-arg 'VITE_SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0Mjk1NDI2MiwiZXhwIjoyMDU4NTMwMjYyfQ.OfKotOdcC3wmCCQz3VhLVfQMgLcQN-VlgDC6D5fqRJU' --build-arg 'VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb' --build-arg 'VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1' --build-arg 'VITE_EPAYCO_CUSTOMER_ID=37257' --build-arg 'VITE_EPAYCO_TEST_MODE=false' --build-arg 'VITE_GIPHY_API_KEY=Kj3vAtPH8E0gWaVO2amamR5xazoGL36q' --build-arg 'VITE_APP_URL=http://localhost:5173' --build-arg 'VITE_BASE_URL=http://localhost:5173' --build-arg 'NODE_ENV=development' --build-arg 'GIT_SHA=32a2626281370d964f3067de640e0f8df964ec4c' /etc/easypanel/projects/academia_online_gamificacion/app_academia_vallenata_online/code/