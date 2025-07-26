Commit: Fix: Configuración nixpacks y dependencias para EasyPanel - Reparado error de build 
##########################################
### Download Github Archive Started...
### Sat, 26 Jul 2025 03:28:12 GMT
##########################################


╔════════════════ Nixpacks v1.34.1 ════════════════╗
║ setup      │ nodejs_18 npm, deno, nodejs_18, npm ║
║──────────────────────────────────────────────────║
║ install    │ npm ci                              ║
║──────────────────────────────────────────────────║
║ build      │ npm run build                       ║
║──────────────────────────────────────────────────║
║ start      │ node build                          ║
╚══════════════════════════════════════════════════╝


Saved output to:
  /etc/easypanel/projects/academia_online_gamificacion/app_academia_vallenata_online/code/
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 1.27kB done
#1 WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_EPAYCO_PRIVATE_KEY") (line 11)
#1 WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_ANON_KEY") (line 11)
#1 WARN: SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_SERVICE_ROLE_KEY") (line 11)
#1 DONE 0.0s

#2 [internal] load metadata for ghcr.io/railwayapp/nixpacks:ubuntu-1741046653
#2 DONE 0.1s

#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s

#4 [1/9] FROM ghcr.io/railwayapp/nixpacks:ubuntu-1741046653@sha256:ed406b77fb751927991b8655e76c33a4521c4957c2afeab293be7c63c2a373d2
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 88.68MB 0.6s done
#5 DONE 0.6s

#6 [2/9] WORKDIR /app/
#6 CACHED

#7 [3/9] COPY .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix
#7 DONE 0.1s

#8 [4/9] RUN nix-env -if .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix && nix-collect-garbage -d
#8 0.103 unpacking 'https://github.com/NixOS/nixpkgs/archive/5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.tar.gz' into the Git cache...
#8 33.31 installing '5148520bfab61f99fd25fb9ff7bfbb50dad3c9db-env'
#8 34.15 error:
#8 34.15        … while calling the 'derivationStrict' builtin
#8 34.15          at <nix/derivation-internal.nix>:37:12:
#8 34.15            36|
#8 34.15            37|   strict = derivationStrict drvAttrs;
#8 34.15              |            ^
#8 34.15            38|
#8 34.15 
#8 34.15        … while evaluating derivation '5148520bfab61f99fd25fb9ff7bfbb50dad3c9db-env'
#8 34.15          whose name attribute is located at /nix/store/lgcjj6s23v2203zyihsd0j26wh1saj0c-source/pkgs/stdenv/generic/make-derivation.nix:300:7
#8 34.15 
#8 34.15        … while evaluating attribute 'passAsFile' of derivation '5148520bfab61f99fd25fb9ff7bfbb50dad3c9db-env'
#8 34.15          at /nix/store/lgcjj6s23v2203zyihsd0j26wh1saj0c-source/pkgs/build-support/trivial-builders/default.nix:88:7:
#8 34.15            87|       inherit buildCommand name;
#8 34.15            88|       passAsFile = [ "buildCommand" ]
#8 34.15              |       ^
#8 34.15            89|         ++ (derivationArgs.passAsFile or []);
#8 34.15 
#8 34.15        (stack trace truncated; use '--show-trace' to show the full, detailed trace)
#8 34.15 
#8 34.15        error: undefined variable 'npm'
#8 34.15        at /app/.nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix:19:34:
#8 34.15            18|         '')
#8 34.15            19|         deno nodejs_18 nodejs_18 npm npm
#8 34.15              |                                  ^
#8 34.15            20|       ];
#8 ERROR: process "/bin/bash -ol pipefail -c nix-env -if .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix && nix-collect-garbage -d" did not complete successfully: exit code: 1
------
 > [4/9] RUN nix-env -if .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix && nix-collect-garbage -d:
34.15            89|         ++ (derivationArgs.passAsFile or []);
34.15 
34.15        (stack trace truncated; use '--show-trace' to show the full, detailed trace)
34.15 
34.15        error: undefined variable 'npm'
34.15        at /app/.nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix:19:34:
34.15            18|         '')
34.15            19|         deno nodejs_18 nodejs_18 npm npm
34.15              |                                  ^
34.15            20|       ];
------

 6 warnings found (use docker --debug to expand):
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_SUPABASE_ANON_KEY") (line 12)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_SUPABASE_SERVICE_ROLE_KEY") (line 12)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_EPAYCO_PRIVATE_KEY") (line 11)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_ANON_KEY") (line 11)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_SERVICE_ROLE_KEY") (line 11)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_EPAYCO_PRIVATE_KEY") (line 12)
Dockerfile:8
--------------------
   6 |     
   7 |     COPY .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix
   8 | >>> RUN nix-env -if .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix && nix-collect-garbage -d
   9 |     
  10 |     
--------------------
ERROR: failed to build: failed to solve: process "/bin/bash -ol pipefail -c nix-env -if .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix && nix-collect-garbage -d" did not complete successfully: exit code: 1
##########################################
### Error
### Sat, 26 Jul 2025 03:28:54 GMT
##########################################

Command failed with exit code 1: docker buildx build --network host -f /etc/easypanel/projects/academia_online_gamificacion/app_academia_vallenata_online/code/.nixpacks/Dockerfile -t easypanel/academia_online_gamificacion/app_academia_vallenata_online --label 'keep=true' --build-arg 'VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co' --build-arg 'VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NTQyNjIsImV4cCI6MjA1ODUzMDI2Mn0.P09L8OpLpcrm5XzTLAN0oQllhl_bePk5bxbUUpoG-cQ' --build-arg 'VITE_SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0Mjk1NDI2MiwiZXhwIjoyMDU4NTMwMjYyfQ.OfKotOdcC3wmCCQz3VhLVfQMgLcQN-VlgDC6D5fqRJU' --build-arg 'VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb' --build-arg 'VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1' --build-arg 'VITE_EPAYCO_CUSTOMER_ID=37257' --build-arg 'VITE_EPAYCO_TEST_MODE=true' --build-arg 'VITE_APP_URL=https://academia-app-academia-vallenata-online.lnrubg.easypanel.host/' --build-arg 'NODE_ENV=production' --build-arg 'GIT_SHA=63be2b57102c9f14606115e0e5736cc5c2cad767' /etc/easypanel/projects/academia_online_gamificacion/app_academia_vallenata_online/code/