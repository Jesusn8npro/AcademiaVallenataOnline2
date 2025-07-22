Commit: 🔧 FIX: Optimize for Nixpacks deployment in Easypanel

- Removed Dockerfile and .dockerignore (not needed for Nixpacks)
- Simplified nixpacks.toml to minimal configuration
- Changed adapter from adapter-node to adapter-auto for vite preview
- Updated start command to use 'npm run preview'
- Confirmed local build and preview work correctly

This configuration is now optimized for Easypanel's Nixpacks deployment method. 
##########################################
### Download Github Archive Started...
### Tue, 22 Jul 2025 17:13:31 GMT
##########################################


╔═════ Nixpacks v1.34.1 ═════╗
║ setup      │ deno          ║
║────────────────────────────║
║ install    │ npm install   ║
║────────────────────────────║
║ build      │ npm run build ║
║────────────────────────────║
║ start      │ node build    ║
╚════════════════════════════╝


Saved output to:
  /etc/easypanel/projects/academia_vallenata_online/academia_vallenata_online/code/
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 1.11kB done
#1 DONE 0.0s

#2 [internal] load metadata for ghcr.io/railwayapp/nixpacks:ubuntu-1741046653
#2 DONE 0.7s

#3 [internal] load .dockerignore
#3 transferring context: 253B done
#3 DONE 0.0s

#4 [1/9] FROM ghcr.io/railwayapp/nixpacks:ubuntu-1741046653@sha256:ed406b77fb751927991b8655e76c33a4521c4957c2afeab293be7c63c2a373d2
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 30.46MB 0.3s done
#5 DONE 0.3s

#6 [2/9] WORKDIR /app/
#6 CACHED

#7 [3/9] COPY .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix
#7 DONE 0.1s

