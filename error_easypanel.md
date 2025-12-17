Commit: fix: upgrade to Node 20 for supabase compatibility 
##########################################
### Download Github Archive Started...
### Wed, 17 Dec 2025 06:28:08 GMT
##########################################


╔═════════════════════ Nixpacks v1.34.1 ═════════════════════╗
║ setup      │ nodejs-20_x                                   ║
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
#1 transferring dockerfile: 1.97kB done
#1 DONE 0.0s

#2 [internal] load metadata for ghcr.io/railwayapp/nixpacks:ubuntu-1741046653
#2 DONE 0.1s

#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s

#4 [stage-0  1/15] FROM ghcr.io/railwayapp/nixpacks:ubuntu-1741046653@sha256:ed406b77fb751927991b8655e76c33a4521c4957c2afeab293be7c63c2a373d2
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 49.92MB 0.6s done
#5 DONE 0.6s

#6 [stage-0  2/15] WORKDIR /app/
#6 CACHED

#7 [stage-0  3/15] COPY .nixpacks/nixpkgs-ba913eda2df8eb72147259189d55932012df6301.nix .nixpacks/nixpkgs-ba913eda2df8eb72147259189d55932012df6301.nix
#7 CACHED

#8 [stage-0  4/15] RUN nix-env -if .nixpacks/nixpkgs-ba913eda2df8eb72147259189d55932012df6301.nix && nix-collect-garbage -d
#8 CACHED

#9 [stage-0  5/15] COPY .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix
#9 DONE 0.2s

#10 [stage-0  6/15] RUN nix-env -if .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix && nix-collect-garbage -d
#10 0.152 unpacking 'https://github.com/NixOS/nixpkgs/archive/ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.tar.gz' into the Git cache...
#10 41.09 unpacking 'https://github.com/railwayapp/nix-npm-overlay/archive/main.tar.gz' into the Git cache...
#10 41.68 installing 'ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7-env'
#10 41.85 error:
#10 41.85        … while calling the 'derivationStrict' builtin
#10 41.85          at <nix/derivation-internal.nix>:37:12:
#10 41.85            36|
#10 41.85            37|   strict = derivationStrict drvAttrs;
#10 41.85              |            ^
#10 41.85            38|
#10 41.85 
#10 41.85        … while evaluating derivation 'ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7-env'
#10 41.85          whose name attribute is located at /nix/store/lwi59jcfwk2lnrakmm1y5vw85hj3n1bi-source/pkgs/stdenv/generic/make-derivation.nix:375:7
#10 41.85 
#10 41.85        … while evaluating attribute 'passAsFile' of derivation 'ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7-env'
#10 41.85          at /nix/store/lwi59jcfwk2lnrakmm1y5vw85hj3n1bi-source/pkgs/build-support/trivial-builders/default.nix:60:9:
#10 41.85            59|         inherit buildCommand name;
#10 41.85            60|         passAsFile = [ "buildCommand" ]
#10 41.85              |         ^
#10 41.85            61|           ++ (derivationArgs.passAsFile or [ ]);
#10 41.85 
#10 41.85        (stack trace truncated; use '--show-trace' to show the full, detailed trace)
#10 41.85 
#10 41.85        error: undefined variable 'nodejs-20_x'
#10 41.85        at /app/.nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix:19:9:
#10 41.85            18|         '')
#10 41.85            19|         nodejs-20_x
#10 41.85              |         ^
#10 41.85            20|       ];
#10 ERROR: process "/bin/bash -ol pipefail -c nix-env -if .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix && nix-collect-garbage -d" did not complete successfully: exit code: 1
------
 > [stage-0  6/15] RUN nix-env -if .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix && nix-collect-garbage -d:
41.85            61|           ++ (derivationArgs.passAsFile or [ ]);
41.85 
41.85        (stack trace truncated; use '--show-trace' to show the full, detailed trace)
41.85 
41.85        error: undefined variable 'nodejs-20_x'
41.85        at /app/.nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix:19:9:
41.85            18|         '')
41.85            19|         nodejs-20_x
41.85              |         ^
41.85            20|       ];
------

 7 warnings found (use docker --debug to expand):
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_ANON_KEY") (line 13)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_SERVICE_ROLE_KEY") (line 13)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_EPAYCO_PRIVATE_KEY") (line 14)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_SUPABASE_ANON_KEY") (line 14)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_SUPABASE_SERVICE_ROLE_KEY") (line 14)
 - UndefinedVar: Usage of undefined variable '$NIXPACKS_PATH' (line 24)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_EPAYCO_PRIVATE_KEY") (line 13)
Dockerfile:10
--------------------
   8 |     RUN nix-env -if .nixpacks/nixpkgs-ba913eda2df8eb72147259189d55932012df6301.nix && nix-collect-garbage -d
   9 |     COPY .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix
  10 | >>> RUN nix-env -if .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix && nix-collect-garbage -d
  11 |     
  12 |     COPY .nixpacks/assets /assets/
--------------------
ERROR: failed to build: failed to solve: process "/bin/bash -ol pipefail -c nix-env -if .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix && nix-collect-garbage -d" did not complete successfully: exit code: 1
##########################################
### Error
### Wed, 17 Dec 2025 06:28:57 GMT
##########################################

Command failed with exit code 1: docker buildx build --network host -f /etc/easypanel/projects/academia_online_gamificacion/app_academia_vallenata_online/code/.nixpacks/Dockerfile -t easypanel/academia_online_gamificacion/app_academia_vallenata_online --label 'keep=true' --build-arg 'VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co' --build-arg 'VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NTQyNjIsImV4cCI6MjA1ODUzMDI2Mn0.P09L8OpLpcrm5XzTLAN0oQllhl_bePk5bxbUUpoG-cQ' --build-arg 'VITE_SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0Mjk1NDI2MiwiZXhwIjoyMDU4NTMwMjYyfQ.OfKotOdcC3wmCCQz3VhLVfQMgLcQN-VlgDC6D5fqRJU' --build-arg 'VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb' --build-arg 'VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1' --build-arg 'VITE_EPAYCO_CUSTOMER_ID=37257' --build-arg 'VITE_EPAYCO_TEST_MODE=false' --build-arg 'VITE_APP_URL=https://academiavallenataonline.com/' --build-arg 'NODE_ENV=production' --build-arg 'GIT_SHA=0c6949b1c0e1437b6b23b6e32f7169b497d1be71' /etc/easypanel/projects/academia_online_gamificacion/app_academia_vallenata_online/code/