#8 [4/9] RUN nix-env -if .nixpacks/nixpkgs-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.nix && nix-collect-garbage -d
#8 0.120 unpacking 'https://github.com/NixOS/nixpkgs/archive/5148520bfab61f99fd25fb9ff7bfbb50dad3c9db.tar.gz' into the Git cache...
#8 30.39 installing '5148520bfab61f99fd25fb9ff7bfbb50dad3c9db-env'
#8 31.38 these 4 derivations will be built:
#8 31.38   /nix/store/ffgkhpmqnnwqvfd0jh3s33z812rwp8s3-builder.pl.drv
#8 31.38   /nix/store/y8fgajnv506phnyaphj9nywx8lssp1np-libraries.drv
#8 31.38   /nix/store/jhqnl53k8zrgfjcd0jiyfcnihx8jwlaq-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db-env.drv
#8 31.38   /nix/store/f6a4gyh4r0d3id8d25h8lx5bckbq86fy-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db-env.drv
#8 31.38 these 35 paths will be fetched (45.84 MiB download, 206.40 MiB unpacked):
#8 31.38   /nix/store/aj6gbshd8hvifpa1d8vy0iv688sm81wp-acl-2.3.1
#8 31.38   /nix/store/srrs7gn04rwa4f6zhsjkdacxydwrmzhj-attr-2.5.1
#8 31.38   /nix/store/vqvj60h076bhqj6977caz0pfxs6543nb-bash-5.2-p15
#8 31.38   /nix/store/rmgpmxddh2hl3yl43f1kacrpd85cdrs4-bzip2-1.0.8
#8 31.38   /nix/store/dwxydys9kcz5l2901asxdvh3qdh981b1-bzip2-1.0.8-bin
#8 31.38   /nix/store/apn3p2b40xvirn7w740wv2gy330ppib5-coreutils-9.3
#8 31.38   /nix/store/4ky0adziza8yy3xpq97jp17hqdgrgi60-deno-1.36.0
#8 31.38   /nix/store/5ca2vh08sq8m20mv4z3wd1lij6wngym0-diffutils-3.10
#8 31.38   /nix/store/wgqxfhs0zj7fl182nk92rsslp796cjx4-ed-1.19
#8 31.38   /nix/store/vzjkllqadhpmy9jbzqvq94xipvd5xk5f-file-5.45
#8 31.38   /nix/store/xvhh3dzdqfaz78nhya1xildz2r38sy3s-findutils-4.9.0
#8 31.38   /nix/store/47pwjwir6m3r0czs8zir5wzfvk7i5z6i-gawk-5.2.2
#8 31.38   /nix/store/xpxln7rqi3pq4m0xpnawhxb2gs0mn1s0-gcc-12.3.0-lib
#8 31.38   /nix/store/3wwfqhdym0sbis4bad1may3ll8rki8y1-gcc-12.3.0-libgcc
#8 31.38   /nix/store/aw2fw9ag10wr9pf0qk4nk5sxi0q0bn56-glibc-2.37-8
#8 31.38   /nix/store/yqa5m326a0ynn4whm4fikyjfljfc6i3q-gmp-with-cxx-6.3.0
#8 31.38   /nix/store/knwyqhxbsxflilyy0mkpai2fp3lxarqz-gnu-config-2023-07-31
#8 31.38   /nix/store/4hx292xs95frrd1hqwwfc2fpcz0niwgp-gnugrep-3.11
#8 31.38   /nix/store/s806iqg5vwsnp434i5whcn1rf605y9s6-gnumake-4.4.1
#8 31.38   /nix/store/7snlgj0l0ys6lbcl5pyy8vwnmk26wh8x-gnused-4.9
#8 31.38   /nix/store/d960k69nahxms669k9fl5rqhk0fkfzr5-gnutar-1.35
#8 31.38   /nix/store/7nfcdvrmdbpms7wcrjjsqwkv07lswhli-gzip-1.13
#8 31.38   /nix/store/k8ivghpggjrq1n49xp8sj116i4sh8lia-libidn2-2.3.4
#8 31.38   /nix/store/s2gi8pfjszy6rq3ydx0z1vwbbskw994i-libunistring-1.1
#8 31.38   /nix/store/jx3kvf6mk8qdaw30dbpngwmgm4p23xdb-libxcrypt-4.4.36
#8 31.38   /nix/store/63m0np3ypqr741nn1a3xmg39p6f97ix1-patch-2.7.6
#8 31.38   /nix/store/v553h3r3f0xqxpvb9pgzx006qrmmv12m-patchelf-0.15.0
#8 31.38   /nix/store/761y2sshd57g3jlgr32s6ac3cv1xhb4b-pcre2-10.42
#8 31.38   /nix/store/1dlkj7j9av3x88l5ri9w08hdvkwmyznx-perl-5.38.0
#8 31.38   /nix/store/mbj7giif6mf1hcda9w4kcr3s01rp66j7-stdenv-linux
#8 31.38   /nix/store/fdgkgam7dgivvg4dzc12k3mlyx6sxrq5-update-autotools-gnu-config-scripts-hook
#8 31.38   /nix/store/jbwb8d8l28lg9z0xzl784wyb9vlbwss6-xgcc-12.3.0-libgcc
#8 31.38   /nix/store/kfrcs055nxbkwd6yy39h5xxyrj8wrb73-xz-5.4.4
#8 31.38   /nix/store/b1rpgx8n48m6520gakkf9rsqf7kv7sra-xz-5.4.4-bin
#8 31.38   /nix/store/4rx3vkkd91wkbhpflsplfga603cp1l1c-zlib-1.3
#8 31.40 copying path '/nix/store/knwyqhxbsxflilyy0mkpai2fp3lxarqz-gnu-config-2023-07-31' from 'https://cache.nixos.org'...
#8 31.40 copying path '/nix/store/3wwfqhdym0sbis4bad1may3ll8rki8y1-gcc-12.3.0-libgcc' from 'https://cache.nixos.org'...
#8 31.40 copying path '/nix/store/jbwb8d8l28lg9z0xzl784wyb9vlbwss6-xgcc-12.3.0-libgcc' from 'https://cache.nixos.org'...
#8 31.40 copying path '/nix/store/s2gi8pfjszy6rq3ydx0z1vwbbskw994i-libunistring-1.1' from 'https://cache.nixos.org'...
#8 31.44 copying path '/nix/store/fdgkgam7dgivvg4dzc12k3mlyx6sxrq5-update-autotools-gnu-config-scripts-hook' from 'https://cache.nixos.org'...
#8 31.51 copying path '/nix/store/k8ivghpggjrq1n49xp8sj116i4sh8lia-libidn2-2.3.4' from 'https://cache.nixos.org'...
#8 31.58 copying path '/nix/store/aw2fw9ag10wr9pf0qk4nk5sxi0q0bn56-glibc-2.37-8' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/srrs7gn04rwa4f6zhsjkdacxydwrmzhj-attr-2.5.1' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/vqvj60h076bhqj6977caz0pfxs6543nb-bash-5.2-p15' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/rmgpmxddh2hl3yl43f1kacrpd85cdrs4-bzip2-1.0.8' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/wgqxfhs0zj7fl182nk92rsslp796cjx4-ed-1.19' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/47pwjwir6m3r0czs8zir5wzfvk7i5z6i-gawk-5.2.2' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/xpxln7rqi3pq4m0xpnawhxb2gs0mn1s0-gcc-12.3.0-lib' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/7snlgj0l0ys6lbcl5pyy8vwnmk26wh8x-gnused-4.9' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/s806iqg5vwsnp434i5whcn1rf605y9s6-gnumake-4.4.1' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/jx3kvf6mk8qdaw30dbpngwmgm4p23xdb-libxcrypt-4.4.36' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/kfrcs055nxbkwd6yy39h5xxyrj8wrb73-xz-5.4.4' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/4rx3vkkd91wkbhpflsplfga603cp1l1c-zlib-1.3' from 'https://cache.nixos.org'...
#8 32.07 copying path '/nix/store/761y2sshd57g3jlgr32s6ac3cv1xhb4b-pcre2-10.42' from 'https://cache.nixos.org'...
#8 32.10 copying path '/nix/store/dwxydys9kcz5l2901asxdvh3qdh981b1-bzip2-1.0.8-bin' from 'https://cache.nixos.org'...
#8 32.10 copying path '/nix/store/aj6gbshd8hvifpa1d8vy0iv688sm81wp-acl-2.3.1' from 'https://cache.nixos.org'...
#8 32.12 copying path '/nix/store/63m0np3ypqr741nn1a3xmg39p6f97ix1-patch-2.7.6' from 'https://cache.nixos.org'...
#8 32.13 copying path '/nix/store/vzjkllqadhpmy9jbzqvq94xipvd5xk5f-file-5.45' from 'https://cache.nixos.org'...
#8 32.18 copying path '/nix/store/d960k69nahxms669k9fl5rqhk0fkfzr5-gnutar-1.35' from 'https://cache.nixos.org'...
#8 32.18 copying path '/nix/store/7nfcdvrmdbpms7wcrjjsqwkv07lswhli-gzip-1.13' from 'https://cache.nixos.org'...
#8 32.20 copying path '/nix/store/b1rpgx8n48m6520gakkf9rsqf7kv7sra-xz-5.4.4-bin' from 'https://cache.nixos.org'...
#8 32.32 copying path '/nix/store/4hx292xs95frrd1hqwwfc2fpcz0niwgp-gnugrep-3.11' from 'https://cache.nixos.org'...
#8 32.40 copying path '/nix/store/4ky0adziza8yy3xpq97jp17hqdgrgi60-deno-1.36.0' from 'https://cache.nixos.org'...
#8 32.40 copying path '/nix/store/yqa5m326a0ynn4whm4fikyjfljfc6i3q-gmp-with-cxx-6.3.0' from 'https://cache.nixos.org'...
#8 32.40 copying path '/nix/store/v553h3r3f0xqxpvb9pgzx006qrmmv12m-patchelf-0.15.0' from 'https://cache.nixos.org'...
#8 32.47 copying path '/nix/store/apn3p2b40xvirn7w740wv2gy330ppib5-coreutils-9.3' from 'https://cache.nixos.org'...
#8 32.56 copying path '/nix/store/xvhh3dzdqfaz78nhya1xildz2r38sy3s-findutils-4.9.0' from 'https://cache.nixos.org'...
#8 32.56 copying path '/nix/store/5ca2vh08sq8m20mv4z3wd1lij6wngym0-diffutils-3.10' from 'https://cache.nixos.org'...
#8 32.56 copying path '/nix/store/1dlkj7j9av3x88l5ri9w08hdvkwmyznx-perl-5.38.0' from 'https://cache.nixos.org'...
#8 32.71 copying path '/nix/store/mbj7giif6mf1hcda9w4kcr3s01rp66j7-stdenv-linux' from 'https://cache.nixos.org'...
#8 32.95 building '/nix/store/ffgkhpmqnnwqvfd0jh3s33z812rwp8s3-builder.pl.drv'...
#8 33.16 building '/nix/store/y8fgajnv506phnyaphj9nywx8lssp1np-libraries.drv'...
#8 33.44 building '/nix/store/jhqnl53k8zrgfjcd0jiyfcnihx8jwlaq-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db-env.drv'...
#8 34.24 building '/nix/store/f6a4gyh4r0d3id8d25h8lx5bckbq86fy-5148520bfab61f99fd25fb9ff7bfbb50dad3c9db-env.drv'...
#8 34.31 created 3 symlinks in user environment
#8 34.35 building '/nix/store/3dv6lq5qbsm4g4ms9mgd37cyb5gk5cxp-user-environment.drv'...
#8 34.53 removing old generations of profile /nix/var/nix/profiles/per-user/root/channels
#8 34.53 removing old generations of profile /nix/var/nix/profiles/per-user/root/profile
#8 34.53 removing profile version 1
#8 34.53 removing old generations of profile /nix/var/nix/profiles/per-user/root/channels
#8 34.53 removing old generations of profile /nix/var/nix/profiles/per-user/root/profile
#8 34.54 finding garbage collector roots...
#8 34.54 removing stale link from '/nix/var/nix/gcroots/auto/lzjbmb2ry0z7lma2fvpqprb12921pnb5' to '/nix/var/nix/profiles/per-user/root/profile-1-link'
#8 34.55 deleting garbage...
#8 34.55 deleting '/nix/store/ir9fki7838bmk4hlj0zmwbw45q101j66-user-environment.drv'
#8 34.55 deleting '/nix/store/b9rj4wk1cxh7g2ib89aqbcapzzar8p2s-user-environment'
#8 34.55 deleting '/nix/store/xxyn8jfxcpr5ac9dvismfzx39ijh9kiv-env-manifest.nix'
#8 34.57 deleting '/nix/store/mbj7giif6mf1hcda9w4kcr3s01rp66j7-stdenv-linux'
#8 34.57 deleting '/nix/store/7snlgj0l0ys6lbcl5pyy8vwnmk26wh8x-gnused-4.9'
#8 34.58 deleting '/nix/store/dc4lnyzdwfck9fc9h8h6n7di5yki5ilx-builder.pl'
#8 34.58 deleting '/nix/store/fdgkgam7dgivvg4dzc12k3mlyx6sxrq5-update-autotools-gnu-config-scripts-hook'
#8 34.58 deleting '/nix/store/knwyqhxbsxflilyy0mkpai2fp3lxarqz-gnu-config-2023-07-31'
#8 34.58 deleting '/nix/store/xvhh3dzdqfaz78nhya1xildz2r38sy3s-findutils-4.9.0'
#8 34.59 deleting '/nix/store/5ca2vh08sq8m20mv4z3wd1lij6wngym0-diffutils-3.10'
#8 34.60 deleting '/nix/store/1dlkj7j9av3x88l5ri9w08hdvkwmyznx-perl-5.38.0'
#8 34.69 deleting '/nix/store/apn3p2b40xvirn7w740wv2gy330ppib5-coreutils-9.3'
#8 34.69 deleting '/nix/store/yqa5m326a0ynn4whm4fikyjfljfc6i3q-gmp-with-cxx-6.3.0'
#8 34.69 deleting '/nix/store/7nfcdvrmdbpms7wcrjjsqwkv07lswhli-gzip-1.13'
#8 34.70 deleting '/nix/store/vqvj60h076bhqj6977caz0pfxs6543nb-bash-5.2-p15'
#8 34.70 deleting '/nix/store/vzjkllqadhpmy9jbzqvq94xipvd5xk5f-file-5.45'
#8 34.70 deleting '/nix/store/s806iqg5vwsnp434i5whcn1rf605y9s6-gnumake-4.4.1'
#8 34.70 deleting '/nix/store/dwxydys9kcz5l2901asxdvh3qdh981b1-bzip2-1.0.8-bin'
#8 34.71 deleting '/nix/store/lgcjj6s23v2203zyihsd0j26wh1saj0c-source'
#8 38.09 deleting '/nix/store/rmgpmxddh2hl3yl43f1kacrpd85cdrs4-bzip2-1.0.8'
#8 38.09 deleting '/nix/store/d960k69nahxms669k9fl5rqhk0fkfzr5-gnutar-1.35'
#8 38.10 deleting '/nix/store/aj6gbshd8hvifpa1d8vy0iv688sm81wp-acl-2.3.1'
#8 38.10 deleting '/nix/store/srrs7gn04rwa4f6zhsjkdacxydwrmzhj-attr-2.5.1'
#8 38.11 deleting '/nix/store/jx3kvf6mk8qdaw30dbpngwmgm4p23xdb-libxcrypt-4.4.36'
#8 38.11 deleting '/nix/store/3j46jwmzy43vq969pqy1z5vp426xn46k-libraries'
#8 38.11 deleting '/nix/store/63m0np3ypqr741nn1a3xmg39p6f97ix1-patch-2.7.6'
#8 38.11 deleting '/nix/store/wgqxfhs0zj7fl182nk92rsslp796cjx4-ed-1.19'
#8 38.11 deleting '/nix/store/4hx292xs95frrd1hqwwfc2fpcz0niwgp-gnugrep-3.11'
#8 38.12 deleting '/nix/store/v553h3r3f0xqxpvb9pgzx006qrmmv12m-patchelf-0.15.0'
#8 38.12 deleting '/nix/store/761y2sshd57g3jlgr32s6ac3cv1xhb4b-pcre2-10.42'
#8 38.12 deleting '/nix/store/b1rpgx8n48m6520gakkf9rsqf7kv7sra-xz-5.4.4-bin'
#8 38.12 deleting '/nix/store/kfrcs055nxbkwd6yy39h5xxyrj8wrb73-xz-5.4.4'
#8 38.13 deleting '/nix/store/47pwjwir6m3r0czs8zir5wzfvk7i5z6i-gawk-5.2.2'
#8 38.13 deleting '/nix/store/4rx3vkkd91wkbhpflsplfga603cp1l1c-zlib-1.3'
#8 38.13 deleting unused links...
#8 38.13 note: currently hard linking saves -0.00 MiB
#8 38.16 34 store paths deleted, 214.19 MiB freed
#8 DONE 38.2s

#9 [5/9] COPY . /app/.
#9 DONE 0.2s

#10 [6/9] RUN  npm install
#10 0.067 /bin/bash: line 1: npm: command not found
#10 ERROR: process "/bin/bash -ol pipefail -c npm install" did not complete successfully: exit code: 127
------
 > [6/9] RUN  npm install:
0.067 /bin/bash: line 1: npm: command not found
------

 4 warnings found (use docker --debug to expand):
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_EPAYCO_PRIVATE_KEY") (line 11)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "VITE_SUPABASE_ANON_KEY") (line 11)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_EPAYCO_PRIVATE_KEY") (line 12)
 - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "VITE_SUPABASE_ANON_KEY") (line 12)
Dockerfile:19
--------------------
  17 |     # install phase
  18 |     COPY . /app/.
  19 | >>> RUN  npm install
  20 |     
  21 |     # build phase
--------------------
ERROR: failed to solve: process "/bin/bash -ol pipefail -c npm install" did not complete successfully: exit code: 127
##########################################
### Error
### Tue, 22 Jul 2025 17:14:14 GMT
##########################################

Command failed with exit code 1: docker buildx build --network host -f /etc/easypanel/projects/academia_vallenata_online/academia_vallenata_online/code/.nixpacks/Dockerfile -t easypanel/academia_vallenata_online/academia_vallenata_online --label 'keep=true' --build-arg 'NODE_ENV=production' --build-arg 'VITE_SUPABASE_URL=https://tbijzvtyyewhtwgakgka.supabase.co' --build-arg 'VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiaWp6dnR5eWV3aHR3Z2FrZ2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NTQyNjIsImV4cCI6MjA1ODUzMDI2Mn0.P09L8OpLpcrm5XzTLAN0oQllhl_bePk5bxbUUpoG-cQ' --build-arg 'VITE_EPAYCO_PUBLIC_KEY=a04d60e2e678d5bd89a58d26f3413fdb' --build-arg 'VITE_EPAYCO_PRIVATE_KEY=83ec651809bb7d11fcd114b16777bfa1' --build-arg 'VITE_EPAYCO_CUSTOMER_ID=37257' --build-arg 'VITE_EPAYCO_TEST_MODE=true' --build-arg 'VITE_APP_URL=https://academia-online-academia-vallenata-online.lnrubg.easypanel.host' --build-arg 'GIT_SHA=a8e40e316c180e882944679090a60d7bc025ea20' /etc/easypanel/projects/academia_vallenata_online/academia_vallenata_online/code/